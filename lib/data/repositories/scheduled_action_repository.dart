import 'dart:developer' as dev;

import 'package:drift/drift.dart';

import 'package:gtdoro/data/local/app_database.dart';
import 'package:gtdoro/data/sync/oracle/utils/rev_helper.dart';

class ScheduledActionRepository {
  final AppDatabase _db;

  ScheduledActionRepository(this._db);

  Stream<List<ScheduledAction>> watchAllScheduledActions() {
    try {
      return (_db.select(_db.scheduledActions)
            ..where((tbl) => tbl.isDeleted.equals(false)))
          .watch();
    } catch (e, stackTrace) {
      dev.log('ScheduledActionRepository: Error in watchAllScheduledActions', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> saveScheduledAction(ScheduledActionsCompanion action) async {
    try {
      // Use insertOnConflictUpdate for more efficient processing
      await _db.into(_db.scheduledActions).insertOnConflictUpdate(action);
      dev.log('ScheduledActionRepository: saveScheduledAction completed for ID: ${action.id.value}');
    } catch (e, stackTrace) {
      dev.log('ScheduledActionRepository: Error in saveScheduledAction', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// ScheduledAction 삭제 (soft delete 사용 - 동기화를 위해)
  /// isDeleted 플래그를 true로 설정하여 실제 삭제 대신 마킹
  Future<void> removeScheduledAction(String id) async {
    try {
      final now = DateTime.now();
      
      // 기존 scheduled action 조회 (rev 갱신을 위해)
      final existing = await (_db.select(_db.scheduledActions)..where((t) => t.id.equals(id))).getSingleOrNull();
      final previousRev = existing?.rev;
      
      // rev 갱신 (오버플로우 안전)
      final newRev = RevHelper.generateNewRev(previousRev: previousRev);
      
      // Soft delete: isDeleted를 true로 설정
      final companion = ScheduledActionsCompanion(
        id: Value(id),
        isDeleted: const Value(true),
        rev: Value(newRev), // rev 갱신 (오버플로우 안전)
        updatedAt: Value(now),
      );
      
      await _db.into(_db.scheduledActions).insertOnConflictUpdate(companion);
      dev.log('ScheduledActionRepository: removeScheduledAction completed (soft delete) for ID: $id');
    } catch (e, stackTrace) {
      dev.log('ScheduledActionRepository: Error in removeScheduledAction', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<ScheduledAction>> getModifiedScheduledActions(
      int timestamp) async {
    try {
      final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final result = await (_db.select(_db.scheduledActions)
            ..where((tbl) => tbl.updatedAt.isBiggerThanValue(dt)))
          .get();
      dev.log('ScheduledActionRepository: getModifiedScheduledActions found ${result.length} actions');
      return result;
    } catch (e, stackTrace) {
      dev.log('ScheduledActionRepository: Error in getModifiedScheduledActions', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<ScheduledAction>> getAllScheduledActions() async {
    try {
      final result = await (_db.select(_db.scheduledActions)
            ..where((tbl) => tbl.isDeleted.equals(false)))
          .get();
      dev.log('ScheduledActionRepository: getAllScheduledActions found ${result.length} actions');
      return result;
    } catch (e, stackTrace) {
      dev.log('ScheduledActionRepository: Error in getAllScheduledActions', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// ID로 ScheduledAction 조회 (삭제된 항목 포함, 동기화용)
  /// 충돌 감지를 위해 삭제된 항목도 가져올 수 있어야 함
  Future<ScheduledAction?> getScheduledActionById(String id) async {
    try {
      final result = await (_db.select(_db.scheduledActions)
            ..where((tbl) => tbl.id.equals(id)))
          .getSingleOrNull();
      return result;
    } catch (e, stackTrace) {
      dev.log('ScheduledActionRepository: Error in getScheduledActionById', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
