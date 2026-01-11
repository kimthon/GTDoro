import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart' hide Action;

import 'package:gtdoro/data/local/app_database.dart';
import 'package:gtdoro/core/utils/change_detector.dart';
import 'package:gtdoro/data/repositories/action_repository.dart';
import 'package:gtdoro/features/todo/providers/action_provider_crud_mixin.dart';
import 'package:gtdoro/features/todo/providers/action_provider_getters_mixin.dart';
import 'package:gtdoro/features/todo/providers/action_provider_logbook_mixin.dart';
import 'package:gtdoro/features/todo/providers/context_provider.dart';
import 'package:gtdoro/features/todo/providers/sync_provider.dart';

class ActionProvider with ChangeNotifier, ActionProviderLogbookMixin, ActionProviderGettersMixin, ActionProviderCrudMixin {
  final ActionRepository _repository;
  SyncProvider? _syncProvider;
  ContextProvider? _contextProvider;
  List<ActionWithContexts> _actions = [];
  late StreamSubscription<List<ActionWithContexts>> _actionSubscription;
  bool _isDisposed = false;

  @override
  ActionRepository get repository => _repository;

  @override
  List<ActionWithContexts> get allActions => _actions;

  @override
  ContextProvider? get contextProvider => _contextProvider;

  ActionProvider({
    required ActionRepository repository,
  }) : _repository = repository {
    dev.log('ActionProvider: Initializing stream subscription');
    _actionSubscription = _repository.watchAllActions().listen(
      (actions) {
        if (_isDisposed) return; // Prevent execution after dispose
        
        // Actions가 실제로 변경되었는지 확인 (불필요한 리빌드 방지)
        // isDone 필드도 비교에 포함하여 완료 상태 변경도 감지
        final actionsChanged = ChangeDetector.hasActionListChanged(
          _actions,
          actions,
          (a) => a.action.id,
          (a) => a.action.updatedAt,
          (a) => a.action.isDeleted,
          getIsDone: (a) => a.action.isDone,
        );
        
        if (!actionsChanged && _actions.isNotEmpty) {
          // 변경사항이 없으면 건너뜀 (성능 최적화)
          return;
        }
        
        dev.log('ActionProvider: Stream update received, ${actions.length} actions');
        _actions = actions;
        if (!_isDisposed) {
          dev.log('ActionProvider: Notifying listeners');
          notifyListeners();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        dev.log('ActionProvider: Stream error', error: error, stackTrace: stackTrace);
      },
    );
    dev.log('ActionProvider: Stream subscription initialized');
  }

  @override
  void dispose() {
    _isDisposed = true;
    cancelLogbookDebounce();
    _actionSubscription.cancel();
    super.dispose();
  }

  void setSyncProvider(SyncProvider provider) {
    _syncProvider = provider;
  }

  void setContextProvider(ContextProvider provider) {
    _contextProvider = provider;
  }

  @override
  SyncProvider? get syncProvider => _syncProvider;

  @override
  void triggerSync() {
    final sync = _syncProvider;
    if (sync != null && sync.canSync) {
      dev.log('ActionProvider: Data change detected, requesting immediate sync (debounced)...');
      sync.triggerImmediateSync(); // 여러 기기 동시 사용 고려: debounce 적용된 즉시 동기화
    }
  }

  void onContextFilterChanged() {
    notifyListeners();
  }
}
