import 'dart:developer' as dev;

import 'package:drift/drift.dart';

import 'package:gtdoro/data/local/app_database.dart';
import 'package:gtdoro/data/sync/oracle/utils/rev_helper.dart';

class ActionRepository {
  final AppDatabase _db;

  ActionRepository(this._db);

  /// Helper function to convert join query results to ActionWithContexts list
  List<ActionWithContexts> _mapRows(List<TypedResult> rows) {
    final Map<String, ActionWithContexts> grouped = {};

    for (final row in rows) {
      final action = row.readTable(_db.actions);
      final contextId = row.readTableOrNull(_db.actionContexts)?.contextId;

      if (!grouped.containsKey(action.id)) {
        grouped[action.id] = ActionWithContexts(action, []);
      }
      if (contextId != null) {
        grouped[action.id]!.contextIds.add(contextId);
      }
    }
    return grouped.values.toList();
  }

  /// Watch all actions with Context information (Stream)
  Stream<List<ActionWithContexts>> watchAllActions() {
    final query = _db.select(_db.actions).join([
      leftOuterJoin(
        _db.actionContexts,
        _db.actionContexts.actionId.equalsExp(_db.actions.id),
      ),
    ]);
    return query.watch().map(_mapRows);
  }

  /// Get all actions with Context information (Future)
  Future<List<ActionWithContexts>> getAllActions() async {
    final query = _db.select(_db.actions).join([
      leftOuterJoin(
        _db.actionContexts,
        _db.actionContexts.actionId.equalsExp(_db.actions.id),
      ),
    ]);
    return _mapRows(await query.get());
  }

  /// Create or update action (transactional)
  Future<void> saveAction(ActionsCompanion action, List<String> contextIds) async {
    dev.log('ActionRepository: saveAction called with action ID: ${action.id.value}, title: ${action.title.value}, contextIds: $contextIds');
    
    try {
      await _db.transaction(() async {
        // 1. Save Action (Insert or Update)
        dev.log('ActionRepository: Inserting/updating action to database');
        await _db.into(_db.actions).insertOnConflictUpdate(action);
        dev.log('ActionRepository: Action saved successfully');

        // 2. Delete existing Context connections
        dev.log('ActionRepository: Deleting existing context connections');
        await (_db.delete(_db.actionContexts)
              ..where((t) => t.actionId.equals(action.id.value)))
            .go();

        // 3. Create new Context connections
        if (contextIds.isNotEmpty) {
          dev.log('ActionRepository: Creating ${contextIds.length} context connections');
          // Using batch inside transaction for efficiency
          await _db.batch((batch) {
            batch.insertAll(
              _db.actionContexts,
              contextIds.map((cid) => ActionContextsCompanion.insert(
                    actionId: action.id.value,
                    contextId: cid,
                  )),
            );
          });
          dev.log('ActionRepository: Context connections created');
        } else {
          dev.log('ActionRepository: No context IDs to create');
        }
      });
      dev.log('ActionRepository: Transaction completed successfully');
    } catch (e, stackTrace) {
      dev.log('ActionRepository: Error in saveAction transaction', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Update specific action (for simple field updates)
  Future<void> updateAction(ActionsCompanion action) async {
    try {
      await (_db.update(_db.actions)..where((t) => t.id.equals(action.id.value)))
          .write(action);
      dev.log('ActionRepository: updateAction completed for ID: ${action.id.value}');
    } catch (e, stackTrace) {
      dev.log('ActionRepository: Error in updateAction', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Permanently delete action
  /// Action 삭제 (soft delete 사용 - 동기화를 위해)
  /// isDeleted 플래그를 true로 설정하여 실제 삭제 대신 마킹
  Future<void> removeAction(String id) async {
    try {
      final now = DateTime.now();
      
      // 기존 action 조회 (rev 갱신을 위해)
      final existing = await (_db.select(_db.actions)..where((t) => t.id.equals(id))).getSingleOrNull();
      final previousRev = existing?.rev;
      
      // rev 갱신 (오버플로우 안전)
      final newRev = RevHelper.generateNewRev(previousRev: previousRev);
      
      // Soft delete: isDeleted를 true로 설정
      final companion = ActionsCompanion(
        id: Value(id),
        isDeleted: const Value(true),
        rev: Value(newRev), // rev 갱신 (오버플로우 안전)
        updatedAt: Value(now),
      );
      
      await _db.into(_db.actions).insertOnConflictUpdate(companion);
      dev.log('ActionRepository: removeAction completed (soft delete) for ID: $id');
    } catch (e, stackTrace) {
      dev.log('ActionRepository: Error in removeAction', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Remove Context connection from all actions when a Context is deleted
  Future<void> removeContextFromAllActionsAtomic(String contextId) async {
    try {
      await (_db.delete(_db.actionContexts)
            ..where((t) => t.contextId.equals(contextId)))
          .go();
      dev.log('ActionRepository: removeContextFromAllActionsAtomic completed for contextId: $contextId');
    } catch (e, stackTrace) {
      dev.log('ActionRepository: Error in removeContextFromAllActionsAtomic', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Watch completed actions stream (for Logbook)
  /// Note: Sorting is done in memory after grouping due to join query complexity
  Stream<List<ActionWithContexts>> watchCompletedActions() {
    final query = _db.select(_db.actions).join([
      leftOuterJoin(
        _db.actionContexts,
        _db.actionContexts.actionId.equalsExp(_db.actions.id),
      ),
    ]);
    
    query.where(_db.actions.isDone.equals(true) & _db.actions.isDeleted.equals(false));
    
    // Sort in memory after grouping (join queries make DB-level sorting complex)
    return query.watch().map((rows) {
      final result = _mapRows(rows);
      result.sort((a, b) {
        final aDate = a.action.completedAt;
        final bDate = b.action.completedAt;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate); // DESC
      });
      return result;
    });
  }

  /// Get completed actions with pagination (for Logbook)
  /// Note: Sorting is done in memory after grouping due to join query complexity
  Future<List<ActionWithContexts>> getCompletedActions({
    int limit = 30,
    int offset = 0,
  }) async {
    final query = _db.select(_db.actions).join([
      leftOuterJoin(
        _db.actionContexts,
        _db.actionContexts.actionId.equalsExp(_db.actions.id),
      ),
    ]);
    
    query.where(_db.actions.isDone.equals(true) & _db.actions.isDeleted.equals(false));
    
    // Get all results first (join queries make DB-level limit/offset complex)
    final rows = await query.get();
    final result = _mapRows(rows);
    
    dev.log('ActionRepository: getCompletedActions - Found ${result.length} completed actions');
    
    // Sort by completedAt DESC
    result.sort((a, b) {
      final aDate = a.action.completedAt;
      final bDate = b.action.completedAt;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate); // DESC
    });
    
    // Apply pagination after sorting
    final start = offset.clamp(0, result.length);
    final end = (start + limit).clamp(0, result.length);
    
    if (start >= result.length) {
      dev.log('ActionRepository: getCompletedActions - Offset ($start) >= result length (${result.length}), returning empty list');
      return [];
    }
    
    final paginatedResult = result.sublist(start, end);
    dev.log('ActionRepository: getCompletedActions - Returning ${paginatedResult.length} actions (offset: $start, limit: $limit)');
    return paginatedResult;
  }

  /// Search completed actions (for Logbook)
  /// Note: Sorting is done in memory after grouping due to join query complexity
  Future<List<ActionWithContexts>> searchCompletedActions(String queryText) async {
    final query = _db.select(_db.actions).join([
      leftOuterJoin(
        _db.actionContexts,
        _db.actionContexts.actionId.equalsExp(_db.actions.id),
      ),
    ]);

    query.where(
      _db.actions.isDone.equals(true) &
      _db.actions.isDeleted.equals(false) &
      _db.actions.title.like('%$queryText%'),
    );

    final result = _mapRows(await query.get());
    // Sort by completedAt DESC
    result.sort((a, b) {
      final aDate = a.action.completedAt;
      final bDate = b.action.completedAt;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate); // DESC
    });
    return result;
  }

  /// Get modified actions (for sync)
  Future<List<ActionWithContexts>> getModifiedActions(int timestamp) async {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final query = _db.select(_db.actions).join([
      leftOuterJoin(
        _db.actionContexts,
        _db.actionContexts.actionId.equalsExp(_db.actions.id),
      ),
    ]);
    query.where(_db.actions.updatedAt.isBiggerThanValue(dt));
    return _mapRows(await query.get());
  }

  /// ID로 Action 조회 (삭제된 항목 포함, 동기화용)
  /// 충돌 감지를 위해 삭제된 항목도 가져올 수 있어야 함
  Future<ActionWithContexts?> getActionById(String id) async {
    try {
      final query = _db.select(_db.actions).join([
        leftOuterJoin(
          _db.actionContexts,
          _db.actionContexts.actionId.equalsExp(_db.actions.id),
        ),
      ]);
      query.where(_db.actions.id.equals(id));
      final rows = await query.get();
      if (rows.isEmpty) return null;
      final results = _mapRows(rows);
      return results.isNotEmpty ? results.first : null;
    } catch (e, stackTrace) {
      dev.log('ActionRepository: Error in getActionById', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
