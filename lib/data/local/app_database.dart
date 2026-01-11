import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// F-Droid non supporta sqlite3_flutter_libs, quindi usiamo una factory
// per fornire l'implementazione corretta in base alla piattaforma.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    Directory dbFolder;
    // 리눅스에서는 .local/share 폴더에 생성
    if (Platform.isLinux) {
      dbFolder = await getApplicationSupportDirectory();
    } else {
      dbFolder = await getApplicationDocumentsDirectory();
    }
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}

// Enums from the original models
enum GTDStatus { inbox, next, waiting, scheduled, someday, completed }

enum ContextType { location, tool, person, etc }

enum RecurrenceType { daily, weekly, monthly }

// Type converter for List<String> (will be removed from Actions table)
class ListStringConverter extends TypeConverter<List<String>, String> {
  const ListStringConverter();
  @override
  List<String> fromSql(String fromDb) {
    return (json.decode(fromDb) as List).map((e) => e.toString()).toList();
  }

  @override
  String toSql(List<String> value) {
    return json.encode(value);
  }
}

// Table for ActionModel
@DataClassName('Action')
class Actions extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get waitingFor => text().nullable()();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  IntColumn get status => intEnum<GTDStatus>().withDefault(const Constant(0))();
  IntColumn get energyLevel => integer().nullable()();
  IntColumn get duration => integer().nullable()();
  // Removed contextIds column
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get rev => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get pomodorosCompleted => integer().nullable()();
  IntColumn get totalPomodoroTime =>
      integer().nullable()(); // Storing Duration as seconds (integer)

  @override
  Set<Column> get primaryKey => {id};
}

// Join table for Actions and Contexts (Many-to-Many)
@DataClassName('ActionContext')
class ActionContexts extends Table {
  TextColumn get actionId =>
      text().references(Actions, #id, onDelete: KeyAction.cascade)();
  TextColumn get contextId =>
      text().references(Contexts, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {actionId, contextId};
}

// Table for ContextModel
@DataClassName('Context')
class Contexts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()(); // 태그
  TextColumn get category => text().nullable()(); // 데이터구분 (예: "장소", "도구" 등)
  IntColumn get typeCategory => intEnum<ContextType>()();
  IntColumn get colorValue => integer()();
  TextColumn get rev => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// Table for RecurringActionModel
@DataClassName('RecurringAction')
class RecurringActions extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get type => intEnum<RecurrenceType>()();
  IntColumn get interval => integer().withDefault(const Constant(1))();
  IntColumn get totalCount => integer().withDefault(const Constant(0))();
  IntColumn get currentCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextRunDate => dateTime()();
  IntColumn get energyLevel => integer().withDefault(const Constant(3))();
  IntColumn get duration => integer().withDefault(const Constant(10))();
  IntColumn get advanceDays => integer().withDefault(const Constant(0))(); // Days before start date to create action
  BoolColumn get skipHolidays => boolean().withDefault(const Constant(false))(); // Skip holidays when scheduling
  TextColumn get contextIds =>
      text().map(const ListStringConverter()).withDefault(const Constant('[]'))();
  TextColumn get rev => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// Table for ScheduledActionModel (one-time scheduled actions)
@DataClassName('ScheduledAction')
class ScheduledActions extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get startDate => dateTime()(); // When the action should be created
  IntColumn get energyLevel => integer().withDefault(const Constant(3))();
  IntColumn get duration => integer().withDefault(const Constant(10))();
  IntColumn get advanceDays => integer().withDefault(const Constant(0))(); // Days before start date to create action
  BoolColumn get skipHolidays => boolean().withDefault(const Constant(false))(); // Skip holidays when scheduling
  BoolColumn get isCreated => boolean().withDefault(const Constant(false))(); // Whether the action has been created
  TextColumn get contextIds =>
      text().map(const ListStringConverter()).withDefault(const Constant('[]'))();
  TextColumn get rev => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// Table for SyncConfig
@DataClassName('SyncConfigData')
class SyncConfigs extends Table {
  // Drift auto-generates an integer primary key, which is fine for a singleton config table.
  IntColumn get id => integer().autoIncrement()();
  TextColumn get url => text().withDefault(const Constant(''))();
  TextColumn get username => text().withDefault(const Constant(''))();
  TextColumn get password => text().withDefault(const Constant(''))();
  TextColumn get dbName => text().withDefault(const Constant('gtdoro'))();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(false))();
  TextColumn get lastSeq => text().nullable()();
  TextColumn get dbType => text().withDefault(const Constant('oracle'))(); // Oracle DB only
}

@DriftDatabase(tables: [
  Actions,
  ActionContexts, // Added join table
  Contexts,
  RecurringActions,
  ScheduledActions, // Added for one-time scheduled actions
  SyncConfigs
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 8; // Incremented for dbType field addition

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Create indexes for better query performance
        await _createIndexes(m);
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from == 1) {
          // Migration from schema version 1 to 2:
          // - Remove contextIds column from Actions table (JSON string)
          // - Add ActionContexts join table (Many-to-Many relationship)
          
          // Create the new ActionContexts join table
          await m.createTable(actionContexts);
          
          // Note: Migration of existing contextIds data is not implemented
          // Due to SQLite limitations, the old contextIds column remains in the database
          // but is excluded from Drift schema and ignored (safe)
        }
        if (from < 3) {
          // Migration from schema version 2 to 3:
          // Add indexes for better query performance
          await _createIndexes(m);
        }
        if (from < 4) {
          // Migration from schema version 3 to 4:
          // Add category field to Contexts table
          await m.addColumn(contexts, contexts.category);
        }
        if (from < 5) {
          // Migration from schema version 4 to 5:
          // Add advanceDays field to RecurringActions table
          await m.addColumn(recurringActions, recurringActions.advanceDays);
        }
        if (from < 6) {
          // Migration from schema version 5 to 6:
          // Add skipHolidays field to RecurringActions table
          await m.addColumn(recurringActions, recurringActions.skipHolidays);
        }
        if (from < 7) {
          // Migration from schema version 6 to 7:
          // Create ScheduledActions table and migrate one-time scheduled actions from RecurringActions
          await m.createTable(scheduledActions);
          
          // Migrate existing one-time scheduled actions (totalCount == 1) from RecurringActions to ScheduledActions
          // Note: This migration preserves the data but marks old RecurringActions as deleted
          final db = m.database;
          final recurringActionsData = await db.customSelect(
            'SELECT id, title, description, next_run_date, energy_level, duration, '
            'advance_days, skip_holidays, current_count, context_ids, rev, updated_at '
            'FROM recurring_actions WHERE total_count = 1 AND is_deleted = 0',
            readsFrom: {recurringActions},
          ).get();
          
          await db.batch((batch) {
            const converter = ListStringConverter();
            for (final row in recurringActionsData) {
              final currentCount = row.read<int>('current_count');
              final isCreated = currentCount > 0;
              final contextIdsStr = row.read<String?>('context_ids') ?? '[]';
              final contextIds = converter.fromSql(contextIdsStr);
              
              // Insert into ScheduledActions
              batch.insert(scheduledActions, ScheduledActionsCompanion.insert(
                id: row.read<String>('id'),
                title: row.read<String>('title'),
                description: Value(row.read<String?>('description')),
                startDate: row.read<DateTime>('next_run_date'),
                energyLevel: Value(row.read<int?>('energy_level') ?? 3),
                duration: Value(row.read<int?>('duration') ?? 10),
                advanceDays: Value(row.read<int?>('advance_days') ?? 0),
                skipHolidays: Value(row.read<bool?>('skip_holidays') ?? false),
                isCreated: Value(isCreated),
                contextIds: Value(contextIds),
                rev: Value(row.read<String?>('rev')),
                updatedAt: Value(row.read<DateTime?>('updated_at')),
                isDeleted: const Value(false),
              ));
              
              // Mark old RecurringAction as deleted
              batch.update(recurringActions, RecurringActionsCompanion(
                id: Value(row.read<String>('id')),
                isDeleted: const Value(true),
              ));
            }
          });
        }
        if (from < 8) {
          // Migration from schema version 7 to 8:
          // Add dbType field to SyncConfigs table
          await m.addColumn(syncConfigs, syncConfigs.dbType);
        }
      },
    );
  }

  /// Create database indexes for performance optimization
  Future<void> _createIndexes(Migrator m) async {
    final db = m.database;
    
    // Indexes for Actions table
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_actions_is_deleted ON actions(is_deleted)',
    );
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_actions_updated_at ON actions(updated_at)',
    );
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_actions_completed_at ON actions(completed_at)',
    );
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_actions_is_done ON actions(is_done)',
    );

    // Indexes for Contexts table
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_contexts_is_deleted ON contexts(is_deleted)',
    );
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_contexts_updated_at ON contexts(updated_at)',
    );

    // Indexes for RecurringActions table
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_recurring_actions_is_deleted ON recurring_actions(is_deleted)',
    );
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_recurring_actions_updated_at ON recurring_actions(updated_at)',
    );
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_recurring_actions_next_run_date ON recurring_actions(next_run_date)',
    );

    // Indexes for ScheduledActions table
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_scheduled_actions_is_deleted ON scheduled_actions(is_deleted)',
    );
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_scheduled_actions_updated_at ON scheduled_actions(updated_at)',
    );
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_scheduled_actions_start_date ON scheduled_actions(start_date)',
    );

    // Indexes for ActionContexts join table
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_action_contexts_action_id ON action_contexts(action_id)',
    );
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_action_contexts_context_id ON action_contexts(context_id)',
    );
  }
}

// Data class that combines Action table with Context ID list
class ActionWithContexts {
  final Action action;
  final List<String> contextIds;

  ActionWithContexts(this.action, this.contextIds);
}
