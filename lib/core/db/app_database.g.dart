// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PrayersTable extends Prayers with TableInfo<$PrayersTable, PrayerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrayersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _personMeta = const VerificationMeta('person');
  @override
  late final GeneratedColumn<String> person = GeneratedColumn<String>(
    'person',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 0,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _requestMeta = const VerificationMeta(
    'request',
  );
  @override
  late final GeneratedColumn<String> request = GeneratedColumn<String>(
    'request',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isAnsweredMeta = const VerificationMeta(
    'isAnswered',
  );
  @override
  late final GeneratedColumn<bool> isAnswered = GeneratedColumn<bool>(
    'is_answered',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_answered" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _answeredAtMeta = const VerificationMeta(
    'answeredAt',
  );
  @override
  late final GeneratedColumn<DateTime> answeredAt = GeneratedColumn<DateTime>(
    'answered_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _answeredNoteMeta = const VerificationMeta(
    'answeredNote',
  );
  @override
  late final GeneratedColumn<String> answeredNote = GeneratedColumn<String>(
    'answered_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    person,
    request,
    isAnswered,
    answeredAt,
    answeredNote,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prayers';
  @override
  VerificationContext validateIntegrity(
    Insertable<PrayerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('person')) {
      context.handle(
        _personMeta,
        person.isAcceptableOrUnknown(data['person']!, _personMeta),
      );
    }
    if (data.containsKey('request')) {
      context.handle(
        _requestMeta,
        request.isAcceptableOrUnknown(data['request']!, _requestMeta),
      );
    } else if (isInserting) {
      context.missing(_requestMeta);
    }
    if (data.containsKey('is_answered')) {
      context.handle(
        _isAnsweredMeta,
        isAnswered.isAcceptableOrUnknown(data['is_answered']!, _isAnsweredMeta),
      );
    }
    if (data.containsKey('answered_at')) {
      context.handle(
        _answeredAtMeta,
        answeredAt.isAcceptableOrUnknown(data['answered_at']!, _answeredAtMeta),
      );
    }
    if (data.containsKey('answered_note')) {
      context.handle(
        _answeredNoteMeta,
        answeredNote.isAcceptableOrUnknown(
          data['answered_note']!,
          _answeredNoteMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PrayerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrayerRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      person: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}person'],
      )!,
      request: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}request'],
      )!,
      isAnswered: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_answered'],
      )!,
      answeredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}answered_at'],
      ),
      answeredNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answered_note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PrayersTable createAlias(String alias) {
    return $PrayersTable(attachedDatabase, alias);
  }
}

class PrayerRow extends DataClass implements Insertable<PrayerRow> {
  final int id;
  final String name;

  /// Who this prayer is for (empty = unassigned).
  final String person;
  final String request;
  final bool isAnswered;
  final DateTime? answeredAt;
  final String? answeredNote;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PrayerRow({
    required this.id,
    required this.name,
    required this.person,
    required this.request,
    required this.isAnswered,
    this.answeredAt,
    this.answeredNote,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['person'] = Variable<String>(person);
    map['request'] = Variable<String>(request);
    map['is_answered'] = Variable<bool>(isAnswered);
    if (!nullToAbsent || answeredAt != null) {
      map['answered_at'] = Variable<DateTime>(answeredAt);
    }
    if (!nullToAbsent || answeredNote != null) {
      map['answered_note'] = Variable<String>(answeredNote);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PrayersCompanion toCompanion(bool nullToAbsent) {
    return PrayersCompanion(
      id: Value(id),
      name: Value(name),
      person: Value(person),
      request: Value(request),
      isAnswered: Value(isAnswered),
      answeredAt: answeredAt == null && nullToAbsent
          ? const Value.absent()
          : Value(answeredAt),
      answeredNote: answeredNote == null && nullToAbsent
          ? const Value.absent()
          : Value(answeredNote),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PrayerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrayerRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      person: serializer.fromJson<String>(json['person']),
      request: serializer.fromJson<String>(json['request']),
      isAnswered: serializer.fromJson<bool>(json['isAnswered']),
      answeredAt: serializer.fromJson<DateTime?>(json['answeredAt']),
      answeredNote: serializer.fromJson<String?>(json['answeredNote']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'person': serializer.toJson<String>(person),
      'request': serializer.toJson<String>(request),
      'isAnswered': serializer.toJson<bool>(isAnswered),
      'answeredAt': serializer.toJson<DateTime?>(answeredAt),
      'answeredNote': serializer.toJson<String?>(answeredNote),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PrayerRow copyWith({
    int? id,
    String? name,
    String? person,
    String? request,
    bool? isAnswered,
    Value<DateTime?> answeredAt = const Value.absent(),
    Value<String?> answeredNote = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PrayerRow(
    id: id ?? this.id,
    name: name ?? this.name,
    person: person ?? this.person,
    request: request ?? this.request,
    isAnswered: isAnswered ?? this.isAnswered,
    answeredAt: answeredAt.present ? answeredAt.value : this.answeredAt,
    answeredNote: answeredNote.present ? answeredNote.value : this.answeredNote,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PrayerRow copyWithCompanion(PrayersCompanion data) {
    return PrayerRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      person: data.person.present ? data.person.value : this.person,
      request: data.request.present ? data.request.value : this.request,
      isAnswered: data.isAnswered.present
          ? data.isAnswered.value
          : this.isAnswered,
      answeredAt: data.answeredAt.present
          ? data.answeredAt.value
          : this.answeredAt,
      answeredNote: data.answeredNote.present
          ? data.answeredNote.value
          : this.answeredNote,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrayerRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('person: $person, ')
          ..write('request: $request, ')
          ..write('isAnswered: $isAnswered, ')
          ..write('answeredAt: $answeredAt, ')
          ..write('answeredNote: $answeredNote, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    person,
    request,
    isAnswered,
    answeredAt,
    answeredNote,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrayerRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.person == this.person &&
          other.request == this.request &&
          other.isAnswered == this.isAnswered &&
          other.answeredAt == this.answeredAt &&
          other.answeredNote == this.answeredNote &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PrayersCompanion extends UpdateCompanion<PrayerRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> person;
  final Value<String> request;
  final Value<bool> isAnswered;
  final Value<DateTime?> answeredAt;
  final Value<String?> answeredNote;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const PrayersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.person = const Value.absent(),
    this.request = const Value.absent(),
    this.isAnswered = const Value.absent(),
    this.answeredAt = const Value.absent(),
    this.answeredNote = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PrayersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.person = const Value.absent(),
    required String request,
    this.isAnswered = const Value.absent(),
    this.answeredAt = const Value.absent(),
    this.answeredNote = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : name = Value(name),
       request = Value(request),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PrayerRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? person,
    Expression<String>? request,
    Expression<bool>? isAnswered,
    Expression<DateTime>? answeredAt,
    Expression<String>? answeredNote,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (person != null) 'person': person,
      if (request != null) 'request': request,
      if (isAnswered != null) 'is_answered': isAnswered,
      if (answeredAt != null) 'answered_at': answeredAt,
      if (answeredNote != null) 'answered_note': answeredNote,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PrayersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? person,
    Value<String>? request,
    Value<bool>? isAnswered,
    Value<DateTime?>? answeredAt,
    Value<String?>? answeredNote,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return PrayersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      person: person ?? this.person,
      request: request ?? this.request,
      isAnswered: isAnswered ?? this.isAnswered,
      answeredAt: answeredAt ?? this.answeredAt,
      answeredNote: answeredNote ?? this.answeredNote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (person.present) {
      map['person'] = Variable<String>(person.value);
    }
    if (request.present) {
      map['request'] = Variable<String>(request.value);
    }
    if (isAnswered.present) {
      map['is_answered'] = Variable<bool>(isAnswered.value);
    }
    if (answeredAt.present) {
      map['answered_at'] = Variable<DateTime>(answeredAt.value);
    }
    if (answeredNote.present) {
      map['answered_note'] = Variable<String>(answeredNote.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrayersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('person: $person, ')
          ..write('request: $request, ')
          ..write('isAnswered: $isAnswered, ')
          ..write('answeredAt: $answeredAt, ')
          ..write('answeredNote: $answeredNote, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 40,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, label];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  final int id;
  final String label;
  const Tag({required this.id, required this.label});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['label'] = Variable<String>(label);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(id: Value(id), label: Value(label));
  }

  factory Tag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<int>(json['id']),
      label: serializer.fromJson<String>(json['label']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'label': serializer.toJson<String>(label),
    };
  }

  Tag copyWith({int? id, String? label}) =>
      Tag(id: id ?? this.id, label: label ?? this.label);
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('label: $label')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, label);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag && other.id == this.id && other.label == this.label);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<int> id;
  final Value<String> label;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
  });
  TagsCompanion.insert({this.id = const Value.absent(), required String label})
    : label = Value(label);
  static Insertable<Tag> custom({
    Expression<int>? id,
    Expression<String>? label,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
    });
  }

  TagsCompanion copyWith({Value<int>? id, Value<String>? label}) {
    return TagsCompanion(id: id ?? this.id, label: label ?? this.label);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('label: $label')
          ..write(')'))
        .toString();
  }
}

class $PrayerTagsTable extends PrayerTags
    with TableInfo<$PrayerTagsTable, PrayerTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrayerTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _prayerIdMeta = const VerificationMeta(
    'prayerId',
  );
  @override
  late final GeneratedColumn<int> prayerId = GeneratedColumn<int>(
    'prayer_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES prayers (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<int> tagId = GeneratedColumn<int>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tags (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [prayerId, tagId, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prayer_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<PrayerTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('prayer_id')) {
      context.handle(
        _prayerIdMeta,
        prayerId.isAcceptableOrUnknown(data['prayer_id']!, _prayerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_prayerIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {prayerId, tagId};
  @override
  PrayerTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrayerTag(
      prayerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prayer_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tag_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $PrayerTagsTable createAlias(String alias) {
    return $PrayerTagsTable(attachedDatabase, alias);
  }
}

class PrayerTag extends DataClass implements Insertable<PrayerTag> {
  final int prayerId;
  final int tagId;
  final int position;
  const PrayerTag({
    required this.prayerId,
    required this.tagId,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['prayer_id'] = Variable<int>(prayerId);
    map['tag_id'] = Variable<int>(tagId);
    map['position'] = Variable<int>(position);
    return map;
  }

  PrayerTagsCompanion toCompanion(bool nullToAbsent) {
    return PrayerTagsCompanion(
      prayerId: Value(prayerId),
      tagId: Value(tagId),
      position: Value(position),
    );
  }

  factory PrayerTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrayerTag(
      prayerId: serializer.fromJson<int>(json['prayerId']),
      tagId: serializer.fromJson<int>(json['tagId']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'prayerId': serializer.toJson<int>(prayerId),
      'tagId': serializer.toJson<int>(tagId),
      'position': serializer.toJson<int>(position),
    };
  }

  PrayerTag copyWith({int? prayerId, int? tagId, int? position}) => PrayerTag(
    prayerId: prayerId ?? this.prayerId,
    tagId: tagId ?? this.tagId,
    position: position ?? this.position,
  );
  PrayerTag copyWithCompanion(PrayerTagsCompanion data) {
    return PrayerTag(
      prayerId: data.prayerId.present ? data.prayerId.value : this.prayerId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrayerTag(')
          ..write('prayerId: $prayerId, ')
          ..write('tagId: $tagId, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(prayerId, tagId, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrayerTag &&
          other.prayerId == this.prayerId &&
          other.tagId == this.tagId &&
          other.position == this.position);
}

class PrayerTagsCompanion extends UpdateCompanion<PrayerTag> {
  final Value<int> prayerId;
  final Value<int> tagId;
  final Value<int> position;
  final Value<int> rowid;
  const PrayerTagsCompanion({
    this.prayerId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrayerTagsCompanion.insert({
    required int prayerId,
    required int tagId,
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : prayerId = Value(prayerId),
       tagId = Value(tagId);
  static Insertable<PrayerTag> custom({
    Expression<int>? prayerId,
    Expression<int>? tagId,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (prayerId != null) 'prayer_id': prayerId,
      if (tagId != null) 'tag_id': tagId,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrayerTagsCompanion copyWith({
    Value<int>? prayerId,
    Value<int>? tagId,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return PrayerTagsCompanion(
      prayerId: prayerId ?? this.prayerId,
      tagId: tagId ?? this.tagId,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (prayerId.present) {
      map['prayer_id'] = Variable<int>(prayerId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<int>(tagId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrayerTagsCompanion(')
          ..write('prayerId: $prayerId, ')
          ..write('tagId: $tagId, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PrayerVersesTable extends PrayerVerses
    with TableInfo<$PrayerVersesTable, PrayerVerse> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrayerVersesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _prayerIdMeta = const VerificationMeta(
    'prayerId',
  );
  @override
  late final GeneratedColumn<int> prayerId = GeneratedColumn<int>(
    'prayer_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES prayers (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _verseIdMeta = const VerificationMeta(
    'verseId',
  );
  @override
  late final GeneratedColumn<String> verseId = GeneratedColumn<String>(
    'verse_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _selectedAtMeta = const VerificationMeta(
    'selectedAt',
  );
  @override
  late final GeneratedColumn<DateTime> selectedAt = GeneratedColumn<DateTime>(
    'selected_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [prayerId, verseId, selectedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prayer_verses';
  @override
  VerificationContext validateIntegrity(
    Insertable<PrayerVerse> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('prayer_id')) {
      context.handle(
        _prayerIdMeta,
        prayerId.isAcceptableOrUnknown(data['prayer_id']!, _prayerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_prayerIdMeta);
    }
    if (data.containsKey('verse_id')) {
      context.handle(
        _verseIdMeta,
        verseId.isAcceptableOrUnknown(data['verse_id']!, _verseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_verseIdMeta);
    }
    if (data.containsKey('selected_at')) {
      context.handle(
        _selectedAtMeta,
        selectedAt.isAcceptableOrUnknown(data['selected_at']!, _selectedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_selectedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {prayerId, verseId};
  @override
  PrayerVerse map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrayerVerse(
      prayerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prayer_id'],
      )!,
      verseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verse_id'],
      )!,
      selectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}selected_at'],
      )!,
    );
  }

  @override
  $PrayerVersesTable createAlias(String alias) {
    return $PrayerVersesTable(attachedDatabase, alias);
  }
}

class PrayerVerse extends DataClass implements Insertable<PrayerVerse> {
  final int prayerId;
  final String verseId;
  final DateTime selectedAt;
  const PrayerVerse({
    required this.prayerId,
    required this.verseId,
    required this.selectedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['prayer_id'] = Variable<int>(prayerId);
    map['verse_id'] = Variable<String>(verseId);
    map['selected_at'] = Variable<DateTime>(selectedAt);
    return map;
  }

  PrayerVersesCompanion toCompanion(bool nullToAbsent) {
    return PrayerVersesCompanion(
      prayerId: Value(prayerId),
      verseId: Value(verseId),
      selectedAt: Value(selectedAt),
    );
  }

  factory PrayerVerse.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrayerVerse(
      prayerId: serializer.fromJson<int>(json['prayerId']),
      verseId: serializer.fromJson<String>(json['verseId']),
      selectedAt: serializer.fromJson<DateTime>(json['selectedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'prayerId': serializer.toJson<int>(prayerId),
      'verseId': serializer.toJson<String>(verseId),
      'selectedAt': serializer.toJson<DateTime>(selectedAt),
    };
  }

  PrayerVerse copyWith({
    int? prayerId,
    String? verseId,
    DateTime? selectedAt,
  }) => PrayerVerse(
    prayerId: prayerId ?? this.prayerId,
    verseId: verseId ?? this.verseId,
    selectedAt: selectedAt ?? this.selectedAt,
  );
  PrayerVerse copyWithCompanion(PrayerVersesCompanion data) {
    return PrayerVerse(
      prayerId: data.prayerId.present ? data.prayerId.value : this.prayerId,
      verseId: data.verseId.present ? data.verseId.value : this.verseId,
      selectedAt: data.selectedAt.present
          ? data.selectedAt.value
          : this.selectedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrayerVerse(')
          ..write('prayerId: $prayerId, ')
          ..write('verseId: $verseId, ')
          ..write('selectedAt: $selectedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(prayerId, verseId, selectedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrayerVerse &&
          other.prayerId == this.prayerId &&
          other.verseId == this.verseId &&
          other.selectedAt == this.selectedAt);
}

class PrayerVersesCompanion extends UpdateCompanion<PrayerVerse> {
  final Value<int> prayerId;
  final Value<String> verseId;
  final Value<DateTime> selectedAt;
  final Value<int> rowid;
  const PrayerVersesCompanion({
    this.prayerId = const Value.absent(),
    this.verseId = const Value.absent(),
    this.selectedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrayerVersesCompanion.insert({
    required int prayerId,
    required String verseId,
    required DateTime selectedAt,
    this.rowid = const Value.absent(),
  }) : prayerId = Value(prayerId),
       verseId = Value(verseId),
       selectedAt = Value(selectedAt);
  static Insertable<PrayerVerse> custom({
    Expression<int>? prayerId,
    Expression<String>? verseId,
    Expression<DateTime>? selectedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (prayerId != null) 'prayer_id': prayerId,
      if (verseId != null) 'verse_id': verseId,
      if (selectedAt != null) 'selected_at': selectedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrayerVersesCompanion copyWith({
    Value<int>? prayerId,
    Value<String>? verseId,
    Value<DateTime>? selectedAt,
    Value<int>? rowid,
  }) {
    return PrayerVersesCompanion(
      prayerId: prayerId ?? this.prayerId,
      verseId: verseId ?? this.verseId,
      selectedAt: selectedAt ?? this.selectedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (prayerId.present) {
      map['prayer_id'] = Variable<int>(prayerId.value);
    }
    if (verseId.present) {
      map['verse_id'] = Variable<String>(verseId.value);
    }
    if (selectedAt.present) {
      map['selected_at'] = Variable<DateTime>(selectedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrayerVersesCompanion(')
          ..write('prayerId: $prayerId, ')
          ..write('verseId: $verseId, ')
          ..write('selectedAt: $selectedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PrayerEventsTable extends PrayerEvents
    with TableInfo<$PrayerEventsTable, PrayerEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrayerEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _prayerIdMeta = const VerificationMeta(
    'prayerId',
  );
  @override
  late final GeneratedColumn<int> prayerId = GeneratedColumn<int>(
    'prayer_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES prayers (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, prayerId, type, at];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prayer_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<PrayerEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('prayer_id')) {
      context.handle(
        _prayerIdMeta,
        prayerId.isAcceptableOrUnknown(data['prayer_id']!, _prayerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_prayerIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PrayerEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrayerEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      prayerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prayer_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
    );
  }

  @override
  $PrayerEventsTable createAlias(String alias) {
    return $PrayerEventsTable(attachedDatabase, alias);
  }
}

class PrayerEvent extends DataClass implements Insertable<PrayerEvent> {
  final int id;
  final int prayerId;
  final String type;
  final DateTime at;
  const PrayerEvent({
    required this.id,
    required this.prayerId,
    required this.type,
    required this.at,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['prayer_id'] = Variable<int>(prayerId);
    map['type'] = Variable<String>(type);
    map['at'] = Variable<DateTime>(at);
    return map;
  }

  PrayerEventsCompanion toCompanion(bool nullToAbsent) {
    return PrayerEventsCompanion(
      id: Value(id),
      prayerId: Value(prayerId),
      type: Value(type),
      at: Value(at),
    );
  }

  factory PrayerEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrayerEvent(
      id: serializer.fromJson<int>(json['id']),
      prayerId: serializer.fromJson<int>(json['prayerId']),
      type: serializer.fromJson<String>(json['type']),
      at: serializer.fromJson<DateTime>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'prayerId': serializer.toJson<int>(prayerId),
      'type': serializer.toJson<String>(type),
      'at': serializer.toJson<DateTime>(at),
    };
  }

  PrayerEvent copyWith({int? id, int? prayerId, String? type, DateTime? at}) =>
      PrayerEvent(
        id: id ?? this.id,
        prayerId: prayerId ?? this.prayerId,
        type: type ?? this.type,
        at: at ?? this.at,
      );
  PrayerEvent copyWithCompanion(PrayerEventsCompanion data) {
    return PrayerEvent(
      id: data.id.present ? data.id.value : this.id,
      prayerId: data.prayerId.present ? data.prayerId.value : this.prayerId,
      type: data.type.present ? data.type.value : this.type,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrayerEvent(')
          ..write('id: $id, ')
          ..write('prayerId: $prayerId, ')
          ..write('type: $type, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, prayerId, type, at);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrayerEvent &&
          other.id == this.id &&
          other.prayerId == this.prayerId &&
          other.type == this.type &&
          other.at == this.at);
}

class PrayerEventsCompanion extends UpdateCompanion<PrayerEvent> {
  final Value<int> id;
  final Value<int> prayerId;
  final Value<String> type;
  final Value<DateTime> at;
  const PrayerEventsCompanion({
    this.id = const Value.absent(),
    this.prayerId = const Value.absent(),
    this.type = const Value.absent(),
    this.at = const Value.absent(),
  });
  PrayerEventsCompanion.insert({
    this.id = const Value.absent(),
    required int prayerId,
    required String type,
    required DateTime at,
  }) : prayerId = Value(prayerId),
       type = Value(type),
       at = Value(at);
  static Insertable<PrayerEvent> custom({
    Expression<int>? id,
    Expression<int>? prayerId,
    Expression<String>? type,
    Expression<DateTime>? at,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (prayerId != null) 'prayer_id': prayerId,
      if (type != null) 'type': type,
      if (at != null) 'at': at,
    });
  }

  PrayerEventsCompanion copyWith({
    Value<int>? id,
    Value<int>? prayerId,
    Value<String>? type,
    Value<DateTime>? at,
  }) {
    return PrayerEventsCompanion(
      id: id ?? this.id,
      prayerId: prayerId ?? this.prayerId,
      type: type ?? this.type,
      at: at ?? this.at,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (prayerId.present) {
      map['prayer_id'] = Variable<int>(prayerId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrayerEventsCompanion(')
          ..write('id: $id, ')
          ..write('prayerId: $prayerId, ')
          ..write('type: $type, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }
}

class $CustomVersesTable extends CustomVerses
    with TableInfo<$CustomVersesTable, CustomVerse> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomVersesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refMeta = const VerificationMeta('ref');
  @override
  late final GeneratedColumn<String> ref = GeneratedColumn<String>(
    'ref',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, ref, body, note, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_verses';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomVerse> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('ref')) {
      context.handle(
        _refMeta,
        ref.isAcceptableOrUnknown(data['ref']!, _refMeta),
      );
    } else if (isInserting) {
      context.missing(_refMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomVerse map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomVerse(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ref: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ref'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CustomVersesTable createAlias(String alias) {
    return $CustomVersesTable(attachedDatabase, alias);
  }
}

class CustomVerse extends DataClass implements Insertable<CustomVerse> {
  final String id;
  final String ref;

  /// Exact Scripture wording (named `body` so it does not shadow Drift's `text()`).
  final String body;
  final String? note;
  final DateTime createdAt;
  const CustomVerse({
    required this.id,
    required this.ref,
    required this.body,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['ref'] = Variable<String>(ref);
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CustomVersesCompanion toCompanion(bool nullToAbsent) {
    return CustomVersesCompanion(
      id: Value(id),
      ref: Value(ref),
      body: Value(body),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory CustomVerse.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomVerse(
      id: serializer.fromJson<String>(json['id']),
      ref: serializer.fromJson<String>(json['ref']),
      body: serializer.fromJson<String>(json['body']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ref': serializer.toJson<String>(ref),
      'body': serializer.toJson<String>(body),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CustomVerse copyWith({
    String? id,
    String? ref,
    String? body,
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
  }) => CustomVerse(
    id: id ?? this.id,
    ref: ref ?? this.ref,
    body: body ?? this.body,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  CustomVerse copyWithCompanion(CustomVersesCompanion data) {
    return CustomVerse(
      id: data.id.present ? data.id.value : this.id,
      ref: data.ref.present ? data.ref.value : this.ref,
      body: data.body.present ? data.body.value : this.body,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomVerse(')
          ..write('id: $id, ')
          ..write('ref: $ref, ')
          ..write('body: $body, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, ref, body, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomVerse &&
          other.id == this.id &&
          other.ref == this.ref &&
          other.body == this.body &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class CustomVersesCompanion extends UpdateCompanion<CustomVerse> {
  final Value<String> id;
  final Value<String> ref;
  final Value<String> body;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CustomVersesCompanion({
    this.id = const Value.absent(),
    this.ref = const Value.absent(),
    this.body = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomVersesCompanion.insert({
    required String id,
    required String ref,
    required String body,
    this.note = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ref = Value(ref),
       body = Value(body),
       createdAt = Value(createdAt);
  static Insertable<CustomVerse> custom({
    Expression<String>? id,
    Expression<String>? ref,
    Expression<String>? body,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ref != null) 'ref': ref,
      if (body != null) 'body': body,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomVersesCompanion copyWith({
    Value<String>? id,
    Value<String>? ref,
    Value<String>? body,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CustomVersesCompanion(
      id: id ?? this.id,
      ref: ref ?? this.ref,
      body: body ?? this.body,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ref.present) {
      map['ref'] = Variable<String>(ref.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomVersesCompanion(')
          ..write('id: $id, ')
          ..write('ref: $ref, ')
          ..write('body: $body, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PrayersTable prayers = $PrayersTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $PrayerTagsTable prayerTags = $PrayerTagsTable(this);
  late final $PrayerVersesTable prayerVerses = $PrayerVersesTable(this);
  late final $PrayerEventsTable prayerEvents = $PrayerEventsTable(this);
  late final $CustomVersesTable customVerses = $CustomVersesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    prayers,
    tags,
    prayerTags,
    prayerVerses,
    prayerEvents,
    customVerses,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'prayers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('prayer_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tags',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('prayer_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'prayers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('prayer_verses', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'prayers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('prayer_events', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$PrayersTableCreateCompanionBuilder = PrayersCompanion Function({
  Value<int> id,
  required String name,
  Value<String> person,
  required String request,
  Value<bool> isAnswered,
  Value<DateTime?> answeredAt,
  Value<String?> answeredNote,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$PrayersTableUpdateCompanionBuilder = PrayersCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> person,
  Value<String> request,
  Value<bool> isAnswered,
  Value<DateTime?> answeredAt,
  Value<String?> answeredNote,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$PrayersTableReferences
    extends BaseReferences<_$AppDatabase, $PrayersTable, PrayerRow> {
  $$PrayersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PrayerTagsTable, List<PrayerTag>>
  _prayerTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.prayerTags,
    aliasName: 'prayers__id__prayer_tags__prayer_id',
  );

  $$PrayerTagsTableProcessedTableManager get prayerTagsRefs {
    final manager = $$PrayerTagsTableTableManager(
      $_db,
      $_db.prayerTags,
    ).filter((f) => f.prayerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_prayerTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PrayerVersesTable, List<PrayerVerse>>
  _prayerVersesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.prayerVerses,
    aliasName: 'prayers__id__prayer_verses__prayer_id',
  );

  $$PrayerVersesTableProcessedTableManager get prayerVersesRefs {
    final manager = $$PrayerVersesTableTableManager(
      $_db,
      $_db.prayerVerses,
    ).filter((f) => f.prayerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_prayerVersesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PrayerEventsTable, List<PrayerEvent>>
  _prayerEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.prayerEvents,
    aliasName: 'prayers__id__prayer_events__prayer_id',
  );

  $$PrayerEventsTableProcessedTableManager get prayerEventsRefs {
    final manager = $$PrayerEventsTableTableManager(
      $_db,
      $_db.prayerEvents,
    ).filter((f) => f.prayerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_prayerEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PrayersTableFilterComposer
    extends Composer<_$AppDatabase, $PrayersTable> {
  $$PrayersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get person => $composableBuilder(
    column: $table.person,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get request => $composableBuilder(
    column: $table.request,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAnswered => $composableBuilder(
    column: $table.isAnswered,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answeredNote => $composableBuilder(
    column: $table.answeredNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> prayerTagsRefs(
    Expression<bool> Function($$PrayerTagsTableFilterComposer f) f,
  ) {
    final $$PrayerTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.prayerTags,
      getReferencedColumn: (t) => t.prayerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrayerTagsTableFilterComposer(
            $db: $db,
            $table: $db.prayerTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> prayerVersesRefs(
    Expression<bool> Function($$PrayerVersesTableFilterComposer f) f,
  ) {
    final $$PrayerVersesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.prayerVerses,
      getReferencedColumn: (t) => t.prayerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrayerVersesTableFilterComposer(
            $db: $db,
            $table: $db.prayerVerses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> prayerEventsRefs(
    Expression<bool> Function($$PrayerEventsTableFilterComposer f) f,
  ) {
    final $$PrayerEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.prayerEvents,
      getReferencedColumn: (t) => t.prayerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrayerEventsTableFilterComposer(
            $db: $db,
            $table: $db.prayerEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PrayersTableOrderingComposer
    extends Composer<_$AppDatabase, $PrayersTable> {
  $$PrayersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get person => $composableBuilder(
    column: $table.person,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get request => $composableBuilder(
    column: $table.request,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAnswered => $composableBuilder(
    column: $table.isAnswered,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answeredNote => $composableBuilder(
    column: $table.answeredNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PrayersTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrayersTable> {
  $$PrayersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get person =>
      $composableBuilder(column: $table.person, builder: (column) => column);

  GeneratedColumn<String> get request =>
      $composableBuilder(column: $table.request, builder: (column) => column);

  GeneratedColumn<bool> get isAnswered => $composableBuilder(
    column: $table.isAnswered,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get answeredNote => $composableBuilder(
    column: $table.answeredNote,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> prayerTagsRefs<T extends Object>(
    Expression<T> Function($$PrayerTagsTableAnnotationComposer a) f,
  ) {
    final $$PrayerTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.prayerTags,
      getReferencedColumn: (t) => t.prayerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrayerTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.prayerTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> prayerVersesRefs<T extends Object>(
    Expression<T> Function($$PrayerVersesTableAnnotationComposer a) f,
  ) {
    final $$PrayerVersesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.prayerVerses,
      getReferencedColumn: (t) => t.prayerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrayerVersesTableAnnotationComposer(
            $db: $db,
            $table: $db.prayerVerses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> prayerEventsRefs<T extends Object>(
    Expression<T> Function($$PrayerEventsTableAnnotationComposer a) f,
  ) {
    final $$PrayerEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.prayerEvents,
      getReferencedColumn: (t) => t.prayerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrayerEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.prayerEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PrayersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrayersTable,
          PrayerRow,
          $$PrayersTableFilterComposer,
          $$PrayersTableOrderingComposer,
          $$PrayersTableAnnotationComposer,
          $$PrayersTableCreateCompanionBuilder,
          $$PrayersTableUpdateCompanionBuilder,
          (PrayerRow, $$PrayersTableReferences),
          PrayerRow,
          PrefetchHooks Function({
            bool prayerTagsRefs,
            bool prayerVersesRefs,
            bool prayerEventsRefs,
          })
        > {
  $$PrayersTableTableManager(_$AppDatabase db, $PrayersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrayersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrayersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrayersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> person = const Value.absent(),
                Value<String> request = const Value.absent(),
                Value<bool> isAnswered = const Value.absent(),
                Value<DateTime?> answeredAt = const Value.absent(),
                Value<String?> answeredNote = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PrayersCompanion(
                id: id,
                name: name,
                person: person,
                request: request,
                isAnswered: isAnswered,
                answeredAt: answeredAt,
                answeredNote: answeredNote,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String> person = const Value.absent(),
                required String request,
                Value<bool> isAnswered = const Value.absent(),
                Value<DateTime?> answeredAt = const Value.absent(),
                Value<String?> answeredNote = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => PrayersCompanion.insert(
                id: id,
                name: name,
                person: person,
                request: request,
                isAnswered: isAnswered,
                answeredAt: answeredAt,
                answeredNote: answeredNote,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PrayersTable, PrayerRow>(table),
                  $$PrayersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                prayerTagsRefs = false,
                prayerVersesRefs = false,
                prayerEventsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (prayerTagsRefs) db.prayerTags,
                    if (prayerVersesRefs) db.prayerVerses,
                    if (prayerEventsRefs) db.prayerEvents,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (prayerTagsRefs)
                        await $_getPrefetchedData<
                          PrayerRow,
                          $PrayersTable,
                          PrayerTag
                        >(
                          currentTable: table,
                          referencedTable: $$PrayersTableReferences
                              ._prayerTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PrayersTableReferences(
                                db,
                                table,
                                p0,
                              ).prayerTagsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.prayerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (prayerVersesRefs)
                        await $_getPrefetchedData<
                          PrayerRow,
                          $PrayersTable,
                          PrayerVerse
                        >(
                          currentTable: table,
                          referencedTable: $$PrayersTableReferences
                              ._prayerVersesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PrayersTableReferences(
                                db,
                                table,
                                p0,
                              ).prayerVersesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.prayerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (prayerEventsRefs)
                        await $_getPrefetchedData<
                          PrayerRow,
                          $PrayersTable,
                          PrayerEvent
                        >(
                          currentTable: table,
                          referencedTable: $$PrayersTableReferences
                              ._prayerEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PrayersTableReferences(
                                db,
                                table,
                                p0,
                              ).prayerEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.prayerId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PrayersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrayersTable,
      PrayerRow,
      $$PrayersTableFilterComposer,
      $$PrayersTableOrderingComposer,
      $$PrayersTableAnnotationComposer,
      $$PrayersTableCreateCompanionBuilder,
      $$PrayersTableUpdateCompanionBuilder,
      (PrayerRow, $$PrayersTableReferences),
      PrayerRow,
      PrefetchHooks Function({
        bool prayerTagsRefs,
        bool prayerVersesRefs,
        bool prayerEventsRefs,
      })
    >;
typedef $$TagsTableCreateCompanionBuilder = TagsCompanion Function({
  Value<int> id,
  required String label,
});
typedef $$TagsTableUpdateCompanionBuilder = TagsCompanion Function({
  Value<int> id,
  Value<String> label,
});

final class $$TagsTableReferences
    extends BaseReferences<_$AppDatabase, $TagsTable, Tag> {
  $$TagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PrayerTagsTable, List<PrayerTag>>
  _prayerTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.prayerTags,
    aliasName: 'tags__id__prayer_tags__tag_id',
  );

  $$PrayerTagsTableProcessedTableManager get prayerTagsRefs {
    final manager = $$PrayerTagsTableTableManager(
      $_db,
      $_db.prayerTags,
    ).filter((f) => f.tagId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_prayerTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> prayerTagsRefs(
    Expression<bool> Function($$PrayerTagsTableFilterComposer f) f,
  ) {
    final $$PrayerTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.prayerTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrayerTagsTableFilterComposer(
            $db: $db,
            $table: $db.prayerTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  Expression<T> prayerTagsRefs<T extends Object>(
    Expression<T> Function($$PrayerTagsTableAnnotationComposer a) f,
  ) {
    final $$PrayerTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.prayerTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrayerTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.prayerTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          Tag,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (Tag, $$TagsTableReferences),
          Tag,
          PrefetchHooks Function({bool prayerTagsRefs})
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> label = const Value.absent(),
          }) => TagsCompanion(id: id, label: label),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String label,
          }) => TagsCompanion.insert(id: id, label: label),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TagsTable, Tag>(table),
                  $$TagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({prayerTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (prayerTagsRefs) db.prayerTags],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (prayerTagsRefs)
                    await $_getPrefetchedData<Tag, $TagsTable, PrayerTag>(
                      currentTable: table,
                      referencedTable: $$TagsTableReferences
                          ._prayerTagsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TagsTableReferences(db, table, p0).prayerTagsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.tagId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      Tag,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (Tag, $$TagsTableReferences),
      Tag,
      PrefetchHooks Function({bool prayerTagsRefs})
    >;
typedef $$PrayerTagsTableCreateCompanionBuilder = PrayerTagsCompanion Function({
  required int prayerId,
  required int tagId,
  Value<int> position,
  Value<int> rowid,
});
typedef $$PrayerTagsTableUpdateCompanionBuilder = PrayerTagsCompanion Function({
  Value<int> prayerId,
  Value<int> tagId,
  Value<int> position,
  Value<int> rowid,
});

final class $$PrayerTagsTableReferences
    extends BaseReferences<_$AppDatabase, $PrayerTagsTable, PrayerTag> {
  $$PrayerTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PrayersTable _prayerIdTable(_$AppDatabase db) =>
      db.prayers.createAlias('prayer_tags__prayer_id__prayers__id');

  $$PrayersTableProcessedTableManager get prayerId {
    final $_column = $_itemColumn<int>('prayer_id')!;

    final manager = $$PrayersTableTableManager(
      $_db,
      $_db.prayers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_prayerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TagsTable _tagIdTable(_$AppDatabase db) =>
      db.tags.createAlias('prayer_tags__tag_id__tags__id');

  $$TagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<int>('tag_id')!;

    final manager = $$TagsTableTableManager(
      $_db,
      $_db.tags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PrayerTagsTableFilterComposer
    extends Composer<_$AppDatabase, $PrayerTagsTable> {
  $$PrayerTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$PrayersTableFilterComposer get prayerId {
    final $$PrayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.prayerId,
      referencedTable: $db.prayers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrayersTableFilterComposer(
            $db: $db,
            $table: $db.prayers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableFilterComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PrayerTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $PrayerTagsTable> {
  $$PrayerTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$PrayersTableOrderingComposer get prayerId {
    final $$PrayersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.prayerId,
      referencedTable: $db.prayers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrayersTableOrderingComposer(
            $db: $db,
            $table: $db.prayers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableOrderingComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PrayerTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrayerTagsTable> {
  $$PrayerTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$PrayersTableAnnotationComposer get prayerId {
    final $$PrayersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.prayerId,
      referencedTable: $db.prayers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrayersTableAnnotationComposer(
            $db: $db,
            $table: $db.prayers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableAnnotationComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PrayerTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrayerTagsTable,
          PrayerTag,
          $$PrayerTagsTableFilterComposer,
          $$PrayerTagsTableOrderingComposer,
          $$PrayerTagsTableAnnotationComposer,
          $$PrayerTagsTableCreateCompanionBuilder,
          $$PrayerTagsTableUpdateCompanionBuilder,
          (PrayerTag, $$PrayerTagsTableReferences),
          PrayerTag,
          PrefetchHooks Function({bool prayerId, bool tagId})
        > {
  $$PrayerTagsTableTableManager(_$AppDatabase db, $PrayerTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrayerTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrayerTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrayerTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> prayerId = const Value.absent(),
                Value<int> tagId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PrayerTagsCompanion(
                prayerId: prayerId,
                tagId: tagId,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int prayerId,
                required int tagId,
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PrayerTagsCompanion.insert(
                prayerId: prayerId,
                tagId: tagId,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PrayerTagsTable, PrayerTag>(table),
                  $$PrayerTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({prayerId = false, tagId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (prayerId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.prayerId,
                        referencedTable: $$PrayerTagsTableReferences
                            ._prayerIdTable(db),
                        referencedColumn: $$PrayerTagsTableReferences
                            ._prayerIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (tagId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.tagId,
                        referencedTable: $$PrayerTagsTableReferences
                            ._tagIdTable(db),
                        referencedColumn: $$PrayerTagsTableReferences
                            ._tagIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PrayerTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrayerTagsTable,
      PrayerTag,
      $$PrayerTagsTableFilterComposer,
      $$PrayerTagsTableOrderingComposer,
      $$PrayerTagsTableAnnotationComposer,
      $$PrayerTagsTableCreateCompanionBuilder,
      $$PrayerTagsTableUpdateCompanionBuilder,
      (PrayerTag, $$PrayerTagsTableReferences),
      PrayerTag,
      PrefetchHooks Function({bool prayerId, bool tagId})
    >;
typedef $$PrayerVersesTableCreateCompanionBuilder =
    PrayerVersesCompanion Function({
      required int prayerId,
      required String verseId,
      required DateTime selectedAt,
      Value<int> rowid,
    });
typedef $$PrayerVersesTableUpdateCompanionBuilder =
    PrayerVersesCompanion Function({
      Value<int> prayerId,
      Value<String> verseId,
      Value<DateTime> selectedAt,
      Value<int> rowid,
    });

final class $$PrayerVersesTableReferences
    extends BaseReferences<_$AppDatabase, $PrayerVersesTable, PrayerVerse> {
  $$PrayerVersesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PrayersTable _prayerIdTable(_$AppDatabase db) =>
      db.prayers.createAlias('prayer_verses__prayer_id__prayers__id');

  $$PrayersTableProcessedTableManager get prayerId {
    final $_column = $_itemColumn<int>('prayer_id')!;

    final manager = $$PrayersTableTableManager(
      $_db,
      $_db.prayers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_prayerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PrayerVersesTableFilterComposer
    extends Composer<_$AppDatabase, $PrayerVersesTable> {
  $$PrayerVersesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get verseId => $composableBuilder(
    column: $table.verseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get selectedAt => $composableBuilder(
    column: $table.selectedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PrayersTableFilterComposer get prayerId {
    final $$PrayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.prayerId,
      referencedTable: $db.prayers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrayersTableFilterComposer(
            $db: $db,
            $table: $db.prayers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PrayerVersesTableOrderingComposer
    extends Composer<_$AppDatabase, $PrayerVersesTable> {
  $$PrayerVersesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get verseId => $composableBuilder(
    column: $table.verseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get selectedAt => $composableBuilder(
    column: $table.selectedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PrayersTableOrderingComposer get prayerId {
    final $$PrayersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.prayerId,
      referencedTable: $db.prayers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrayersTableOrderingComposer(
            $db: $db,
            $table: $db.prayers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PrayerVersesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrayerVersesTable> {
  $$PrayerVersesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get verseId =>
      $composableBuilder(column: $table.verseId, builder: (column) => column);

  GeneratedColumn<DateTime> get selectedAt => $composableBuilder(
    column: $table.selectedAt,
    builder: (column) => column,
  );

  $$PrayersTableAnnotationComposer get prayerId {
    final $$PrayersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.prayerId,
      referencedTable: $db.prayers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrayersTableAnnotationComposer(
            $db: $db,
            $table: $db.prayers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PrayerVersesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrayerVersesTable,
          PrayerVerse,
          $$PrayerVersesTableFilterComposer,
          $$PrayerVersesTableOrderingComposer,
          $$PrayerVersesTableAnnotationComposer,
          $$PrayerVersesTableCreateCompanionBuilder,
          $$PrayerVersesTableUpdateCompanionBuilder,
          (PrayerVerse, $$PrayerVersesTableReferences),
          PrayerVerse,
          PrefetchHooks Function({bool prayerId})
        > {
  $$PrayerVersesTableTableManager(_$AppDatabase db, $PrayerVersesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrayerVersesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrayerVersesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrayerVersesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> prayerId = const Value.absent(),
                Value<String> verseId = const Value.absent(),
                Value<DateTime> selectedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PrayerVersesCompanion(
                prayerId: prayerId,
                verseId: verseId,
                selectedAt: selectedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int prayerId,
                required String verseId,
                required DateTime selectedAt,
                Value<int> rowid = const Value.absent(),
              }) => PrayerVersesCompanion.insert(
                prayerId: prayerId,
                verseId: verseId,
                selectedAt: selectedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PrayerVersesTable, PrayerVerse>(table),
                  $$PrayerVersesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({prayerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (prayerId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.prayerId,
                        referencedTable: $$PrayerVersesTableReferences
                            ._prayerIdTable(db),
                        referencedColumn: $$PrayerVersesTableReferences
                            ._prayerIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PrayerVersesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrayerVersesTable,
      PrayerVerse,
      $$PrayerVersesTableFilterComposer,
      $$PrayerVersesTableOrderingComposer,
      $$PrayerVersesTableAnnotationComposer,
      $$PrayerVersesTableCreateCompanionBuilder,
      $$PrayerVersesTableUpdateCompanionBuilder,
      (PrayerVerse, $$PrayerVersesTableReferences),
      PrayerVerse,
      PrefetchHooks Function({bool prayerId})
    >;
typedef $$PrayerEventsTableCreateCompanionBuilder =
    PrayerEventsCompanion Function({
      Value<int> id,
      required int prayerId,
      required String type,
      required DateTime at,
    });
typedef $$PrayerEventsTableUpdateCompanionBuilder =
    PrayerEventsCompanion Function({
      Value<int> id,
      Value<int> prayerId,
      Value<String> type,
      Value<DateTime> at,
    });

final class $$PrayerEventsTableReferences
    extends BaseReferences<_$AppDatabase, $PrayerEventsTable, PrayerEvent> {
  $$PrayerEventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PrayersTable _prayerIdTable(_$AppDatabase db) =>
      db.prayers.createAlias('prayer_events__prayer_id__prayers__id');

  $$PrayersTableProcessedTableManager get prayerId {
    final $_column = $_itemColumn<int>('prayer_id')!;

    final manager = $$PrayersTableTableManager(
      $_db,
      $_db.prayers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_prayerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PrayerEventsTableFilterComposer
    extends Composer<_$AppDatabase, $PrayerEventsTable> {
  $$PrayerEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );

  $$PrayersTableFilterComposer get prayerId {
    final $$PrayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.prayerId,
      referencedTable: $db.prayers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrayersTableFilterComposer(
            $db: $db,
            $table: $db.prayers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PrayerEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $PrayerEventsTable> {
  $$PrayerEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );

  $$PrayersTableOrderingComposer get prayerId {
    final $$PrayersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.prayerId,
      referencedTable: $db.prayers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrayersTableOrderingComposer(
            $db: $db,
            $table: $db.prayers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PrayerEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrayerEventsTable> {
  $$PrayerEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

  $$PrayersTableAnnotationComposer get prayerId {
    final $$PrayersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.prayerId,
      referencedTable: $db.prayers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PrayersTableAnnotationComposer(
            $db: $db,
            $table: $db.prayers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PrayerEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrayerEventsTable,
          PrayerEvent,
          $$PrayerEventsTableFilterComposer,
          $$PrayerEventsTableOrderingComposer,
          $$PrayerEventsTableAnnotationComposer,
          $$PrayerEventsTableCreateCompanionBuilder,
          $$PrayerEventsTableUpdateCompanionBuilder,
          (PrayerEvent, $$PrayerEventsTableReferences),
          PrayerEvent,
          PrefetchHooks Function({bool prayerId})
        > {
  $$PrayerEventsTableTableManager(_$AppDatabase db, $PrayerEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrayerEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrayerEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrayerEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> prayerId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
              }) => PrayerEventsCompanion(
                id: id,
                prayerId: prayerId,
                type: type,
                at: at,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int prayerId,
                required String type,
                required DateTime at,
              }) => PrayerEventsCompanion.insert(
                id: id,
                prayerId: prayerId,
                type: type,
                at: at,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PrayerEventsTable, PrayerEvent>(table),
                  $$PrayerEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({prayerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (prayerId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.prayerId,
                        referencedTable: $$PrayerEventsTableReferences
                            ._prayerIdTable(db),
                        referencedColumn: $$PrayerEventsTableReferences
                            ._prayerIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PrayerEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrayerEventsTable,
      PrayerEvent,
      $$PrayerEventsTableFilterComposer,
      $$PrayerEventsTableOrderingComposer,
      $$PrayerEventsTableAnnotationComposer,
      $$PrayerEventsTableCreateCompanionBuilder,
      $$PrayerEventsTableUpdateCompanionBuilder,
      (PrayerEvent, $$PrayerEventsTableReferences),
      PrayerEvent,
      PrefetchHooks Function({bool prayerId})
    >;
typedef $$CustomVersesTableCreateCompanionBuilder =
    CustomVersesCompanion Function({
      required String id,
      required String ref,
      required String body,
      Value<String?> note,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$CustomVersesTableUpdateCompanionBuilder =
    CustomVersesCompanion Function({
      Value<String> id,
      Value<String> ref,
      Value<String> body,
      Value<String?> note,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$CustomVersesTableFilterComposer
    extends Composer<_$AppDatabase, $CustomVersesTable> {
  $$CustomVersesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ref => $composableBuilder(
    column: $table.ref,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomVersesTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomVersesTable> {
  $$CustomVersesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ref => $composableBuilder(
    column: $table.ref,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomVersesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomVersesTable> {
  $$CustomVersesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ref =>
      $composableBuilder(column: $table.ref, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CustomVersesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomVersesTable,
          CustomVerse,
          $$CustomVersesTableFilterComposer,
          $$CustomVersesTableOrderingComposer,
          $$CustomVersesTableAnnotationComposer,
          $$CustomVersesTableCreateCompanionBuilder,
          $$CustomVersesTableUpdateCompanionBuilder,
          (
            CustomVerse,
            BaseReferences<_$AppDatabase, $CustomVersesTable, CustomVerse>,
          ),
          CustomVerse,
          PrefetchHooks Function()
        > {
  $$CustomVersesTableTableManager(_$AppDatabase db, $CustomVersesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomVersesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomVersesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomVersesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ref = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomVersesCompanion(
                id: id,
                ref: ref,
                body: body,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ref,
                required String body,
                Value<String?> note = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CustomVersesCompanion.insert(
                id: id,
                ref: ref,
                body: body,
                note: note,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CustomVersesTable, CustomVerse>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CustomVersesTable,
                    CustomVerse
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomVersesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomVersesTable,
      CustomVerse,
      $$CustomVersesTableFilterComposer,
      $$CustomVersesTableOrderingComposer,
      $$CustomVersesTableAnnotationComposer,
      $$CustomVersesTableCreateCompanionBuilder,
      $$CustomVersesTableUpdateCompanionBuilder,
      (
        CustomVerse,
        BaseReferences<_$AppDatabase, $CustomVersesTable, CustomVerse>,
      ),
      CustomVerse,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PrayersTableTableManager get prayers =>
      $$PrayersTableTableManager(_db, _db.prayers);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$PrayerTagsTableTableManager get prayerTags =>
      $$PrayerTagsTableTableManager(_db, _db.prayerTags);
  $$PrayerVersesTableTableManager get prayerVerses =>
      $$PrayerVersesTableTableManager(_db, _db.prayerVerses);
  $$PrayerEventsTableTableManager get prayerEvents =>
      $$PrayerEventsTableTableManager(_db, _db.prayerEvents);
  $$CustomVersesTableTableManager get customVerses =>
      $$CustomVersesTableTableManager(_db, _db.customVerses);
}
