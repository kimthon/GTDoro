import 'dart:async';
import 'dart:developer' as dev;

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:gtdoro/core/constants/app_strings.dart';
import 'package:gtdoro/core/utils/change_detector.dart';
import 'package:gtdoro/core/utils/list_extensions.dart';
import 'package:gtdoro/data/local/app_database.dart';
import 'package:gtdoro/data/local/oracle_serialization.dart';
import 'package:gtdoro/data/repositories/context_repository.dart';
import 'package:gtdoro/data/sync/oracle/utils/rev_helper.dart';
import 'package:gtdoro/features/todo/providers/action_provider.dart';
import 'package:gtdoro/features/todo/providers/sync_provider.dart';
import 'package:gtdoro/features/todo/providers/sync_trigger_mixin.dart';

class ContextProvider with ChangeNotifier, SyncTriggerMixin {
  final ActionProvider _actionProvider;
  final ContextRepository _repository;
  SyncProvider? _syncProvider;
  List<Context> _availableContexts = [];
  List<Context>? _cachedAvailableContexts; // Cache filtered contexts
  final Set<String> _activeFilterIds = {};
  late StreamSubscription<List<Context>> _contextSubscription;
  bool _isDisposed = false;
  static const _uuid = Uuid();

  ContextProvider({
    required ActionProvider actionProvider,
    required ContextRepository repository,
  })  : _actionProvider = actionProvider,
        _repository = repository {
    _contextSubscription = _repository.watchAllContexts().listen(
      (contexts) {
        if (_isDisposed) return; // Prevent execution after dispose
        
        // 성능 최적화: 실제로 변경되었는지 확인
        final contextsChanged = ChangeDetector.hasContextListChanged(
          _availableContexts,
          contexts,
          (c) => c.id,
          (c) => c.updatedAt,
        );
        
        if (!contextsChanged && _availableContexts.isNotEmpty) {
          // 변경사항이 없으면 건너뜀 (성능 최적화)
          return;
        }
        
        _availableContexts = contexts;
        _cachedAvailableContexts = null; // Invalidate cache
        if (!_isDisposed) {
          notifyListeners();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        dev.log('ContextProvider: Stream error', error: error, stackTrace: stackTrace);
      },
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _contextSubscription.cancel();
    super.dispose();
  }

  void setSyncProvider(SyncProvider provider) {
    _syncProvider = provider;
  }

  @override
  SyncProvider? get syncProvider => _syncProvider;

  // --- Getters ---
  List<Context> get availableContexts {
    // Cache filtered result to avoid repeated filtering
    return _cachedAvailableContexts ??= 
        _availableContexts.where((c) => !c.isDeleted).toList();
  }

  Set<String> get activeFilterIds => _activeFilterIds;

  // --- Methods ---
  void toggleFilter(Context context) {
    if (_activeFilterIds.contains(context.id)) {
      _activeFilterIds.remove(context.id);
    } else {
      _activeFilterIds.add(context.id);
    }
    notifyListeners();
    _actionProvider.onContextFilterChanged();
  }

  void clearFilters() {
    _activeFilterIds.clear();
    notifyListeners();
    _actionProvider.onContextFilterChanged();
  }

  List<Context> getContextsByIds(List<String> ids) {
    try {
      // Use Set for O(1) lookup instead of O(n) contains
      final idsSet = ids.toSet();
      return _availableContexts
          .where((c) => idsSet.contains(c.id) && !c.isDeleted)
          .toList();
    } catch (e) {
      dev.log('ContextProvider: Failed to get contexts by IDs', error: e);
      return [];
    }
  }

  Future<void> addContext({
    required String name,
    String? category,
    required ContextType type,
    required int colorValue,
  }) async {
    try {
      final cleanedName = name.replaceAll('#', '').trim();
      if (cleanedName.isEmpty) {
        throw ArgumentError('Context name cannot be empty');
      }
      final cleanedCategory = category?.trim();
      final now = DateTime.now();
      final newRev = RevHelper.generateNewRev(); // rev 생성 (오버플로우 안전)
      
      final companion = ContextsCompanion.insert(
        id: _uuid.v4(),
        name: cleanedName,
        category: cleanedCategory != null && cleanedCategory.isNotEmpty 
            ? Value(cleanedCategory) 
            : const Value.absent(),
        typeCategory: type,
        colorValue: colorValue,
        rev: Value(newRev), // rev 생성 (오버플로우 안전)
        updatedAt: Value(now),
      );
      await _repository.saveContext(companion);
      
      // 변경된 항목만 즉시 원격 DB에 업로드
      try {
        final savedContext = await _repository.getContextById(companion.id.value!);
        if (savedContext != null && _syncProvider != null) {
          final oracleJson = savedContext.toOracleJson();
          await _syncProvider!.uploadSingleItem(oracleJson);
          dev.log('ContextProvider: Single context uploaded immediately (ID: ${companion.id.value})');
        }
      } catch (e, stackTrace) {
        dev.log('ContextProvider: Error uploading single context (will sync later)', error: e, stackTrace: stackTrace);
        // 업로드 실패해도 전체 동기화는 트리거
      }
      
      triggerSyncIfAvailable();
    } catch (e, stackTrace) {
      dev.log('ContextProvider: Error in addContext', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> updateContext(
    String id, {
    String? name,
    String? category,
    ContextType? type,
    int? colorValue,
  }) async {
    try {
      if (name != null && name.replaceAll('#', '').trim().isEmpty) {
        throw ArgumentError('Context name cannot be empty');
      }
      
      // 기존 context 찾기 (rev 갱신을 위해)
      final existingContext = _availableContexts.firstWhereOrNull((c) => c.id == id);
      if (existingContext == null) {
        throw StateError('Context not found: $id');
      }
      
      final now = DateTime.now();
      final newRev = RevHelper.generateNewRev(previousRev: existingContext.rev); // rev 갱신 (오버플로우 안전)
      
      final companion = ContextsCompanion(
        id: Value(id),
        name: name != null ? Value(name.replaceAll('#', '').trim()) : const Value.absent(),
        category: category != null 
            ? (category.trim().isNotEmpty ? Value(category.trim()) : const Value.absent())
            : const Value.absent(),
        typeCategory: type != null ? Value(type) : const Value.absent(),
        colorValue: colorValue != null ? Value(colorValue) : const Value.absent(),
        rev: Value(newRev), // rev 갱신 (오버플로우 안전)
        updatedAt: Value(now),
      );
      await _repository.saveContext(companion);
      
      // 변경된 항목만 즉시 원격 DB에 업로드
      try {
        final savedContext = await _repository.getContextById(id);
        if (savedContext != null && _syncProvider != null) {
          final oracleJson = savedContext.toOracleJson();
          await _syncProvider!.uploadSingleItem(oracleJson);
          dev.log('ContextProvider: Single context uploaded immediately (ID: $id)');
        }
      } catch (e, stackTrace) {
        dev.log('ContextProvider: Error uploading single context (will sync later)', error: e, stackTrace: stackTrace);
        // 업로드 실패해도 전체 동기화는 트리거
      }
      
      triggerSyncIfAvailable();
    } catch (e, stackTrace) {
      dev.log('ContextProvider: Error in updateContext', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Context를 "컨텍스트 구분::컨텍스트" 형식으로 표시
  static String formatContextName(Context context) {
    final typeName = _getContextTypeName(context.typeCategory);
    return '$typeName::${context.name}';
  }

  /// ContextType을 한국어로 변환
  static String _getContextTypeName(ContextType type) {
    switch (type) {
      case ContextType.location:
        return '장소';
      case ContextType.tool:
        return '도구';
      case ContextType.person:
        return '관계';
      case ContextType.etc:
        return AppStrings.contextTypeOther;
    }
  }

  Future<void> removeContext(String id) async {
    try {
      // 기존 context 찾기 (rev 갱신을 위해)
      final existingContext = _availableContexts.firstWhereOrNull((c) => c.id == id);
      if (existingContext == null) {
        throw StateError('Context not found: $id');
      }
      
      final now = DateTime.now();
      final newRev = RevHelper.generateNewRev(previousRev: existingContext.rev); // rev 갱신 (오버플로우 안전)
      
      final companion = ContextsCompanion(
        id: Value(id),
        isDeleted: const Value(true),
        rev: Value(newRev), // rev 갱신 (오버플로우 안전)
        updatedAt: Value(now),
      );
      await _repository.saveContext(companion);
      
      // 변경된 항목만 즉시 원격 DB에 업로드 (삭제 마킹)
      try {
        final savedContext = await _repository.getContextById(id);
        if (savedContext != null && _syncProvider != null) {
          final oracleJson = savedContext.toOracleJson();
          await _syncProvider!.uploadSingleItem(oracleJson);
          dev.log('ContextProvider: Single context (deleted) uploaded immediately (ID: $id)');
        }
      } catch (e, stackTrace) {
        dev.log('ContextProvider: Error uploading single context (will sync later)', error: e, stackTrace: stackTrace);
        // 업로드 실패해도 전체 동기화는 트리거
      }
      
      await _actionProvider.removeContextIdFromAllActions(id);
      triggerSyncIfAvailable();
    } catch (e, stackTrace) {
      dev.log('ContextProvider: Error in removeContext', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
