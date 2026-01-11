import 'dart:developer' as dev;

import 'package:drift/drift.dart';

import 'package:gtdoro/data/local/app_database.dart';
import 'package:gtdoro/data/sync/oracle/utils/rev_helper.dart';

class RecurringActionRepository {
  final AppDatabase _db;

  RecurringActionRepository(this._db);

  Stream<List<RecurringAction>> watchAllRecurringActions() {
    try {
      return (_db.select(_db.recurringActions)
            ..where((tbl) => tbl.isDeleted.equals(false)))
          .watch();
    } catch (e, stackTrace) {
      dev.log('RecurringActionRepository: Error in watchAllRecurringActions', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> saveRecurringAction(RecurringActionsCompanion action) async {
    try {
      // Use insertOnConflictUpdate for more efficient processing
      await _db.into(_db.recurringActions).insertOnConflictUpdate(action);
      dev.log('RecurringActionRepository: saveRecurringAction completed for ID: ${action.id.value}');
    } catch (e, stackTrace) {
      dev.log('RecurringActionRepository: Error in saveRecurringAction', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// RecurringAction 삭제 (soft delete 사용 - 동기화를 위해)
  /// isDeleted 플래그를 true로 설정하여 실제 삭제 대신 마킹
  Future<void> removeRecurringAction(String id) async {
    try {
      final now = DateTime.now();
      
      // 기존 recurring action 조회 (rev 갱신을 위해)
      final existing = await (_db.select(_db.recurringActions)..where((t) => t.id.equals(id))).getSingleOrNull();
      final previousRev = existing?.rev;
      
      // rev 갱신 (오버플로우 안전)
      final newRev = RevHelper.generateNewRev(previousRev: previousRev);
      
      // Soft delete: isDeleted를 true로 설정
      final companion = RecurringActionsCompanion(
        id: Value(id),
        isDeleted: const Value(true),
        rev: Value(newRev), // rev 갱신 (오버플로우 안전)
        updatedAt: Value(now),
      );
      
      await _db.into(_db.recurringActions).insertOnConflictUpdate(companion);
      dev.log('RecurringActionRepository: removeRecurringAction completed (soft delete) for ID: $id');
    } catch (e, stackTrace) {
      dev.log('RecurringActionRepository: Error in removeRecurringAction', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<RecurringAction>> getModifiedRecurringActions(
      int timestamp) async {
    try {
      final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final result = await (_db.select(_db.recurringActions)
            ..where((tbl) => tbl.updatedAt.isBiggerThanValue(dt)))
          .get();
      dev.log('RecurringActionRepository: getModifiedRecurringActions found ${result.length} actions');
      return result;
    } catch (e, stackTrace) {
      dev.log('RecurringActionRepository: Error in getModifiedRecurringActions', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<RecurringAction>> getAllRecurringActions() async {
    try {
      final result = await (_db.select(_db.recurringActions)
            ..where((tbl) => tbl.isDeleted.equals(false)))
          .get();
      dev.log('RecurringActionRepository: getAllRecurringActions found ${result.length} actions');
      return result;
    } catch (e, stackTrace) {
      dev.log('RecurringActionRepository: Error in getAllRecurringActions', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// ID로 RecurringAction 조회 (삭제된 항목 포함, 동기화용)
  /// 충돌 감지를 위해 삭제된 항목도 가져올 수 있어야 함
  Future<RecurringAction?> getRecurringActionById(String id) async {
    try {
      final result = await (_db.select(_db.recurringActions)
            ..where((tbl) => tbl.id.equals(id)))
          .getSingleOrNull();
      return result;
    } catch (e, stackTrace) {
      dev.log('RecurringActionRepository: Error in getRecurringActionById', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
