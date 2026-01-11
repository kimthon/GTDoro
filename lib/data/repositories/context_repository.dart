import 'dart:developer' as dev;

import 'package:drift/drift.dart';

import 'package:gtdoro/data/local/app_database.dart';
import 'package:gtdoro/data/sync/oracle/utils/rev_helper.dart';

class ContextRepository {
  final AppDatabase _db;

  ContextRepository(this._db);

  Stream<List<Context>> watchAllContexts() {
    try {
      return (_db.select(_db.contexts)
            ..where((tbl) => tbl.isDeleted.equals(false)))
          .watch();
    } catch (e, stackTrace) {
      dev.log('ContextRepository: Error in watchAllContexts', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> saveContext(ContextsCompanion context) async {
    try {
      // Use insertOnConflictUpdate for more efficient processing
      await _db.into(_db.contexts).insertOnConflictUpdate(context);
      dev.log('ContextRepository: saveContext completed for ID: ${context.id.value}');
    } catch (e, stackTrace) {
      dev.log('ContextRepository: Error in saveContext', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Context 삭제 (soft delete 사용 - 동기화를 위해)
  /// isDeleted 플래그를 true로 설정하여 실제 삭제 대신 마킹
  Future<void> removeContext(String id) async {
    try {
      final now = DateTime.now();
      
      // 기존 context 조회 (rev 갱신을 위해)
      final existing = await (_db.select(_db.contexts)..where((t) => t.id.equals(id))).getSingleOrNull();
      final previousRev = existing?.rev;
      
      // rev 갱신 (오버플로우 안전)
      final newRev = RevHelper.generateNewRev(previousRev: previousRev);
      
      // Soft delete: isDeleted를 true로 설정
      final companion = ContextsCompanion(
        id: Value(id),
        isDeleted: const Value(true),
        rev: Value(newRev), // rev 갱신 (오버플로우 안전)
        updatedAt: Value(now),
      );
      
      await _db.into(_db.contexts).insertOnConflictUpdate(companion);
      dev.log('ContextRepository: removeContext completed (soft delete) for ID: $id');
    } catch (e, stackTrace) {
      dev.log('ContextRepository: Error in removeContext', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<Context>> getModifiedContexts(int timestamp) async {
    try {
      final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final result = await (_db.select(_db.contexts)
            ..where((tbl) => tbl.updatedAt.isBiggerThanValue(dt)))
          .get();
      dev.log('ContextRepository: getModifiedContexts found ${result.length} contexts');
      return result;
    } catch (e, stackTrace) {
      dev.log('ContextRepository: Error in getModifiedContexts', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<Context>> getAllContexts() async {
    try {
      final result = await (_db.select(_db.contexts)
            ..where((tbl) => tbl.isDeleted.equals(false)))
          .get();
      dev.log('ContextRepository: getAllContexts found ${result.length} contexts');
      return result;
    } catch (e, stackTrace) {
      dev.log('ContextRepository: Error in getAllContexts', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// ID로 Context 조회 (삭제된 항목 포함, 동기화용)
  /// 충돌 감지를 위해 삭제된 항목도 가져올 수 있어야 함
  Future<Context?> getContextById(String id) async {
    try {
      final result = await (_db.select(_db.contexts)
            ..where((tbl) => tbl.id.equals(id)))
          .getSingleOrNull();
      return result;
    } catch (e, stackTrace) {
      dev.log('ContextRepository: Error in getContextById', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
