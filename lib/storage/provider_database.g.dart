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

abstract class _$ProviderDatabase extends GeneratedDatabase {
  _$ProviderDatabase(QueryExecutor e) : super(e);
  $ProviderDatabaseManager get managers => $ProviderDatabaseManager(this);
  late final $ProviderProfilesTable providerProfiles = $ProviderProfilesTable(
    this,
  );
  late final $ProviderSecretsTable providerSecrets = $ProviderSecretsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    providerProfiles,
    providerSecrets,
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
          PrefetchHooks Function({bool providerSecretsRefs})
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
          prefetchHooksCallback: ({providerSecretsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (providerSecretsRefs) db.providerSecrets,
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
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.providerId == item.id),
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
      PrefetchHooks Function({bool providerSecretsRefs})
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

class $ProviderDatabaseManager {
  final _$ProviderDatabase _db;
  $ProviderDatabaseManager(this._db);
  $$ProviderProfilesTableTableManager get providerProfiles =>
      $$ProviderProfilesTableTableManager(_db, _db.providerProfiles);
  $$ProviderSecretsTableTableManager get providerSecrets =>
      $$ProviderSecretsTableTableManager(_db, _db.providerSecrets);
}
