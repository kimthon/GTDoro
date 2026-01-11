// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ActionsTable extends Actions with TableInfo<$ActionsTable, Action> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _waitingForMeta =
      const VerificationMeta('waitingFor');
  @override
  late final GeneratedColumn<String> waitingFor = GeneratedColumn<String>(
      'waiting_for', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isDoneMeta = const VerificationMeta('isDone');
  @override
  late final GeneratedColumn<bool> isDone = GeneratedColumn<bool>(
      'is_done', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_done" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumnWithTypeConverter<GTDStatus, int> status =
      GeneratedColumn<int>('status', aliasedName, false,
              type: DriftSqlType.int,
              requiredDuringInsert: false,
              defaultValue: const Constant(0))
          .withConverter<GTDStatus>($ActionsTable.$converterstatus);
  static const VerificationMeta _energyLevelMeta =
      const VerificationMeta('energyLevel');
  @override
  late final GeneratedColumn<int> energyLevel = GeneratedColumn<int>(
      'energy_level', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _durationMeta =
      const VerificationMeta('duration');
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
      'duration', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _dueDateMeta =
      const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
      'due_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _revMeta = const VerificationMeta('rev');
  @override
  late final GeneratedColumn<String> rev = GeneratedColumn<String>(
      'rev', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _pomodorosCompletedMeta =
      const VerificationMeta('pomodorosCompleted');
  @override
  late final GeneratedColumn<int> pomodorosCompleted = GeneratedColumn<int>(
      'pomodoros_completed', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _totalPomodoroTimeMeta =
      const VerificationMeta('totalPomodoroTime');
  @override
  late final GeneratedColumn<int> totalPomodoroTime = GeneratedColumn<int>(
      'total_pomodoro_time', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        description,
        waitingFor,
        isDone,
        status,
        energyLevel,
        duration,
        createdAt,
        dueDate,
        completedAt,
        rev,
        updatedAt,
        isDeleted,
        pomodorosCompleted,
        totalPomodoroTime
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'actions';
  @override
  VerificationContext validateIntegrity(Insertable<Action> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('waiting_for')) {
      context.handle(
          _waitingForMeta,
          waitingFor.isAcceptableOrUnknown(
              data['waiting_for']!, _waitingForMeta));
    }
    if (data.containsKey('is_done')) {
      context.handle(_isDoneMeta,
          isDone.isAcceptableOrUnknown(data['is_done']!, _isDoneMeta));
    }
    context.handle(_statusMeta, const VerificationResult.success());
    if (data.containsKey('energy_level')) {
      context.handle(
          _energyLevelMeta,
          energyLevel.isAcceptableOrUnknown(
              data['energy_level']!, _energyLevelMeta));
    }
    if (data.containsKey('duration')) {
      context.handle(_durationMeta,
          duration.isAcceptableOrUnknown(data['duration']!, _durationMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    if (data.containsKey('rev')) {
      context.handle(
          _revMeta, rev.isAcceptableOrUnknown(data['rev']!, _revMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    if (data.containsKey('pomodoros_completed')) {
      context.handle(
          _pomodorosCompletedMeta,
          pomodorosCompleted.isAcceptableOrUnknown(
              data['pomodoros_completed']!, _pomodorosCompletedMeta));
    }
    if (data.containsKey('total_pomodoro_time')) {
      context.handle(
          _totalPomodoroTimeMeta,
          totalPomodoroTime.isAcceptableOrUnknown(
              data['total_pomodoro_time']!, _totalPomodoroTimeMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Action map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Action(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      waitingFor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}waiting_for']),
      isDone: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_done'])!,
      status: $ActionsTable.$converterstatus.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}status'])!),
      energyLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}energy_level']),
      duration: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}due_date']),
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
      rev: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rev']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
      pomodorosCompleted: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}pomodoros_completed']),
      totalPomodoroTime: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}total_pomodoro_time']),
    );
  }

  @override
  $ActionsTable createAlias(String alias) {
    return $ActionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<GTDStatus, int, int> $converterstatus =
      const EnumIndexConverter<GTDStatus>(GTDStatus.values);
}

class Action extends DataClass implements Insertable<Action> {
  final String id;
  final String title;
  final String? description;
  final String? waitingFor;
  final bool isDone;
  final GTDStatus status;
  final int? energyLevel;
  final int? duration;
  final DateTime createdAt;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final String? rev;
  final DateTime? updatedAt;
  final bool isDeleted;
  final int? pomodorosCompleted;
  final int? totalPomodoroTime;
  const Action(
      {required this.id,
      required this.title,
      this.description,
      this.waitingFor,
      required this.isDone,
      required this.status,
      this.energyLevel,
      this.duration,
      required this.createdAt,
      this.dueDate,
      this.completedAt,
      this.rev,
      this.updatedAt,
      required this.isDeleted,
      this.pomodorosCompleted,
      this.totalPomodoroTime});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || waitingFor != null) {
      map['waiting_for'] = Variable<String>(waitingFor);
    }
    map['is_done'] = Variable<bool>(isDone);
    {
      map['status'] =
          Variable<int>($ActionsTable.$converterstatus.toSql(status));
    }
    if (!nullToAbsent || energyLevel != null) {
      map['energy_level'] = Variable<int>(energyLevel);
    }
    if (!nullToAbsent || duration != null) {
      map['duration'] = Variable<int>(duration);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || rev != null) {
      map['rev'] = Variable<String>(rev);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    if (!nullToAbsent || pomodorosCompleted != null) {
      map['pomodoros_completed'] = Variable<int>(pomodorosCompleted);
    }
    if (!nullToAbsent || totalPomodoroTime != null) {
      map['total_pomodoro_time'] = Variable<int>(totalPomodoroTime);
    }
    return map;
  }

  ActionsCompanion toCompanion(bool nullToAbsent) {
    return ActionsCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      waitingFor: waitingFor == null && nullToAbsent
          ? const Value.absent()
          : Value(waitingFor),
      isDone: Value(isDone),
      status: Value(status),
      energyLevel: energyLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(energyLevel),
      duration: duration == null && nullToAbsent
          ? const Value.absent()
          : Value(duration),
      createdAt: Value(createdAt),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      rev: rev == null && nullToAbsent ? const Value.absent() : Value(rev),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      isDeleted: Value(isDeleted),
      pomodorosCompleted: pomodorosCompleted == null && nullToAbsent
          ? const Value.absent()
          : Value(pomodorosCompleted),
      totalPomodoroTime: totalPomodoroTime == null && nullToAbsent
          ? const Value.absent()
          : Value(totalPomodoroTime),
    );
  }

  factory Action.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Action(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      waitingFor: serializer.fromJson<String?>(json['waitingFor']),
      isDone: serializer.fromJson<bool>(json['isDone']),
      status: $ActionsTable.$converterstatus
          .fromJson(serializer.fromJson<int>(json['status'])),
      energyLevel: serializer.fromJson<int?>(json['energyLevel']),
      duration: serializer.fromJson<int?>(json['duration']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      rev: serializer.fromJson<String?>(json['rev']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      pomodorosCompleted: serializer.fromJson<int?>(json['pomodorosCompleted']),
      totalPomodoroTime: serializer.fromJson<int?>(json['totalPomodoroTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'waitingFor': serializer.toJson<String?>(waitingFor),
      'isDone': serializer.toJson<bool>(isDone),
      'status':
          serializer.toJson<int>($ActionsTable.$converterstatus.toJson(status)),
      'energyLevel': serializer.toJson<int?>(energyLevel),
      'duration': serializer.toJson<int?>(duration),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'rev': serializer.toJson<String?>(rev),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'pomodorosCompleted': serializer.toJson<int?>(pomodorosCompleted),
      'totalPomodoroTime': serializer.toJson<int?>(totalPomodoroTime),
    };
  }

  Action copyWith(
          {String? id,
          String? title,
          Value<String?> description = const Value.absent(),
          Value<String?> waitingFor = const Value.absent(),
          bool? isDone,
          GTDStatus? status,
          Value<int?> energyLevel = const Value.absent(),
          Value<int?> duration = const Value.absent(),
          DateTime? createdAt,
          Value<DateTime?> dueDate = const Value.absent(),
          Value<DateTime?> completedAt = const Value.absent(),
          Value<String?> rev = const Value.absent(),
          Value<DateTime?> updatedAt = const Value.absent(),
          bool? isDeleted,
          Value<int?> pomodorosCompleted = const Value.absent(),
          Value<int?> totalPomodoroTime = const Value.absent()}) =>
      Action(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description.present ? description.value : this.description,
        waitingFor: waitingFor.present ? waitingFor.value : this.waitingFor,
        isDone: isDone ?? this.isDone,
        status: status ?? this.status,
        energyLevel: energyLevel.present ? energyLevel.value : this.energyLevel,
        duration: duration.present ? duration.value : this.duration,
        createdAt: createdAt ?? this.createdAt,
        dueDate: dueDate.present ? dueDate.value : this.dueDate,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
        rev: rev.present ? rev.value : this.rev,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
        pomodorosCompleted: pomodorosCompleted.present
            ? pomodorosCompleted.value
            : this.pomodorosCompleted,
        totalPomodoroTime: totalPomodoroTime.present
            ? totalPomodoroTime.value
            : this.totalPomodoroTime,
      );
  Action copyWithCompanion(ActionsCompanion data) {
    return Action(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      waitingFor:
          data.waitingFor.present ? data.waitingFor.value : this.waitingFor,
      isDone: data.isDone.present ? data.isDone.value : this.isDone,
      status: data.status.present ? data.status.value : this.status,
      energyLevel:
          data.energyLevel.present ? data.energyLevel.value : this.energyLevel,
      duration: data.duration.present ? data.duration.value : this.duration,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      rev: data.rev.present ? data.rev.value : this.rev,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      pomodorosCompleted: data.pomodorosCompleted.present
          ? data.pomodorosCompleted.value
          : this.pomodorosCompleted,
      totalPomodoroTime: data.totalPomodoroTime.present
          ? data.totalPomodoroTime.value
          : this.totalPomodoroTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Action(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('waitingFor: $waitingFor, ')
          ..write('isDone: $isDone, ')
          ..write('status: $status, ')
          ..write('energyLevel: $energyLevel, ')
          ..write('duration: $duration, ')
          ..write('createdAt: $createdAt, ')
          ..write('dueDate: $dueDate, ')
          ..write('completedAt: $completedAt, ')
          ..write('rev: $rev, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('pomodorosCompleted: $pomodorosCompleted, ')
          ..write('totalPomodoroTime: $totalPomodoroTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      description,
      waitingFor,
      isDone,
      status,
      energyLevel,
      duration,
      createdAt,
      dueDate,
      completedAt,
      rev,
      updatedAt,
      isDeleted,
      pomodorosCompleted,
      totalPomodoroTime);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Action &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.waitingFor == this.waitingFor &&
          other.isDone == this.isDone &&
          other.status == this.status &&
          other.energyLevel == this.energyLevel &&
          other.duration == this.duration &&
          other.createdAt == this.createdAt &&
          other.dueDate == this.dueDate &&
          other.completedAt == this.completedAt &&
          other.rev == this.rev &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted &&
          other.pomodorosCompleted == this.pomodorosCompleted &&
          other.totalPomodoroTime == this.totalPomodoroTime);
}

class ActionsCompanion extends UpdateCompanion<Action> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<String?> waitingFor;
  final Value<bool> isDone;
  final Value<GTDStatus> status;
  final Value<int?> energyLevel;
  final Value<int?> duration;
  final Value<DateTime> createdAt;
  final Value<DateTime?> dueDate;
  final Value<DateTime?> completedAt;
  final Value<String?> rev;
  final Value<DateTime?> updatedAt;
  final Value<bool> isDeleted;
  final Value<int?> pomodorosCompleted;
  final Value<int?> totalPomodoroTime;
  final Value<int> rowid;
  const ActionsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.waitingFor = const Value.absent(),
    this.isDone = const Value.absent(),
    this.status = const Value.absent(),
    this.energyLevel = const Value.absent(),
    this.duration = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rev = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.pomodorosCompleted = const Value.absent(),
    this.totalPomodoroTime = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ActionsCompanion.insert({
    required String id,
    required String title,
    this.description = const Value.absent(),
    this.waitingFor = const Value.absent(),
    this.isDone = const Value.absent(),
    this.status = const Value.absent(),
    this.energyLevel = const Value.absent(),
    this.duration = const Value.absent(),
    required DateTime createdAt,
    this.dueDate = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rev = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.pomodorosCompleted = const Value.absent(),
    this.totalPomodoroTime = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        createdAt = Value(createdAt);
  static Insertable<Action> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? waitingFor,
    Expression<bool>? isDone,
    Expression<int>? status,
    Expression<int>? energyLevel,
    Expression<int>? duration,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? dueDate,
    Expression<DateTime>? completedAt,
    Expression<String>? rev,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isDeleted,
    Expression<int>? pomodorosCompleted,
    Expression<int>? totalPomodoroTime,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (waitingFor != null) 'waiting_for': waitingFor,
      if (isDone != null) 'is_done': isDone,
      if (status != null) 'status': status,
      if (energyLevel != null) 'energy_level': energyLevel,
      if (duration != null) 'duration': duration,
      if (createdAt != null) 'created_at': createdAt,
      if (dueDate != null) 'due_date': dueDate,
      if (completedAt != null) 'completed_at': completedAt,
      if (rev != null) 'rev': rev,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (pomodorosCompleted != null) 'pomodoros_completed': pomodorosCompleted,
      if (totalPomodoroTime != null) 'total_pomodoro_time': totalPomodoroTime,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ActionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String?>? description,
      Value<String?>? waitingFor,
      Value<bool>? isDone,
      Value<GTDStatus>? status,
      Value<int?>? energyLevel,
      Value<int?>? duration,
      Value<DateTime>? createdAt,
      Value<DateTime?>? dueDate,
      Value<DateTime?>? completedAt,
      Value<String?>? rev,
      Value<DateTime?>? updatedAt,
      Value<bool>? isDeleted,
      Value<int?>? pomodorosCompleted,
      Value<int?>? totalPomodoroTime,
      Value<int>? rowid}) {
    return ActionsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      waitingFor: waitingFor ?? this.waitingFor,
      isDone: isDone ?? this.isDone,
      status: status ?? this.status,
      energyLevel: energyLevel ?? this.energyLevel,
      duration: duration ?? this.duration,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      rev: rev ?? this.rev,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      pomodorosCompleted: pomodorosCompleted ?? this.pomodorosCompleted,
      totalPomodoroTime: totalPomodoroTime ?? this.totalPomodoroTime,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (waitingFor.present) {
      map['waiting_for'] = Variable<String>(waitingFor.value);
    }
    if (isDone.present) {
      map['is_done'] = Variable<bool>(isDone.value);
    }
    if (status.present) {
      map['status'] =
          Variable<int>($ActionsTable.$converterstatus.toSql(status.value));
    }
    if (energyLevel.present) {
      map['energy_level'] = Variable<int>(energyLevel.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rev.present) {
      map['rev'] = Variable<String>(rev.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (pomodorosCompleted.present) {
      map['pomodoros_completed'] = Variable<int>(pomodorosCompleted.value);
    }
    if (totalPomodoroTime.present) {
      map['total_pomodoro_time'] = Variable<int>(totalPomodoroTime.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActionsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('waitingFor: $waitingFor, ')
          ..write('isDone: $isDone, ')
          ..write('status: $status, ')
          ..write('energyLevel: $energyLevel, ')
          ..write('duration: $duration, ')
          ..write('createdAt: $createdAt, ')
          ..write('dueDate: $dueDate, ')
          ..write('completedAt: $completedAt, ')
          ..write('rev: $rev, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('pomodorosCompleted: $pomodorosCompleted, ')
          ..write('totalPomodoroTime: $totalPomodoroTime, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContextsTable extends Contexts with TableInfo<$ContextsTable, Context> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContextsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _typeCategoryMeta =
      const VerificationMeta('typeCategory');
  @override
  late final GeneratedColumnWithTypeConverter<ContextType, int> typeCategory =
      GeneratedColumn<int>('type_category', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<ContextType>($ContextsTable.$convertertypeCategory);
  static const VerificationMeta _colorValueMeta =
      const VerificationMeta('colorValue');
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
      'color_value', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _revMeta = const VerificationMeta('rev');
  @override
  late final GeneratedColumn<String> rev = GeneratedColumn<String>(
      'rev', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, category, typeCategory, colorValue, rev, updatedAt, isDeleted];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contexts';
  @override
  VerificationContext validateIntegrity(Insertable<Context> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    context.handle(_typeCategoryMeta, const VerificationResult.success());
    if (data.containsKey('color_value')) {
      context.handle(
          _colorValueMeta,
          colorValue.isAcceptableOrUnknown(
              data['color_value']!, _colorValueMeta));
    } else if (isInserting) {
      context.missing(_colorValueMeta);
    }
    if (data.containsKey('rev')) {
      context.handle(
          _revMeta, rev.isAcceptableOrUnknown(data['rev']!, _revMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Context map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Context(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
      typeCategory: $ContextsTable.$convertertypeCategory.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.int, data['${effectivePrefix}type_category'])!),
      colorValue: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}color_value'])!,
      rev: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rev']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
    );
  }

  @override
  $ContextsTable createAlias(String alias) {
    return $ContextsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ContextType, int, int> $convertertypeCategory =
      const EnumIndexConverter<ContextType>(ContextType.values);
}

class Context extends DataClass implements Insertable<Context> {
  final String id;
  final String name;
  final String? category;
  final ContextType typeCategory;
  final int colorValue;
  final String? rev;
  final DateTime? updatedAt;
  final bool isDeleted;
  const Context(
      {required this.id,
      required this.name,
      this.category,
      required this.typeCategory,
      required this.colorValue,
      this.rev,
      this.updatedAt,
      required this.isDeleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    {
      map['type_category'] = Variable<int>(
          $ContextsTable.$convertertypeCategory.toSql(typeCategory));
    }
    map['color_value'] = Variable<int>(colorValue);
    if (!nullToAbsent || rev != null) {
      map['rev'] = Variable<String>(rev);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  ContextsCompanion toCompanion(bool nullToAbsent) {
    return ContextsCompanion(
      id: Value(id),
      name: Value(name),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      typeCategory: Value(typeCategory),
      colorValue: Value(colorValue),
      rev: rev == null && nullToAbsent ? const Value.absent() : Value(rev),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory Context.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Context(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      category: serializer.fromJson<String?>(json['category']),
      typeCategory: $ContextsTable.$convertertypeCategory
          .fromJson(serializer.fromJson<int>(json['typeCategory'])),
      colorValue: serializer.fromJson<int>(json['colorValue']),
      rev: serializer.fromJson<String?>(json['rev']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'category': serializer.toJson<String?>(category),
      'typeCategory': serializer.toJson<int>(
          $ContextsTable.$convertertypeCategory.toJson(typeCategory)),
      'colorValue': serializer.toJson<int>(colorValue),
      'rev': serializer.toJson<String?>(rev),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  Context copyWith(
          {String? id,
          String? name,
          Value<String?> category = const Value.absent(),
          ContextType? typeCategory,
          int? colorValue,
          Value<String?> rev = const Value.absent(),
          Value<DateTime?> updatedAt = const Value.absent(),
          bool? isDeleted}) =>
      Context(
        id: id ?? this.id,
        name: name ?? this.name,
        category: category.present ? category.value : this.category,
        typeCategory: typeCategory ?? this.typeCategory,
        colorValue: colorValue ?? this.colorValue,
        rev: rev.present ? rev.value : this.rev,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
      );
  Context copyWithCompanion(ContextsCompanion data) {
    return Context(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      category: data.category.present ? data.category.value : this.category,
      typeCategory: data.typeCategory.present
          ? data.typeCategory.value
          : this.typeCategory,
      colorValue:
          data.colorValue.present ? data.colorValue.value : this.colorValue,
      rev: data.rev.present ? data.rev.value : this.rev,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Context(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('typeCategory: $typeCategory, ')
          ..write('colorValue: $colorValue, ')
          ..write('rev: $rev, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, name, category, typeCategory, colorValue, rev, updatedAt, isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Context &&
          other.id == this.id &&
          other.name == this.name &&
          other.category == this.category &&
          other.typeCategory == this.typeCategory &&
          other.colorValue == this.colorValue &&
          other.rev == this.rev &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted);
}

class ContextsCompanion extends UpdateCompanion<Context> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> category;
  final Value<ContextType> typeCategory;
  final Value<int> colorValue;
  final Value<String?> rev;
  final Value<DateTime?> updatedAt;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const ContextsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.category = const Value.absent(),
    this.typeCategory = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.rev = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContextsCompanion.insert({
    required String id,
    required String name,
    this.category = const Value.absent(),
    required ContextType typeCategory,
    required int colorValue,
    this.rev = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        typeCategory = Value(typeCategory),
        colorValue = Value(colorValue);
  static Insertable<Context> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? category,
    Expression<int>? typeCategory,
    Expression<int>? colorValue,
    Expression<String>? rev,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (category != null) 'category': category,
      if (typeCategory != null) 'type_category': typeCategory,
      if (colorValue != null) 'color_value': colorValue,
      if (rev != null) 'rev': rev,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContextsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? category,
      Value<ContextType>? typeCategory,
      Value<int>? colorValue,
      Value<String?>? rev,
      Value<DateTime?>? updatedAt,
      Value<bool>? isDeleted,
      Value<int>? rowid}) {
    return ContextsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      typeCategory: typeCategory ?? this.typeCategory,
      colorValue: colorValue ?? this.colorValue,
      rev: rev ?? this.rev,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (typeCategory.present) {
      map['type_category'] = Variable<int>(
          $ContextsTable.$convertertypeCategory.toSql(typeCategory.value));
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (rev.present) {
      map['rev'] = Variable<String>(rev.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContextsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('category: $category, ')
          ..write('typeCategory: $typeCategory, ')
          ..write('colorValue: $colorValue, ')
          ..write('rev: $rev, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ActionContextsTable extends ActionContexts
    with TableInfo<$ActionContextsTable, ActionContext> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActionContextsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _actionIdMeta =
      const VerificationMeta('actionId');
  @override
  late final GeneratedColumn<String> actionId = GeneratedColumn<String>(
      'action_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES actions (id) ON DELETE CASCADE'));
  static const VerificationMeta _contextIdMeta =
      const VerificationMeta('contextId');
  @override
  late final GeneratedColumn<String> contextId = GeneratedColumn<String>(
      'context_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES contexts (id) ON DELETE CASCADE'));
  @override
  List<GeneratedColumn> get $columns => [actionId, contextId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'action_contexts';
  @override
  VerificationContext validateIntegrity(Insertable<ActionContext> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('action_id')) {
      context.handle(_actionIdMeta,
          actionId.isAcceptableOrUnknown(data['action_id']!, _actionIdMeta));
    } else if (isInserting) {
      context.missing(_actionIdMeta);
    }
    if (data.containsKey('context_id')) {
      context.handle(_contextIdMeta,
          contextId.isAcceptableOrUnknown(data['context_id']!, _contextIdMeta));
    } else if (isInserting) {
      context.missing(_contextIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {actionId, contextId};
  @override
  ActionContext map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActionContext(
      actionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action_id'])!,
      contextId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}context_id'])!,
    );
  }

  @override
  $ActionContextsTable createAlias(String alias) {
    return $ActionContextsTable(attachedDatabase, alias);
  }
}

class ActionContext extends DataClass implements Insertable<ActionContext> {
  final String actionId;
  final String contextId;
  const ActionContext({required this.actionId, required this.contextId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['action_id'] = Variable<String>(actionId);
    map['context_id'] = Variable<String>(contextId);
    return map;
  }

  ActionContextsCompanion toCompanion(bool nullToAbsent) {
    return ActionContextsCompanion(
      actionId: Value(actionId),
      contextId: Value(contextId),
    );
  }

  factory ActionContext.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActionContext(
      actionId: serializer.fromJson<String>(json['actionId']),
      contextId: serializer.fromJson<String>(json['contextId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'actionId': serializer.toJson<String>(actionId),
      'contextId': serializer.toJson<String>(contextId),
    };
  }

  ActionContext copyWith({String? actionId, String? contextId}) =>
      ActionContext(
        actionId: actionId ?? this.actionId,
        contextId: contextId ?? this.contextId,
      );
  ActionContext copyWithCompanion(ActionContextsCompanion data) {
    return ActionContext(
      actionId: data.actionId.present ? data.actionId.value : this.actionId,
      contextId: data.contextId.present ? data.contextId.value : this.contextId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActionContext(')
          ..write('actionId: $actionId, ')
          ..write('contextId: $contextId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(actionId, contextId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActionContext &&
          other.actionId == this.actionId &&
          other.contextId == this.contextId);
}

class ActionContextsCompanion extends UpdateCompanion<ActionContext> {
  final Value<String> actionId;
  final Value<String> contextId;
  final Value<int> rowid;
  const ActionContextsCompanion({
    this.actionId = const Value.absent(),
    this.contextId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ActionContextsCompanion.insert({
    required String actionId,
    required String contextId,
    this.rowid = const Value.absent(),
  })  : actionId = Value(actionId),
        contextId = Value(contextId);
  static Insertable<ActionContext> custom({
    Expression<String>? actionId,
    Expression<String>? contextId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (actionId != null) 'action_id': actionId,
      if (contextId != null) 'context_id': contextId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ActionContextsCompanion copyWith(
      {Value<String>? actionId, Value<String>? contextId, Value<int>? rowid}) {
    return ActionContextsCompanion(
      actionId: actionId ?? this.actionId,
      contextId: contextId ?? this.contextId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (actionId.present) {
      map['action_id'] = Variable<String>(actionId.value);
    }
    if (contextId.present) {
      map['context_id'] = Variable<String>(contextId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActionContextsCompanion(')
          ..write('actionId: $actionId, ')
          ..write('contextId: $contextId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecurringActionsTable extends RecurringActions
    with TableInfo<$RecurringActionsTable, RecurringAction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurringActionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumnWithTypeConverter<RecurrenceType, int> type =
      GeneratedColumn<int>('type', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<RecurrenceType>($RecurringActionsTable.$convertertype);
  static const VerificationMeta _intervalMeta =
      const VerificationMeta('interval');
  @override
  late final GeneratedColumn<int> interval = GeneratedColumn<int>(
      'interval', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _totalCountMeta =
      const VerificationMeta('totalCount');
  @override
  late final GeneratedColumn<int> totalCount = GeneratedColumn<int>(
      'total_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _currentCountMeta =
      const VerificationMeta('currentCount');
  @override
  late final GeneratedColumn<int> currentCount = GeneratedColumn<int>(
      'current_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _nextRunDateMeta =
      const VerificationMeta('nextRunDate');
  @override
  late final GeneratedColumn<DateTime> nextRunDate = GeneratedColumn<DateTime>(
      'next_run_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _energyLevelMeta =
      const VerificationMeta('energyLevel');
  @override
  late final GeneratedColumn<int> energyLevel = GeneratedColumn<int>(
      'energy_level', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(3));
  static const VerificationMeta _durationMeta =
      const VerificationMeta('duration');
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
      'duration', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(10));
  static const VerificationMeta _advanceDaysMeta =
      const VerificationMeta('advanceDays');
  @override
  late final GeneratedColumn<int> advanceDays = GeneratedColumn<int>(
      'advance_days', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _skipHolidaysMeta =
      const VerificationMeta('skipHolidays');
  @override
  late final GeneratedColumn<bool> skipHolidays = GeneratedColumn<bool>(
      'skip_holidays', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("skip_holidays" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _contextIdsMeta =
      const VerificationMeta('contextIds');
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> contextIds =
      GeneratedColumn<String>('context_ids', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: const Constant('[]'))
          .withConverter<List<String>>(
              $RecurringActionsTable.$convertercontextIds);
  static const VerificationMeta _revMeta = const VerificationMeta('rev');
  @override
  late final GeneratedColumn<String> rev = GeneratedColumn<String>(
      'rev', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        description,
        type,
        interval,
        totalCount,
        currentCount,
        nextRunDate,
        energyLevel,
        duration,
        advanceDays,
        skipHolidays,
        contextIds,
        rev,
        updatedAt,
        isDeleted
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurring_actions';
  @override
  VerificationContext validateIntegrity(Insertable<RecurringAction> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    context.handle(_typeMeta, const VerificationResult.success());
    if (data.containsKey('interval')) {
      context.handle(_intervalMeta,
          interval.isAcceptableOrUnknown(data['interval']!, _intervalMeta));
    }
    if (data.containsKey('total_count')) {
      context.handle(
          _totalCountMeta,
          totalCount.isAcceptableOrUnknown(
              data['total_count']!, _totalCountMeta));
    }
    if (data.containsKey('current_count')) {
      context.handle(
          _currentCountMeta,
          currentCount.isAcceptableOrUnknown(
              data['current_count']!, _currentCountMeta));
    }
    if (data.containsKey('next_run_date')) {
      context.handle(
          _nextRunDateMeta,
          nextRunDate.isAcceptableOrUnknown(
              data['next_run_date']!, _nextRunDateMeta));
    } else if (isInserting) {
      context.missing(_nextRunDateMeta);
    }
    if (data.containsKey('energy_level')) {
      context.handle(
          _energyLevelMeta,
          energyLevel.isAcceptableOrUnknown(
              data['energy_level']!, _energyLevelMeta));
    }
    if (data.containsKey('duration')) {
      context.handle(_durationMeta,
          duration.isAcceptableOrUnknown(data['duration']!, _durationMeta));
    }
    if (data.containsKey('advance_days')) {
      context.handle(
          _advanceDaysMeta,
          advanceDays.isAcceptableOrUnknown(
              data['advance_days']!, _advanceDaysMeta));
    }
    if (data.containsKey('skip_holidays')) {
      context.handle(
          _skipHolidaysMeta,
          skipHolidays.isAcceptableOrUnknown(
              data['skip_holidays']!, _skipHolidaysMeta));
    }
    context.handle(_contextIdsMeta, const VerificationResult.success());
    if (data.containsKey('rev')) {
      context.handle(
          _revMeta, rev.isAcceptableOrUnknown(data['rev']!, _revMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecurringAction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurringAction(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      type: $RecurringActionsTable.$convertertype.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}type'])!),
      interval: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}interval'])!,
      totalCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_count'])!,
      currentCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}current_count'])!,
      nextRunDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}next_run_date'])!,
      energyLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}energy_level'])!,
      duration: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration'])!,
      advanceDays: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}advance_days'])!,
      skipHolidays: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}skip_holidays'])!,
      contextIds: $RecurringActionsTable.$convertercontextIds.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}context_ids'])!),
      rev: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rev']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
    );
  }

  @override
  $RecurringActionsTable createAlias(String alias) {
    return $RecurringActionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<RecurrenceType, int, int> $convertertype =
      const EnumIndexConverter<RecurrenceType>(RecurrenceType.values);
  static TypeConverter<List<String>, String> $convertercontextIds =
      const ListStringConverter();
}

class RecurringAction extends DataClass implements Insertable<RecurringAction> {
  final String id;
  final String title;
  final String? description;
  final RecurrenceType type;
  final int interval;
  final int totalCount;
  final int currentCount;
  final DateTime nextRunDate;
  final int energyLevel;
  final int duration;
  final int advanceDays;
  final bool skipHolidays;
  final List<String> contextIds;
  final String? rev;
  final DateTime? updatedAt;
  final bool isDeleted;
  const RecurringAction(
      {required this.id,
      required this.title,
      this.description,
      required this.type,
      required this.interval,
      required this.totalCount,
      required this.currentCount,
      required this.nextRunDate,
      required this.energyLevel,
      required this.duration,
      required this.advanceDays,
      required this.skipHolidays,
      required this.contextIds,
      this.rev,
      this.updatedAt,
      required this.isDeleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    {
      map['type'] =
          Variable<int>($RecurringActionsTable.$convertertype.toSql(type));
    }
    map['interval'] = Variable<int>(interval);
    map['total_count'] = Variable<int>(totalCount);
    map['current_count'] = Variable<int>(currentCount);
    map['next_run_date'] = Variable<DateTime>(nextRunDate);
    map['energy_level'] = Variable<int>(energyLevel);
    map['duration'] = Variable<int>(duration);
    map['advance_days'] = Variable<int>(advanceDays);
    map['skip_holidays'] = Variable<bool>(skipHolidays);
    {
      map['context_ids'] = Variable<String>(
          $RecurringActionsTable.$convertercontextIds.toSql(contextIds));
    }
    if (!nullToAbsent || rev != null) {
      map['rev'] = Variable<String>(rev);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  RecurringActionsCompanion toCompanion(bool nullToAbsent) {
    return RecurringActionsCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      type: Value(type),
      interval: Value(interval),
      totalCount: Value(totalCount),
      currentCount: Value(currentCount),
      nextRunDate: Value(nextRunDate),
      energyLevel: Value(energyLevel),
      duration: Value(duration),
      advanceDays: Value(advanceDays),
      skipHolidays: Value(skipHolidays),
      contextIds: Value(contextIds),
      rev: rev == null && nullToAbsent ? const Value.absent() : Value(rev),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory RecurringAction.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurringAction(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      type: $RecurringActionsTable.$convertertype
          .fromJson(serializer.fromJson<int>(json['type'])),
      interval: serializer.fromJson<int>(json['interval']),
      totalCount: serializer.fromJson<int>(json['totalCount']),
      currentCount: serializer.fromJson<int>(json['currentCount']),
      nextRunDate: serializer.fromJson<DateTime>(json['nextRunDate']),
      energyLevel: serializer.fromJson<int>(json['energyLevel']),
      duration: serializer.fromJson<int>(json['duration']),
      advanceDays: serializer.fromJson<int>(json['advanceDays']),
      skipHolidays: serializer.fromJson<bool>(json['skipHolidays']),
      contextIds: serializer.fromJson<List<String>>(json['contextIds']),
      rev: serializer.fromJson<String?>(json['rev']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'type': serializer
          .toJson<int>($RecurringActionsTable.$convertertype.toJson(type)),
      'interval': serializer.toJson<int>(interval),
      'totalCount': serializer.toJson<int>(totalCount),
      'currentCount': serializer.toJson<int>(currentCount),
      'nextRunDate': serializer.toJson<DateTime>(nextRunDate),
      'energyLevel': serializer.toJson<int>(energyLevel),
      'duration': serializer.toJson<int>(duration),
      'advanceDays': serializer.toJson<int>(advanceDays),
      'skipHolidays': serializer.toJson<bool>(skipHolidays),
      'contextIds': serializer.toJson<List<String>>(contextIds),
      'rev': serializer.toJson<String?>(rev),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  RecurringAction copyWith(
          {String? id,
          String? title,
          Value<String?> description = const Value.absent(),
          RecurrenceType? type,
          int? interval,
          int? totalCount,
          int? currentCount,
          DateTime? nextRunDate,
          int? energyLevel,
          int? duration,
          int? advanceDays,
          bool? skipHolidays,
          List<String>? contextIds,
          Value<String?> rev = const Value.absent(),
          Value<DateTime?> updatedAt = const Value.absent(),
          bool? isDeleted}) =>
      RecurringAction(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description.present ? description.value : this.description,
        type: type ?? this.type,
        interval: interval ?? this.interval,
        totalCount: totalCount ?? this.totalCount,
        currentCount: currentCount ?? this.currentCount,
        nextRunDate: nextRunDate ?? this.nextRunDate,
        energyLevel: energyLevel ?? this.energyLevel,
        duration: duration ?? this.duration,
        advanceDays: advanceDays ?? this.advanceDays,
        skipHolidays: skipHolidays ?? this.skipHolidays,
        contextIds: contextIds ?? this.contextIds,
        rev: rev.present ? rev.value : this.rev,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
      );
  RecurringAction copyWithCompanion(RecurringActionsCompanion data) {
    return RecurringAction(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      type: data.type.present ? data.type.value : this.type,
      interval: data.interval.present ? data.interval.value : this.interval,
      totalCount:
          data.totalCount.present ? data.totalCount.value : this.totalCount,
      currentCount: data.currentCount.present
          ? data.currentCount.value
          : this.currentCount,
      nextRunDate:
          data.nextRunDate.present ? data.nextRunDate.value : this.nextRunDate,
      energyLevel:
          data.energyLevel.present ? data.energyLevel.value : this.energyLevel,
      duration: data.duration.present ? data.duration.value : this.duration,
      advanceDays:
          data.advanceDays.present ? data.advanceDays.value : this.advanceDays,
      skipHolidays: data.skipHolidays.present
          ? data.skipHolidays.value
          : this.skipHolidays,
      contextIds:
          data.contextIds.present ? data.contextIds.value : this.contextIds,
      rev: data.rev.present ? data.rev.value : this.rev,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurringAction(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('interval: $interval, ')
          ..write('totalCount: $totalCount, ')
          ..write('currentCount: $currentCount, ')
          ..write('nextRunDate: $nextRunDate, ')
          ..write('energyLevel: $energyLevel, ')
          ..write('duration: $duration, ')
          ..write('advanceDays: $advanceDays, ')
          ..write('skipHolidays: $skipHolidays, ')
          ..write('contextIds: $contextIds, ')
          ..write('rev: $rev, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      description,
      type,
      interval,
      totalCount,
      currentCount,
      nextRunDate,
      energyLevel,
      duration,
      advanceDays,
      skipHolidays,
      contextIds,
      rev,
      updatedAt,
      isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurringAction &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.type == this.type &&
          other.interval == this.interval &&
          other.totalCount == this.totalCount &&
          other.currentCount == this.currentCount &&
          other.nextRunDate == this.nextRunDate &&
          other.energyLevel == this.energyLevel &&
          other.duration == this.duration &&
          other.advanceDays == this.advanceDays &&
          other.skipHolidays == this.skipHolidays &&
          other.contextIds == this.contextIds &&
          other.rev == this.rev &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted);
}

class RecurringActionsCompanion extends UpdateCompanion<RecurringAction> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<RecurrenceType> type;
  final Value<int> interval;
  final Value<int> totalCount;
  final Value<int> currentCount;
  final Value<DateTime> nextRunDate;
  final Value<int> energyLevel;
  final Value<int> duration;
  final Value<int> advanceDays;
  final Value<bool> skipHolidays;
  final Value<List<String>> contextIds;
  final Value<String?> rev;
  final Value<DateTime?> updatedAt;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const RecurringActionsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.type = const Value.absent(),
    this.interval = const Value.absent(),
    this.totalCount = const Value.absent(),
    this.currentCount = const Value.absent(),
    this.nextRunDate = const Value.absent(),
    this.energyLevel = const Value.absent(),
    this.duration = const Value.absent(),
    this.advanceDays = const Value.absent(),
    this.skipHolidays = const Value.absent(),
    this.contextIds = const Value.absent(),
    this.rev = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecurringActionsCompanion.insert({
    required String id,
    required String title,
    this.description = const Value.absent(),
    required RecurrenceType type,
    this.interval = const Value.absent(),
    this.totalCount = const Value.absent(),
    this.currentCount = const Value.absent(),
    required DateTime nextRunDate,
    this.energyLevel = const Value.absent(),
    this.duration = const Value.absent(),
    this.advanceDays = const Value.absent(),
    this.skipHolidays = const Value.absent(),
    this.contextIds = const Value.absent(),
    this.rev = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        type = Value(type),
        nextRunDate = Value(nextRunDate);
  static Insertable<RecurringAction> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? type,
    Expression<int>? interval,
    Expression<int>? totalCount,
    Expression<int>? currentCount,
    Expression<DateTime>? nextRunDate,
    Expression<int>? energyLevel,
    Expression<int>? duration,
    Expression<int>? advanceDays,
    Expression<bool>? skipHolidays,
    Expression<String>? contextIds,
    Expression<String>? rev,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (type != null) 'type': type,
      if (interval != null) 'interval': interval,
      if (totalCount != null) 'total_count': totalCount,
      if (currentCount != null) 'current_count': currentCount,
      if (nextRunDate != null) 'next_run_date': nextRunDate,
      if (energyLevel != null) 'energy_level': energyLevel,
      if (duration != null) 'duration': duration,
      if (advanceDays != null) 'advance_days': advanceDays,
      if (skipHolidays != null) 'skip_holidays': skipHolidays,
      if (contextIds != null) 'context_ids': contextIds,
      if (rev != null) 'rev': rev,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecurringActionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String?>? description,
      Value<RecurrenceType>? type,
      Value<int>? interval,
      Value<int>? totalCount,
      Value<int>? currentCount,
      Value<DateTime>? nextRunDate,
      Value<int>? energyLevel,
      Value<int>? duration,
      Value<int>? advanceDays,
      Value<bool>? skipHolidays,
      Value<List<String>>? contextIds,
      Value<String?>? rev,
      Value<DateTime?>? updatedAt,
      Value<bool>? isDeleted,
      Value<int>? rowid}) {
    return RecurringActionsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      interval: interval ?? this.interval,
      totalCount: totalCount ?? this.totalCount,
      currentCount: currentCount ?? this.currentCount,
      nextRunDate: nextRunDate ?? this.nextRunDate,
      energyLevel: energyLevel ?? this.energyLevel,
      duration: duration ?? this.duration,
      advanceDays: advanceDays ?? this.advanceDays,
      skipHolidays: skipHolidays ?? this.skipHolidays,
      contextIds: contextIds ?? this.contextIds,
      rev: rev ?? this.rev,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(
          $RecurringActionsTable.$convertertype.toSql(type.value));
    }
    if (interval.present) {
      map['interval'] = Variable<int>(interval.value);
    }
    if (totalCount.present) {
      map['total_count'] = Variable<int>(totalCount.value);
    }
    if (currentCount.present) {
      map['current_count'] = Variable<int>(currentCount.value);
    }
    if (nextRunDate.present) {
      map['next_run_date'] = Variable<DateTime>(nextRunDate.value);
    }
    if (energyLevel.present) {
      map['energy_level'] = Variable<int>(energyLevel.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (advanceDays.present) {
      map['advance_days'] = Variable<int>(advanceDays.value);
    }
    if (skipHolidays.present) {
      map['skip_holidays'] = Variable<bool>(skipHolidays.value);
    }
    if (contextIds.present) {
      map['context_ids'] = Variable<String>(
          $RecurringActionsTable.$convertercontextIds.toSql(contextIds.value));
    }
    if (rev.present) {
      map['rev'] = Variable<String>(rev.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurringActionsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('interval: $interval, ')
          ..write('totalCount: $totalCount, ')
          ..write('currentCount: $currentCount, ')
          ..write('nextRunDate: $nextRunDate, ')
          ..write('energyLevel: $energyLevel, ')
          ..write('duration: $duration, ')
          ..write('advanceDays: $advanceDays, ')
          ..write('skipHolidays: $skipHolidays, ')
          ..write('contextIds: $contextIds, ')
          ..write('rev: $rev, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScheduledActionsTable extends ScheduledActions
    with TableInfo<$ScheduledActionsTable, ScheduledAction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScheduledActionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
      'start_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _energyLevelMeta =
      const VerificationMeta('energyLevel');
  @override
  late final GeneratedColumn<int> energyLevel = GeneratedColumn<int>(
      'energy_level', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(3));
  static const VerificationMeta _durationMeta =
      const VerificationMeta('duration');
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
      'duration', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(10));
  static const VerificationMeta _advanceDaysMeta =
      const VerificationMeta('advanceDays');
  @override
  late final GeneratedColumn<int> advanceDays = GeneratedColumn<int>(
      'advance_days', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _skipHolidaysMeta =
      const VerificationMeta('skipHolidays');
  @override
  late final GeneratedColumn<bool> skipHolidays = GeneratedColumn<bool>(
      'skip_holidays', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("skip_holidays" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isCreatedMeta =
      const VerificationMeta('isCreated');
  @override
  late final GeneratedColumn<bool> isCreated = GeneratedColumn<bool>(
      'is_created', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_created" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _contextIdsMeta =
      const VerificationMeta('contextIds');
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> contextIds =
      GeneratedColumn<String>('context_ids', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: const Constant('[]'))
          .withConverter<List<String>>(
              $ScheduledActionsTable.$convertercontextIds);
  static const VerificationMeta _revMeta = const VerificationMeta('rev');
  @override
  late final GeneratedColumn<String> rev = GeneratedColumn<String>(
      'rev', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        description,
        startDate,
        energyLevel,
        duration,
        advanceDays,
        skipHolidays,
        isCreated,
        contextIds,
        rev,
        updatedAt,
        isDeleted
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scheduled_actions';
  @override
  VerificationContext validateIntegrity(Insertable<ScheduledAction> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('energy_level')) {
      context.handle(
          _energyLevelMeta,
          energyLevel.isAcceptableOrUnknown(
              data['energy_level']!, _energyLevelMeta));
    }
    if (data.containsKey('duration')) {
      context.handle(_durationMeta,
          duration.isAcceptableOrUnknown(data['duration']!, _durationMeta));
    }
    if (data.containsKey('advance_days')) {
      context.handle(
          _advanceDaysMeta,
          advanceDays.isAcceptableOrUnknown(
              data['advance_days']!, _advanceDaysMeta));
    }
    if (data.containsKey('skip_holidays')) {
      context.handle(
          _skipHolidaysMeta,
          skipHolidays.isAcceptableOrUnknown(
              data['skip_holidays']!, _skipHolidaysMeta));
    }
    if (data.containsKey('is_created')) {
      context.handle(_isCreatedMeta,
          isCreated.isAcceptableOrUnknown(data['is_created']!, _isCreatedMeta));
    }
    context.handle(_contextIdsMeta, const VerificationResult.success());
    if (data.containsKey('rev')) {
      context.handle(
          _revMeta, rev.isAcceptableOrUnknown(data['rev']!, _revMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScheduledAction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScheduledAction(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_date'])!,
      energyLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}energy_level'])!,
      duration: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration'])!,
      advanceDays: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}advance_days'])!,
      skipHolidays: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}skip_holidays'])!,
      isCreated: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_created'])!,
      contextIds: $ScheduledActionsTable.$convertercontextIds.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}context_ids'])!),
      rev: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rev']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
    );
  }

  @override
  $ScheduledActionsTable createAlias(String alias) {
    return $ScheduledActionsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $convertercontextIds =
      const ListStringConverter();
}

class ScheduledAction extends DataClass implements Insertable<ScheduledAction> {
  final String id;
  final String title;
  final String? description;
  final DateTime startDate;
  final int energyLevel;
  final int duration;
  final int advanceDays;
  final bool skipHolidays;
  final bool isCreated;
  final List<String> contextIds;
  final String? rev;
  final DateTime? updatedAt;
  final bool isDeleted;
  const ScheduledAction(
      {required this.id,
      required this.title,
      this.description,
      required this.startDate,
      required this.energyLevel,
      required this.duration,
      required this.advanceDays,
      required this.skipHolidays,
      required this.isCreated,
      required this.contextIds,
      this.rev,
      this.updatedAt,
      required this.isDeleted});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['start_date'] = Variable<DateTime>(startDate);
    map['energy_level'] = Variable<int>(energyLevel);
    map['duration'] = Variable<int>(duration);
    map['advance_days'] = Variable<int>(advanceDays);
    map['skip_holidays'] = Variable<bool>(skipHolidays);
    map['is_created'] = Variable<bool>(isCreated);
    {
      map['context_ids'] = Variable<String>(
          $ScheduledActionsTable.$convertercontextIds.toSql(contextIds));
    }
    if (!nullToAbsent || rev != null) {
      map['rev'] = Variable<String>(rev);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  ScheduledActionsCompanion toCompanion(bool nullToAbsent) {
    return ScheduledActionsCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      startDate: Value(startDate),
      energyLevel: Value(energyLevel),
      duration: Value(duration),
      advanceDays: Value(advanceDays),
      skipHolidays: Value(skipHolidays),
      isCreated: Value(isCreated),
      contextIds: Value(contextIds),
      rev: rev == null && nullToAbsent ? const Value.absent() : Value(rev),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      isDeleted: Value(isDeleted),
    );
  }

  factory ScheduledAction.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScheduledAction(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      energyLevel: serializer.fromJson<int>(json['energyLevel']),
      duration: serializer.fromJson<int>(json['duration']),
      advanceDays: serializer.fromJson<int>(json['advanceDays']),
      skipHolidays: serializer.fromJson<bool>(json['skipHolidays']),
      isCreated: serializer.fromJson<bool>(json['isCreated']),
      contextIds: serializer.fromJson<List<String>>(json['contextIds']),
      rev: serializer.fromJson<String?>(json['rev']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'startDate': serializer.toJson<DateTime>(startDate),
      'energyLevel': serializer.toJson<int>(energyLevel),
      'duration': serializer.toJson<int>(duration),
      'advanceDays': serializer.toJson<int>(advanceDays),
      'skipHolidays': serializer.toJson<bool>(skipHolidays),
      'isCreated': serializer.toJson<bool>(isCreated),
      'contextIds': serializer.toJson<List<String>>(contextIds),
      'rev': serializer.toJson<String?>(rev),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  ScheduledAction copyWith(
          {String? id,
          String? title,
          Value<String?> description = const Value.absent(),
          DateTime? startDate,
          int? energyLevel,
          int? duration,
          int? advanceDays,
          bool? skipHolidays,
          bool? isCreated,
          List<String>? contextIds,
          Value<String?> rev = const Value.absent(),
          Value<DateTime?> updatedAt = const Value.absent(),
          bool? isDeleted}) =>
      ScheduledAction(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description.present ? description.value : this.description,
        startDate: startDate ?? this.startDate,
        energyLevel: energyLevel ?? this.energyLevel,
        duration: duration ?? this.duration,
        advanceDays: advanceDays ?? this.advanceDays,
        skipHolidays: skipHolidays ?? this.skipHolidays,
        isCreated: isCreated ?? this.isCreated,
        contextIds: contextIds ?? this.contextIds,
        rev: rev.present ? rev.value : this.rev,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
      );
  ScheduledAction copyWithCompanion(ScheduledActionsCompanion data) {
    return ScheduledAction(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      energyLevel:
          data.energyLevel.present ? data.energyLevel.value : this.energyLevel,
      duration: data.duration.present ? data.duration.value : this.duration,
      advanceDays:
          data.advanceDays.present ? data.advanceDays.value : this.advanceDays,
      skipHolidays: data.skipHolidays.present
          ? data.skipHolidays.value
          : this.skipHolidays,
      isCreated: data.isCreated.present ? data.isCreated.value : this.isCreated,
      contextIds:
          data.contextIds.present ? data.contextIds.value : this.contextIds,
      rev: data.rev.present ? data.rev.value : this.rev,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScheduledAction(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('startDate: $startDate, ')
          ..write('energyLevel: $energyLevel, ')
          ..write('duration: $duration, ')
          ..write('advanceDays: $advanceDays, ')
          ..write('skipHolidays: $skipHolidays, ')
          ..write('isCreated: $isCreated, ')
          ..write('contextIds: $contextIds, ')
          ..write('rev: $rev, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      description,
      startDate,
      energyLevel,
      duration,
      advanceDays,
      skipHolidays,
      isCreated,
      contextIds,
      rev,
      updatedAt,
      isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScheduledAction &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.startDate == this.startDate &&
          other.energyLevel == this.energyLevel &&
          other.duration == this.duration &&
          other.advanceDays == this.advanceDays &&
          other.skipHolidays == this.skipHolidays &&
          other.isCreated == this.isCreated &&
          other.contextIds == this.contextIds &&
          other.rev == this.rev &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted);
}

class ScheduledActionsCompanion extends UpdateCompanion<ScheduledAction> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<DateTime> startDate;
  final Value<int> energyLevel;
  final Value<int> duration;
  final Value<int> advanceDays;
  final Value<bool> skipHolidays;
  final Value<bool> isCreated;
  final Value<List<String>> contextIds;
  final Value<String?> rev;
  final Value<DateTime?> updatedAt;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const ScheduledActionsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.startDate = const Value.absent(),
    this.energyLevel = const Value.absent(),
    this.duration = const Value.absent(),
    this.advanceDays = const Value.absent(),
    this.skipHolidays = const Value.absent(),
    this.isCreated = const Value.absent(),
    this.contextIds = const Value.absent(),
    this.rev = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScheduledActionsCompanion.insert({
    required String id,
    required String title,
    this.description = const Value.absent(),
    required DateTime startDate,
    this.energyLevel = const Value.absent(),
    this.duration = const Value.absent(),
    this.advanceDays = const Value.absent(),
    this.skipHolidays = const Value.absent(),
    this.isCreated = const Value.absent(),
    this.contextIds = const Value.absent(),
    this.rev = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        startDate = Value(startDate);
  static Insertable<ScheduledAction> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<DateTime>? startDate,
    Expression<int>? energyLevel,
    Expression<int>? duration,
    Expression<int>? advanceDays,
    Expression<bool>? skipHolidays,
    Expression<bool>? isCreated,
    Expression<String>? contextIds,
    Expression<String>? rev,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (startDate != null) 'start_date': startDate,
      if (energyLevel != null) 'energy_level': energyLevel,
      if (duration != null) 'duration': duration,
      if (advanceDays != null) 'advance_days': advanceDays,
      if (skipHolidays != null) 'skip_holidays': skipHolidays,
      if (isCreated != null) 'is_created': isCreated,
      if (contextIds != null) 'context_ids': contextIds,
      if (rev != null) 'rev': rev,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScheduledActionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String?>? description,
      Value<DateTime>? startDate,
      Value<int>? energyLevel,
      Value<int>? duration,
      Value<int>? advanceDays,
      Value<bool>? skipHolidays,
      Value<bool>? isCreated,
      Value<List<String>>? contextIds,
      Value<String?>? rev,
      Value<DateTime?>? updatedAt,
      Value<bool>? isDeleted,
      Value<int>? rowid}) {
    return ScheduledActionsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      energyLevel: energyLevel ?? this.energyLevel,
      duration: duration ?? this.duration,
      advanceDays: advanceDays ?? this.advanceDays,
      skipHolidays: skipHolidays ?? this.skipHolidays,
      isCreated: isCreated ?? this.isCreated,
      contextIds: contextIds ?? this.contextIds,
      rev: rev ?? this.rev,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (energyLevel.present) {
      map['energy_level'] = Variable<int>(energyLevel.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (advanceDays.present) {
      map['advance_days'] = Variable<int>(advanceDays.value);
    }
    if (skipHolidays.present) {
      map['skip_holidays'] = Variable<bool>(skipHolidays.value);
    }
    if (isCreated.present) {
      map['is_created'] = Variable<bool>(isCreated.value);
    }
    if (contextIds.present) {
      map['context_ids'] = Variable<String>(
          $ScheduledActionsTable.$convertercontextIds.toSql(contextIds.value));
    }
    if (rev.present) {
      map['rev'] = Variable<String>(rev.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScheduledActionsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('startDate: $startDate, ')
          ..write('energyLevel: $energyLevel, ')
          ..write('duration: $duration, ')
          ..write('advanceDays: $advanceDays, ')
          ..write('skipHolidays: $skipHolidays, ')
          ..write('isCreated: $isCreated, ')
          ..write('contextIds: $contextIds, ')
          ..write('rev: $rev, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncConfigsTable extends SyncConfigs
    with TableInfo<$SyncConfigsTable, SyncConfigData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncConfigsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
      'url', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _usernameMeta =
      const VerificationMeta('username');
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
      'username', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _passwordMeta =
      const VerificationMeta('password');
  @override
  late final GeneratedColumn<String> password = GeneratedColumn<String>(
      'password', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _dbNameMeta = const VerificationMeta('dbName');
  @override
  late final GeneratedColumn<String> dbName = GeneratedColumn<String>(
      'db_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('gtdoro'));
  static const VerificationMeta _isEnabledMeta =
      const VerificationMeta('isEnabled');
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
      'is_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_enabled" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _lastSeqMeta =
      const VerificationMeta('lastSeq');
  @override
  late final GeneratedColumn<String> lastSeq = GeneratedColumn<String>(
      'last_seq', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dbTypeMeta = const VerificationMeta('dbType');
  @override
  late final GeneratedColumn<String> dbType = GeneratedColumn<String>(
      'db_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('oracle'));
  @override
  List<GeneratedColumn> get $columns =>
      [id, url, username, password, dbName, isEnabled, lastSeq, dbType];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_configs';
  @override
  VerificationContext validateIntegrity(Insertable<SyncConfigData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('url')) {
      context.handle(
          _urlMeta, url.isAcceptableOrUnknown(data['url']!, _urlMeta));
    }
    if (data.containsKey('username')) {
      context.handle(_usernameMeta,
          username.isAcceptableOrUnknown(data['username']!, _usernameMeta));
    }
    if (data.containsKey('password')) {
      context.handle(_passwordMeta,
          password.isAcceptableOrUnknown(data['password']!, _passwordMeta));
    }
    if (data.containsKey('db_name')) {
      context.handle(_dbNameMeta,
          dbName.isAcceptableOrUnknown(data['db_name']!, _dbNameMeta));
    }
    if (data.containsKey('is_enabled')) {
      context.handle(_isEnabledMeta,
          isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta));
    }
    if (data.containsKey('last_seq')) {
      context.handle(_lastSeqMeta,
          lastSeq.isAcceptableOrUnknown(data['last_seq']!, _lastSeqMeta));
    }
    if (data.containsKey('db_type')) {
      context.handle(_dbTypeMeta,
          dbType.isAcceptableOrUnknown(data['db_type']!, _dbTypeMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncConfigData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncConfigData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      url: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}url'])!,
      username: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}username'])!,
      password: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}password'])!,
      dbName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}db_name'])!,
      isEnabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_enabled'])!,
      lastSeq: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_seq']),
      dbType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}db_type'])!,
    );
  }

  @override
  $SyncConfigsTable createAlias(String alias) {
    return $SyncConfigsTable(attachedDatabase, alias);
  }
}

class SyncConfigData extends DataClass implements Insertable<SyncConfigData> {
  final int id;
  final String url;
  final String username;
  final String password;
  final String dbName;
  final bool isEnabled;
  final String? lastSeq;
  final String dbType;
  const SyncConfigData(
      {required this.id,
      required this.url,
      required this.username,
      required this.password,
      required this.dbName,
      required this.isEnabled,
      this.lastSeq,
      required this.dbType});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['url'] = Variable<String>(url);
    map['username'] = Variable<String>(username);
    map['password'] = Variable<String>(password);
    map['db_name'] = Variable<String>(dbName);
    map['is_enabled'] = Variable<bool>(isEnabled);
    if (!nullToAbsent || lastSeq != null) {
      map['last_seq'] = Variable<String>(lastSeq);
    }
    map['db_type'] = Variable<String>(dbType);
    return map;
  }

  SyncConfigsCompanion toCompanion(bool nullToAbsent) {
    return SyncConfigsCompanion(
      id: Value(id),
      url: Value(url),
      username: Value(username),
      password: Value(password),
      dbName: Value(dbName),
      isEnabled: Value(isEnabled),
      lastSeq: lastSeq == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeq),
      dbType: Value(dbType),
    );
  }

  factory SyncConfigData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncConfigData(
      id: serializer.fromJson<int>(json['id']),
      url: serializer.fromJson<String>(json['url']),
      username: serializer.fromJson<String>(json['username']),
      password: serializer.fromJson<String>(json['password']),
      dbName: serializer.fromJson<String>(json['dbName']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      lastSeq: serializer.fromJson<String?>(json['lastSeq']),
      dbType: serializer.fromJson<String>(json['dbType']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'url': serializer.toJson<String>(url),
      'username': serializer.toJson<String>(username),
      'password': serializer.toJson<String>(password),
      'dbName': serializer.toJson<String>(dbName),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'lastSeq': serializer.toJson<String?>(lastSeq),
      'dbType': serializer.toJson<String>(dbType),
    };
  }

  SyncConfigData copyWith(
          {int? id,
          String? url,
          String? username,
          String? password,
          String? dbName,
          bool? isEnabled,
          Value<String?> lastSeq = const Value.absent(),
          String? dbType}) =>
      SyncConfigData(
        id: id ?? this.id,
        url: url ?? this.url,
        username: username ?? this.username,
        password: password ?? this.password,
        dbName: dbName ?? this.dbName,
        isEnabled: isEnabled ?? this.isEnabled,
        lastSeq: lastSeq.present ? lastSeq.value : this.lastSeq,
        dbType: dbType ?? this.dbType,
      );
  SyncConfigData copyWithCompanion(SyncConfigsCompanion data) {
    return SyncConfigData(
      id: data.id.present ? data.id.value : this.id,
      url: data.url.present ? data.url.value : this.url,
      username: data.username.present ? data.username.value : this.username,
      password: data.password.present ? data.password.value : this.password,
      dbName: data.dbName.present ? data.dbName.value : this.dbName,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      lastSeq: data.lastSeq.present ? data.lastSeq.value : this.lastSeq,
      dbType: data.dbType.present ? data.dbType.value : this.dbType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncConfigData(')
          ..write('id: $id, ')
          ..write('url: $url, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('dbName: $dbName, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('lastSeq: $lastSeq, ')
          ..write('dbType: $dbType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, url, username, password, dbName, isEnabled, lastSeq, dbType);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncConfigData &&
          other.id == this.id &&
          other.url == this.url &&
          other.username == this.username &&
          other.password == this.password &&
          other.dbName == this.dbName &&
          other.isEnabled == this.isEnabled &&
          other.lastSeq == this.lastSeq &&
          other.dbType == this.dbType);
}

class SyncConfigsCompanion extends UpdateCompanion<SyncConfigData> {
  final Value<int> id;
  final Value<String> url;
  final Value<String> username;
  final Value<String> password;
  final Value<String> dbName;
  final Value<bool> isEnabled;
  final Value<String?> lastSeq;
  final Value<String> dbType;
  const SyncConfigsCompanion({
    this.id = const Value.absent(),
    this.url = const Value.absent(),
    this.username = const Value.absent(),
    this.password = const Value.absent(),
    this.dbName = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.lastSeq = const Value.absent(),
    this.dbType = const Value.absent(),
  });
  SyncConfigsCompanion.insert({
    this.id = const Value.absent(),
    this.url = const Value.absent(),
    this.username = const Value.absent(),
    this.password = const Value.absent(),
    this.dbName = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.lastSeq = const Value.absent(),
    this.dbType = const Value.absent(),
  });
  static Insertable<SyncConfigData> custom({
    Expression<int>? id,
    Expression<String>? url,
    Expression<String>? username,
    Expression<String>? password,
    Expression<String>? dbName,
    Expression<bool>? isEnabled,
    Expression<String>? lastSeq,
    Expression<String>? dbType,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (url != null) 'url': url,
      if (username != null) 'username': username,
      if (password != null) 'password': password,
      if (dbName != null) 'db_name': dbName,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (lastSeq != null) 'last_seq': lastSeq,
      if (dbType != null) 'db_type': dbType,
    });
  }

  SyncConfigsCompanion copyWith(
      {Value<int>? id,
      Value<String>? url,
      Value<String>? username,
      Value<String>? password,
      Value<String>? dbName,
      Value<bool>? isEnabled,
      Value<String?>? lastSeq,
      Value<String>? dbType}) {
    return SyncConfigsCompanion(
      id: id ?? this.id,
      url: url ?? this.url,
      username: username ?? this.username,
      password: password ?? this.password,
      dbName: dbName ?? this.dbName,
      isEnabled: isEnabled ?? this.isEnabled,
      lastSeq: lastSeq ?? this.lastSeq,
      dbType: dbType ?? this.dbType,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (password.present) {
      map['password'] = Variable<String>(password.value);
    }
    if (dbName.present) {
      map['db_name'] = Variable<String>(dbName.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (lastSeq.present) {
      map['last_seq'] = Variable<String>(lastSeq.value);
    }
    if (dbType.present) {
      map['db_type'] = Variable<String>(dbType.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncConfigsCompanion(')
          ..write('id: $id, ')
          ..write('url: $url, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('dbName: $dbName, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('lastSeq: $lastSeq, ')
          ..write('dbType: $dbType')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ActionsTable actions = $ActionsTable(this);
  late final $ContextsTable contexts = $ContextsTable(this);
  late final $ActionContextsTable actionContexts = $ActionContextsTable(this);
  late final $RecurringActionsTable recurringActions =
      $RecurringActionsTable(this);
  late final $ScheduledActionsTable scheduledActions =
      $ScheduledActionsTable(this);
  late final $SyncConfigsTable syncConfigs = $SyncConfigsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        actions,
        contexts,
        actionContexts,
        recurringActions,
        scheduledActions,
        syncConfigs
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('actions',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('action_contexts', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('contexts',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('action_contexts', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$ActionsTableCreateCompanionBuilder = ActionsCompanion Function({
  required String id,
  required String title,
  Value<String?> description,
  Value<String?> waitingFor,
  Value<bool> isDone,
  Value<GTDStatus> status,
  Value<int?> energyLevel,
  Value<int?> duration,
  required DateTime createdAt,
  Value<DateTime?> dueDate,
  Value<DateTime?> completedAt,
  Value<String?> rev,
  Value<DateTime?> updatedAt,
  Value<bool> isDeleted,
  Value<int?> pomodorosCompleted,
  Value<int?> totalPomodoroTime,
  Value<int> rowid,
});
typedef $$ActionsTableUpdateCompanionBuilder = ActionsCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String?> description,
  Value<String?> waitingFor,
  Value<bool> isDone,
  Value<GTDStatus> status,
  Value<int?> energyLevel,
  Value<int?> duration,
  Value<DateTime> createdAt,
  Value<DateTime?> dueDate,
  Value<DateTime?> completedAt,
  Value<String?> rev,
  Value<DateTime?> updatedAt,
  Value<bool> isDeleted,
  Value<int?> pomodorosCompleted,
  Value<int?> totalPomodoroTime,
  Value<int> rowid,
});

final class $$ActionsTableReferences
    extends BaseReferences<_$AppDatabase, $ActionsTable, Action> {
  $$ActionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ActionContextsTable, List<ActionContext>>
      _actionContextsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.actionContexts,
              aliasName: $_aliasNameGenerator(
                  db.actions.id, db.actionContexts.actionId));

  $$ActionContextsTableProcessedTableManager get actionContextsRefs {
    final manager = $$ActionContextsTableTableManager($_db, $_db.actionContexts)
        .filter((f) => f.actionId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_actionContextsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ActionsTableFilterComposer
    extends Composer<_$AppDatabase, $ActionsTable> {
  $$ActionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get waitingFor => $composableBuilder(
      column: $table.waitingFor, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDone => $composableBuilder(
      column: $table.isDone, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<GTDStatus, GTDStatus, int> get status =>
      $composableBuilder(
          column: $table.status,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get energyLevel => $composableBuilder(
      column: $table.energyLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rev => $composableBuilder(
      column: $table.rev, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get pomodorosCompleted => $composableBuilder(
      column: $table.pomodorosCompleted,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalPomodoroTime => $composableBuilder(
      column: $table.totalPomodoroTime,
      builder: (column) => ColumnFilters(column));

  Expression<bool> actionContextsRefs(
      Expression<bool> Function($$ActionContextsTableFilterComposer f) f) {
    final $$ActionContextsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.actionContexts,
        getReferencedColumn: (t) => t.actionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ActionContextsTableFilterComposer(
              $db: $db,
              $table: $db.actionContexts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ActionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ActionsTable> {
  $$ActionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get waitingFor => $composableBuilder(
      column: $table.waitingFor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDone => $composableBuilder(
      column: $table.isDone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get energyLevel => $composableBuilder(
      column: $table.energyLevel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rev => $composableBuilder(
      column: $table.rev, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get pomodorosCompleted => $composableBuilder(
      column: $table.pomodorosCompleted,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalPomodoroTime => $composableBuilder(
      column: $table.totalPomodoroTime,
      builder: (column) => ColumnOrderings(column));
}

class $$ActionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActionsTable> {
  $$ActionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get waitingFor => $composableBuilder(
      column: $table.waitingFor, builder: (column) => column);

  GeneratedColumn<bool> get isDone =>
      $composableBuilder(column: $table.isDone, builder: (column) => column);

  GeneratedColumnWithTypeConverter<GTDStatus, int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get energyLevel => $composableBuilder(
      column: $table.energyLevel, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<String> get rev =>
      $composableBuilder(column: $table.rev, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<int> get pomodorosCompleted => $composableBuilder(
      column: $table.pomodorosCompleted, builder: (column) => column);

  GeneratedColumn<int> get totalPomodoroTime => $composableBuilder(
      column: $table.totalPomodoroTime, builder: (column) => column);

  Expression<T> actionContextsRefs<T extends Object>(
      Expression<T> Function($$ActionContextsTableAnnotationComposer a) f) {
    final $$ActionContextsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.actionContexts,
        getReferencedColumn: (t) => t.actionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ActionContextsTableAnnotationComposer(
              $db: $db,
              $table: $db.actionContexts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ActionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ActionsTable,
    Action,
    $$ActionsTableFilterComposer,
    $$ActionsTableOrderingComposer,
    $$ActionsTableAnnotationComposer,
    $$ActionsTableCreateCompanionBuilder,
    $$ActionsTableUpdateCompanionBuilder,
    (Action, $$ActionsTableReferences),
    Action,
    PrefetchHooks Function({bool actionContextsRefs})> {
  $$ActionsTableTableManager(_$AppDatabase db, $ActionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> waitingFor = const Value.absent(),
            Value<bool> isDone = const Value.absent(),
            Value<GTDStatus> status = const Value.absent(),
            Value<int?> energyLevel = const Value.absent(),
            Value<int?> duration = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<String?> rev = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<int?> pomodorosCompleted = const Value.absent(),
            Value<int?> totalPomodoroTime = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ActionsCompanion(
            id: id,
            title: title,
            description: description,
            waitingFor: waitingFor,
            isDone: isDone,
            status: status,
            energyLevel: energyLevel,
            duration: duration,
            createdAt: createdAt,
            dueDate: dueDate,
            completedAt: completedAt,
            rev: rev,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
            pomodorosCompleted: pomodorosCompleted,
            totalPomodoroTime: totalPomodoroTime,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            Value<String?> description = const Value.absent(),
            Value<String?> waitingFor = const Value.absent(),
            Value<bool> isDone = const Value.absent(),
            Value<GTDStatus> status = const Value.absent(),
            Value<int?> energyLevel = const Value.absent(),
            Value<int?> duration = const Value.absent(),
            required DateTime createdAt,
            Value<DateTime?> dueDate = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<String?> rev = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<int?> pomodorosCompleted = const Value.absent(),
            Value<int?> totalPomodoroTime = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ActionsCompanion.insert(
            id: id,
            title: title,
            description: description,
            waitingFor: waitingFor,
            isDone: isDone,
            status: status,
            energyLevel: energyLevel,
            duration: duration,
            createdAt: createdAt,
            dueDate: dueDate,
            completedAt: completedAt,
            rev: rev,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
            pomodorosCompleted: pomodorosCompleted,
            totalPomodoroTime: totalPomodoroTime,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ActionsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({actionContextsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (actionContextsRefs) db.actionContexts
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (actionContextsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$ActionsTableReferences
                            ._actionContextsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ActionsTableReferences(db, table, p0)
                                .actionContextsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.actionId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ActionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ActionsTable,
    Action,
    $$ActionsTableFilterComposer,
    $$ActionsTableOrderingComposer,
    $$ActionsTableAnnotationComposer,
    $$ActionsTableCreateCompanionBuilder,
    $$ActionsTableUpdateCompanionBuilder,
    (Action, $$ActionsTableReferences),
    Action,
    PrefetchHooks Function({bool actionContextsRefs})>;
typedef $$ContextsTableCreateCompanionBuilder = ContextsCompanion Function({
  required String id,
  required String name,
  Value<String?> category,
  required ContextType typeCategory,
  required int colorValue,
  Value<String?> rev,
  Value<DateTime?> updatedAt,
  Value<bool> isDeleted,
  Value<int> rowid,
});
typedef $$ContextsTableUpdateCompanionBuilder = ContextsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> category,
  Value<ContextType> typeCategory,
  Value<int> colorValue,
  Value<String?> rev,
  Value<DateTime?> updatedAt,
  Value<bool> isDeleted,
  Value<int> rowid,
});

final class $$ContextsTableReferences
    extends BaseReferences<_$AppDatabase, $ContextsTable, Context> {
  $$ContextsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ActionContextsTable, List<ActionContext>>
      _actionContextsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.actionContexts,
              aliasName: $_aliasNameGenerator(
                  db.contexts.id, db.actionContexts.contextId));

  $$ActionContextsTableProcessedTableManager get actionContextsRefs {
    final manager = $$ActionContextsTableTableManager($_db, $_db.actionContexts)
        .filter((f) => f.contextId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_actionContextsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ContextsTableFilterComposer
    extends Composer<_$AppDatabase, $ContextsTable> {
  $$ContextsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<ContextType, ContextType, int>
      get typeCategory => $composableBuilder(
          column: $table.typeCategory,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get colorValue => $composableBuilder(
      column: $table.colorValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rev => $composableBuilder(
      column: $table.rev, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));

  Expression<bool> actionContextsRefs(
      Expression<bool> Function($$ActionContextsTableFilterComposer f) f) {
    final $$ActionContextsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.actionContexts,
        getReferencedColumn: (t) => t.contextId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ActionContextsTableFilterComposer(
              $db: $db,
              $table: $db.actionContexts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ContextsTableOrderingComposer
    extends Composer<_$AppDatabase, $ContextsTable> {
  $$ContextsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get typeCategory => $composableBuilder(
      column: $table.typeCategory,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get colorValue => $composableBuilder(
      column: $table.colorValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rev => $composableBuilder(
      column: $table.rev, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));
}

class $$ContextsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContextsTable> {
  $$ContextsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ContextType, int> get typeCategory =>
      $composableBuilder(
          column: $table.typeCategory, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
      column: $table.colorValue, builder: (column) => column);

  GeneratedColumn<String> get rev =>
      $composableBuilder(column: $table.rev, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  Expression<T> actionContextsRefs<T extends Object>(
      Expression<T> Function($$ActionContextsTableAnnotationComposer a) f) {
    final $$ActionContextsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.actionContexts,
        getReferencedColumn: (t) => t.contextId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ActionContextsTableAnnotationComposer(
              $db: $db,
              $table: $db.actionContexts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ContextsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ContextsTable,
    Context,
    $$ContextsTableFilterComposer,
    $$ContextsTableOrderingComposer,
    $$ContextsTableAnnotationComposer,
    $$ContextsTableCreateCompanionBuilder,
    $$ContextsTableUpdateCompanionBuilder,
    (Context, $$ContextsTableReferences),
    Context,
    PrefetchHooks Function({bool actionContextsRefs})> {
  $$ContextsTableTableManager(_$AppDatabase db, $ContextsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContextsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContextsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContextsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<ContextType> typeCategory = const Value.absent(),
            Value<int> colorValue = const Value.absent(),
            Value<String?> rev = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ContextsCompanion(
            id: id,
            name: name,
            category: category,
            typeCategory: typeCategory,
            colorValue: colorValue,
            rev: rev,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> category = const Value.absent(),
            required ContextType typeCategory,
            required int colorValue,
            Value<String?> rev = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ContextsCompanion.insert(
            id: id,
            name: name,
            category: category,
            typeCategory: typeCategory,
            colorValue: colorValue,
            rev: rev,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ContextsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({actionContextsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (actionContextsRefs) db.actionContexts
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (actionContextsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$ContextsTableReferences
                            ._actionContextsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ContextsTableReferences(db, table, p0)
                                .actionContextsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.contextId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ContextsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ContextsTable,
    Context,
    $$ContextsTableFilterComposer,
    $$ContextsTableOrderingComposer,
    $$ContextsTableAnnotationComposer,
    $$ContextsTableCreateCompanionBuilder,
    $$ContextsTableUpdateCompanionBuilder,
    (Context, $$ContextsTableReferences),
    Context,
    PrefetchHooks Function({bool actionContextsRefs})>;
typedef $$ActionContextsTableCreateCompanionBuilder = ActionContextsCompanion
    Function({
  required String actionId,
  required String contextId,
  Value<int> rowid,
});
typedef $$ActionContextsTableUpdateCompanionBuilder = ActionContextsCompanion
    Function({
  Value<String> actionId,
  Value<String> contextId,
  Value<int> rowid,
});

final class $$ActionContextsTableReferences
    extends BaseReferences<_$AppDatabase, $ActionContextsTable, ActionContext> {
  $$ActionContextsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ActionsTable _actionIdTable(_$AppDatabase db) =>
      db.actions.createAlias(
          $_aliasNameGenerator(db.actionContexts.actionId, db.actions.id));

  $$ActionsTableProcessedTableManager? get actionId {
    if ($_item.actionId == null) return null;
    final manager = $$ActionsTableTableManager($_db, $_db.actions)
        .filter((f) => f.id($_item.actionId!));
    final item = $_typedResult.readTableOrNull(_actionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ContextsTable _contextIdTable(_$AppDatabase db) =>
      db.contexts.createAlias(
          $_aliasNameGenerator(db.actionContexts.contextId, db.contexts.id));

  $$ContextsTableProcessedTableManager? get contextId {
    if ($_item.contextId == null) return null;
    final manager = $$ContextsTableTableManager($_db, $_db.contexts)
        .filter((f) => f.id($_item.contextId!));
    final item = $_typedResult.readTableOrNull(_contextIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ActionContextsTableFilterComposer
    extends Composer<_$AppDatabase, $ActionContextsTable> {
  $$ActionContextsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ActionsTableFilterComposer get actionId {
    final $$ActionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.actionId,
        referencedTable: $db.actions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ActionsTableFilterComposer(
              $db: $db,
              $table: $db.actions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ContextsTableFilterComposer get contextId {
    final $$ContextsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.contextId,
        referencedTable: $db.contexts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContextsTableFilterComposer(
              $db: $db,
              $table: $db.contexts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ActionContextsTableOrderingComposer
    extends Composer<_$AppDatabase, $ActionContextsTable> {
  $$ActionContextsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ActionsTableOrderingComposer get actionId {
    final $$ActionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.actionId,
        referencedTable: $db.actions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ActionsTableOrderingComposer(
              $db: $db,
              $table: $db.actions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ContextsTableOrderingComposer get contextId {
    final $$ContextsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.contextId,
        referencedTable: $db.contexts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContextsTableOrderingComposer(
              $db: $db,
              $table: $db.contexts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ActionContextsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActionContextsTable> {
  $$ActionContextsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ActionsTableAnnotationComposer get actionId {
    final $$ActionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.actionId,
        referencedTable: $db.actions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ActionsTableAnnotationComposer(
              $db: $db,
              $table: $db.actions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ContextsTableAnnotationComposer get contextId {
    final $$ContextsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.contextId,
        referencedTable: $db.contexts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ContextsTableAnnotationComposer(
              $db: $db,
              $table: $db.contexts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ActionContextsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ActionContextsTable,
    ActionContext,
    $$ActionContextsTableFilterComposer,
    $$ActionContextsTableOrderingComposer,
    $$ActionContextsTableAnnotationComposer,
    $$ActionContextsTableCreateCompanionBuilder,
    $$ActionContextsTableUpdateCompanionBuilder,
    (ActionContext, $$ActionContextsTableReferences),
    ActionContext,
    PrefetchHooks Function({bool actionId, bool contextId})> {
  $$ActionContextsTableTableManager(
      _$AppDatabase db, $ActionContextsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActionContextsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActionContextsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActionContextsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> actionId = const Value.absent(),
            Value<String> contextId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ActionContextsCompanion(
            actionId: actionId,
            contextId: contextId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String actionId,
            required String contextId,
            Value<int> rowid = const Value.absent(),
          }) =>
              ActionContextsCompanion.insert(
            actionId: actionId,
            contextId: contextId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ActionContextsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({actionId = false, contextId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (actionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.actionId,
                    referencedTable:
                        $$ActionContextsTableReferences._actionIdTable(db),
                    referencedColumn:
                        $$ActionContextsTableReferences._actionIdTable(db).id,
                  ) as T;
                }
                if (contextId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.contextId,
                    referencedTable:
                        $$ActionContextsTableReferences._contextIdTable(db),
                    referencedColumn:
                        $$ActionContextsTableReferences._contextIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ActionContextsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ActionContextsTable,
    ActionContext,
    $$ActionContextsTableFilterComposer,
    $$ActionContextsTableOrderingComposer,
    $$ActionContextsTableAnnotationComposer,
    $$ActionContextsTableCreateCompanionBuilder,
    $$ActionContextsTableUpdateCompanionBuilder,
    (ActionContext, $$ActionContextsTableReferences),
    ActionContext,
    PrefetchHooks Function({bool actionId, bool contextId})>;
typedef $$RecurringActionsTableCreateCompanionBuilder
    = RecurringActionsCompanion Function({
  required String id,
  required String title,
  Value<String?> description,
  required RecurrenceType type,
  Value<int> interval,
  Value<int> totalCount,
  Value<int> currentCount,
  required DateTime nextRunDate,
  Value<int> energyLevel,
  Value<int> duration,
  Value<int> advanceDays,
  Value<bool> skipHolidays,
  Value<List<String>> contextIds,
  Value<String?> rev,
  Value<DateTime?> updatedAt,
  Value<bool> isDeleted,
  Value<int> rowid,
});
typedef $$RecurringActionsTableUpdateCompanionBuilder
    = RecurringActionsCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String?> description,
  Value<RecurrenceType> type,
  Value<int> interval,
  Value<int> totalCount,
  Value<int> currentCount,
  Value<DateTime> nextRunDate,
  Value<int> energyLevel,
  Value<int> duration,
  Value<int> advanceDays,
  Value<bool> skipHolidays,
  Value<List<String>> contextIds,
  Value<String?> rev,
  Value<DateTime?> updatedAt,
  Value<bool> isDeleted,
  Value<int> rowid,
});

class $$RecurringActionsTableFilterComposer
    extends Composer<_$AppDatabase, $RecurringActionsTable> {
  $$RecurringActionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<RecurrenceType, RecurrenceType, int>
      get type => $composableBuilder(
          column: $table.type,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get interval => $composableBuilder(
      column: $table.interval, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalCount => $composableBuilder(
      column: $table.totalCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentCount => $composableBuilder(
      column: $table.currentCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get nextRunDate => $composableBuilder(
      column: $table.nextRunDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get energyLevel => $composableBuilder(
      column: $table.energyLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get advanceDays => $composableBuilder(
      column: $table.advanceDays, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get skipHolidays => $composableBuilder(
      column: $table.skipHolidays, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
      get contextIds => $composableBuilder(
          column: $table.contextIds,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get rev => $composableBuilder(
      column: $table.rev, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));
}

class $$RecurringActionsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecurringActionsTable> {
  $$RecurringActionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get interval => $composableBuilder(
      column: $table.interval, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalCount => $composableBuilder(
      column: $table.totalCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentCount => $composableBuilder(
      column: $table.currentCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get nextRunDate => $composableBuilder(
      column: $table.nextRunDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get energyLevel => $composableBuilder(
      column: $table.energyLevel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get advanceDays => $composableBuilder(
      column: $table.advanceDays, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get skipHolidays => $composableBuilder(
      column: $table.skipHolidays,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contextIds => $composableBuilder(
      column: $table.contextIds, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rev => $composableBuilder(
      column: $table.rev, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));
}

class $$RecurringActionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecurringActionsTable> {
  $$RecurringActionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RecurrenceType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get interval =>
      $composableBuilder(column: $table.interval, builder: (column) => column);

  GeneratedColumn<int> get totalCount => $composableBuilder(
      column: $table.totalCount, builder: (column) => column);

  GeneratedColumn<int> get currentCount => $composableBuilder(
      column: $table.currentCount, builder: (column) => column);

  GeneratedColumn<DateTime> get nextRunDate => $composableBuilder(
      column: $table.nextRunDate, builder: (column) => column);

  GeneratedColumn<int> get energyLevel => $composableBuilder(
      column: $table.energyLevel, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<int> get advanceDays => $composableBuilder(
      column: $table.advanceDays, builder: (column) => column);

  GeneratedColumn<bool> get skipHolidays => $composableBuilder(
      column: $table.skipHolidays, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get contextIds =>
      $composableBuilder(
          column: $table.contextIds, builder: (column) => column);

  GeneratedColumn<String> get rev =>
      $composableBuilder(column: $table.rev, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);
}

class $$RecurringActionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RecurringActionsTable,
    RecurringAction,
    $$RecurringActionsTableFilterComposer,
    $$RecurringActionsTableOrderingComposer,
    $$RecurringActionsTableAnnotationComposer,
    $$RecurringActionsTableCreateCompanionBuilder,
    $$RecurringActionsTableUpdateCompanionBuilder,
    (
      RecurringAction,
      BaseReferences<_$AppDatabase, $RecurringActionsTable, RecurringAction>
    ),
    RecurringAction,
    PrefetchHooks Function()> {
  $$RecurringActionsTableTableManager(
      _$AppDatabase db, $RecurringActionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurringActionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecurringActionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecurringActionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<RecurrenceType> type = const Value.absent(),
            Value<int> interval = const Value.absent(),
            Value<int> totalCount = const Value.absent(),
            Value<int> currentCount = const Value.absent(),
            Value<DateTime> nextRunDate = const Value.absent(),
            Value<int> energyLevel = const Value.absent(),
            Value<int> duration = const Value.absent(),
            Value<int> advanceDays = const Value.absent(),
            Value<bool> skipHolidays = const Value.absent(),
            Value<List<String>> contextIds = const Value.absent(),
            Value<String?> rev = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecurringActionsCompanion(
            id: id,
            title: title,
            description: description,
            type: type,
            interval: interval,
            totalCount: totalCount,
            currentCount: currentCount,
            nextRunDate: nextRunDate,
            energyLevel: energyLevel,
            duration: duration,
            advanceDays: advanceDays,
            skipHolidays: skipHolidays,
            contextIds: contextIds,
            rev: rev,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            Value<String?> description = const Value.absent(),
            required RecurrenceType type,
            Value<int> interval = const Value.absent(),
            Value<int> totalCount = const Value.absent(),
            Value<int> currentCount = const Value.absent(),
            required DateTime nextRunDate,
            Value<int> energyLevel = const Value.absent(),
            Value<int> duration = const Value.absent(),
            Value<int> advanceDays = const Value.absent(),
            Value<bool> skipHolidays = const Value.absent(),
            Value<List<String>> contextIds = const Value.absent(),
            Value<String?> rev = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecurringActionsCompanion.insert(
            id: id,
            title: title,
            description: description,
            type: type,
            interval: interval,
            totalCount: totalCount,
            currentCount: currentCount,
            nextRunDate: nextRunDate,
            energyLevel: energyLevel,
            duration: duration,
            advanceDays: advanceDays,
            skipHolidays: skipHolidays,
            contextIds: contextIds,
            rev: rev,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RecurringActionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RecurringActionsTable,
    RecurringAction,
    $$RecurringActionsTableFilterComposer,
    $$RecurringActionsTableOrderingComposer,
    $$RecurringActionsTableAnnotationComposer,
    $$RecurringActionsTableCreateCompanionBuilder,
    $$RecurringActionsTableUpdateCompanionBuilder,
    (
      RecurringAction,
      BaseReferences<_$AppDatabase, $RecurringActionsTable, RecurringAction>
    ),
    RecurringAction,
    PrefetchHooks Function()>;
typedef $$ScheduledActionsTableCreateCompanionBuilder
    = ScheduledActionsCompanion Function({
  required String id,
  required String title,
  Value<String?> description,
  required DateTime startDate,
  Value<int> energyLevel,
  Value<int> duration,
  Value<int> advanceDays,
  Value<bool> skipHolidays,
  Value<bool> isCreated,
  Value<List<String>> contextIds,
  Value<String?> rev,
  Value<DateTime?> updatedAt,
  Value<bool> isDeleted,
  Value<int> rowid,
});
typedef $$ScheduledActionsTableUpdateCompanionBuilder
    = ScheduledActionsCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String?> description,
  Value<DateTime> startDate,
  Value<int> energyLevel,
  Value<int> duration,
  Value<int> advanceDays,
  Value<bool> skipHolidays,
  Value<bool> isCreated,
  Value<List<String>> contextIds,
  Value<String?> rev,
  Value<DateTime?> updatedAt,
  Value<bool> isDeleted,
  Value<int> rowid,
});

class $$ScheduledActionsTableFilterComposer
    extends Composer<_$AppDatabase, $ScheduledActionsTable> {
  $$ScheduledActionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get energyLevel => $composableBuilder(
      column: $table.energyLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get advanceDays => $composableBuilder(
      column: $table.advanceDays, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get skipHolidays => $composableBuilder(
      column: $table.skipHolidays, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCreated => $composableBuilder(
      column: $table.isCreated, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
      get contextIds => $composableBuilder(
          column: $table.contextIds,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get rev => $composableBuilder(
      column: $table.rev, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));
}

class $$ScheduledActionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScheduledActionsTable> {
  $$ScheduledActionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get energyLevel => $composableBuilder(
      column: $table.energyLevel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get advanceDays => $composableBuilder(
      column: $table.advanceDays, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get skipHolidays => $composableBuilder(
      column: $table.skipHolidays,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCreated => $composableBuilder(
      column: $table.isCreated, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contextIds => $composableBuilder(
      column: $table.contextIds, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rev => $composableBuilder(
      column: $table.rev, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));
}

class $$ScheduledActionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScheduledActionsTable> {
  $$ScheduledActionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<int> get energyLevel => $composableBuilder(
      column: $table.energyLevel, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<int> get advanceDays => $composableBuilder(
      column: $table.advanceDays, builder: (column) => column);

  GeneratedColumn<bool> get skipHolidays => $composableBuilder(
      column: $table.skipHolidays, builder: (column) => column);

  GeneratedColumn<bool> get isCreated =>
      $composableBuilder(column: $table.isCreated, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get contextIds =>
      $composableBuilder(
          column: $table.contextIds, builder: (column) => column);

  GeneratedColumn<String> get rev =>
      $composableBuilder(column: $table.rev, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);
}

class $$ScheduledActionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ScheduledActionsTable,
    ScheduledAction,
    $$ScheduledActionsTableFilterComposer,
    $$ScheduledActionsTableOrderingComposer,
    $$ScheduledActionsTableAnnotationComposer,
    $$ScheduledActionsTableCreateCompanionBuilder,
    $$ScheduledActionsTableUpdateCompanionBuilder,
    (
      ScheduledAction,
      BaseReferences<_$AppDatabase, $ScheduledActionsTable, ScheduledAction>
    ),
    ScheduledAction,
    PrefetchHooks Function()> {
  $$ScheduledActionsTableTableManager(
      _$AppDatabase db, $ScheduledActionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScheduledActionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScheduledActionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScheduledActionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<DateTime> startDate = const Value.absent(),
            Value<int> energyLevel = const Value.absent(),
            Value<int> duration = const Value.absent(),
            Value<int> advanceDays = const Value.absent(),
            Value<bool> skipHolidays = const Value.absent(),
            Value<bool> isCreated = const Value.absent(),
            Value<List<String>> contextIds = const Value.absent(),
            Value<String?> rev = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ScheduledActionsCompanion(
            id: id,
            title: title,
            description: description,
            startDate: startDate,
            energyLevel: energyLevel,
            duration: duration,
            advanceDays: advanceDays,
            skipHolidays: skipHolidays,
            isCreated: isCreated,
            contextIds: contextIds,
            rev: rev,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            Value<String?> description = const Value.absent(),
            required DateTime startDate,
            Value<int> energyLevel = const Value.absent(),
            Value<int> duration = const Value.absent(),
            Value<int> advanceDays = const Value.absent(),
            Value<bool> skipHolidays = const Value.absent(),
            Value<bool> isCreated = const Value.absent(),
            Value<List<String>> contextIds = const Value.absent(),
            Value<String?> rev = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ScheduledActionsCompanion.insert(
            id: id,
            title: title,
            description: description,
            startDate: startDate,
            energyLevel: energyLevel,
            duration: duration,
            advanceDays: advanceDays,
            skipHolidays: skipHolidays,
            isCreated: isCreated,
            contextIds: contextIds,
            rev: rev,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ScheduledActionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ScheduledActionsTable,
    ScheduledAction,
    $$ScheduledActionsTableFilterComposer,
    $$ScheduledActionsTableOrderingComposer,
    $$ScheduledActionsTableAnnotationComposer,
    $$ScheduledActionsTableCreateCompanionBuilder,
    $$ScheduledActionsTableUpdateCompanionBuilder,
    (
      ScheduledAction,
      BaseReferences<_$AppDatabase, $ScheduledActionsTable, ScheduledAction>
    ),
    ScheduledAction,
    PrefetchHooks Function()>;
typedef $$SyncConfigsTableCreateCompanionBuilder = SyncConfigsCompanion
    Function({
  Value<int> id,
  Value<String> url,
  Value<String> username,
  Value<String> password,
  Value<String> dbName,
  Value<bool> isEnabled,
  Value<String?> lastSeq,
  Value<String> dbType,
});
typedef $$SyncConfigsTableUpdateCompanionBuilder = SyncConfigsCompanion
    Function({
  Value<int> id,
  Value<String> url,
  Value<String> username,
  Value<String> password,
  Value<String> dbName,
  Value<bool> isEnabled,
  Value<String?> lastSeq,
  Value<String> dbType,
});

class $$SyncConfigsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncConfigsTable> {
  $$SyncConfigsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get password => $composableBuilder(
      column: $table.password, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dbName => $composableBuilder(
      column: $table.dbName, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isEnabled => $composableBuilder(
      column: $table.isEnabled, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastSeq => $composableBuilder(
      column: $table.lastSeq, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dbType => $composableBuilder(
      column: $table.dbType, builder: (column) => ColumnFilters(column));
}

class $$SyncConfigsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncConfigsTable> {
  $$SyncConfigsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get password => $composableBuilder(
      column: $table.password, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dbName => $composableBuilder(
      column: $table.dbName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
      column: $table.isEnabled, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastSeq => $composableBuilder(
      column: $table.lastSeq, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dbType => $composableBuilder(
      column: $table.dbType, builder: (column) => ColumnOrderings(column));
}

class $$SyncConfigsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncConfigsTable> {
  $$SyncConfigsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get password =>
      $composableBuilder(column: $table.password, builder: (column) => column);

  GeneratedColumn<String> get dbName =>
      $composableBuilder(column: $table.dbName, builder: (column) => column);

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumn<String> get lastSeq =>
      $composableBuilder(column: $table.lastSeq, builder: (column) => column);

  GeneratedColumn<String> get dbType =>
      $composableBuilder(column: $table.dbType, builder: (column) => column);
}

class $$SyncConfigsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncConfigsTable,
    SyncConfigData,
    $$SyncConfigsTableFilterComposer,
    $$SyncConfigsTableOrderingComposer,
    $$SyncConfigsTableAnnotationComposer,
    $$SyncConfigsTableCreateCompanionBuilder,
    $$SyncConfigsTableUpdateCompanionBuilder,
    (
      SyncConfigData,
      BaseReferences<_$AppDatabase, $SyncConfigsTable, SyncConfigData>
    ),
    SyncConfigData,
    PrefetchHooks Function()> {
  $$SyncConfigsTableTableManager(_$AppDatabase db, $SyncConfigsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncConfigsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncConfigsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncConfigsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> url = const Value.absent(),
            Value<String> username = const Value.absent(),
            Value<String> password = const Value.absent(),
            Value<String> dbName = const Value.absent(),
            Value<bool> isEnabled = const Value.absent(),
            Value<String?> lastSeq = const Value.absent(),
            Value<String> dbType = const Value.absent(),
          }) =>
              SyncConfigsCompanion(
            id: id,
            url: url,
            username: username,
            password: password,
            dbName: dbName,
            isEnabled: isEnabled,
            lastSeq: lastSeq,
            dbType: dbType,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> url = const Value.absent(),
            Value<String> username = const Value.absent(),
            Value<String> password = const Value.absent(),
            Value<String> dbName = const Value.absent(),
            Value<bool> isEnabled = const Value.absent(),
            Value<String?> lastSeq = const Value.absent(),
            Value<String> dbType = const Value.absent(),
          }) =>
              SyncConfigsCompanion.insert(
            id: id,
            url: url,
            username: username,
            password: password,
            dbName: dbName,
            isEnabled: isEnabled,
            lastSeq: lastSeq,
            dbType: dbType,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncConfigsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncConfigsTable,
    SyncConfigData,
    $$SyncConfigsTableFilterComposer,
    $$SyncConfigsTableOrderingComposer,
    $$SyncConfigsTableAnnotationComposer,
    $$SyncConfigsTableCreateCompanionBuilder,
    $$SyncConfigsTableUpdateCompanionBuilder,
    (
      SyncConfigData,
      BaseReferences<_$AppDatabase, $SyncConfigsTable, SyncConfigData>
    ),
    SyncConfigData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ActionsTableTableManager get actions =>
      $$ActionsTableTableManager(_db, _db.actions);
  $$ContextsTableTableManager get contexts =>
      $$ContextsTableTableManager(_db, _db.contexts);
  $$ActionContextsTableTableManager get actionContexts =>
      $$ActionContextsTableTableManager(_db, _db.actionContexts);
  $$RecurringActionsTableTableManager get recurringActions =>
      $$RecurringActionsTableTableManager(_db, _db.recurringActions);
  $$ScheduledActionsTableTableManager get scheduledActions =>
      $$ScheduledActionsTableTableManager(_db, _db.scheduledActions);
  $$SyncConfigsTableTableManager get syncConfigs =>
      $$SyncConfigsTableTableManager(_db, _db.syncConfigs);
}
