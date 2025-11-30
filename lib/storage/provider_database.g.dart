// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider_database.dart';

// ignore_for_file: type=lint
class $ProviderProfilesTable extends ProviderProfiles
    with TableInfo<$ProviderProfilesTable, ProviderProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProviderProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ProviderKind, int> kind =
      GeneratedColumn<int>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<ProviderKind>($ProviderProfilesTable.$converterkind);
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lockedBaseMeta = const VerificationMeta(
    'lockedBase',
  );
  @override
  late final GeneratedColumn<String> lockedBase = GeneratedColumn<String>(
    'locked_base',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _needsUserAgentMeta = const VerificationMeta(
    'needsUserAgent',
  );
  @override
  late final GeneratedColumn<bool> needsUserAgent = GeneratedColumn<bool>(
    'needs_user_agent',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("needs_user_agent" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _allowSelfSignedTlsMeta =
      const VerificationMeta('allowSelfSignedTls');
  @override
  late final GeneratedColumn<bool> allowSelfSignedTls = GeneratedColumn<bool>(
    'allow_self_signed_tls',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("allow_self_signed_tls" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _followRedirectsMeta = const VerificationMeta(
    'followRedirects',
  );
  @override
  late final GeneratedColumn<bool> followRedirects = GeneratedColumn<bool>(
    'follow_redirects',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("follow_redirects" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Map<String, String>, String>
  configuration =
      GeneratedColumn<String>(
        'configuration',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('{}'),
      ).withConverter<Map<String, String>>(
        $ProviderProfilesTable.$converterconfiguration,
      );
  @override
  late final GeneratedColumnWithTypeConverter<Map<String, String>, String>
  hints = GeneratedColumn<String>(
    'hints',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  ).withConverter<Map<String, String>>($ProviderProfilesTable.$converterhints);
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
  static const VerificationMeta _lastOkAtMeta = const VerificationMeta(
    'lastOkAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastOkAt = GeneratedColumn<DateTime>(
    'last_ok_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    displayName,
    lockedBase,
    needsUserAgent,
    allowSelfSignedTls,
    followRedirects,
    configuration,
    hints,
    createdAt,
    updatedAt,
    lastOkAt,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'providers';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProviderProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('locked_base')) {
      context.handle(
        _lockedBaseMeta,
        lockedBase.isAcceptableOrUnknown(data['locked_base']!, _lockedBaseMeta),
      );
    } else if (isInserting) {
      context.missing(_lockedBaseMeta);
    }
    if (data.containsKey('needs_user_agent')) {
      context.handle(
        _needsUserAgentMeta,
        needsUserAgent.isAcceptableOrUnknown(
          data['needs_user_agent']!,
          _needsUserAgentMeta,
        ),
      );
    }
    if (data.containsKey('allow_self_signed_tls')) {
      context.handle(
        _allowSelfSignedTlsMeta,
        allowSelfSignedTls.isAcceptableOrUnknown(
          data['allow_self_signed_tls']!,
          _allowSelfSignedTlsMeta,
        ),
      );
    }
    if (data.containsKey('follow_redirects')) {
      context.handle(
        _followRedirectsMeta,
        followRedirects.isAcceptableOrUnknown(
          data['follow_redirects']!,
          _followRedirectsMeta,
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
    if (data.containsKey('last_ok_at')) {
      context.handle(
        _lastOkAtMeta,
        lastOkAt.isAcceptableOrUnknown(data['last_ok_at']!, _lastOkAtMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProviderProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProviderProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: $ProviderProfilesTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}kind'],
        )!,
      ),
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      lockedBase: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locked_base'],
      )!,
      needsUserAgent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}needs_user_agent'],
      )!,
      allowSelfSignedTls: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}allow_self_signed_tls'],
      )!,
      followRedirects: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}follow_redirects'],
      )!,
      configuration: $ProviderProfilesTable.$converterconfiguration.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}configuration'],
        )!,
      ),
      hints: $ProviderProfilesTable.$converterhints.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}hints'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      lastOkAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_ok_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $ProviderProfilesTable createAlias(String alias) {
    return $ProviderProfilesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ProviderKind, int, int> $converterkind =
      const EnumIndexConverter<ProviderKind>(ProviderKind.values);
  static TypeConverter<Map<String, String>, String> $converterconfiguration =
      const MapStringConverter();
  static TypeConverter<Map<String, String>, String> $converterhints =
      const MapStringConverter();
}

class ProviderProfile extends DataClass implements Insertable<ProviderProfile> {
  final String id;
  final ProviderKind kind;
  final String displayName;
  final String lockedBase;
  final bool needsUserAgent;
  final bool allowSelfSignedTls;
  final bool followRedirects;
  final Map<String, String> configuration;
  final Map<String, String> hints;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastOkAt;
  final String? lastError;
  const ProviderProfile({
    required this.id,
    required this.kind,
    required this.displayName,
    required this.lockedBase,
    required this.needsUserAgent,
    required this.allowSelfSignedTls,
    required this.followRedirects,
    required this.configuration,
    required this.hints,
    required this.createdAt,
    required this.updatedAt,
    this.lastOkAt,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['kind'] = Variable<int>(
        $ProviderProfilesTable.$converterkind.toSql(kind),
      );
    }
    map['display_name'] = Variable<String>(displayName);
    map['locked_base'] = Variable<String>(lockedBase);
    map['needs_user_agent'] = Variable<bool>(needsUserAgent);
    map['allow_self_signed_tls'] = Variable<bool>(allowSelfSignedTls);
    map['follow_redirects'] = Variable<bool>(followRedirects);
    {
      map['configuration'] = Variable<String>(
        $ProviderProfilesTable.$converterconfiguration.toSql(configuration),
      );
    }
    {
      map['hints'] = Variable<String>(
        $ProviderProfilesTable.$converterhints.toSql(hints),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || lastOkAt != null) {
      map['last_ok_at'] = Variable<DateTime>(lastOkAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  ProviderProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProviderProfilesCompanion(
      id: Value(id),
      kind: Value(kind),
      displayName: Value(displayName),
      lockedBase: Value(lockedBase),
      needsUserAgent: Value(needsUserAgent),
      allowSelfSignedTls: Value(allowSelfSignedTls),
      followRedirects: Value(followRedirects),
      configuration: Value(configuration),
      hints: Value(hints),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastOkAt: lastOkAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastOkAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory ProviderProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProviderProfile(
      id: serializer.fromJson<String>(json['id']),
      kind: $ProviderProfilesTable.$converterkind.fromJson(
        serializer.fromJson<int>(json['kind']),
      ),
      displayName: serializer.fromJson<String>(json['displayName']),
      lockedBase: serializer.fromJson<String>(json['lockedBase']),
      needsUserAgent: serializer.fromJson<bool>(json['needsUserAgent']),
      allowSelfSignedTls: serializer.fromJson<bool>(json['allowSelfSignedTls']),
      followRedirects: serializer.fromJson<bool>(json['followRedirects']),
      configuration: serializer.fromJson<Map<String, String>>(
        json['configuration'],
      ),
      hints: serializer.fromJson<Map<String, String>>(json['hints']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastOkAt: serializer.fromJson<DateTime?>(json['lastOkAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<int>(
        $ProviderProfilesTable.$converterkind.toJson(kind),
      ),
      'displayName': serializer.toJson<String>(displayName),
      'lockedBase': serializer.toJson<String>(lockedBase),
      'needsUserAgent': serializer.toJson<bool>(needsUserAgent),
      'allowSelfSignedTls': serializer.toJson<bool>(allowSelfSignedTls),
      'followRedirects': serializer.toJson<bool>(followRedirects),
      'configuration': serializer.toJson<Map<String, String>>(configuration),
      'hints': serializer.toJson<Map<String, String>>(hints),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastOkAt': serializer.toJson<DateTime?>(lastOkAt),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  ProviderProfile copyWith({
    String? id,
    ProviderKind? kind,
    String? displayName,
    String? lockedBase,
    bool? needsUserAgent,
    bool? allowSelfSignedTls,
    bool? followRedirects,
    Map<String, String>? configuration,
    Map<String, String>? hints,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> lastOkAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
  }) => ProviderProfile(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    displayName: displayName ?? this.displayName,
    lockedBase: lockedBase ?? this.lockedBase,
    needsUserAgent: needsUserAgent ?? this.needsUserAgent,
    allowSelfSignedTls: allowSelfSignedTls ?? this.allowSelfSignedTls,
    followRedirects: followRedirects ?? this.followRedirects,
    configuration: configuration ?? this.configuration,
    hints: hints ?? this.hints,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastOkAt: lastOkAt.present ? lastOkAt.value : this.lastOkAt,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  ProviderProfile copyWithCompanion(ProviderProfilesCompanion data) {
    return ProviderProfile(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      lockedBase: data.lockedBase.present
          ? data.lockedBase.value
          : this.lockedBase,
      needsUserAgent: data.needsUserAgent.present
          ? data.needsUserAgent.value
          : this.needsUserAgent,
      allowSelfSignedTls: data.allowSelfSignedTls.present
          ? data.allowSelfSignedTls.value
          : this.allowSelfSignedTls,
      followRedirects: data.followRedirects.present
          ? data.followRedirects.value
          : this.followRedirects,
      configuration: data.configuration.present
          ? data.configuration.value
          : this.configuration,
      hints: data.hints.present ? data.hints.value : this.hints,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastOkAt: data.lastOkAt.present ? data.lastOkAt.value : this.lastOkAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProviderProfile(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('displayName: $displayName, ')
          ..write('lockedBase: $lockedBase, ')
          ..write('needsUserAgent: $needsUserAgent, ')
          ..write('allowSelfSignedTls: $allowSelfSignedTls, ')
          ..write('followRedirects: $followRedirects, ')
          ..write('configuration: $configuration, ')
          ..write('hints: $hints, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastOkAt: $lastOkAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    displayName,
    lockedBase,
    needsUserAgent,
    allowSelfSignedTls,
    followRedirects,
    configuration,
    hints,
    createdAt,
    updatedAt,
    lastOkAt,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProviderProfile &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.displayName == this.displayName &&
          other.lockedBase == this.lockedBase &&
          other.needsUserAgent == this.needsUserAgent &&
          other.allowSelfSignedTls == this.allowSelfSignedTls &&
          other.followRedirects == this.followRedirects &&
          other.configuration == this.configuration &&
          other.hints == this.hints &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastOkAt == this.lastOkAt &&
          other.lastError == this.lastError);
}

class ProviderProfilesCompanion extends UpdateCompanion<ProviderProfile> {
  final Value<String> id;
  final Value<ProviderKind> kind;
  final Value<String> displayName;
  final Value<String> lockedBase;
  final Value<bool> needsUserAgent;
  final Value<bool> allowSelfSignedTls;
  final Value<bool> followRedirects;
  final Value<Map<String, String>> configuration;
  final Value<Map<String, String>> hints;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> lastOkAt;
  final Value<String?> lastError;
  final Value<int> rowid;
  const ProviderProfilesCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.displayName = const Value.absent(),
    this.lockedBase = const Value.absent(),
    this.needsUserAgent = const Value.absent(),
    this.allowSelfSignedTls = const Value.absent(),
    this.followRedirects = const Value.absent(),
    this.configuration = const Value.absent(),
    this.hints = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastOkAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProviderProfilesCompanion.insert({
    required String id,
    required ProviderKind kind,
    required String displayName,
    required String lockedBase,
    this.needsUserAgent = const Value.absent(),
    this.allowSelfSignedTls = const Value.absent(),
    this.followRedirects = const Value.absent(),
    this.configuration = const Value.absent(),
    this.hints = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.lastOkAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       displayName = Value(displayName),
       lockedBase = Value(lockedBase),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ProviderProfile> custom({
    Expression<String>? id,
    Expression<int>? kind,
    Expression<String>? displayName,
    Expression<String>? lockedBase,
    Expression<bool>? needsUserAgent,
    Expression<bool>? allowSelfSignedTls,
    Expression<bool>? followRedirects,
    Expression<String>? configuration,
    Expression<String>? hints,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastOkAt,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (displayName != null) 'display_name': displayName,
      if (lockedBase != null) 'locked_base': lockedBase,
      if (needsUserAgent != null) 'needs_user_agent': needsUserAgent,
      if (allowSelfSignedTls != null)
        'allow_self_signed_tls': allowSelfSignedTls,
      if (followRedirects != null) 'follow_redirects': followRedirects,
      if (configuration != null) 'configuration': configuration,
      if (hints != null) 'hints': hints,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastOkAt != null) 'last_ok_at': lastOkAt,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProviderProfilesCompanion copyWith({
    Value<String>? id,
    Value<ProviderKind>? kind,
    Value<String>? displayName,
    Value<String>? lockedBase,
    Value<bool>? needsUserAgent,
    Value<bool>? allowSelfSignedTls,
    Value<bool>? followRedirects,
    Value<Map<String, String>>? configuration,
    Value<Map<String, String>>? hints,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? lastOkAt,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return ProviderProfilesCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      displayName: displayName ?? this.displayName,
      lockedBase: lockedBase ?? this.lockedBase,
      needsUserAgent: needsUserAgent ?? this.needsUserAgent,
      allowSelfSignedTls: allowSelfSignedTls ?? this.allowSelfSignedTls,
      followRedirects: followRedirects ?? this.followRedirects,
      configuration: configuration ?? this.configuration,
      hints: hints ?? this.hints,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastOkAt: lastOkAt ?? this.lastOkAt,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>(
        $ProviderProfilesTable.$converterkind.toSql(kind.value),
      );
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (lockedBase.present) {
      map['locked_base'] = Variable<String>(lockedBase.value);
    }
    if (needsUserAgent.present) {
      map['needs_user_agent'] = Variable<bool>(needsUserAgent.value);
    }
    if (allowSelfSignedTls.present) {
      map['allow_self_signed_tls'] = Variable<bool>(allowSelfSignedTls.value);
    }
    if (followRedirects.present) {
      map['follow_redirects'] = Variable<bool>(followRedirects.value);
    }
    if (configuration.present) {
      map['configuration'] = Variable<String>(
        $ProviderProfilesTable.$converterconfiguration.toSql(
          configuration.value,
        ),
      );
    }
    if (hints.present) {
      map['hints'] = Variable<String>(
        $ProviderProfilesTable.$converterhints.toSql(hints.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastOkAt.present) {
      map['last_ok_at'] = Variable<DateTime>(lastOkAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProviderProfilesCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('displayName: $displayName, ')
          ..write('lockedBase: $lockedBase, ')
          ..write('needsUserAgent: $needsUserAgent, ')
          ..write('allowSelfSignedTls: $allowSelfSignedTls, ')
          ..write('followRedirects: $followRedirects, ')
          ..write('configuration: $configuration, ')
          ..write('hints: $hints, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastOkAt: $lastOkAt, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProviderSecretsTable extends ProviderSecrets
    with TableInfo<$ProviderSecretsTable, ProviderSecret> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProviderSecretsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'REFERENCES providers(id) ON DELETE CASCADE NOT NULL',
  );
  static const VerificationMeta _vaultKeyMeta = const VerificationMeta(
    'vaultKey',
  );
  @override
  late final GeneratedColumn<String> vaultKey = GeneratedColumn<String>(
    'vault_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    providerId,
    vaultKey,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'provider_secrets';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProviderSecret> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('vault_key')) {
      context.handle(
        _vaultKeyMeta,
        vaultKey.isAcceptableOrUnknown(data['vault_key']!, _vaultKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_vaultKeyMeta);
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
  Set<GeneratedColumn> get $primaryKey => {providerId};
  @override
  ProviderSecret map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProviderSecret(
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      vaultKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vault_key'],
      )!,
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
  $ProviderSecretsTable createAlias(String alias) {
    return $ProviderSecretsTable(attachedDatabase, alias);
  }
}

class ProviderSecret extends DataClass implements Insertable<ProviderSecret> {
  final String providerId;
  final String vaultKey;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ProviderSecret({
    required this.providerId,
    required this.vaultKey,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['provider_id'] = Variable<String>(providerId);
    map['vault_key'] = Variable<String>(vaultKey);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProviderSecretsCompanion toCompanion(bool nullToAbsent) {
    return ProviderSecretsCompanion(
      providerId: Value(providerId),
      vaultKey: Value(vaultKey),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProviderSecret.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProviderSecret(
      providerId: serializer.fromJson<String>(json['providerId']),
      vaultKey: serializer.fromJson<String>(json['vaultKey']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'providerId': serializer.toJson<String>(providerId),
      'vaultKey': serializer.toJson<String>(vaultKey),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ProviderSecret copyWith({
    String? providerId,
    String? vaultKey,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ProviderSecret(
    providerId: providerId ?? this.providerId,
    vaultKey: vaultKey ?? this.vaultKey,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ProviderSecret copyWithCompanion(ProviderSecretsCompanion data) {
    return ProviderSecret(
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      vaultKey: data.vaultKey.present ? data.vaultKey.value : this.vaultKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProviderSecret(')
          ..write('providerId: $providerId, ')
          ..write('vaultKey: $vaultKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(providerId, vaultKey, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProviderSecret &&
          other.providerId == this.providerId &&
          other.vaultKey == this.vaultKey &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProviderSecretsCompanion extends UpdateCompanion<ProviderSecret> {
  final Value<String> providerId;
  final Value<String> vaultKey;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProviderSecretsCompanion({
    this.providerId = const Value.absent(),
    this.vaultKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProviderSecretsCompanion.insert({
    required String providerId,
    required String vaultKey,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : providerId = Value(providerId),
       vaultKey = Value(vaultKey),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ProviderSecret> custom({
    Expression<String>? providerId,
    Expression<String>? vaultKey,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (providerId != null) 'provider_id': providerId,
      if (vaultKey != null) 'vault_key': vaultKey,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProviderSecretsCompanion copyWith({
    Value<String>? providerId,
    Value<String>? vaultKey,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProviderSecretsCompanion(
      providerId: providerId ?? this.providerId,
      vaultKey: vaultKey ?? this.vaultKey,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (vaultKey.present) {
      map['vault_key'] = Variable<String>(vaultKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProviderSecretsCompanion(')
          ..write('providerId: $providerId, ')
          ..write('vaultKey: $vaultKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StreamGroupsTable extends StreamGroups
    with TableInfo<$StreamGroupsTable, StreamGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StreamGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'REFERENCES providers(id) ON DELETE CASCADE NOT NULL',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  @override
  List<GeneratedColumn> get $columns => [id, providerId, name, type];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stream_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<StreamGroup> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id, providerId, type};
  @override
  StreamGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StreamGroup(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
    );
  }

  @override
  $StreamGroupsTable createAlias(String alias) {
    return $StreamGroupsTable(attachedDatabase, alias);
  }
}

class StreamGroup extends DataClass implements Insertable<StreamGroup> {
  final int id;
  final String providerId;
  final String name;
  final String type;
  const StreamGroup({
    required this.id,
    required this.providerId,
    required this.name,
    required this.type,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['provider_id'] = Variable<String>(providerId);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    return map;
  }

  StreamGroupsCompanion toCompanion(bool nullToAbsent) {
    return StreamGroupsCompanion(
      id: Value(id),
      providerId: Value(providerId),
      name: Value(name),
      type: Value(type),
    );
  }

  factory StreamGroup.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StreamGroup(
      id: serializer.fromJson<int>(json['id']),
      providerId: serializer.fromJson<String>(json['providerId']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'providerId': serializer.toJson<String>(providerId),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
    };
  }

  StreamGroup copyWith({
    int? id,
    String? providerId,
    String? name,
    String? type,
  }) => StreamGroup(
    id: id ?? this.id,
    providerId: providerId ?? this.providerId,
    name: name ?? this.name,
    type: type ?? this.type,
  );
  StreamGroup copyWithCompanion(StreamGroupsCompanion data) {
    return StreamGroup(
      id: data.id.present ? data.id.value : this.id,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StreamGroup(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('name: $name, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, providerId, name, type);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StreamGroup &&
          other.id == this.id &&
          other.providerId == this.providerId &&
          other.name == this.name &&
          other.type == this.type);
}

class StreamGroupsCompanion extends UpdateCompanion<StreamGroup> {
  final Value<int> id;
  final Value<String> providerId;
  final Value<String> name;
  final Value<String> type;
  final Value<int> rowid;
  const StreamGroupsCompanion({
    this.id = const Value.absent(),
    this.providerId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StreamGroupsCompanion.insert({
    required int id,
    required String providerId,
    required String name,
    required String type,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       providerId = Value(providerId),
       name = Value(name),
       type = Value(type);
  static Insertable<StreamGroup> custom({
    Expression<int>? id,
    Expression<String>? providerId,
    Expression<String>? name,
    Expression<String>? type,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (providerId != null) 'provider_id': providerId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StreamGroupsCompanion copyWith({
    Value<int>? id,
    Value<String>? providerId,
    Value<String>? name,
    Value<String>? type,
    Value<int>? rowid,
  }) {
    return StreamGroupsCompanion(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      name: name ?? this.name,
      type: type ?? this.type,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StreamGroupsCompanion(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LiveStreamsTable extends LiveStreams
    with TableInfo<$LiveStreamsTable, LiveStream> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LiveStreamsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _streamIdMeta = const VerificationMeta(
    'streamId',
  );
  @override
  late final GeneratedColumn<int> streamId = GeneratedColumn<int>(
    'stream_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'REFERENCES providers(id) ON DELETE CASCADE NOT NULL',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _streamIconMeta = const VerificationMeta(
    'streamIcon',
  );
  @override
  late final GeneratedColumn<String> streamIcon = GeneratedColumn<String>(
    'stream_icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _epgChannelIdMeta = const VerificationMeta(
    'epgChannelId',
  );
  @override
  late final GeneratedColumn<String> epgChannelId = GeneratedColumn<String>(
    'epg_channel_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _numMeta = const VerificationMeta('num');
  @override
  late final GeneratedColumn<int> num = GeneratedColumn<int>(
    'num',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isAdultMeta = const VerificationMeta(
    'isAdult',
  );
  @override
  late final GeneratedColumn<bool> isAdult = GeneratedColumn<bool>(
    'is_adult',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_adult" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    streamId,
    providerId,
    name,
    streamIcon,
    epgChannelId,
    categoryId,
    num,
    isAdult,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'live_streams';
  @override
  VerificationContext validateIntegrity(
    Insertable<LiveStream> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('stream_id')) {
      context.handle(
        _streamIdMeta,
        streamId.isAcceptableOrUnknown(data['stream_id']!, _streamIdMeta),
      );
    } else if (isInserting) {
      context.missing(_streamIdMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('stream_icon')) {
      context.handle(
        _streamIconMeta,
        streamIcon.isAcceptableOrUnknown(data['stream_icon']!, _streamIconMeta),
      );
    }
    if (data.containsKey('epg_channel_id')) {
      context.handle(
        _epgChannelIdMeta,
        epgChannelId.isAcceptableOrUnknown(
          data['epg_channel_id']!,
          _epgChannelIdMeta,
        ),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('num')) {
      context.handle(
        _numMeta,
        num.isAcceptableOrUnknown(data['num']!, _numMeta),
      );
    }
    if (data.containsKey('is_adult')) {
      context.handle(
        _isAdultMeta,
        isAdult.isAcceptableOrUnknown(data['is_adult']!, _isAdultMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {streamId, providerId};
  @override
  LiveStream map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LiveStream(
      streamId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stream_id'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      streamIcon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stream_icon'],
      ),
      epgChannelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}epg_channel_id'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      ),
      num: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}num'],
      ),
      isAdult: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_adult'],
      )!,
    );
  }

  @override
  $LiveStreamsTable createAlias(String alias) {
    return $LiveStreamsTable(attachedDatabase, alias);
  }
}

class LiveStream extends DataClass implements Insertable<LiveStream> {
  final int streamId;
  final String providerId;
  final String name;
  final String? streamIcon;
  final String? epgChannelId;
  final int? categoryId;
  final int? num;
  final bool isAdult;
  const LiveStream({
    required this.streamId,
    required this.providerId,
    required this.name,
    this.streamIcon,
    this.epgChannelId,
    this.categoryId,
    this.num,
    required this.isAdult,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['stream_id'] = Variable<int>(streamId);
    map['provider_id'] = Variable<String>(providerId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || streamIcon != null) {
      map['stream_icon'] = Variable<String>(streamIcon);
    }
    if (!nullToAbsent || epgChannelId != null) {
      map['epg_channel_id'] = Variable<String>(epgChannelId);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    if (!nullToAbsent || num != null) {
      map['num'] = Variable<int>(num);
    }
    map['is_adult'] = Variable<bool>(isAdult);
    return map;
  }

  LiveStreamsCompanion toCompanion(bool nullToAbsent) {
    return LiveStreamsCompanion(
      streamId: Value(streamId),
      providerId: Value(providerId),
      name: Value(name),
      streamIcon: streamIcon == null && nullToAbsent
          ? const Value.absent()
          : Value(streamIcon),
      epgChannelId: epgChannelId == null && nullToAbsent
          ? const Value.absent()
          : Value(epgChannelId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      num: num == null && nullToAbsent ? const Value.absent() : Value(num),
      isAdult: Value(isAdult),
    );
  }

  factory LiveStream.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LiveStream(
      streamId: serializer.fromJson<int>(json['streamId']),
      providerId: serializer.fromJson<String>(json['providerId']),
      name: serializer.fromJson<String>(json['name']),
      streamIcon: serializer.fromJson<String?>(json['streamIcon']),
      epgChannelId: serializer.fromJson<String?>(json['epgChannelId']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      num: serializer.fromJson<int?>(json['num']),
      isAdult: serializer.fromJson<bool>(json['isAdult']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'streamId': serializer.toJson<int>(streamId),
      'providerId': serializer.toJson<String>(providerId),
      'name': serializer.toJson<String>(name),
      'streamIcon': serializer.toJson<String?>(streamIcon),
      'epgChannelId': serializer.toJson<String?>(epgChannelId),
      'categoryId': serializer.toJson<int?>(categoryId),
      'num': serializer.toJson<int?>(num),
      'isAdult': serializer.toJson<bool>(isAdult),
    };
  }

  LiveStream copyWith({
    int? streamId,
    String? providerId,
    String? name,
    Value<String?> streamIcon = const Value.absent(),
    Value<String?> epgChannelId = const Value.absent(),
    Value<int?> categoryId = const Value.absent(),
    Value<int?> num = const Value.absent(),
    bool? isAdult,
  }) => LiveStream(
    streamId: streamId ?? this.streamId,
    providerId: providerId ?? this.providerId,
    name: name ?? this.name,
    streamIcon: streamIcon.present ? streamIcon.value : this.streamIcon,
    epgChannelId: epgChannelId.present ? epgChannelId.value : this.epgChannelId,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    num: num.present ? num.value : this.num,
    isAdult: isAdult ?? this.isAdult,
  );
  LiveStream copyWithCompanion(LiveStreamsCompanion data) {
    return LiveStream(
      streamId: data.streamId.present ? data.streamId.value : this.streamId,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      name: data.name.present ? data.name.value : this.name,
      streamIcon: data.streamIcon.present
          ? data.streamIcon.value
          : this.streamIcon,
      epgChannelId: data.epgChannelId.present
          ? data.epgChannelId.value
          : this.epgChannelId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      num: data.num.present ? data.num.value : this.num,
      isAdult: data.isAdult.present ? data.isAdult.value : this.isAdult,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LiveStream(')
          ..write('streamId: $streamId, ')
          ..write('providerId: $providerId, ')
          ..write('name: $name, ')
          ..write('streamIcon: $streamIcon, ')
          ..write('epgChannelId: $epgChannelId, ')
          ..write('categoryId: $categoryId, ')
          ..write('num: $num, ')
          ..write('isAdult: $isAdult')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    streamId,
    providerId,
    name,
    streamIcon,
    epgChannelId,
    categoryId,
    num,
    isAdult,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LiveStream &&
          other.streamId == this.streamId &&
          other.providerId == this.providerId &&
          other.name == this.name &&
          other.streamIcon == this.streamIcon &&
          other.epgChannelId == this.epgChannelId &&
          other.categoryId == this.categoryId &&
          other.num == this.num &&
          other.isAdult == this.isAdult);
}

class LiveStreamsCompanion extends UpdateCompanion<LiveStream> {
  final Value<int> streamId;
  final Value<String> providerId;
  final Value<String> name;
  final Value<String?> streamIcon;
  final Value<String?> epgChannelId;
  final Value<int?> categoryId;
  final Value<int?> num;
  final Value<bool> isAdult;
  final Value<int> rowid;
  const LiveStreamsCompanion({
    this.streamId = const Value.absent(),
    this.providerId = const Value.absent(),
    this.name = const Value.absent(),
    this.streamIcon = const Value.absent(),
    this.epgChannelId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.num = const Value.absent(),
    this.isAdult = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LiveStreamsCompanion.insert({
    required int streamId,
    required String providerId,
    required String name,
    this.streamIcon = const Value.absent(),
    this.epgChannelId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.num = const Value.absent(),
    this.isAdult = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : streamId = Value(streamId),
       providerId = Value(providerId),
       name = Value(name);
  static Insertable<LiveStream> custom({
    Expression<int>? streamId,
    Expression<String>? providerId,
    Expression<String>? name,
    Expression<String>? streamIcon,
    Expression<String>? epgChannelId,
    Expression<int>? categoryId,
    Expression<int>? num,
    Expression<bool>? isAdult,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (streamId != null) 'stream_id': streamId,
      if (providerId != null) 'provider_id': providerId,
      if (name != null) 'name': name,
      if (streamIcon != null) 'stream_icon': streamIcon,
      if (epgChannelId != null) 'epg_channel_id': epgChannelId,
      if (categoryId != null) 'category_id': categoryId,
      if (num != null) 'num': num,
      if (isAdult != null) 'is_adult': isAdult,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LiveStreamsCompanion copyWith({
    Value<int>? streamId,
    Value<String>? providerId,
    Value<String>? name,
    Value<String?>? streamIcon,
    Value<String?>? epgChannelId,
    Value<int?>? categoryId,
    Value<int?>? num,
    Value<bool>? isAdult,
    Value<int>? rowid,
  }) {
    return LiveStreamsCompanion(
      streamId: streamId ?? this.streamId,
      providerId: providerId ?? this.providerId,
      name: name ?? this.name,
      streamIcon: streamIcon ?? this.streamIcon,
      epgChannelId: epgChannelId ?? this.epgChannelId,
      categoryId: categoryId ?? this.categoryId,
      num: num ?? this.num,
      isAdult: isAdult ?? this.isAdult,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (streamId.present) {
      map['stream_id'] = Variable<int>(streamId.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (streamIcon.present) {
      map['stream_icon'] = Variable<String>(streamIcon.value);
    }
    if (epgChannelId.present) {
      map['epg_channel_id'] = Variable<String>(epgChannelId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (num.present) {
      map['num'] = Variable<int>(num.value);
    }
    if (isAdult.present) {
      map['is_adult'] = Variable<bool>(isAdult.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LiveStreamsCompanion(')
          ..write('streamId: $streamId, ')
          ..write('providerId: $providerId, ')
          ..write('name: $name, ')
          ..write('streamIcon: $streamIcon, ')
          ..write('epgChannelId: $epgChannelId, ')
          ..write('categoryId: $categoryId, ')
          ..write('num: $num, ')
          ..write('isAdult: $isAdult, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VodStreamsTable extends VodStreams
    with TableInfo<$VodStreamsTable, VodStream> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VodStreamsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _streamIdMeta = const VerificationMeta(
    'streamId',
  );
  @override
  late final GeneratedColumn<int> streamId = GeneratedColumn<int>(
    'stream_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'REFERENCES providers(id) ON DELETE CASCADE NOT NULL',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _streamIconMeta = const VerificationMeta(
    'streamIcon',
  );
  @override
  late final GeneratedColumn<String> streamIcon = GeneratedColumn<String>(
    'stream_icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _containerExtensionMeta =
      const VerificationMeta('containerExtension');
  @override
  late final GeneratedColumn<String> containerExtension =
      GeneratedColumn<String>(
        'container_extension',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addedMeta = const VerificationMeta('added');
  @override
  late final GeneratedColumn<DateTime> added = GeneratedColumn<DateTime>(
    'added',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    streamId,
    providerId,
    name,
    streamIcon,
    containerExtension,
    categoryId,
    rating,
    added,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vod_streams';
  @override
  VerificationContext validateIntegrity(
    Insertable<VodStream> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('stream_id')) {
      context.handle(
        _streamIdMeta,
        streamId.isAcceptableOrUnknown(data['stream_id']!, _streamIdMeta),
      );
    } else if (isInserting) {
      context.missing(_streamIdMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('stream_icon')) {
      context.handle(
        _streamIconMeta,
        streamIcon.isAcceptableOrUnknown(data['stream_icon']!, _streamIconMeta),
      );
    }
    if (data.containsKey('container_extension')) {
      context.handle(
        _containerExtensionMeta,
        containerExtension.isAcceptableOrUnknown(
          data['container_extension']!,
          _containerExtensionMeta,
        ),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('added')) {
      context.handle(
        _addedMeta,
        added.isAcceptableOrUnknown(data['added']!, _addedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {streamId, providerId};
  @override
  VodStream map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VodStream(
      streamId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stream_id'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      streamIcon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stream_icon'],
      ),
      containerExtension: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}container_extension'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      ),
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rating'],
      ),
      added: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added'],
      ),
    );
  }

  @override
  $VodStreamsTable createAlias(String alias) {
    return $VodStreamsTable(attachedDatabase, alias);
  }
}

class VodStream extends DataClass implements Insertable<VodStream> {
  final int streamId;
  final String providerId;
  final String name;
  final String? streamIcon;
  final String? containerExtension;
  final int? categoryId;
  final double? rating;
  final DateTime? added;
  const VodStream({
    required this.streamId,
    required this.providerId,
    required this.name,
    this.streamIcon,
    this.containerExtension,
    this.categoryId,
    this.rating,
    this.added,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['stream_id'] = Variable<int>(streamId);
    map['provider_id'] = Variable<String>(providerId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || streamIcon != null) {
      map['stream_icon'] = Variable<String>(streamIcon);
    }
    if (!nullToAbsent || containerExtension != null) {
      map['container_extension'] = Variable<String>(containerExtension);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<double>(rating);
    }
    if (!nullToAbsent || added != null) {
      map['added'] = Variable<DateTime>(added);
    }
    return map;
  }

  VodStreamsCompanion toCompanion(bool nullToAbsent) {
    return VodStreamsCompanion(
      streamId: Value(streamId),
      providerId: Value(providerId),
      name: Value(name),
      streamIcon: streamIcon == null && nullToAbsent
          ? const Value.absent()
          : Value(streamIcon),
      containerExtension: containerExtension == null && nullToAbsent
          ? const Value.absent()
          : Value(containerExtension),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      rating: rating == null && nullToAbsent
          ? const Value.absent()
          : Value(rating),
      added: added == null && nullToAbsent
          ? const Value.absent()
          : Value(added),
    );
  }

  factory VodStream.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VodStream(
      streamId: serializer.fromJson<int>(json['streamId']),
      providerId: serializer.fromJson<String>(json['providerId']),
      name: serializer.fromJson<String>(json['name']),
      streamIcon: serializer.fromJson<String?>(json['streamIcon']),
      containerExtension: serializer.fromJson<String?>(
        json['containerExtension'],
      ),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      rating: serializer.fromJson<double?>(json['rating']),
      added: serializer.fromJson<DateTime?>(json['added']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'streamId': serializer.toJson<int>(streamId),
      'providerId': serializer.toJson<String>(providerId),
      'name': serializer.toJson<String>(name),
      'streamIcon': serializer.toJson<String?>(streamIcon),
      'containerExtension': serializer.toJson<String?>(containerExtension),
      'categoryId': serializer.toJson<int?>(categoryId),
      'rating': serializer.toJson<double?>(rating),
      'added': serializer.toJson<DateTime?>(added),
    };
  }

  VodStream copyWith({
    int? streamId,
    String? providerId,
    String? name,
    Value<String?> streamIcon = const Value.absent(),
    Value<String?> containerExtension = const Value.absent(),
    Value<int?> categoryId = const Value.absent(),
    Value<double?> rating = const Value.absent(),
    Value<DateTime?> added = const Value.absent(),
  }) => VodStream(
    streamId: streamId ?? this.streamId,
    providerId: providerId ?? this.providerId,
    name: name ?? this.name,
    streamIcon: streamIcon.present ? streamIcon.value : this.streamIcon,
    containerExtension: containerExtension.present
        ? containerExtension.value
        : this.containerExtension,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    rating: rating.present ? rating.value : this.rating,
    added: added.present ? added.value : this.added,
  );
  VodStream copyWithCompanion(VodStreamsCompanion data) {
    return VodStream(
      streamId: data.streamId.present ? data.streamId.value : this.streamId,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      name: data.name.present ? data.name.value : this.name,
      streamIcon: data.streamIcon.present
          ? data.streamIcon.value
          : this.streamIcon,
      containerExtension: data.containerExtension.present
          ? data.containerExtension.value
          : this.containerExtension,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      rating: data.rating.present ? data.rating.value : this.rating,
      added: data.added.present ? data.added.value : this.added,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VodStream(')
          ..write('streamId: $streamId, ')
          ..write('providerId: $providerId, ')
          ..write('name: $name, ')
          ..write('streamIcon: $streamIcon, ')
          ..write('containerExtension: $containerExtension, ')
          ..write('categoryId: $categoryId, ')
          ..write('rating: $rating, ')
          ..write('added: $added')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    streamId,
    providerId,
    name,
    streamIcon,
    containerExtension,
    categoryId,
    rating,
    added,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VodStream &&
          other.streamId == this.streamId &&
          other.providerId == this.providerId &&
          other.name == this.name &&
          other.streamIcon == this.streamIcon &&
          other.containerExtension == this.containerExtension &&
          other.categoryId == this.categoryId &&
          other.rating == this.rating &&
          other.added == this.added);
}

class VodStreamsCompanion extends UpdateCompanion<VodStream> {
  final Value<int> streamId;
  final Value<String> providerId;
  final Value<String> name;
  final Value<String?> streamIcon;
  final Value<String?> containerExtension;
  final Value<int?> categoryId;
  final Value<double?> rating;
  final Value<DateTime?> added;
  final Value<int> rowid;
  const VodStreamsCompanion({
    this.streamId = const Value.absent(),
    this.providerId = const Value.absent(),
    this.name = const Value.absent(),
    this.streamIcon = const Value.absent(),
    this.containerExtension = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.rating = const Value.absent(),
    this.added = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VodStreamsCompanion.insert({
    required int streamId,
    required String providerId,
    required String name,
    this.streamIcon = const Value.absent(),
    this.containerExtension = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.rating = const Value.absent(),
    this.added = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : streamId = Value(streamId),
       providerId = Value(providerId),
       name = Value(name);
  static Insertable<VodStream> custom({
    Expression<int>? streamId,
    Expression<String>? providerId,
    Expression<String>? name,
    Expression<String>? streamIcon,
    Expression<String>? containerExtension,
    Expression<int>? categoryId,
    Expression<double>? rating,
    Expression<DateTime>? added,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (streamId != null) 'stream_id': streamId,
      if (providerId != null) 'provider_id': providerId,
      if (name != null) 'name': name,
      if (streamIcon != null) 'stream_icon': streamIcon,
      if (containerExtension != null) 'container_extension': containerExtension,
      if (categoryId != null) 'category_id': categoryId,
      if (rating != null) 'rating': rating,
      if (added != null) 'added': added,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VodStreamsCompanion copyWith({
    Value<int>? streamId,
    Value<String>? providerId,
    Value<String>? name,
    Value<String?>? streamIcon,
    Value<String?>? containerExtension,
    Value<int?>? categoryId,
    Value<double?>? rating,
    Value<DateTime?>? added,
    Value<int>? rowid,
  }) {
    return VodStreamsCompanion(
      streamId: streamId ?? this.streamId,
      providerId: providerId ?? this.providerId,
      name: name ?? this.name,
      streamIcon: streamIcon ?? this.streamIcon,
      containerExtension: containerExtension ?? this.containerExtension,
      categoryId: categoryId ?? this.categoryId,
      rating: rating ?? this.rating,
      added: added ?? this.added,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (streamId.present) {
      map['stream_id'] = Variable<int>(streamId.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (streamIcon.present) {
      map['stream_icon'] = Variable<String>(streamIcon.value);
    }
    if (containerExtension.present) {
      map['container_extension'] = Variable<String>(containerExtension.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (added.present) {
      map['added'] = Variable<DateTime>(added.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VodStreamsCompanion(')
          ..write('streamId: $streamId, ')
          ..write('providerId: $providerId, ')
          ..write('name: $name, ')
          ..write('streamIcon: $streamIcon, ')
          ..write('containerExtension: $containerExtension, ')
          ..write('categoryId: $categoryId, ')
          ..write('rating: $rating, ')
          ..write('added: $added, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SeriesTable extends Series with TableInfo<$SeriesTable, Sery> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<int> seriesId = GeneratedColumn<int>(
    'series_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'REFERENCES providers(id) ON DELETE CASCADE NOT NULL',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverMeta = const VerificationMeta('cover');
  @override
  late final GeneratedColumn<String> cover = GeneratedColumn<String>(
    'cover',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _plotMeta = const VerificationMeta('plot');
  @override
  late final GeneratedColumn<String> plot = GeneratedColumn<String>(
    'plot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _castMeta = const VerificationMeta('cast');
  @override
  late final GeneratedColumn<String> cast = GeneratedColumn<String>(
    'cast',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _directorMeta = const VerificationMeta(
    'director',
  );
  @override
  late final GeneratedColumn<String> director = GeneratedColumn<String>(
    'director',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _genreMeta = const VerificationMeta('genre');
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
    'genre',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _releaseDateMeta = const VerificationMeta(
    'releaseDate',
  );
  @override
  late final GeneratedColumn<String> releaseDate = GeneratedColumn<String>(
    'release_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastModifiedMeta = const VerificationMeta(
    'lastModified',
  );
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
    'last_modified',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    seriesId,
    providerId,
    name,
    cover,
    plot,
    cast,
    director,
    genre,
    releaseDate,
    lastModified,
    categoryId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'series';
  @override
  VerificationContext validateIntegrity(
    Insertable<Sery> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    } else if (isInserting) {
      context.missing(_seriesIdMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('cover')) {
      context.handle(
        _coverMeta,
        cover.isAcceptableOrUnknown(data['cover']!, _coverMeta),
      );
    }
    if (data.containsKey('plot')) {
      context.handle(
        _plotMeta,
        plot.isAcceptableOrUnknown(data['plot']!, _plotMeta),
      );
    }
    if (data.containsKey('cast')) {
      context.handle(
        _castMeta,
        cast.isAcceptableOrUnknown(data['cast']!, _castMeta),
      );
    }
    if (data.containsKey('director')) {
      context.handle(
        _directorMeta,
        director.isAcceptableOrUnknown(data['director']!, _directorMeta),
      );
    }
    if (data.containsKey('genre')) {
      context.handle(
        _genreMeta,
        genre.isAcceptableOrUnknown(data['genre']!, _genreMeta),
      );
    }
    if (data.containsKey('release_date')) {
      context.handle(
        _releaseDateMeta,
        releaseDate.isAcceptableOrUnknown(
          data['release_date']!,
          _releaseDateMeta,
        ),
      );
    }
    if (data.containsKey('last_modified')) {
      context.handle(
        _lastModifiedMeta,
        lastModified.isAcceptableOrUnknown(
          data['last_modified']!,
          _lastModifiedMeta,
        ),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {seriesId, providerId};
  @override
  Sery map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Sery(
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}series_id'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      cover: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover'],
      ),
      plot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plot'],
      ),
      cast: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cast'],
      ),
      director: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}director'],
      ),
      genre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genre'],
      ),
      releaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}release_date'],
      ),
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      ),
    );
  }

  @override
  $SeriesTable createAlias(String alias) {
    return $SeriesTable(attachedDatabase, alias);
  }
}

class Sery extends DataClass implements Insertable<Sery> {
  final int seriesId;
  final String providerId;
  final String name;
  final String? cover;
  final String? plot;
  final String? cast;
  final String? director;
  final String? genre;
  final String? releaseDate;
  final DateTime? lastModified;
  final int? categoryId;
  const Sery({
    required this.seriesId,
    required this.providerId,
    required this.name,
    this.cover,
    this.plot,
    this.cast,
    this.director,
    this.genre,
    this.releaseDate,
    this.lastModified,
    this.categoryId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['series_id'] = Variable<int>(seriesId);
    map['provider_id'] = Variable<String>(providerId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || cover != null) {
      map['cover'] = Variable<String>(cover);
    }
    if (!nullToAbsent || plot != null) {
      map['plot'] = Variable<String>(plot);
    }
    if (!nullToAbsent || cast != null) {
      map['cast'] = Variable<String>(cast);
    }
    if (!nullToAbsent || director != null) {
      map['director'] = Variable<String>(director);
    }
    if (!nullToAbsent || genre != null) {
      map['genre'] = Variable<String>(genre);
    }
    if (!nullToAbsent || releaseDate != null) {
      map['release_date'] = Variable<String>(releaseDate);
    }
    if (!nullToAbsent || lastModified != null) {
      map['last_modified'] = Variable<DateTime>(lastModified);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    return map;
  }

  SeriesCompanion toCompanion(bool nullToAbsent) {
    return SeriesCompanion(
      seriesId: Value(seriesId),
      providerId: Value(providerId),
      name: Value(name),
      cover: cover == null && nullToAbsent
          ? const Value.absent()
          : Value(cover),
      plot: plot == null && nullToAbsent ? const Value.absent() : Value(plot),
      cast: cast == null && nullToAbsent ? const Value.absent() : Value(cast),
      director: director == null && nullToAbsent
          ? const Value.absent()
          : Value(director),
      genre: genre == null && nullToAbsent
          ? const Value.absent()
          : Value(genre),
      releaseDate: releaseDate == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseDate),
      lastModified: lastModified == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModified),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
    );
  }

  factory Sery.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Sery(
      seriesId: serializer.fromJson<int>(json['seriesId']),
      providerId: serializer.fromJson<String>(json['providerId']),
      name: serializer.fromJson<String>(json['name']),
      cover: serializer.fromJson<String?>(json['cover']),
      plot: serializer.fromJson<String?>(json['plot']),
      cast: serializer.fromJson<String?>(json['cast']),
      director: serializer.fromJson<String?>(json['director']),
      genre: serializer.fromJson<String?>(json['genre']),
      releaseDate: serializer.fromJson<String?>(json['releaseDate']),
      lastModified: serializer.fromJson<DateTime?>(json['lastModified']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seriesId': serializer.toJson<int>(seriesId),
      'providerId': serializer.toJson<String>(providerId),
      'name': serializer.toJson<String>(name),
      'cover': serializer.toJson<String?>(cover),
      'plot': serializer.toJson<String?>(plot),
      'cast': serializer.toJson<String?>(cast),
      'director': serializer.toJson<String?>(director),
      'genre': serializer.toJson<String?>(genre),
      'releaseDate': serializer.toJson<String?>(releaseDate),
      'lastModified': serializer.toJson<DateTime?>(lastModified),
      'categoryId': serializer.toJson<int?>(categoryId),
    };
  }

  Sery copyWith({
    int? seriesId,
    String? providerId,
    String? name,
    Value<String?> cover = const Value.absent(),
    Value<String?> plot = const Value.absent(),
    Value<String?> cast = const Value.absent(),
    Value<String?> director = const Value.absent(),
    Value<String?> genre = const Value.absent(),
    Value<String?> releaseDate = const Value.absent(),
    Value<DateTime?> lastModified = const Value.absent(),
    Value<int?> categoryId = const Value.absent(),
  }) => Sery(
    seriesId: seriesId ?? this.seriesId,
    providerId: providerId ?? this.providerId,
    name: name ?? this.name,
    cover: cover.present ? cover.value : this.cover,
    plot: plot.present ? plot.value : this.plot,
    cast: cast.present ? cast.value : this.cast,
    director: director.present ? director.value : this.director,
    genre: genre.present ? genre.value : this.genre,
    releaseDate: releaseDate.present ? releaseDate.value : this.releaseDate,
    lastModified: lastModified.present ? lastModified.value : this.lastModified,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
  );
  Sery copyWithCompanion(SeriesCompanion data) {
    return Sery(
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      name: data.name.present ? data.name.value : this.name,
      cover: data.cover.present ? data.cover.value : this.cover,
      plot: data.plot.present ? data.plot.value : this.plot,
      cast: data.cast.present ? data.cast.value : this.cast,
      director: data.director.present ? data.director.value : this.director,
      genre: data.genre.present ? data.genre.value : this.genre,
      releaseDate: data.releaseDate.present
          ? data.releaseDate.value
          : this.releaseDate,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Sery(')
          ..write('seriesId: $seriesId, ')
          ..write('providerId: $providerId, ')
          ..write('name: $name, ')
          ..write('cover: $cover, ')
          ..write('plot: $plot, ')
          ..write('cast: $cast, ')
          ..write('director: $director, ')
          ..write('genre: $genre, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('lastModified: $lastModified, ')
          ..write('categoryId: $categoryId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    seriesId,
    providerId,
    name,
    cover,
    plot,
    cast,
    director,
    genre,
    releaseDate,
    lastModified,
    categoryId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Sery &&
          other.seriesId == this.seriesId &&
          other.providerId == this.providerId &&
          other.name == this.name &&
          other.cover == this.cover &&
          other.plot == this.plot &&
          other.cast == this.cast &&
          other.director == this.director &&
          other.genre == this.genre &&
          other.releaseDate == this.releaseDate &&
          other.lastModified == this.lastModified &&
          other.categoryId == this.categoryId);
}

class SeriesCompanion extends UpdateCompanion<Sery> {
  final Value<int> seriesId;
  final Value<String> providerId;
  final Value<String> name;
  final Value<String?> cover;
  final Value<String?> plot;
  final Value<String?> cast;
  final Value<String?> director;
  final Value<String?> genre;
  final Value<String?> releaseDate;
  final Value<DateTime?> lastModified;
  final Value<int?> categoryId;
  final Value<int> rowid;
  const SeriesCompanion({
    this.seriesId = const Value.absent(),
    this.providerId = const Value.absent(),
    this.name = const Value.absent(),
    this.cover = const Value.absent(),
    this.plot = const Value.absent(),
    this.cast = const Value.absent(),
    this.director = const Value.absent(),
    this.genre = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SeriesCompanion.insert({
    required int seriesId,
    required String providerId,
    required String name,
    this.cover = const Value.absent(),
    this.plot = const Value.absent(),
    this.cast = const Value.absent(),
    this.director = const Value.absent(),
    this.genre = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : seriesId = Value(seriesId),
       providerId = Value(providerId),
       name = Value(name);
  static Insertable<Sery> custom({
    Expression<int>? seriesId,
    Expression<String>? providerId,
    Expression<String>? name,
    Expression<String>? cover,
    Expression<String>? plot,
    Expression<String>? cast,
    Expression<String>? director,
    Expression<String>? genre,
    Expression<String>? releaseDate,
    Expression<DateTime>? lastModified,
    Expression<int>? categoryId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (seriesId != null) 'series_id': seriesId,
      if (providerId != null) 'provider_id': providerId,
      if (name != null) 'name': name,
      if (cover != null) 'cover': cover,
      if (plot != null) 'plot': plot,
      if (cast != null) 'cast': cast,
      if (director != null) 'director': director,
      if (genre != null) 'genre': genre,
      if (releaseDate != null) 'release_date': releaseDate,
      if (lastModified != null) 'last_modified': lastModified,
      if (categoryId != null) 'category_id': categoryId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SeriesCompanion copyWith({
    Value<int>? seriesId,
    Value<String>? providerId,
    Value<String>? name,
    Value<String?>? cover,
    Value<String?>? plot,
    Value<String?>? cast,
    Value<String?>? director,
    Value<String?>? genre,
    Value<String?>? releaseDate,
    Value<DateTime?>? lastModified,
    Value<int?>? categoryId,
    Value<int>? rowid,
  }) {
    return SeriesCompanion(
      seriesId: seriesId ?? this.seriesId,
      providerId: providerId ?? this.providerId,
      name: name ?? this.name,
      cover: cover ?? this.cover,
      plot: plot ?? this.plot,
      cast: cast ?? this.cast,
      director: director ?? this.director,
      genre: genre ?? this.genre,
      releaseDate: releaseDate ?? this.releaseDate,
      lastModified: lastModified ?? this.lastModified,
      categoryId: categoryId ?? this.categoryId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seriesId.present) {
      map['series_id'] = Variable<int>(seriesId.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (cover.present) {
      map['cover'] = Variable<String>(cover.value);
    }
    if (plot.present) {
      map['plot'] = Variable<String>(plot.value);
    }
    if (cast.present) {
      map['cast'] = Variable<String>(cast.value);
    }
    if (director.present) {
      map['director'] = Variable<String>(director.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (releaseDate.present) {
      map['release_date'] = Variable<String>(releaseDate.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeriesCompanion(')
          ..write('seriesId: $seriesId, ')
          ..write('providerId: $providerId, ')
          ..write('name: $name, ')
          ..write('cover: $cover, ')
          ..write('plot: $plot, ')
          ..write('cast: $cast, ')
          ..write('director: $director, ')
          ..write('genre: $genre, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('lastModified: $lastModified, ')
          ..write('categoryId: $categoryId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EpisodesTable extends Episodes with TableInfo<$EpisodesTable, Episode> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EpisodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<int> seriesId = GeneratedColumn<int>(
    'series_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'REFERENCES providers(id) ON DELETE CASCADE NOT NULL',
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _containerExtensionMeta =
      const VerificationMeta('containerExtension');
  @override
  late final GeneratedColumn<String> containerExtension =
      GeneratedColumn<String>(
        'container_extension',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _infoMeta = const VerificationMeta('info');
  @override
  late final GeneratedColumn<String> info = GeneratedColumn<String>(
    'info',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seasonMeta = const VerificationMeta('season');
  @override
  late final GeneratedColumn<int> season = GeneratedColumn<int>(
    'season',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _episodeMeta = const VerificationMeta(
    'episode',
  );
  @override
  late final GeneratedColumn<int> episode = GeneratedColumn<int>(
    'episode',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
    'duration',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    seriesId,
    providerId,
    title,
    containerExtension,
    info,
    season,
    episode,
    duration,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'episodes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Episode> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    } else if (isInserting) {
      context.missing(_seriesIdMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('container_extension')) {
      context.handle(
        _containerExtensionMeta,
        containerExtension.isAcceptableOrUnknown(
          data['container_extension']!,
          _containerExtensionMeta,
        ),
      );
    }
    if (data.containsKey('info')) {
      context.handle(
        _infoMeta,
        info.isAcceptableOrUnknown(data['info']!, _infoMeta),
      );
    }
    if (data.containsKey('season')) {
      context.handle(
        _seasonMeta,
        season.isAcceptableOrUnknown(data['season']!, _seasonMeta),
      );
    }
    if (data.containsKey('episode')) {
      context.handle(
        _episodeMeta,
        episode.isAcceptableOrUnknown(data['episode']!, _episodeMeta),
      );
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id, providerId};
  @override
  Episode map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Episode(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}series_id'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      containerExtension: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}container_extension'],
      ),
      info: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}info'],
      ),
      season: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}season'],
      ),
      episode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}episode'],
      ),
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration'],
      ),
    );
  }

  @override
  $EpisodesTable createAlias(String alias) {
    return $EpisodesTable(attachedDatabase, alias);
  }
}

class Episode extends DataClass implements Insertable<Episode> {
  final int id;
  final int seriesId;
  final String providerId;
  final String title;
  final String? containerExtension;
  final String? info;
  final int? season;
  final int? episode;
  final int? duration;
  const Episode({
    required this.id,
    required this.seriesId,
    required this.providerId,
    required this.title,
    this.containerExtension,
    this.info,
    this.season,
    this.episode,
    this.duration,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['series_id'] = Variable<int>(seriesId);
    map['provider_id'] = Variable<String>(providerId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || containerExtension != null) {
      map['container_extension'] = Variable<String>(containerExtension);
    }
    if (!nullToAbsent || info != null) {
      map['info'] = Variable<String>(info);
    }
    if (!nullToAbsent || season != null) {
      map['season'] = Variable<int>(season);
    }
    if (!nullToAbsent || episode != null) {
      map['episode'] = Variable<int>(episode);
    }
    if (!nullToAbsent || duration != null) {
      map['duration'] = Variable<int>(duration);
    }
    return map;
  }

  EpisodesCompanion toCompanion(bool nullToAbsent) {
    return EpisodesCompanion(
      id: Value(id),
      seriesId: Value(seriesId),
      providerId: Value(providerId),
      title: Value(title),
      containerExtension: containerExtension == null && nullToAbsent
          ? const Value.absent()
          : Value(containerExtension),
      info: info == null && nullToAbsent ? const Value.absent() : Value(info),
      season: season == null && nullToAbsent
          ? const Value.absent()
          : Value(season),
      episode: episode == null && nullToAbsent
          ? const Value.absent()
          : Value(episode),
      duration: duration == null && nullToAbsent
          ? const Value.absent()
          : Value(duration),
    );
  }

  factory Episode.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Episode(
      id: serializer.fromJson<int>(json['id']),
      seriesId: serializer.fromJson<int>(json['seriesId']),
      providerId: serializer.fromJson<String>(json['providerId']),
      title: serializer.fromJson<String>(json['title']),
      containerExtension: serializer.fromJson<String?>(
        json['containerExtension'],
      ),
      info: serializer.fromJson<String?>(json['info']),
      season: serializer.fromJson<int?>(json['season']),
      episode: serializer.fromJson<int?>(json['episode']),
      duration: serializer.fromJson<int?>(json['duration']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'seriesId': serializer.toJson<int>(seriesId),
      'providerId': serializer.toJson<String>(providerId),
      'title': serializer.toJson<String>(title),
      'containerExtension': serializer.toJson<String?>(containerExtension),
      'info': serializer.toJson<String?>(info),
      'season': serializer.toJson<int?>(season),
      'episode': serializer.toJson<int?>(episode),
      'duration': serializer.toJson<int?>(duration),
    };
  }

  Episode copyWith({
    int? id,
    int? seriesId,
    String? providerId,
    String? title,
    Value<String?> containerExtension = const Value.absent(),
    Value<String?> info = const Value.absent(),
    Value<int?> season = const Value.absent(),
    Value<int?> episode = const Value.absent(),
    Value<int?> duration = const Value.absent(),
  }) => Episode(
    id: id ?? this.id,
    seriesId: seriesId ?? this.seriesId,
    providerId: providerId ?? this.providerId,
    title: title ?? this.title,
    containerExtension: containerExtension.present
        ? containerExtension.value
        : this.containerExtension,
    info: info.present ? info.value : this.info,
    season: season.present ? season.value : this.season,
    episode: episode.present ? episode.value : this.episode,
    duration: duration.present ? duration.value : this.duration,
  );
  Episode copyWithCompanion(EpisodesCompanion data) {
    return Episode(
      id: data.id.present ? data.id.value : this.id,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      title: data.title.present ? data.title.value : this.title,
      containerExtension: data.containerExtension.present
          ? data.containerExtension.value
          : this.containerExtension,
      info: data.info.present ? data.info.value : this.info,
      season: data.season.present ? data.season.value : this.season,
      episode: data.episode.present ? data.episode.value : this.episode,
      duration: data.duration.present ? data.duration.value : this.duration,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Episode(')
          ..write('id: $id, ')
          ..write('seriesId: $seriesId, ')
          ..write('providerId: $providerId, ')
          ..write('title: $title, ')
          ..write('containerExtension: $containerExtension, ')
          ..write('info: $info, ')
          ..write('season: $season, ')
          ..write('episode: $episode, ')
          ..write('duration: $duration')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    seriesId,
    providerId,
    title,
    containerExtension,
    info,
    season,
    episode,
    duration,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Episode &&
          other.id == this.id &&
          other.seriesId == this.seriesId &&
          other.providerId == this.providerId &&
          other.title == this.title &&
          other.containerExtension == this.containerExtension &&
          other.info == this.info &&
          other.season == this.season &&
          other.episode == this.episode &&
          other.duration == this.duration);
}

class EpisodesCompanion extends UpdateCompanion<Episode> {
  final Value<int> id;
  final Value<int> seriesId;
  final Value<String> providerId;
  final Value<String> title;
  final Value<String?> containerExtension;
  final Value<String?> info;
  final Value<int?> season;
  final Value<int?> episode;
  final Value<int?> duration;
  final Value<int> rowid;
  const EpisodesCompanion({
    this.id = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.providerId = const Value.absent(),
    this.title = const Value.absent(),
    this.containerExtension = const Value.absent(),
    this.info = const Value.absent(),
    this.season = const Value.absent(),
    this.episode = const Value.absent(),
    this.duration = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EpisodesCompanion.insert({
    required int id,
    required int seriesId,
    required String providerId,
    required String title,
    this.containerExtension = const Value.absent(),
    this.info = const Value.absent(),
    this.season = const Value.absent(),
    this.episode = const Value.absent(),
    this.duration = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       seriesId = Value(seriesId),
       providerId = Value(providerId),
       title = Value(title);
  static Insertable<Episode> custom({
    Expression<int>? id,
    Expression<int>? seriesId,
    Expression<String>? providerId,
    Expression<String>? title,
    Expression<String>? containerExtension,
    Expression<String>? info,
    Expression<int>? season,
    Expression<int>? episode,
    Expression<int>? duration,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (seriesId != null) 'series_id': seriesId,
      if (providerId != null) 'provider_id': providerId,
      if (title != null) 'title': title,
      if (containerExtension != null) 'container_extension': containerExtension,
      if (info != null) 'info': info,
      if (season != null) 'season': season,
      if (episode != null) 'episode': episode,
      if (duration != null) 'duration': duration,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EpisodesCompanion copyWith({
    Value<int>? id,
    Value<int>? seriesId,
    Value<String>? providerId,
    Value<String>? title,
    Value<String?>? containerExtension,
    Value<String?>? info,
    Value<int?>? season,
    Value<int?>? episode,
    Value<int?>? duration,
    Value<int>? rowid,
  }) {
    return EpisodesCompanion(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      providerId: providerId ?? this.providerId,
      title: title ?? this.title,
      containerExtension: containerExtension ?? this.containerExtension,
      info: info ?? this.info,
      season: season ?? this.season,
      episode: episode ?? this.episode,
      duration: duration ?? this.duration,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<int>(seriesId.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (containerExtension.present) {
      map['container_extension'] = Variable<String>(containerExtension.value);
    }
    if (info.present) {
      map['info'] = Variable<String>(info.value);
    }
    if (season.present) {
      map['season'] = Variable<int>(season.value);
    }
    if (episode.present) {
      map['episode'] = Variable<int>(episode.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EpisodesCompanion(')
          ..write('id: $id, ')
          ..write('seriesId: $seriesId, ')
          ..write('providerId: $providerId, ')
          ..write('title: $title, ')
          ..write('containerExtension: $containerExtension, ')
          ..write('info: $info, ')
          ..write('season: $season, ')
          ..write('episode: $episode, ')
          ..write('duration: $duration, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EpgEventsTable extends EpgEvents
    with TableInfo<$EpgEventsTable, EpgEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EpgEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'REFERENCES providers(id) ON DELETE CASCADE NOT NULL',
  );
  static const VerificationMeta _channelIdMeta = const VerificationMeta(
    'channelId',
  );
  @override
  late final GeneratedColumn<String> channelId = GeneratedColumn<String>(
    'channel_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startMeta = const VerificationMeta('start');
  @override
  late final GeneratedColumn<DateTime> start = GeneratedColumn<DateTime>(
    'start',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endMeta = const VerificationMeta('end');
  @override
  late final GeneratedColumn<DateTime> end = GeneratedColumn<DateTime>(
    'end',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    providerId,
    channelId,
    title,
    description,
    start,
    end,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'epg_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<EpgEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('channel_id')) {
      context.handle(
        _channelIdMeta,
        channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_channelIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('start')) {
      context.handle(
        _startMeta,
        start.isAcceptableOrUnknown(data['start']!, _startMeta),
      );
    } else if (isInserting) {
      context.missing(_startMeta);
    }
    if (data.containsKey('end')) {
      context.handle(
        _endMeta,
        end.isAcceptableOrUnknown(data['end']!, _endMeta),
      );
    } else if (isInserting) {
      context.missing(_endMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {providerId, channelId, start};
  @override
  EpgEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EpgEvent(
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      channelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      start: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start'],
      )!,
      end: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end'],
      )!,
    );
  }

  @override
  $EpgEventsTable createAlias(String alias) {
    return $EpgEventsTable(attachedDatabase, alias);
  }
}

class EpgEvent extends DataClass implements Insertable<EpgEvent> {
  final String providerId;
  final String channelId;
  final String title;
  final String? description;
  final DateTime start;
  final DateTime end;
  const EpgEvent({
    required this.providerId,
    required this.channelId,
    required this.title,
    this.description,
    required this.start,
    required this.end,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['provider_id'] = Variable<String>(providerId);
    map['channel_id'] = Variable<String>(channelId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['start'] = Variable<DateTime>(start);
    map['end'] = Variable<DateTime>(end);
    return map;
  }

  EpgEventsCompanion toCompanion(bool nullToAbsent) {
    return EpgEventsCompanion(
      providerId: Value(providerId),
      channelId: Value(channelId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      start: Value(start),
      end: Value(end),
    );
  }

  factory EpgEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EpgEvent(
      providerId: serializer.fromJson<String>(json['providerId']),
      channelId: serializer.fromJson<String>(json['channelId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      start: serializer.fromJson<DateTime>(json['start']),
      end: serializer.fromJson<DateTime>(json['end']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'providerId': serializer.toJson<String>(providerId),
      'channelId': serializer.toJson<String>(channelId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'start': serializer.toJson<DateTime>(start),
      'end': serializer.toJson<DateTime>(end),
    };
  }

  EpgEvent copyWith({
    String? providerId,
    String? channelId,
    String? title,
    Value<String?> description = const Value.absent(),
    DateTime? start,
    DateTime? end,
  }) => EpgEvent(
    providerId: providerId ?? this.providerId,
    channelId: channelId ?? this.channelId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    start: start ?? this.start,
    end: end ?? this.end,
  );
  EpgEvent copyWithCompanion(EpgEventsCompanion data) {
    return EpgEvent(
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      start: data.start.present ? data.start.value : this.start,
      end: data.end.present ? data.end.value : this.end,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EpgEvent(')
          ..write('providerId: $providerId, ')
          ..write('channelId: $channelId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('start: $start, ')
          ..write('end: $end')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(providerId, channelId, title, description, start, end);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EpgEvent &&
          other.providerId == this.providerId &&
          other.channelId == this.channelId &&
          other.title == this.title &&
          other.description == this.description &&
          other.start == this.start &&
          other.end == this.end);
}

class EpgEventsCompanion extends UpdateCompanion<EpgEvent> {
  final Value<String> providerId;
  final Value<String> channelId;
  final Value<String> title;
  final Value<String?> description;
  final Value<DateTime> start;
  final Value<DateTime> end;
  final Value<int> rowid;
  const EpgEventsCompanion({
    this.providerId = const Value.absent(),
    this.channelId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.start = const Value.absent(),
    this.end = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EpgEventsCompanion.insert({
    required String providerId,
    required String channelId,
    required String title,
    this.description = const Value.absent(),
    required DateTime start,
    required DateTime end,
    this.rowid = const Value.absent(),
  }) : providerId = Value(providerId),
       channelId = Value(channelId),
       title = Value(title),
       start = Value(start),
       end = Value(end);
  static Insertable<EpgEvent> custom({
    Expression<String>? providerId,
    Expression<String>? channelId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<DateTime>? start,
    Expression<DateTime>? end,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (providerId != null) 'provider_id': providerId,
      if (channelId != null) 'channel_id': channelId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EpgEventsCompanion copyWith({
    Value<String>? providerId,
    Value<String>? channelId,
    Value<String>? title,
    Value<String?>? description,
    Value<DateTime>? start,
    Value<DateTime>? end,
    Value<int>? rowid,
  }) {
    return EpgEventsCompanion(
      providerId: providerId ?? this.providerId,
      channelId: channelId ?? this.channelId,
      title: title ?? this.title,
      description: description ?? this.description,
      start: start ?? this.start,
      end: end ?? this.end,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (channelId.present) {
      map['channel_id'] = Variable<String>(channelId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (start.present) {
      map['start'] = Variable<DateTime>(start.value);
    }
    if (end.present) {
      map['end'] = Variable<DateTime>(end.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EpgEventsCompanion(')
          ..write('providerId: $providerId, ')
          ..write('channelId: $channelId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('start: $start, ')
          ..write('end: $end, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FavoritesTable extends Favorites
    with TableInfo<$FavoritesTable, Favorite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'REFERENCES providers(id) ON DELETE CASCADE NOT NULL',
  );
  static const VerificationMeta _contentIdMeta = const VerificationMeta(
    'contentId',
  );
  @override
  late final GeneratedColumn<int> contentId = GeneratedColumn<int>(
    'content_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  static const VerificationMeta _dateAddedMeta = const VerificationMeta(
    'dateAdded',
  );
  @override
  late final GeneratedColumn<DateTime> dateAdded = GeneratedColumn<DateTime>(
    'date_added',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    providerId,
    contentId,
    type,
    dateAdded,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorites';
  @override
  VerificationContext validateIntegrity(
    Insertable<Favorite> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('content_id')) {
      context.handle(
        _contentIdMeta,
        contentId.isAcceptableOrUnknown(data['content_id']!, _contentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_contentIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('date_added')) {
      context.handle(
        _dateAddedMeta,
        dateAdded.isAcceptableOrUnknown(data['date_added']!, _dateAddedMeta),
      );
    } else if (isInserting) {
      context.missing(_dateAddedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {providerId, contentId, type};
  @override
  Favorite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Favorite(
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      contentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}content_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      dateAdded: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_added'],
      )!,
    );
  }

  @override
  $FavoritesTable createAlias(String alias) {
    return $FavoritesTable(attachedDatabase, alias);
  }
}

class Favorite extends DataClass implements Insertable<Favorite> {
  final String providerId;
  final int contentId;
  final String type;
  final DateTime dateAdded;
  const Favorite({
    required this.providerId,
    required this.contentId,
    required this.type,
    required this.dateAdded,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['provider_id'] = Variable<String>(providerId);
    map['content_id'] = Variable<int>(contentId);
    map['type'] = Variable<String>(type);
    map['date_added'] = Variable<DateTime>(dateAdded);
    return map;
  }

  FavoritesCompanion toCompanion(bool nullToAbsent) {
    return FavoritesCompanion(
      providerId: Value(providerId),
      contentId: Value(contentId),
      type: Value(type),
      dateAdded: Value(dateAdded),
    );
  }

  factory Favorite.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Favorite(
      providerId: serializer.fromJson<String>(json['providerId']),
      contentId: serializer.fromJson<int>(json['contentId']),
      type: serializer.fromJson<String>(json['type']),
      dateAdded: serializer.fromJson<DateTime>(json['dateAdded']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'providerId': serializer.toJson<String>(providerId),
      'contentId': serializer.toJson<int>(contentId),
      'type': serializer.toJson<String>(type),
      'dateAdded': serializer.toJson<DateTime>(dateAdded),
    };
  }

  Favorite copyWith({
    String? providerId,
    int? contentId,
    String? type,
    DateTime? dateAdded,
  }) => Favorite(
    providerId: providerId ?? this.providerId,
    contentId: contentId ?? this.contentId,
    type: type ?? this.type,
    dateAdded: dateAdded ?? this.dateAdded,
  );
  Favorite copyWithCompanion(FavoritesCompanion data) {
    return Favorite(
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      contentId: data.contentId.present ? data.contentId.value : this.contentId,
      type: data.type.present ? data.type.value : this.type,
      dateAdded: data.dateAdded.present ? data.dateAdded.value : this.dateAdded,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Favorite(')
          ..write('providerId: $providerId, ')
          ..write('contentId: $contentId, ')
          ..write('type: $type, ')
          ..write('dateAdded: $dateAdded')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(providerId, contentId, type, dateAdded);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Favorite &&
          other.providerId == this.providerId &&
          other.contentId == this.contentId &&
          other.type == this.type &&
          other.dateAdded == this.dateAdded);
}

class FavoritesCompanion extends UpdateCompanion<Favorite> {
  final Value<String> providerId;
  final Value<int> contentId;
  final Value<String> type;
  final Value<DateTime> dateAdded;
  final Value<int> rowid;
  const FavoritesCompanion({
    this.providerId = const Value.absent(),
    this.contentId = const Value.absent(),
    this.type = const Value.absent(),
    this.dateAdded = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FavoritesCompanion.insert({
    required String providerId,
    required int contentId,
    required String type,
    required DateTime dateAdded,
    this.rowid = const Value.absent(),
  }) : providerId = Value(providerId),
       contentId = Value(contentId),
       type = Value(type),
       dateAdded = Value(dateAdded);
  static Insertable<Favorite> custom({
    Expression<String>? providerId,
    Expression<int>? contentId,
    Expression<String>? type,
    Expression<DateTime>? dateAdded,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (providerId != null) 'provider_id': providerId,
      if (contentId != null) 'content_id': contentId,
      if (type != null) 'type': type,
      if (dateAdded != null) 'date_added': dateAdded,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FavoritesCompanion copyWith({
    Value<String>? providerId,
    Value<int>? contentId,
    Value<String>? type,
    Value<DateTime>? dateAdded,
    Value<int>? rowid,
  }) {
    return FavoritesCompanion(
      providerId: providerId ?? this.providerId,
      contentId: contentId ?? this.contentId,
      type: type ?? this.type,
      dateAdded: dateAdded ?? this.dateAdded,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (contentId.present) {
      map['content_id'] = Variable<int>(contentId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (dateAdded.present) {
      map['date_added'] = Variable<DateTime>(dateAdded.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoritesCompanion(')
          ..write('providerId: $providerId, ')
          ..write('contentId: $contentId, ')
          ..write('type: $type, ')
          ..write('dateAdded: $dateAdded, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaybackHistoryTable extends PlaybackHistory
    with TableInfo<$PlaybackHistoryTable, PlaybackHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaybackHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'REFERENCES providers(id) ON DELETE CASCADE NOT NULL',
  );
  static const VerificationMeta _contentIdMeta = const VerificationMeta(
    'contentId',
  );
  @override
  late final GeneratedColumn<int> contentId = GeneratedColumn<int>(
    'content_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  static const VerificationMeta _positionSecondsMeta = const VerificationMeta(
    'positionSeconds',
  );
  @override
  late final GeneratedColumn<int> positionSeconds = GeneratedColumn<int>(
    'position_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastWatchedMeta = const VerificationMeta(
    'lastWatched',
  );
  @override
  late final GeneratedColumn<DateTime> lastWatched = GeneratedColumn<DateTime>(
    'last_watched',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    providerId,
    contentId,
    type,
    positionSeconds,
    durationSeconds,
    lastWatched,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playback_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaybackHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('content_id')) {
      context.handle(
        _contentIdMeta,
        contentId.isAcceptableOrUnknown(data['content_id']!, _contentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_contentIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('position_seconds')) {
      context.handle(
        _positionSecondsMeta,
        positionSeconds.isAcceptableOrUnknown(
          data['position_seconds']!,
          _positionSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_positionSecondsMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('last_watched')) {
      context.handle(
        _lastWatchedMeta,
        lastWatched.isAcceptableOrUnknown(
          data['last_watched']!,
          _lastWatchedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastWatchedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {providerId, contentId, type};
  @override
  PlaybackHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaybackHistoryData(
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      contentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}content_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      positionSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_seconds'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      ),
      lastWatched: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_watched'],
      )!,
    );
  }

  @override
  $PlaybackHistoryTable createAlias(String alias) {
    return $PlaybackHistoryTable(attachedDatabase, alias);
  }
}

class PlaybackHistoryData extends DataClass
    implements Insertable<PlaybackHistoryData> {
  final String providerId;
  final int contentId;
  final String type;
  final int positionSeconds;
  final int? durationSeconds;
  final DateTime lastWatched;
  const PlaybackHistoryData({
    required this.providerId,
    required this.contentId,
    required this.type,
    required this.positionSeconds,
    this.durationSeconds,
    required this.lastWatched,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['provider_id'] = Variable<String>(providerId);
    map['content_id'] = Variable<int>(contentId);
    map['type'] = Variable<String>(type);
    map['position_seconds'] = Variable<int>(positionSeconds);
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    map['last_watched'] = Variable<DateTime>(lastWatched);
    return map;
  }

  PlaybackHistoryCompanion toCompanion(bool nullToAbsent) {
    return PlaybackHistoryCompanion(
      providerId: Value(providerId),
      contentId: Value(contentId),
      type: Value(type),
      positionSeconds: Value(positionSeconds),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      lastWatched: Value(lastWatched),
    );
  }

  factory PlaybackHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaybackHistoryData(
      providerId: serializer.fromJson<String>(json['providerId']),
      contentId: serializer.fromJson<int>(json['contentId']),
      type: serializer.fromJson<String>(json['type']),
      positionSeconds: serializer.fromJson<int>(json['positionSeconds']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      lastWatched: serializer.fromJson<DateTime>(json['lastWatched']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'providerId': serializer.toJson<String>(providerId),
      'contentId': serializer.toJson<int>(contentId),
      'type': serializer.toJson<String>(type),
      'positionSeconds': serializer.toJson<int>(positionSeconds),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'lastWatched': serializer.toJson<DateTime>(lastWatched),
    };
  }

  PlaybackHistoryData copyWith({
    String? providerId,
    int? contentId,
    String? type,
    int? positionSeconds,
    Value<int?> durationSeconds = const Value.absent(),
    DateTime? lastWatched,
  }) => PlaybackHistoryData(
    providerId: providerId ?? this.providerId,
    contentId: contentId ?? this.contentId,
    type: type ?? this.type,
    positionSeconds: positionSeconds ?? this.positionSeconds,
    durationSeconds: durationSeconds.present
        ? durationSeconds.value
        : this.durationSeconds,
    lastWatched: lastWatched ?? this.lastWatched,
  );
  PlaybackHistoryData copyWithCompanion(PlaybackHistoryCompanion data) {
    return PlaybackHistoryData(
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      contentId: data.contentId.present ? data.contentId.value : this.contentId,
      type: data.type.present ? data.type.value : this.type,
      positionSeconds: data.positionSeconds.present
          ? data.positionSeconds.value
          : this.positionSeconds,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      lastWatched: data.lastWatched.present
          ? data.lastWatched.value
          : this.lastWatched,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackHistoryData(')
          ..write('providerId: $providerId, ')
          ..write('contentId: $contentId, ')
          ..write('type: $type, ')
          ..write('positionSeconds: $positionSeconds, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('lastWatched: $lastWatched')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    providerId,
    contentId,
    type,
    positionSeconds,
    durationSeconds,
    lastWatched,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaybackHistoryData &&
          other.providerId == this.providerId &&
          other.contentId == this.contentId &&
          other.type == this.type &&
          other.positionSeconds == this.positionSeconds &&
          other.durationSeconds == this.durationSeconds &&
          other.lastWatched == this.lastWatched);
}

class PlaybackHistoryCompanion extends UpdateCompanion<PlaybackHistoryData> {
  final Value<String> providerId;
  final Value<int> contentId;
  final Value<String> type;
  final Value<int> positionSeconds;
  final Value<int?> durationSeconds;
  final Value<DateTime> lastWatched;
  final Value<int> rowid;
  const PlaybackHistoryCompanion({
    this.providerId = const Value.absent(),
    this.contentId = const Value.absent(),
    this.type = const Value.absent(),
    this.positionSeconds = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.lastWatched = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaybackHistoryCompanion.insert({
    required String providerId,
    required int contentId,
    required String type,
    required int positionSeconds,
    this.durationSeconds = const Value.absent(),
    required DateTime lastWatched,
    this.rowid = const Value.absent(),
  }) : providerId = Value(providerId),
       contentId = Value(contentId),
       type = Value(type),
       positionSeconds = Value(positionSeconds),
       lastWatched = Value(lastWatched);
  static Insertable<PlaybackHistoryData> custom({
    Expression<String>? providerId,
    Expression<int>? contentId,
    Expression<String>? type,
    Expression<int>? positionSeconds,
    Expression<int>? durationSeconds,
    Expression<DateTime>? lastWatched,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (providerId != null) 'provider_id': providerId,
      if (contentId != null) 'content_id': contentId,
      if (type != null) 'type': type,
      if (positionSeconds != null) 'position_seconds': positionSeconds,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (lastWatched != null) 'last_watched': lastWatched,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaybackHistoryCompanion copyWith({
    Value<String>? providerId,
    Value<int>? contentId,
    Value<String>? type,
    Value<int>? positionSeconds,
    Value<int?>? durationSeconds,
    Value<DateTime>? lastWatched,
    Value<int>? rowid,
  }) {
    return PlaybackHistoryCompanion(
      providerId: providerId ?? this.providerId,
      contentId: contentId ?? this.contentId,
      type: type ?? this.type,
      positionSeconds: positionSeconds ?? this.positionSeconds,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      lastWatched: lastWatched ?? this.lastWatched,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (contentId.present) {
      map['content_id'] = Variable<int>(contentId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (positionSeconds.present) {
      map['position_seconds'] = Variable<int>(positionSeconds.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (lastWatched.present) {
      map['last_watched'] = Variable<DateTime>(lastWatched.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackHistoryCompanion(')
          ..write('providerId: $providerId, ')
          ..write('contentId: $contentId, ')
          ..write('type: $type, ')
          ..write('positionSeconds: $positionSeconds, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('lastWatched: $lastWatched, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$ProviderDatabase extends GeneratedDatabase {
  _$ProviderDatabase(QueryExecutor e) : super(e);
  $ProviderDatabaseManager get managers => $ProviderDatabaseManager(this);
  late final $ProviderProfilesTable providerProfiles = $ProviderProfilesTable(
    this,
  );
  late final $ProviderSecretsTable providerSecrets = $ProviderSecretsTable(
    this,
  );
  late final $StreamGroupsTable streamGroups = $StreamGroupsTable(this);
  late final $LiveStreamsTable liveStreams = $LiveStreamsTable(this);
  late final $VodStreamsTable vodStreams = $VodStreamsTable(this);
  late final $SeriesTable series = $SeriesTable(this);
  late final $EpisodesTable episodes = $EpisodesTable(this);
  late final $EpgEventsTable epgEvents = $EpgEventsTable(this);
  late final $FavoritesTable favorites = $FavoritesTable(this);
  late final $PlaybackHistoryTable playbackHistory = $PlaybackHistoryTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    providerProfiles,
    providerSecrets,
    streamGroups,
    liveStreams,
    vodStreams,
    series,
    episodes,
    epgEvents,
    favorites,
    playbackHistory,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'providers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('provider_secrets', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'providers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('stream_groups', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'providers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('live_streams', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'providers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('vod_streams', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'providers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('series', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'providers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('episodes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'providers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('epg_events', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'providers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('favorites', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'providers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('playback_history', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ProviderProfilesTableCreateCompanionBuilder =
    ProviderProfilesCompanion Function({
      required String id,
      required ProviderKind kind,
      required String displayName,
      required String lockedBase,
      Value<bool> needsUserAgent,
      Value<bool> allowSelfSignedTls,
      Value<bool> followRedirects,
      Value<Map<String, String>> configuration,
      Value<Map<String, String>> hints,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> lastOkAt,
      Value<String?> lastError,
      Value<int> rowid,
    });
typedef $$ProviderProfilesTableUpdateCompanionBuilder =
    ProviderProfilesCompanion Function({
      Value<String> id,
      Value<ProviderKind> kind,
      Value<String> displayName,
      Value<String> lockedBase,
      Value<bool> needsUserAgent,
      Value<bool> allowSelfSignedTls,
      Value<bool> followRedirects,
      Value<Map<String, String>> configuration,
      Value<Map<String, String>> hints,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> lastOkAt,
      Value<String?> lastError,
      Value<int> rowid,
    });

final class $$ProviderProfilesTableReferences
    extends
        BaseReferences<
          _$ProviderDatabase,
          $ProviderProfilesTable,
          ProviderProfile
        > {
  $$ProviderProfilesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ProviderSecretsTable, List<ProviderSecret>>
  _providerSecretsRefsTable(_$ProviderDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.providerSecrets,
        aliasName: $_aliasNameGenerator(
          db.providerProfiles.id,
          db.providerSecrets.providerId,
        ),
      );

  $$ProviderSecretsTableProcessedTableManager get providerSecretsRefs {
    final manager = $$ProviderSecretsTableTableManager(
      $_db,
      $_db.providerSecrets,
    ).filter((f) => f.providerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _providerSecretsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$StreamGroupsTable, List<StreamGroup>>
  _streamGroupsRefsTable(_$ProviderDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.streamGroups,
        aliasName: $_aliasNameGenerator(
          db.providerProfiles.id,
          db.streamGroups.providerId,
        ),
      );

  $$StreamGroupsTableProcessedTableManager get streamGroupsRefs {
    final manager = $$StreamGroupsTableTableManager(
      $_db,
      $_db.streamGroups,
    ).filter((f) => f.providerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_streamGroupsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LiveStreamsTable, List<LiveStream>>
  _liveStreamsRefsTable(_$ProviderDatabase db) => MultiTypedResultKey.fromTable(
    db.liveStreams,
    aliasName: $_aliasNameGenerator(
      db.providerProfiles.id,
      db.liveStreams.providerId,
    ),
  );

  $$LiveStreamsTableProcessedTableManager get liveStreamsRefs {
    final manager = $$LiveStreamsTableTableManager(
      $_db,
      $_db.liveStreams,
    ).filter((f) => f.providerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_liveStreamsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$VodStreamsTable, List<VodStream>>
  _vodStreamsRefsTable(_$ProviderDatabase db) => MultiTypedResultKey.fromTable(
    db.vodStreams,
    aliasName: $_aliasNameGenerator(
      db.providerProfiles.id,
      db.vodStreams.providerId,
    ),
  );

  $$VodStreamsTableProcessedTableManager get vodStreamsRefs {
    final manager = $$VodStreamsTableTableManager(
      $_db,
      $_db.vodStreams,
    ).filter((f) => f.providerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_vodStreamsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SeriesTable, List<Sery>> _seriesRefsTable(
    _$ProviderDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.series,
    aliasName: $_aliasNameGenerator(
      db.providerProfiles.id,
      db.series.providerId,
    ),
  );

  $$SeriesTableProcessedTableManager get seriesRefs {
    final manager = $$SeriesTableTableManager(
      $_db,
      $_db.series,
    ).filter((f) => f.providerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_seriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EpisodesTable, List<Episode>> _episodesRefsTable(
    _$ProviderDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.episodes,
    aliasName: $_aliasNameGenerator(
      db.providerProfiles.id,
      db.episodes.providerId,
    ),
  );

  $$EpisodesTableProcessedTableManager get episodesRefs {
    final manager = $$EpisodesTableTableManager(
      $_db,
      $_db.episodes,
    ).filter((f) => f.providerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_episodesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EpgEventsTable, List<EpgEvent>>
  _epgEventsRefsTable(_$ProviderDatabase db) => MultiTypedResultKey.fromTable(
    db.epgEvents,
    aliasName: $_aliasNameGenerator(
      db.providerProfiles.id,
      db.epgEvents.providerId,
    ),
  );

  $$EpgEventsTableProcessedTableManager get epgEventsRefs {
    final manager = $$EpgEventsTableTableManager(
      $_db,
      $_db.epgEvents,
    ).filter((f) => f.providerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_epgEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FavoritesTable, List<Favorite>>
  _favoritesRefsTable(_$ProviderDatabase db) => MultiTypedResultKey.fromTable(
    db.favorites,
    aliasName: $_aliasNameGenerator(
      db.providerProfiles.id,
      db.favorites.providerId,
    ),
  );

  $$FavoritesTableProcessedTableManager get favoritesRefs {
    final manager = $$FavoritesTableTableManager(
      $_db,
      $_db.favorites,
    ).filter((f) => f.providerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_favoritesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PlaybackHistoryTable, List<PlaybackHistoryData>>
  _playbackHistoryRefsTable(_$ProviderDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.playbackHistory,
        aliasName: $_aliasNameGenerator(
          db.providerProfiles.id,
          db.playbackHistory.providerId,
        ),
      );

  $$PlaybackHistoryTableProcessedTableManager get playbackHistoryRefs {
    final manager = $$PlaybackHistoryTableTableManager(
      $_db,
      $_db.playbackHistory,
    ).filter((f) => f.providerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _playbackHistoryRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProviderProfilesTableFilterComposer
    extends Composer<_$ProviderDatabase, $ProviderProfilesTable> {
  $$ProviderProfilesTableFilterComposer({
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

  ColumnWithTypeConverterFilters<ProviderKind, ProviderKind, int> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lockedBase => $composableBuilder(
    column: $table.lockedBase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get needsUserAgent => $composableBuilder(
    column: $table.needsUserAgent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get allowSelfSignedTls => $composableBuilder(
    column: $table.allowSelfSignedTls,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get followRedirects => $composableBuilder(
    column: $table.followRedirects,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    Map<String, String>,
    Map<String, String>,
    String
  >
  get configuration => $composableBuilder(
    column: $table.configuration,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<
    Map<String, String>,
    Map<String, String>,
    String
  >
  get hints => $composableBuilder(
    column: $table.hints,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastOkAt => $composableBuilder(
    column: $table.lastOkAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> providerSecretsRefs(
    Expression<bool> Function($$ProviderSecretsTableFilterComposer f) f,
  ) {
    final $$ProviderSecretsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.providerSecrets,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProviderSecretsTableFilterComposer(
            $db: $db,
            $table: $db.providerSecrets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> streamGroupsRefs(
    Expression<bool> Function($$StreamGroupsTableFilterComposer f) f,
  ) {
    final $$StreamGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.streamGroups,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StreamGroupsTableFilterComposer(
            $db: $db,
            $table: $db.streamGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> liveStreamsRefs(
    Expression<bool> Function($$LiveStreamsTableFilterComposer f) f,
  ) {
    final $$LiveStreamsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.liveStreams,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LiveStreamsTableFilterComposer(
            $db: $db,
            $table: $db.liveStreams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> vodStreamsRefs(
    Expression<bool> Function($$VodStreamsTableFilterComposer f) f,
  ) {
    final $$VodStreamsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.vodStreams,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VodStreamsTableFilterComposer(
            $db: $db,
            $table: $db.vodStreams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> seriesRefs(
    Expression<bool> Function($$SeriesTableFilterComposer f) f,
  ) {
    final $$SeriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.series,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SeriesTableFilterComposer(
            $db: $db,
            $table: $db.series,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> episodesRefs(
    Expression<bool> Function($$EpisodesTableFilterComposer f) f,
  ) {
    final $$EpisodesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.episodes,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpisodesTableFilterComposer(
            $db: $db,
            $table: $db.episodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> epgEventsRefs(
    Expression<bool> Function($$EpgEventsTableFilterComposer f) f,
  ) {
    final $$EpgEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.epgEvents,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpgEventsTableFilterComposer(
            $db: $db,
            $table: $db.epgEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> favoritesRefs(
    Expression<bool> Function($$FavoritesTableFilterComposer f) f,
  ) {
    final $$FavoritesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.favorites,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoritesTableFilterComposer(
            $db: $db,
            $table: $db.favorites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> playbackHistoryRefs(
    Expression<bool> Function($$PlaybackHistoryTableFilterComposer f) f,
  ) {
    final $$PlaybackHistoryTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playbackHistory,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaybackHistoryTableFilterComposer(
            $db: $db,
            $table: $db.playbackHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProviderProfilesTableOrderingComposer
    extends Composer<_$ProviderDatabase, $ProviderProfilesTable> {
  $$ProviderProfilesTableOrderingComposer({
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

  ColumnOrderings<int> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lockedBase => $composableBuilder(
    column: $table.lockedBase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get needsUserAgent => $composableBuilder(
    column: $table.needsUserAgent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get allowSelfSignedTls => $composableBuilder(
    column: $table.allowSelfSignedTls,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get followRedirects => $composableBuilder(
    column: $table.followRedirects,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get configuration => $composableBuilder(
    column: $table.configuration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hints => $composableBuilder(
    column: $table.hints,
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

  ColumnOrderings<DateTime> get lastOkAt => $composableBuilder(
    column: $table.lastOkAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProviderProfilesTableAnnotationComposer
    extends Composer<_$ProviderDatabase, $ProviderProfilesTable> {
  $$ProviderProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ProviderKind, int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lockedBase => $composableBuilder(
    column: $table.lockedBase,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get needsUserAgent => $composableBuilder(
    column: $table.needsUserAgent,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get allowSelfSignedTls => $composableBuilder(
    column: $table.allowSelfSignedTls,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get followRedirects => $composableBuilder(
    column: $table.followRedirects,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Map<String, String>, String>
  get configuration => $composableBuilder(
    column: $table.configuration,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Map<String, String>, String> get hints =>
      $composableBuilder(column: $table.hints, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastOkAt =>
      $composableBuilder(column: $table.lastOkAt, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  Expression<T> providerSecretsRefs<T extends Object>(
    Expression<T> Function($$ProviderSecretsTableAnnotationComposer a) f,
  ) {
    final $$ProviderSecretsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.providerSecrets,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProviderSecretsTableAnnotationComposer(
            $db: $db,
            $table: $db.providerSecrets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> streamGroupsRefs<T extends Object>(
    Expression<T> Function($$StreamGroupsTableAnnotationComposer a) f,
  ) {
    final $$StreamGroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.streamGroups,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StreamGroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.streamGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> liveStreamsRefs<T extends Object>(
    Expression<T> Function($$LiveStreamsTableAnnotationComposer a) f,
  ) {
    final $$LiveStreamsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.liveStreams,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LiveStreamsTableAnnotationComposer(
            $db: $db,
            $table: $db.liveStreams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> vodStreamsRefs<T extends Object>(
    Expression<T> Function($$VodStreamsTableAnnotationComposer a) f,
  ) {
    final $$VodStreamsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.vodStreams,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VodStreamsTableAnnotationComposer(
            $db: $db,
            $table: $db.vodStreams,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> seriesRefs<T extends Object>(
    Expression<T> Function($$SeriesTableAnnotationComposer a) f,
  ) {
    final $$SeriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.series,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SeriesTableAnnotationComposer(
            $db: $db,
            $table: $db.series,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> episodesRefs<T extends Object>(
    Expression<T> Function($$EpisodesTableAnnotationComposer a) f,
  ) {
    final $$EpisodesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.episodes,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpisodesTableAnnotationComposer(
            $db: $db,
            $table: $db.episodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> epgEventsRefs<T extends Object>(
    Expression<T> Function($$EpgEventsTableAnnotationComposer a) f,
  ) {
    final $$EpgEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.epgEvents,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpgEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.epgEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> favoritesRefs<T extends Object>(
    Expression<T> Function($$FavoritesTableAnnotationComposer a) f,
  ) {
    final $$FavoritesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.favorites,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FavoritesTableAnnotationComposer(
            $db: $db,
            $table: $db.favorites,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> playbackHistoryRefs<T extends Object>(
    Expression<T> Function($$PlaybackHistoryTableAnnotationComposer a) f,
  ) {
    final $$PlaybackHistoryTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playbackHistory,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaybackHistoryTableAnnotationComposer(
            $db: $db,
            $table: $db.playbackHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProviderProfilesTableTableManager
    extends
        RootTableManager<
          _$ProviderDatabase,
          $ProviderProfilesTable,
          ProviderProfile,
          $$ProviderProfilesTableFilterComposer,
          $$ProviderProfilesTableOrderingComposer,
          $$ProviderProfilesTableAnnotationComposer,
          $$ProviderProfilesTableCreateCompanionBuilder,
          $$ProviderProfilesTableUpdateCompanionBuilder,
          (ProviderProfile, $$ProviderProfilesTableReferences),
          ProviderProfile,
          PrefetchHooks Function({
            bool providerSecretsRefs,
            bool streamGroupsRefs,
            bool liveStreamsRefs,
            bool vodStreamsRefs,
            bool seriesRefs,
            bool episodesRefs,
            bool epgEventsRefs,
            bool favoritesRefs,
            bool playbackHistoryRefs,
          })
        > {
  $$ProviderProfilesTableTableManager(
    _$ProviderDatabase db,
    $ProviderProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProviderProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProviderProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProviderProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<ProviderKind> kind = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> lockedBase = const Value.absent(),
                Value<bool> needsUserAgent = const Value.absent(),
                Value<bool> allowSelfSignedTls = const Value.absent(),
                Value<bool> followRedirects = const Value.absent(),
                Value<Map<String, String>> configuration = const Value.absent(),
                Value<Map<String, String>> hints = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> lastOkAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProviderProfilesCompanion(
                id: id,
                kind: kind,
                displayName: displayName,
                lockedBase: lockedBase,
                needsUserAgent: needsUserAgent,
                allowSelfSignedTls: allowSelfSignedTls,
                followRedirects: followRedirects,
                configuration: configuration,
                hints: hints,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastOkAt: lastOkAt,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required ProviderKind kind,
                required String displayName,
                required String lockedBase,
                Value<bool> needsUserAgent = const Value.absent(),
                Value<bool> allowSelfSignedTls = const Value.absent(),
                Value<bool> followRedirects = const Value.absent(),
                Value<Map<String, String>> configuration = const Value.absent(),
                Value<Map<String, String>> hints = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> lastOkAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProviderProfilesCompanion.insert(
                id: id,
                kind: kind,
                displayName: displayName,
                lockedBase: lockedBase,
                needsUserAgent: needsUserAgent,
                allowSelfSignedTls: allowSelfSignedTls,
                followRedirects: followRedirects,
                configuration: configuration,
                hints: hints,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastOkAt: lastOkAt,
                lastError: lastError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProviderProfilesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                providerSecretsRefs = false,
                streamGroupsRefs = false,
                liveStreamsRefs = false,
                vodStreamsRefs = false,
                seriesRefs = false,
                episodesRefs = false,
                epgEventsRefs = false,
                favoritesRefs = false,
                playbackHistoryRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (providerSecretsRefs) db.providerSecrets,
                    if (streamGroupsRefs) db.streamGroups,
                    if (liveStreamsRefs) db.liveStreams,
                    if (vodStreamsRefs) db.vodStreams,
                    if (seriesRefs) db.series,
                    if (episodesRefs) db.episodes,
                    if (epgEventsRefs) db.epgEvents,
                    if (favoritesRefs) db.favorites,
                    if (playbackHistoryRefs) db.playbackHistory,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (providerSecretsRefs)
                        await $_getPrefetchedData<
                          ProviderProfile,
                          $ProviderProfilesTable,
                          ProviderSecret
                        >(
                          currentTable: table,
                          referencedTable: $$ProviderProfilesTableReferences
                              ._providerSecretsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProviderProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).providerSecretsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.providerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (streamGroupsRefs)
                        await $_getPrefetchedData<
                          ProviderProfile,
                          $ProviderProfilesTable,
                          StreamGroup
                        >(
                          currentTable: table,
                          referencedTable: $$ProviderProfilesTableReferences
                              ._streamGroupsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProviderProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).streamGroupsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.providerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (liveStreamsRefs)
                        await $_getPrefetchedData<
                          ProviderProfile,
                          $ProviderProfilesTable,
                          LiveStream
                        >(
                          currentTable: table,
                          referencedTable: $$ProviderProfilesTableReferences
                              ._liveStreamsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProviderProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).liveStreamsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.providerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (vodStreamsRefs)
                        await $_getPrefetchedData<
                          ProviderProfile,
                          $ProviderProfilesTable,
                          VodStream
                        >(
                          currentTable: table,
                          referencedTable: $$ProviderProfilesTableReferences
                              ._vodStreamsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProviderProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).vodStreamsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.providerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (seriesRefs)
                        await $_getPrefetchedData<
                          ProviderProfile,
                          $ProviderProfilesTable,
                          Sery
                        >(
                          currentTable: table,
                          referencedTable: $$ProviderProfilesTableReferences
                              ._seriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProviderProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).seriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.providerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (episodesRefs)
                        await $_getPrefetchedData<
                          ProviderProfile,
                          $ProviderProfilesTable,
                          Episode
                        >(
                          currentTable: table,
                          referencedTable: $$ProviderProfilesTableReferences
                              ._episodesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProviderProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).episodesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.providerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (epgEventsRefs)
                        await $_getPrefetchedData<
                          ProviderProfile,
                          $ProviderProfilesTable,
                          EpgEvent
                        >(
                          currentTable: table,
                          referencedTable: $$ProviderProfilesTableReferences
                              ._epgEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProviderProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).epgEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.providerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (favoritesRefs)
                        await $_getPrefetchedData<
                          ProviderProfile,
                          $ProviderProfilesTable,
                          Favorite
                        >(
                          currentTable: table,
                          referencedTable: $$ProviderProfilesTableReferences
                              ._favoritesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProviderProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).favoritesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.providerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (playbackHistoryRefs)
                        await $_getPrefetchedData<
                          ProviderProfile,
                          $ProviderProfilesTable,
                          PlaybackHistoryData
                        >(
                          currentTable: table,
                          referencedTable: $$ProviderProfilesTableReferences
                              ._playbackHistoryRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProviderProfilesTableReferences(
                                db,
                                table,
                                p0,
                              ).playbackHistoryRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.providerId == item.id,
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

typedef $$ProviderProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$ProviderDatabase,
      $ProviderProfilesTable,
      ProviderProfile,
      $$ProviderProfilesTableFilterComposer,
      $$ProviderProfilesTableOrderingComposer,
      $$ProviderProfilesTableAnnotationComposer,
      $$ProviderProfilesTableCreateCompanionBuilder,
      $$ProviderProfilesTableUpdateCompanionBuilder,
      (ProviderProfile, $$ProviderProfilesTableReferences),
      ProviderProfile,
      PrefetchHooks Function({
        bool providerSecretsRefs,
        bool streamGroupsRefs,
        bool liveStreamsRefs,
        bool vodStreamsRefs,
        bool seriesRefs,
        bool episodesRefs,
        bool epgEventsRefs,
        bool favoritesRefs,
        bool playbackHistoryRefs,
      })
    >;
typedef $$ProviderSecretsTableCreateCompanionBuilder =
    ProviderSecretsCompanion Function({
      required String providerId,
      required String vaultKey,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ProviderSecretsTableUpdateCompanionBuilder =
    ProviderSecretsCompanion Function({
      Value<String> providerId,
      Value<String> vaultKey,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$ProviderSecretsTableReferences
    extends
        BaseReferences<
          _$ProviderDatabase,
          $ProviderSecretsTable,
          ProviderSecret
        > {
  $$ProviderSecretsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProviderProfilesTable _providerIdTable(_$ProviderDatabase db) =>
      db.providerProfiles.createAlias(
        $_aliasNameGenerator(
          db.providerSecrets.providerId,
          db.providerProfiles.id,
        ),
      );

  $$ProviderProfilesTableProcessedTableManager get providerId {
    final $_column = $_itemColumn<String>('provider_id')!;

    final manager = $$ProviderProfilesTableTableManager(
      $_db,
      $_db.providerProfiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_providerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProviderSecretsTableFilterComposer
    extends Composer<_$ProviderDatabase, $ProviderSecretsTable> {
  $$ProviderSecretsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get vaultKey => $composableBuilder(
    column: $table.vaultKey,
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

  $$ProviderProfilesTableFilterComposer get providerId {
    final $$ProviderProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providerProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProviderProfilesTableFilterComposer(
            $db: $db,
            $table: $db.providerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProviderSecretsTableOrderingComposer
    extends Composer<_$ProviderDatabase, $ProviderSecretsTable> {
  $$ProviderSecretsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get vaultKey => $composableBuilder(
    column: $table.vaultKey,
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

  $$ProviderProfilesTableOrderingComposer get providerId {
    final $$ProviderProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providerProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProviderProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.providerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProviderSecretsTableAnnotationComposer
    extends Composer<_$ProviderDatabase, $ProviderSecretsTable> {
  $$ProviderSecretsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get vaultKey =>
      $composableBuilder(column: $table.vaultKey, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ProviderProfilesTableAnnotationComposer get providerId {
    final $$ProviderProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providerProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProviderProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.providerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProviderSecretsTableTableManager
    extends
        RootTableManager<
          _$ProviderDatabase,
          $ProviderSecretsTable,
          ProviderSecret,
          $$ProviderSecretsTableFilterComposer,
          $$ProviderSecretsTableOrderingComposer,
          $$ProviderSecretsTableAnnotationComposer,
          $$ProviderSecretsTableCreateCompanionBuilder,
          $$ProviderSecretsTableUpdateCompanionBuilder,
          (ProviderSecret, $$ProviderSecretsTableReferences),
          ProviderSecret,
          PrefetchHooks Function({bool providerId})
        > {
  $$ProviderSecretsTableTableManager(
    _$ProviderDatabase db,
    $ProviderSecretsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProviderSecretsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProviderSecretsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProviderSecretsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> providerId = const Value.absent(),
                Value<String> vaultKey = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProviderSecretsCompanion(
                providerId: providerId,
                vaultKey: vaultKey,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String providerId,
                required String vaultKey,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ProviderSecretsCompanion.insert(
                providerId: providerId,
                vaultKey: vaultKey,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProviderSecretsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({providerId = false}) {
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
                    if (providerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.providerId,
                                referencedTable:
                                    $$ProviderSecretsTableReferences
                                        ._providerIdTable(db),
                                referencedColumn:
                                    $$ProviderSecretsTableReferences
                                        ._providerIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$ProviderSecretsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProviderDatabase,
      $ProviderSecretsTable,
      ProviderSecret,
      $$ProviderSecretsTableFilterComposer,
      $$ProviderSecretsTableOrderingComposer,
      $$ProviderSecretsTableAnnotationComposer,
      $$ProviderSecretsTableCreateCompanionBuilder,
      $$ProviderSecretsTableUpdateCompanionBuilder,
      (ProviderSecret, $$ProviderSecretsTableReferences),
      ProviderSecret,
      PrefetchHooks Function({bool providerId})
    >;
typedef $$StreamGroupsTableCreateCompanionBuilder =
    StreamGroupsCompanion Function({
      required int id,
      required String providerId,
      required String name,
      required String type,
      Value<int> rowid,
    });
typedef $$StreamGroupsTableUpdateCompanionBuilder =
    StreamGroupsCompanion Function({
      Value<int> id,
      Value<String> providerId,
      Value<String> name,
      Value<String> type,
      Value<int> rowid,
    });

final class $$StreamGroupsTableReferences
    extends
        BaseReferences<_$ProviderDatabase, $StreamGroupsTable, StreamGroup> {
  $$StreamGroupsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProviderProfilesTable _providerIdTable(_$ProviderDatabase db) =>
      db.providerProfiles.createAlias(
        $_aliasNameGenerator(
          db.streamGroups.providerId,
          db.providerProfiles.id,
        ),
      );

  $$ProviderProfilesTableProcessedTableManager get providerId {
    final $_column = $_itemColumn<String>('provider_id')!;

    final manager = $$ProviderProfilesTableTableManager(
      $_db,
      $_db.providerProfiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_providerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StreamGroupsTableFilterComposer
    extends Composer<_$ProviderDatabase, $StreamGroupsTable> {
  $$StreamGroupsTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  $$ProviderProfilesTableFilterComposer get providerId {
    final $$ProviderProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providerProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProviderProfilesTableFilterComposer(
            $db: $db,
            $table: $db.providerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StreamGroupsTableOrderingComposer
    extends Composer<_$ProviderDatabase, $StreamGroupsTable> {
  $$StreamGroupsTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProviderProfilesTableOrderingComposer get providerId {
    final $$ProviderProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providerProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProviderProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.providerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StreamGroupsTableAnnotationComposer
    extends Composer<_$ProviderDatabase, $StreamGroupsTable> {
  $$StreamGroupsTableAnnotationComposer({
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

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  $$ProviderProfilesTableAnnotationComposer get providerId {
    final $$ProviderProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providerProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProviderProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.providerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StreamGroupsTableTableManager
    extends
        RootTableManager<
          _$ProviderDatabase,
          $StreamGroupsTable,
          StreamGroup,
          $$StreamGroupsTableFilterComposer,
          $$StreamGroupsTableOrderingComposer,
          $$StreamGroupsTableAnnotationComposer,
          $$StreamGroupsTableCreateCompanionBuilder,
          $$StreamGroupsTableUpdateCompanionBuilder,
          (StreamGroup, $$StreamGroupsTableReferences),
          StreamGroup,
          PrefetchHooks Function({bool providerId})
        > {
  $$StreamGroupsTableTableManager(
    _$ProviderDatabase db,
    $StreamGroupsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StreamGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StreamGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StreamGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> providerId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StreamGroupsCompanion(
                id: id,
                providerId: providerId,
                name: name,
                type: type,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int id,
                required String providerId,
                required String name,
                required String type,
                Value<int> rowid = const Value.absent(),
              }) => StreamGroupsCompanion.insert(
                id: id,
                providerId: providerId,
                name: name,
                type: type,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StreamGroupsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({providerId = false}) {
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
                    if (providerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.providerId,
                                referencedTable: $$StreamGroupsTableReferences
                                    ._providerIdTable(db),
                                referencedColumn: $$StreamGroupsTableReferences
                                    ._providerIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$StreamGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProviderDatabase,
      $StreamGroupsTable,
      StreamGroup,
      $$StreamGroupsTableFilterComposer,
      $$StreamGroupsTableOrderingComposer,
      $$StreamGroupsTableAnnotationComposer,
      $$StreamGroupsTableCreateCompanionBuilder,
      $$StreamGroupsTableUpdateCompanionBuilder,
      (StreamGroup, $$StreamGroupsTableReferences),
      StreamGroup,
      PrefetchHooks Function({bool providerId})
    >;
typedef $$LiveStreamsTableCreateCompanionBuilder =
    LiveStreamsCompanion Function({
      required int streamId,
      required String providerId,
      required String name,
      Value<String?> streamIcon,
      Value<String?> epgChannelId,
      Value<int?> categoryId,
      Value<int?> num,
      Value<bool> isAdult,
      Value<int> rowid,
    });
typedef $$LiveStreamsTableUpdateCompanionBuilder =
    LiveStreamsCompanion Function({
      Value<int> streamId,
      Value<String> providerId,
      Value<String> name,
      Value<String?> streamIcon,
      Value<String?> epgChannelId,
      Value<int?> categoryId,
      Value<int?> num,
      Value<bool> isAdult,
      Value<int> rowid,
    });

final class $$LiveStreamsTableReferences
    extends BaseReferences<_$ProviderDatabase, $LiveStreamsTable, LiveStream> {
  $$LiveStreamsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProviderProfilesTable _providerIdTable(_$ProviderDatabase db) =>
      db.providerProfiles.createAlias(
        $_aliasNameGenerator(db.liveStreams.providerId, db.providerProfiles.id),
      );

  $$ProviderProfilesTableProcessedTableManager get providerId {
    final $_column = $_itemColumn<String>('provider_id')!;

    final manager = $$ProviderProfilesTableTableManager(
      $_db,
      $_db.providerProfiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_providerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LiveStreamsTableFilterComposer
    extends Composer<_$ProviderDatabase, $LiveStreamsTable> {
  $$LiveStreamsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get streamId => $composableBuilder(
    column: $table.streamId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get streamIcon => $composableBuilder(
    column: $table.streamIcon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get epgChannelId => $composableBuilder(
    column: $table.epgChannelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get num => $composableBuilder(
    column: $table.num,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAdult => $composableBuilder(
    column: $table.isAdult,
    builder: (column) => ColumnFilters(column),
  );

  $$ProviderProfilesTableFilterComposer get providerId {
    final $$ProviderProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providerProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProviderProfilesTableFilterComposer(
            $db: $db,
            $table: $db.providerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LiveStreamsTableOrderingComposer
    extends Composer<_$ProviderDatabase, $LiveStreamsTable> {
  $$LiveStreamsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get streamId => $composableBuilder(
    column: $table.streamId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get streamIcon => $composableBuilder(
    column: $table.streamIcon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get epgChannelId => $composableBuilder(
    column: $table.epgChannelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get num => $composableBuilder(
    column: $table.num,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAdult => $composableBuilder(
    column: $table.isAdult,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProviderProfilesTableOrderingComposer get providerId {
    final $$ProviderProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providerProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProviderProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.providerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LiveStreamsTableAnnotationComposer
    extends Composer<_$ProviderDatabase, $LiveStreamsTable> {
  $$LiveStreamsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get streamId =>
      $composableBuilder(column: $table.streamId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get streamIcon => $composableBuilder(
    column: $table.streamIcon,
    builder: (column) => column,
  );

  GeneratedColumn<String> get epgChannelId => $composableBuilder(
    column: $table.epgChannelId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get num =>
      $composableBuilder(column: $table.num, builder: (column) => column);

  GeneratedColumn<bool> get isAdult =>
      $composableBuilder(column: $table.isAdult, builder: (column) => column);

  $$ProviderProfilesTableAnnotationComposer get providerId {
    final $$ProviderProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providerProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProviderProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.providerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LiveStreamsTableTableManager
    extends
        RootTableManager<
          _$ProviderDatabase,
          $LiveStreamsTable,
          LiveStream,
          $$LiveStreamsTableFilterComposer,
          $$LiveStreamsTableOrderingComposer,
          $$LiveStreamsTableAnnotationComposer,
          $$LiveStreamsTableCreateCompanionBuilder,
          $$LiveStreamsTableUpdateCompanionBuilder,
          (LiveStream, $$LiveStreamsTableReferences),
          LiveStream,
          PrefetchHooks Function({bool providerId})
        > {
  $$LiveStreamsTableTableManager(_$ProviderDatabase db, $LiveStreamsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LiveStreamsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LiveStreamsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LiveStreamsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> streamId = const Value.absent(),
                Value<String> providerId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> streamIcon = const Value.absent(),
                Value<String?> epgChannelId = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<int?> num = const Value.absent(),
                Value<bool> isAdult = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LiveStreamsCompanion(
                streamId: streamId,
                providerId: providerId,
                name: name,
                streamIcon: streamIcon,
                epgChannelId: epgChannelId,
                categoryId: categoryId,
                num: num,
                isAdult: isAdult,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int streamId,
                required String providerId,
                required String name,
                Value<String?> streamIcon = const Value.absent(),
                Value<String?> epgChannelId = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<int?> num = const Value.absent(),
                Value<bool> isAdult = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LiveStreamsCompanion.insert(
                streamId: streamId,
                providerId: providerId,
                name: name,
                streamIcon: streamIcon,
                epgChannelId: epgChannelId,
                categoryId: categoryId,
                num: num,
                isAdult: isAdult,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LiveStreamsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({providerId = false}) {
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
                    if (providerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.providerId,
                                referencedTable: $$LiveStreamsTableReferences
                                    ._providerIdTable(db),
                                referencedColumn: $$LiveStreamsTableReferences
                                    ._providerIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$LiveStreamsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProviderDatabase,
      $LiveStreamsTable,
      LiveStream,
      $$LiveStreamsTableFilterComposer,
      $$LiveStreamsTableOrderingComposer,
      $$LiveStreamsTableAnnotationComposer,
      $$LiveStreamsTableCreateCompanionBuilder,
      $$LiveStreamsTableUpdateCompanionBuilder,
      (LiveStream, $$LiveStreamsTableReferences),
      LiveStream,
      PrefetchHooks Function({bool providerId})
    >;
typedef $$VodStreamsTableCreateCompanionBuilder =
    VodStreamsCompanion Function({
      required int streamId,
      required String providerId,
      required String name,
      Value<String?> streamIcon,
      Value<String?> containerExtension,
      Value<int?> categoryId,
      Value<double?> rating,
      Value<DateTime?> added,
      Value<int> rowid,
    });
typedef $$VodStreamsTableUpdateCompanionBuilder =
    VodStreamsCompanion Function({
      Value<int> streamId,
      Value<String> providerId,
      Value<String> name,
      Value<String?> streamIcon,
      Value<String?> containerExtension,
      Value<int?> categoryId,
      Value<double?> rating,
      Value<DateTime?> added,
      Value<int> rowid,
    });

final class $$VodStreamsTableReferences
    extends BaseReferences<_$ProviderDatabase, $VodStreamsTable, VodStream> {
  $$VodStreamsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProviderProfilesTable _providerIdTable(_$ProviderDatabase db) =>
      db.providerProfiles.createAlias(
        $_aliasNameGenerator(db.vodStreams.providerId, db.providerProfiles.id),
      );

  $$ProviderProfilesTableProcessedTableManager get providerId {
    final $_column = $_itemColumn<String>('provider_id')!;

    final manager = $$ProviderProfilesTableTableManager(
      $_db,
      $_db.providerProfiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_providerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$VodStreamsTableFilterComposer
    extends Composer<_$ProviderDatabase, $VodStreamsTable> {
  $$VodStreamsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get streamId => $composableBuilder(
    column: $table.streamId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get streamIcon => $composableBuilder(
    column: $table.streamIcon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get containerExtension => $composableBuilder(
    column: $table.containerExtension,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get added => $composableBuilder(
    column: $table.added,
    builder: (column) => ColumnFilters(column),
  );

  $$ProviderProfilesTableFilterComposer get providerId {
    final $$ProviderProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providerProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProviderProfilesTableFilterComposer(
            $db: $db,
            $table: $db.providerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VodStreamsTableOrderingComposer
    extends Composer<_$ProviderDatabase, $VodStreamsTable> {
  $$VodStreamsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get streamId => $composableBuilder(
    column: $table.streamId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get streamIcon => $composableBuilder(
    column: $table.streamIcon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get containerExtension => $composableBuilder(
    column: $table.containerExtension,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get added => $composableBuilder(
    column: $table.added,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProviderProfilesTableOrderingComposer get providerId {
    final $$ProviderProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providerProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProviderProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.providerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VodStreamsTableAnnotationComposer
    extends Composer<_$ProviderDatabase, $VodStreamsTable> {
  $$VodStreamsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get streamId =>
      $composableBuilder(column: $table.streamId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get streamIcon => $composableBuilder(
    column: $table.streamIcon,
    builder: (column) => column,
  );

  GeneratedColumn<String> get containerExtension => $composableBuilder(
    column: $table.containerExtension,
    builder: (column) => column,
  );

  GeneratedColumn<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<DateTime> get added =>
      $composableBuilder(column: $table.added, builder: (column) => column);

  $$ProviderProfilesTableAnnotationComposer get providerId {
    final $$ProviderProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providerProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProviderProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.providerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VodStreamsTableTableManager
    extends
        RootTableManager<
          _$ProviderDatabase,
          $VodStreamsTable,
          VodStream,
          $$VodStreamsTableFilterComposer,
          $$VodStreamsTableOrderingComposer,
          $$VodStreamsTableAnnotationComposer,
          $$VodStreamsTableCreateCompanionBuilder,
          $$VodStreamsTableUpdateCompanionBuilder,
          (VodStream, $$VodStreamsTableReferences),
          VodStream,
          PrefetchHooks Function({bool providerId})
        > {
  $$VodStreamsTableTableManager(_$ProviderDatabase db, $VodStreamsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VodStreamsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VodStreamsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VodStreamsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> streamId = const Value.absent(),
                Value<String> providerId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> streamIcon = const Value.absent(),
                Value<String?> containerExtension = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<double?> rating = const Value.absent(),
                Value<DateTime?> added = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VodStreamsCompanion(
                streamId: streamId,
                providerId: providerId,
                name: name,
                streamIcon: streamIcon,
                containerExtension: containerExtension,
                categoryId: categoryId,
                rating: rating,
                added: added,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int streamId,
                required String providerId,
                required String name,
                Value<String?> streamIcon = const Value.absent(),
                Value<String?> containerExtension = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<double?> rating = const Value.absent(),
                Value<DateTime?> added = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VodStreamsCompanion.insert(
                streamId: streamId,
                providerId: providerId,
                name: name,
                streamIcon: streamIcon,
                containerExtension: containerExtension,
                categoryId: categoryId,
                rating: rating,
                added: added,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$VodStreamsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({providerId = false}) {
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
                    if (providerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.providerId,
                                referencedTable: $$VodStreamsTableReferences
                                    ._providerIdTable(db),
                                referencedColumn: $$VodStreamsTableReferences
                                    ._providerIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$VodStreamsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProviderDatabase,
      $VodStreamsTable,
      VodStream,
      $$VodStreamsTableFilterComposer,
      $$VodStreamsTableOrderingComposer,
      $$VodStreamsTableAnnotationComposer,
      $$VodStreamsTableCreateCompanionBuilder,
      $$VodStreamsTableUpdateCompanionBuilder,
      (VodStream, $$VodStreamsTableReferences),
      VodStream,
      PrefetchHooks Function({bool providerId})
    >;
typedef $$SeriesTableCreateCompanionBuilder =
    SeriesCompanion Function({
      required int seriesId,
      required String providerId,
      required String name,
      Value<String?> cover,
      Value<String?> plot,
      Value<String?> cast,
      Value<String?> director,
      Value<String?> genre,
      Value<String?> releaseDate,
      Value<DateTime?> lastModified,
      Value<int?> categoryId,
      Value<int> rowid,
    });
typedef $$SeriesTableUpdateCompanionBuilder =
    SeriesCompanion Function({
      Value<int> seriesId,
      Value<String> providerId,
      Value<String> name,
      Value<String?> cover,
      Value<String?> plot,
      Value<String?> cast,
      Value<String?> director,
      Value<String?> genre,
      Value<String?> releaseDate,
      Value<DateTime?> lastModified,
      Value<int?> categoryId,
      Value<int> rowid,
    });

final class $$SeriesTableReferences
    extends BaseReferences<_$ProviderDatabase, $SeriesTable, Sery> {
  $$SeriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProviderProfilesTable _providerIdTable(_$ProviderDatabase db) =>
      db.providerProfiles.createAlias(
        $_aliasNameGenerator(db.series.providerId, db.providerProfiles.id),
      );

  $$ProviderProfilesTableProcessedTableManager get providerId {
    final $_column = $_itemColumn<String>('provider_id')!;

    final manager = $$ProviderProfilesTableTableManager(
      $_db,
      $_db.providerProfiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_providerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SeriesTableFilterComposer
    extends Composer<_$ProviderDatabase, $SeriesTable> {
  $$SeriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cover => $composableBuilder(
    column: $table.cover,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plot => $composableBuilder(
    column: $table.plot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cast => $composableBuilder(
    column: $table.cast,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get director => $composableBuilder(
    column: $table.director,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  $$ProviderProfilesTableFilterComposer get providerId {
    final $$ProviderProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providerProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProviderProfilesTableFilterComposer(
            $db: $db,
            $table: $db.providerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SeriesTableOrderingComposer
    extends Composer<_$ProviderDatabase, $SeriesTable> {
  $$SeriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cover => $composableBuilder(
    column: $table.cover,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plot => $composableBuilder(
    column: $table.plot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cast => $composableBuilder(
    column: $table.cast,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get director => $composableBuilder(
    column: $table.director,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProviderProfilesTableOrderingComposer get providerId {
    final $$ProviderProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providerProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProviderProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.providerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SeriesTableAnnotationComposer
    extends Composer<_$ProviderDatabase, $SeriesTable> {
  $$SeriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seriesId =>
      $composableBuilder(column: $table.seriesId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get cover =>
      $composableBuilder(column: $table.cover, builder: (column) => column);

  GeneratedColumn<String> get plot =>
      $composableBuilder(column: $table.plot, builder: (column) => column);

  GeneratedColumn<String> get cast =>
      $composableBuilder(column: $table.cast, builder: (column) => column);

  GeneratedColumn<String> get director =>
      $composableBuilder(column: $table.director, builder: (column) => column);

  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  GeneratedColumn<String> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );

  GeneratedColumn<int> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  $$ProviderProfilesTableAnnotationComposer get providerId {
    final $$ProviderProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providerProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProviderProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.providerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SeriesTableTableManager
    extends
        RootTableManager<
          _$ProviderDatabase,
          $SeriesTable,
          Sery,
          $$SeriesTableFilterComposer,
          $$SeriesTableOrderingComposer,
          $$SeriesTableAnnotationComposer,
          $$SeriesTableCreateCompanionBuilder,
          $$SeriesTableUpdateCompanionBuilder,
          (Sery, $$SeriesTableReferences),
          Sery,
          PrefetchHooks Function({bool providerId})
        > {
  $$SeriesTableTableManager(_$ProviderDatabase db, $SeriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SeriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SeriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SeriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> seriesId = const Value.absent(),
                Value<String> providerId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> cover = const Value.absent(),
                Value<String?> plot = const Value.absent(),
                Value<String?> cast = const Value.absent(),
                Value<String?> director = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<String?> releaseDate = const Value.absent(),
                Value<DateTime?> lastModified = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeriesCompanion(
                seriesId: seriesId,
                providerId: providerId,
                name: name,
                cover: cover,
                plot: plot,
                cast: cast,
                director: director,
                genre: genre,
                releaseDate: releaseDate,
                lastModified: lastModified,
                categoryId: categoryId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int seriesId,
                required String providerId,
                required String name,
                Value<String?> cover = const Value.absent(),
                Value<String?> plot = const Value.absent(),
                Value<String?> cast = const Value.absent(),
                Value<String?> director = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<String?> releaseDate = const Value.absent(),
                Value<DateTime?> lastModified = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeriesCompanion.insert(
                seriesId: seriesId,
                providerId: providerId,
                name: name,
                cover: cover,
                plot: plot,
                cast: cast,
                director: director,
                genre: genre,
                releaseDate: releaseDate,
                lastModified: lastModified,
                categoryId: categoryId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$SeriesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({providerId = false}) {
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
                    if (providerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.providerId,
                                referencedTable: $$SeriesTableReferences
                                    ._providerIdTable(db),
                                referencedColumn: $$SeriesTableReferences
                                    ._providerIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$SeriesTableProcessedTableManager =
    ProcessedTableManager<
      _$ProviderDatabase,
      $SeriesTable,
      Sery,
      $$SeriesTableFilterComposer,
      $$SeriesTableOrderingComposer,
      $$SeriesTableAnnotationComposer,
      $$SeriesTableCreateCompanionBuilder,
      $$SeriesTableUpdateCompanionBuilder,
      (Sery, $$SeriesTableReferences),
      Sery,
      PrefetchHooks Function({bool providerId})
    >;
typedef $$EpisodesTableCreateCompanionBuilder =
    EpisodesCompanion Function({
      required int id,
      required int seriesId,
      required String providerId,
      required String title,
      Value<String?> containerExtension,
      Value<String?> info,
      Value<int?> season,
      Value<int?> episode,
      Value<int?> duration,
      Value<int> rowid,
    });
typedef $$EpisodesTableUpdateCompanionBuilder =
    EpisodesCompanion Function({
      Value<int> id,
      Value<int> seriesId,
      Value<String> providerId,
      Value<String> title,
      Value<String?> containerExtension,
      Value<String?> info,
      Value<int?> season,
      Value<int?> episode,
      Value<int?> duration,
      Value<int> rowid,
    });

final class $$EpisodesTableReferences
    extends BaseReferences<_$ProviderDatabase, $EpisodesTable, Episode> {
  $$EpisodesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProviderProfilesTable _providerIdTable(_$ProviderDatabase db) =>
      db.providerProfiles.createAlias(
        $_aliasNameGenerator(db.episodes.providerId, db.providerProfiles.id),
      );

  $$ProviderProfilesTableProcessedTableManager get providerId {
    final $_column = $_itemColumn<String>('provider_id')!;

    final manager = $$ProviderProfilesTableTableManager(
      $_db,
      $_db.providerProfiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_providerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EpisodesTableFilterComposer
    extends Composer<_$ProviderDatabase, $EpisodesTable> {
  $$EpisodesTableFilterComposer({
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

  ColumnFilters<int> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get containerExtension => $composableBuilder(
    column: $table.containerExtension,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get info => $composableBuilder(
    column: $table.info,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get season => $composableBuilder(
    column: $table.season,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get episode => $composableBuilder(
    column: $table.episode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  $$ProviderProfilesTableFilterComposer get providerId {
    final $$ProviderProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providerProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProviderProfilesTableFilterComposer(
            $db: $db,
            $table: $db.providerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EpisodesTableOrderingComposer
    extends Composer<_$ProviderDatabase, $EpisodesTable> {
  $$EpisodesTableOrderingComposer({
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

  ColumnOrderings<int> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get containerExtension => $composableBuilder(
    column: $table.containerExtension,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get info => $composableBuilder(
    column: $table.info,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get season => $composableBuilder(
    column: $table.season,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get episode => $composableBuilder(
    column: $table.episode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProviderProfilesTableOrderingComposer get providerId {
    final $$ProviderProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providerProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProviderProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.providerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EpisodesTableAnnotationComposer
    extends Composer<_$ProviderDatabase, $EpisodesTable> {
  $$EpisodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get seriesId =>
      $composableBuilder(column: $table.seriesId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get containerExtension => $composableBuilder(
    column: $table.containerExtension,
    builder: (column) => column,
  );

  GeneratedColumn<String> get info =>
      $composableBuilder(column: $table.info, builder: (column) => column);

  GeneratedColumn<int> get season =>
      $composableBuilder(column: $table.season, builder: (column) => column);

  GeneratedColumn<int> get episode =>
      $composableBuilder(column: $table.episode, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  $$ProviderProfilesTableAnnotationComposer get providerId {
    final $$ProviderProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providerProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProviderProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.providerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EpisodesTableTableManager
    extends
        RootTableManager<
          _$ProviderDatabase,
          $EpisodesTable,
          Episode,
          $$EpisodesTableFilterComposer,
          $$EpisodesTableOrderingComposer,
          $$EpisodesTableAnnotationComposer,
          $$EpisodesTableCreateCompanionBuilder,
          $$EpisodesTableUpdateCompanionBuilder,
          (Episode, $$EpisodesTableReferences),
          Episode,
          PrefetchHooks Function({bool providerId})
        > {
  $$EpisodesTableTableManager(_$ProviderDatabase db, $EpisodesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EpisodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EpisodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EpisodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> seriesId = const Value.absent(),
                Value<String> providerId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> containerExtension = const Value.absent(),
                Value<String?> info = const Value.absent(),
                Value<int?> season = const Value.absent(),
                Value<int?> episode = const Value.absent(),
                Value<int?> duration = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EpisodesCompanion(
                id: id,
                seriesId: seriesId,
                providerId: providerId,
                title: title,
                containerExtension: containerExtension,
                info: info,
                season: season,
                episode: episode,
                duration: duration,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int id,
                required int seriesId,
                required String providerId,
                required String title,
                Value<String?> containerExtension = const Value.absent(),
                Value<String?> info = const Value.absent(),
                Value<int?> season = const Value.absent(),
                Value<int?> episode = const Value.absent(),
                Value<int?> duration = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EpisodesCompanion.insert(
                id: id,
                seriesId: seriesId,
                providerId: providerId,
                title: title,
                containerExtension: containerExtension,
                info: info,
                season: season,
                episode: episode,
                duration: duration,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EpisodesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({providerId = false}) {
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
                    if (providerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.providerId,
                                referencedTable: $$EpisodesTableReferences
                                    ._providerIdTable(db),
                                referencedColumn: $$EpisodesTableReferences
                                    ._providerIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$EpisodesTableProcessedTableManager =
    ProcessedTableManager<
      _$ProviderDatabase,
      $EpisodesTable,
      Episode,
      $$EpisodesTableFilterComposer,
      $$EpisodesTableOrderingComposer,
      $$EpisodesTableAnnotationComposer,
      $$EpisodesTableCreateCompanionBuilder,
      $$EpisodesTableUpdateCompanionBuilder,
      (Episode, $$EpisodesTableReferences),
      Episode,
      PrefetchHooks Function({bool providerId})
    >;
typedef $$EpgEventsTableCreateCompanionBuilder =
    EpgEventsCompanion Function({
      required String providerId,
      required String channelId,
      required String title,
      Value<String?> description,
      required DateTime start,
      required DateTime end,
      Value<int> rowid,
    });
typedef $$EpgEventsTableUpdateCompanionBuilder =
    EpgEventsCompanion Function({
      Value<String> providerId,
      Value<String> channelId,
      Value<String> title,
      Value<String?> description,
      Value<DateTime> start,
      Value<DateTime> end,
      Value<int> rowid,
    });

final class $$EpgEventsTableReferences
    extends BaseReferences<_$ProviderDatabase, $EpgEventsTable, EpgEvent> {
  $$EpgEventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProviderProfilesTable _providerIdTable(_$ProviderDatabase db) =>
      db.providerProfiles.createAlias(
        $_aliasNameGenerator(db.epgEvents.providerId, db.providerProfiles.id),
      );

  $$ProviderProfilesTableProcessedTableManager get providerId {
    final $_column = $_itemColumn<String>('provider_id')!;

    final manager = $$ProviderProfilesTableTableManager(
      $_db,
      $_db.providerProfiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_providerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EpgEventsTableFilterComposer
    extends Composer<_$ProviderDatabase, $EpgEventsTable> {
  $$EpgEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get start => $composableBuilder(
    column: $table.start,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get end => $composableBuilder(
    column: $table.end,
    builder: (column) => ColumnFilters(column),
  );

  $$ProviderProfilesTableFilterComposer get providerId {
    final $$ProviderProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providerProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProviderProfilesTableFilterComposer(
            $db: $db,
            $table: $db.providerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EpgEventsTableOrderingComposer
    extends Composer<_$ProviderDatabase, $EpgEventsTable> {
  $$EpgEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get start => $composableBuilder(
    column: $table.start,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get end => $composableBuilder(
    column: $table.end,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProviderProfilesTableOrderingComposer get providerId {
    final $$ProviderProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providerProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProviderProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.providerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EpgEventsTableAnnotationComposer
    extends Composer<_$ProviderDatabase, $EpgEventsTable> {
  $$EpgEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get channelId =>
      $composableBuilder(column: $table.channelId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get start =>
      $composableBuilder(column: $table.start, builder: (column) => column);

  GeneratedColumn<DateTime> get end =>
      $composableBuilder(column: $table.end, builder: (column) => column);

  $$ProviderProfilesTableAnnotationComposer get providerId {
    final $$ProviderProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providerProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProviderProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.providerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EpgEventsTableTableManager
    extends
        RootTableManager<
          _$ProviderDatabase,
          $EpgEventsTable,
          EpgEvent,
          $$EpgEventsTableFilterComposer,
          $$EpgEventsTableOrderingComposer,
          $$EpgEventsTableAnnotationComposer,
          $$EpgEventsTableCreateCompanionBuilder,
          $$EpgEventsTableUpdateCompanionBuilder,
          (EpgEvent, $$EpgEventsTableReferences),
          EpgEvent,
          PrefetchHooks Function({bool providerId})
        > {
  $$EpgEventsTableTableManager(_$ProviderDatabase db, $EpgEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EpgEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EpgEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EpgEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> providerId = const Value.absent(),
                Value<String> channelId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> start = const Value.absent(),
                Value<DateTime> end = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EpgEventsCompanion(
                providerId: providerId,
                channelId: channelId,
                title: title,
                description: description,
                start: start,
                end: end,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String providerId,
                required String channelId,
                required String title,
                Value<String?> description = const Value.absent(),
                required DateTime start,
                required DateTime end,
                Value<int> rowid = const Value.absent(),
              }) => EpgEventsCompanion.insert(
                providerId: providerId,
                channelId: channelId,
                title: title,
                description: description,
                start: start,
                end: end,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EpgEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({providerId = false}) {
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
                    if (providerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.providerId,
                                referencedTable: $$EpgEventsTableReferences
                                    ._providerIdTable(db),
                                referencedColumn: $$EpgEventsTableReferences
                                    ._providerIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$EpgEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$ProviderDatabase,
      $EpgEventsTable,
      EpgEvent,
      $$EpgEventsTableFilterComposer,
      $$EpgEventsTableOrderingComposer,
      $$EpgEventsTableAnnotationComposer,
      $$EpgEventsTableCreateCompanionBuilder,
      $$EpgEventsTableUpdateCompanionBuilder,
      (EpgEvent, $$EpgEventsTableReferences),
      EpgEvent,
      PrefetchHooks Function({bool providerId})
    >;
typedef $$FavoritesTableCreateCompanionBuilder =
    FavoritesCompanion Function({
      required String providerId,
      required int contentId,
      required String type,
      required DateTime dateAdded,
      Value<int> rowid,
    });
typedef $$FavoritesTableUpdateCompanionBuilder =
    FavoritesCompanion Function({
      Value<String> providerId,
      Value<int> contentId,
      Value<String> type,
      Value<DateTime> dateAdded,
      Value<int> rowid,
    });

final class $$FavoritesTableReferences
    extends BaseReferences<_$ProviderDatabase, $FavoritesTable, Favorite> {
  $$FavoritesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProviderProfilesTable _providerIdTable(_$ProviderDatabase db) =>
      db.providerProfiles.createAlias(
        $_aliasNameGenerator(db.favorites.providerId, db.providerProfiles.id),
      );

  $$ProviderProfilesTableProcessedTableManager get providerId {
    final $_column = $_itemColumn<String>('provider_id')!;

    final manager = $$ProviderProfilesTableTableManager(
      $_db,
      $_db.providerProfiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_providerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FavoritesTableFilterComposer
    extends Composer<_$ProviderDatabase, $FavoritesTable> {
  $$FavoritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get contentId => $composableBuilder(
    column: $table.contentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateAdded => $composableBuilder(
    column: $table.dateAdded,
    builder: (column) => ColumnFilters(column),
  );

  $$ProviderProfilesTableFilterComposer get providerId {
    final $$ProviderProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providerProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProviderProfilesTableFilterComposer(
            $db: $db,
            $table: $db.providerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoritesTableOrderingComposer
    extends Composer<_$ProviderDatabase, $FavoritesTable> {
  $$FavoritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get contentId => $composableBuilder(
    column: $table.contentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateAdded => $composableBuilder(
    column: $table.dateAdded,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProviderProfilesTableOrderingComposer get providerId {
    final $$ProviderProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providerProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProviderProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.providerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoritesTableAnnotationComposer
    extends Composer<_$ProviderDatabase, $FavoritesTable> {
  $$FavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get contentId =>
      $composableBuilder(column: $table.contentId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get dateAdded =>
      $composableBuilder(column: $table.dateAdded, builder: (column) => column);

  $$ProviderProfilesTableAnnotationComposer get providerId {
    final $$ProviderProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providerProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProviderProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.providerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FavoritesTableTableManager
    extends
        RootTableManager<
          _$ProviderDatabase,
          $FavoritesTable,
          Favorite,
          $$FavoritesTableFilterComposer,
          $$FavoritesTableOrderingComposer,
          $$FavoritesTableAnnotationComposer,
          $$FavoritesTableCreateCompanionBuilder,
          $$FavoritesTableUpdateCompanionBuilder,
          (Favorite, $$FavoritesTableReferences),
          Favorite,
          PrefetchHooks Function({bool providerId})
        > {
  $$FavoritesTableTableManager(_$ProviderDatabase db, $FavoritesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> providerId = const Value.absent(),
                Value<int> contentId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<DateTime> dateAdded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FavoritesCompanion(
                providerId: providerId,
                contentId: contentId,
                type: type,
                dateAdded: dateAdded,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String providerId,
                required int contentId,
                required String type,
                required DateTime dateAdded,
                Value<int> rowid = const Value.absent(),
              }) => FavoritesCompanion.insert(
                providerId: providerId,
                contentId: contentId,
                type: type,
                dateAdded: dateAdded,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FavoritesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({providerId = false}) {
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
                    if (providerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.providerId,
                                referencedTable: $$FavoritesTableReferences
                                    ._providerIdTable(db),
                                referencedColumn: $$FavoritesTableReferences
                                    ._providerIdTable(db)
                                    .id,
                              )
                              as T;
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

typedef $$FavoritesTableProcessedTableManager =
    ProcessedTableManager<
      _$ProviderDatabase,
      $FavoritesTable,
      Favorite,
      $$FavoritesTableFilterComposer,
      $$FavoritesTableOrderingComposer,
      $$FavoritesTableAnnotationComposer,
      $$FavoritesTableCreateCompanionBuilder,
      $$FavoritesTableUpdateCompanionBuilder,
      (Favorite, $$FavoritesTableReferences),
      Favorite,
      PrefetchHooks Function({bool providerId})
    >;
typedef $$PlaybackHistoryTableCreateCompanionBuilder =
    PlaybackHistoryCompanion Function({
      required String providerId,
      required int contentId,
      required String type,
      required int positionSeconds,
      Value<int?> durationSeconds,
      required DateTime lastWatched,
      Value<int> rowid,
    });
typedef $$PlaybackHistoryTableUpdateCompanionBuilder =
    PlaybackHistoryCompanion Function({
      Value<String> providerId,
      Value<int> contentId,
      Value<String> type,
      Value<int> positionSeconds,
      Value<int?> durationSeconds,
      Value<DateTime> lastWatched,
      Value<int> rowid,
    });

final class $$PlaybackHistoryTableReferences
    extends
        BaseReferences<
          _$ProviderDatabase,
          $PlaybackHistoryTable,
          PlaybackHistoryData
        > {
  $$PlaybackHistoryTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProviderProfilesTable _providerIdTable(_$ProviderDatabase db) =>
      db.providerProfiles.createAlias(
        $_aliasNameGenerator(
          db.playbackHistory.providerId,
          db.providerProfiles.id,
        ),
      );

  $$ProviderProfilesTableProcessedTableManager get providerId {
    final $_column = $_itemColumn<String>('provider_id')!;

    final manager = $$ProviderProfilesTableTableManager(
      $_db,
      $_db.providerProfiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_providerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlaybackHistoryTableFilterComposer
    extends Composer<_$ProviderDatabase, $PlaybackHistoryTable> {
  $$PlaybackHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get contentId => $composableBuilder(
    column: $table.contentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get positionSeconds => $composableBuilder(
    column: $table.positionSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastWatched => $composableBuilder(
    column: $table.lastWatched,
    builder: (column) => ColumnFilters(column),
  );

  $$ProviderProfilesTableFilterComposer get providerId {
    final $$ProviderProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providerProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProviderProfilesTableFilterComposer(
            $db: $db,
            $table: $db.providerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaybackHistoryTableOrderingComposer
    extends Composer<_$ProviderDatabase, $PlaybackHistoryTable> {
  $$PlaybackHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get contentId => $composableBuilder(
    column: $table.contentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get positionSeconds => $composableBuilder(
    column: $table.positionSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastWatched => $composableBuilder(
    column: $table.lastWatched,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProviderProfilesTableOrderingComposer get providerId {
    final $$ProviderProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providerProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProviderProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.providerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaybackHistoryTableAnnotationComposer
    extends Composer<_$ProviderDatabase, $PlaybackHistoryTable> {
  $$PlaybackHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get contentId =>
      $composableBuilder(column: $table.contentId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get positionSeconds => $composableBuilder(
    column: $table.positionSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastWatched => $composableBuilder(
    column: $table.lastWatched,
    builder: (column) => column,
  );

  $$ProviderProfilesTableAnnotationComposer get providerId {
    final $$ProviderProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providerProfiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProviderProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.providerProfiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaybackHistoryTableTableManager
    extends
        RootTableManager<
          _$ProviderDatabase,
          $PlaybackHistoryTable,
          PlaybackHistoryData,
          $$PlaybackHistoryTableFilterComposer,
          $$PlaybackHistoryTableOrderingComposer,
          $$PlaybackHistoryTableAnnotationComposer,
          $$PlaybackHistoryTableCreateCompanionBuilder,
          $$PlaybackHistoryTableUpdateCompanionBuilder,
          (PlaybackHistoryData, $$PlaybackHistoryTableReferences),
          PlaybackHistoryData,
          PrefetchHooks Function({bool providerId})
        > {
  $$PlaybackHistoryTableTableManager(
    _$ProviderDatabase db,
    $PlaybackHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaybackHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaybackHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaybackHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> providerId = const Value.absent(),
                Value<int> contentId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> positionSeconds = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<DateTime> lastWatched = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaybackHistoryCompanion(
                providerId: providerId,
                contentId: contentId,
                type: type,
                positionSeconds: positionSeconds,
                durationSeconds: durationSeconds,
                lastWatched: lastWatched,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String providerId,
                required int contentId,
                required String type,
                required int positionSeconds,
                Value<int?> durationSeconds = const Value.absent(),
                required DateTime lastWatched,
                Value<int> rowid = const Value.absent(),
              }) => PlaybackHistoryCompanion.insert(
                providerId: providerId,
                contentId: contentId,
                type: type,
                positionSeconds: positionSeconds,
                durationSeconds: durationSeconds,
                lastWatched: lastWatched,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlaybackHistoryTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({providerId = false}) {
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
                    if (providerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.providerId,
                                referencedTable:
                                    $$PlaybackHistoryTableReferences
                                        ._providerIdTable(db),
                                referencedColumn:
                                    $$PlaybackHistoryTableReferences
                                        ._providerIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$PlaybackHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$ProviderDatabase,
      $PlaybackHistoryTable,
      PlaybackHistoryData,
      $$PlaybackHistoryTableFilterComposer,
      $$PlaybackHistoryTableOrderingComposer,
      $$PlaybackHistoryTableAnnotationComposer,
      $$PlaybackHistoryTableCreateCompanionBuilder,
      $$PlaybackHistoryTableUpdateCompanionBuilder,
      (PlaybackHistoryData, $$PlaybackHistoryTableReferences),
      PlaybackHistoryData,
      PrefetchHooks Function({bool providerId})
    >;

class $ProviderDatabaseManager {
  final _$ProviderDatabase _db;
  $ProviderDatabaseManager(this._db);
  $$ProviderProfilesTableTableManager get providerProfiles =>
      $$ProviderProfilesTableTableManager(_db, _db.providerProfiles);
  $$ProviderSecretsTableTableManager get providerSecrets =>
      $$ProviderSecretsTableTableManager(_db, _db.providerSecrets);
  $$StreamGroupsTableTableManager get streamGroups =>
      $$StreamGroupsTableTableManager(_db, _db.streamGroups);
  $$LiveStreamsTableTableManager get liveStreams =>
      $$LiveStreamsTableTableManager(_db, _db.liveStreams);
  $$VodStreamsTableTableManager get vodStreams =>
      $$VodStreamsTableTableManager(_db, _db.vodStreams);
  $$SeriesTableTableManager get series =>
      $$SeriesTableTableManager(_db, _db.series);
  $$EpisodesTableTableManager get episodes =>
      $$EpisodesTableTableManager(_db, _db.episodes);
  $$EpgEventsTableTableManager get epgEvents =>
      $$EpgEventsTableTableManager(_db, _db.epgEvents);
  $$FavoritesTableTableManager get favorites =>
      $$FavoritesTableTableManager(_db, _db.favorites);
  $$PlaybackHistoryTableTableManager get playbackHistory =>
      $$PlaybackHistoryTableTableManager(_db, _db.playbackHistory);
}
