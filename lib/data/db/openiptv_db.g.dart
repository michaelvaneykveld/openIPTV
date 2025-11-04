// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'openiptv_db.dart';

// ignore_for_file: type=lint
class $ProvidersTable extends Providers
    with TableInfo<$ProvidersTable, ProviderRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProvidersTable(this.attachedDatabase, [this._alias]);
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
  @override
  late final GeneratedColumnWithTypeConverter<ProviderKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ProviderKind>($ProvidersTable.$converterkind);
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
  static const VerificationMeta _needsUaMeta = const VerificationMeta(
    'needsUa',
  );
  @override
  late final GeneratedColumn<bool> needsUa = GeneratedColumn<bool>(
    'needs_ua',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("needs_ua" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _allowSelfSignedMeta = const VerificationMeta(
    'allowSelfSigned',
  );
  @override
  late final GeneratedColumn<bool> allowSelfSigned = GeneratedColumn<bool>(
    'allow_self_signed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("allow_self_signed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastSyncAtMeta = const VerificationMeta(
    'lastSyncAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAt = GeneratedColumn<DateTime>(
    'last_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _etagHashMeta = const VerificationMeta(
    'etagHash',
  );
  @override
  late final GeneratedColumn<String> etagHash = GeneratedColumn<String>(
    'etag_hash',
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
    needsUa,
    allowSelfSigned,
    lastSyncAt,
    etagHash,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'providers';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProviderRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('locked_base')) {
      context.handle(
        _lockedBaseMeta,
        lockedBase.isAcceptableOrUnknown(data['locked_base']!, _lockedBaseMeta),
      );
    } else if (isInserting) {
      context.missing(_lockedBaseMeta);
    }
    if (data.containsKey('needs_ua')) {
      context.handle(
        _needsUaMeta,
        needsUa.isAcceptableOrUnknown(data['needs_ua']!, _needsUaMeta),
      );
    }
    if (data.containsKey('allow_self_signed')) {
      context.handle(
        _allowSelfSignedMeta,
        allowSelfSigned.isAcceptableOrUnknown(
          data['allow_self_signed']!,
          _allowSelfSignedMeta,
        ),
      );
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
        _lastSyncAtMeta,
        lastSyncAt.isAcceptableOrUnknown(
          data['last_sync_at']!,
          _lastSyncAtMeta,
        ),
      );
    }
    if (data.containsKey('etag_hash')) {
      context.handle(
        _etagHashMeta,
        etagHash.isAcceptableOrUnknown(data['etag_hash']!, _etagHashMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProviderRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProviderRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kind: $ProvidersTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
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
      needsUa: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}needs_ua'],
      )!,
      allowSelfSigned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}allow_self_signed'],
      )!,
      lastSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_at'],
      ),
      etagHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag_hash'],
      ),
    );
  }

  @override
  $ProvidersTable createAlias(String alias) {
    return $ProvidersTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ProviderKind, String, String> $converterkind =
      const EnumNameConverter<ProviderKind>(ProviderKind.values);
}

class ProviderRecord extends DataClass implements Insertable<ProviderRecord> {
  final int id;
  final ProviderKind kind;
  final String displayName;
  final String lockedBase;
  final bool needsUa;
  final bool allowSelfSigned;
  final DateTime? lastSyncAt;
  final String? etagHash;
  const ProviderRecord({
    required this.id,
    required this.kind,
    required this.displayName,
    required this.lockedBase,
    required this.needsUa,
    required this.allowSelfSigned,
    this.lastSyncAt,
    this.etagHash,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['kind'] = Variable<String>(
        $ProvidersTable.$converterkind.toSql(kind),
      );
    }
    map['display_name'] = Variable<String>(displayName);
    map['locked_base'] = Variable<String>(lockedBase);
    map['needs_ua'] = Variable<bool>(needsUa);
    map['allow_self_signed'] = Variable<bool>(allowSelfSigned);
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt);
    }
    if (!nullToAbsent || etagHash != null) {
      map['etag_hash'] = Variable<String>(etagHash);
    }
    return map;
  }

  ProvidersCompanion toCompanion(bool nullToAbsent) {
    return ProvidersCompanion(
      id: Value(id),
      kind: Value(kind),
      displayName: Value(displayName),
      lockedBase: Value(lockedBase),
      needsUa: Value(needsUa),
      allowSelfSigned: Value(allowSelfSigned),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
      etagHash: etagHash == null && nullToAbsent
          ? const Value.absent()
          : Value(etagHash),
    );
  }

  factory ProviderRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProviderRecord(
      id: serializer.fromJson<int>(json['id']),
      kind: $ProvidersTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      displayName: serializer.fromJson<String>(json['displayName']),
      lockedBase: serializer.fromJson<String>(json['lockedBase']),
      needsUa: serializer.fromJson<bool>(json['needsUa']),
      allowSelfSigned: serializer.fromJson<bool>(json['allowSelfSigned']),
      lastSyncAt: serializer.fromJson<DateTime?>(json['lastSyncAt']),
      etagHash: serializer.fromJson<String?>(json['etagHash']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<String>(
        $ProvidersTable.$converterkind.toJson(kind),
      ),
      'displayName': serializer.toJson<String>(displayName),
      'lockedBase': serializer.toJson<String>(lockedBase),
      'needsUa': serializer.toJson<bool>(needsUa),
      'allowSelfSigned': serializer.toJson<bool>(allowSelfSigned),
      'lastSyncAt': serializer.toJson<DateTime?>(lastSyncAt),
      'etagHash': serializer.toJson<String?>(etagHash),
    };
  }

  ProviderRecord copyWith({
    int? id,
    ProviderKind? kind,
    String? displayName,
    String? lockedBase,
    bool? needsUa,
    bool? allowSelfSigned,
    Value<DateTime?> lastSyncAt = const Value.absent(),
    Value<String?> etagHash = const Value.absent(),
  }) => ProviderRecord(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    displayName: displayName ?? this.displayName,
    lockedBase: lockedBase ?? this.lockedBase,
    needsUa: needsUa ?? this.needsUa,
    allowSelfSigned: allowSelfSigned ?? this.allowSelfSigned,
    lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
    etagHash: etagHash.present ? etagHash.value : this.etagHash,
  );
  ProviderRecord copyWithCompanion(ProvidersCompanion data) {
    return ProviderRecord(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      lockedBase: data.lockedBase.present
          ? data.lockedBase.value
          : this.lockedBase,
      needsUa: data.needsUa.present ? data.needsUa.value : this.needsUa,
      allowSelfSigned: data.allowSelfSigned.present
          ? data.allowSelfSigned.value
          : this.allowSelfSigned,
      lastSyncAt: data.lastSyncAt.present
          ? data.lastSyncAt.value
          : this.lastSyncAt,
      etagHash: data.etagHash.present ? data.etagHash.value : this.etagHash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProviderRecord(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('displayName: $displayName, ')
          ..write('lockedBase: $lockedBase, ')
          ..write('needsUa: $needsUa, ')
          ..write('allowSelfSigned: $allowSelfSigned, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('etagHash: $etagHash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    displayName,
    lockedBase,
    needsUa,
    allowSelfSigned,
    lastSyncAt,
    etagHash,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProviderRecord &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.displayName == this.displayName &&
          other.lockedBase == this.lockedBase &&
          other.needsUa == this.needsUa &&
          other.allowSelfSigned == this.allowSelfSigned &&
          other.lastSyncAt == this.lastSyncAt &&
          other.etagHash == this.etagHash);
}

class ProvidersCompanion extends UpdateCompanion<ProviderRecord> {
  final Value<int> id;
  final Value<ProviderKind> kind;
  final Value<String> displayName;
  final Value<String> lockedBase;
  final Value<bool> needsUa;
  final Value<bool> allowSelfSigned;
  final Value<DateTime?> lastSyncAt;
  final Value<String?> etagHash;
  const ProvidersCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.displayName = const Value.absent(),
    this.lockedBase = const Value.absent(),
    this.needsUa = const Value.absent(),
    this.allowSelfSigned = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.etagHash = const Value.absent(),
  });
  ProvidersCompanion.insert({
    this.id = const Value.absent(),
    required ProviderKind kind,
    this.displayName = const Value.absent(),
    required String lockedBase,
    this.needsUa = const Value.absent(),
    this.allowSelfSigned = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.etagHash = const Value.absent(),
  }) : kind = Value(kind),
       lockedBase = Value(lockedBase);
  static Insertable<ProviderRecord> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<String>? displayName,
    Expression<String>? lockedBase,
    Expression<bool>? needsUa,
    Expression<bool>? allowSelfSigned,
    Expression<DateTime>? lastSyncAt,
    Expression<String>? etagHash,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (displayName != null) 'display_name': displayName,
      if (lockedBase != null) 'locked_base': lockedBase,
      if (needsUa != null) 'needs_ua': needsUa,
      if (allowSelfSigned != null) 'allow_self_signed': allowSelfSigned,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (etagHash != null) 'etag_hash': etagHash,
    });
  }

  ProvidersCompanion copyWith({
    Value<int>? id,
    Value<ProviderKind>? kind,
    Value<String>? displayName,
    Value<String>? lockedBase,
    Value<bool>? needsUa,
    Value<bool>? allowSelfSigned,
    Value<DateTime?>? lastSyncAt,
    Value<String?>? etagHash,
  }) {
    return ProvidersCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      displayName: displayName ?? this.displayName,
      lockedBase: lockedBase ?? this.lockedBase,
      needsUa: needsUa ?? this.needsUa,
      allowSelfSigned: allowSelfSigned ?? this.allowSelfSigned,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      etagHash: etagHash ?? this.etagHash,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $ProvidersTable.$converterkind.toSql(kind.value),
      );
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (lockedBase.present) {
      map['locked_base'] = Variable<String>(lockedBase.value);
    }
    if (needsUa.present) {
      map['needs_ua'] = Variable<bool>(needsUa.value);
    }
    if (allowSelfSigned.present) {
      map['allow_self_signed'] = Variable<bool>(allowSelfSigned.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt.value);
    }
    if (etagHash.present) {
      map['etag_hash'] = Variable<String>(etagHash.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProvidersCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('displayName: $displayName, ')
          ..write('lockedBase: $lockedBase, ')
          ..write('needsUa: $needsUa, ')
          ..write('allowSelfSigned: $allowSelfSigned, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('etagHash: $etagHash')
          ..write(')'))
        .toString();
  }
}

class $ChannelsTable extends Channels
    with TableInfo<$ChannelsTable, ChannelRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChannelsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<int> providerId = GeneratedColumn<int>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES providers (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _providerChannelKeyMeta =
      const VerificationMeta('providerChannelKey');
  @override
  late final GeneratedColumn<String> providerChannelKey =
      GeneratedColumn<String>(
        'provider_channel_key',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
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
  static const VerificationMeta _logoUrlMeta = const VerificationMeta(
    'logoUrl',
  );
  @override
  late final GeneratedColumn<String> logoUrl = GeneratedColumn<String>(
    'logo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
    'number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isRadioMeta = const VerificationMeta(
    'isRadio',
  );
  @override
  late final GeneratedColumn<bool> isRadio = GeneratedColumn<bool>(
    'is_radio',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_radio" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _streamUrlTemplateMeta = const VerificationMeta(
    'streamUrlTemplate',
  );
  @override
  late final GeneratedColumn<String> streamUrlTemplate =
      GeneratedColumn<String>(
        'stream_url_template',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastSeenAtMeta = const VerificationMeta(
    'lastSeenAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSeenAt = GeneratedColumn<DateTime>(
    'last_seen_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    providerId,
    providerChannelKey,
    name,
    logoUrl,
    number,
    isRadio,
    streamUrlTemplate,
    lastSeenAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'channels';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChannelRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('provider_channel_key')) {
      context.handle(
        _providerChannelKeyMeta,
        providerChannelKey.isAcceptableOrUnknown(
          data['provider_channel_key']!,
          _providerChannelKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_providerChannelKeyMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('logo_url')) {
      context.handle(
        _logoUrlMeta,
        logoUrl.isAcceptableOrUnknown(data['logo_url']!, _logoUrlMeta),
      );
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    }
    if (data.containsKey('is_radio')) {
      context.handle(
        _isRadioMeta,
        isRadio.isAcceptableOrUnknown(data['is_radio']!, _isRadioMeta),
      );
    }
    if (data.containsKey('stream_url_template')) {
      context.handle(
        _streamUrlTemplateMeta,
        streamUrlTemplate.isAcceptableOrUnknown(
          data['stream_url_template']!,
          _streamUrlTemplateMeta,
        ),
      );
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
        _lastSeenAtMeta,
        lastSeenAt.isAcceptableOrUnknown(
          data['last_seen_at']!,
          _lastSeenAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {providerId, providerChannelKey},
  ];
  @override
  ChannelRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChannelRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}provider_id'],
      )!,
      providerChannelKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_channel_key'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      logoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}logo_url'],
      ),
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number'],
      ),
      isRadio: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_radio'],
      )!,
      streamUrlTemplate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stream_url_template'],
      ),
      lastSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_seen_at'],
      ),
    );
  }

  @override
  $ChannelsTable createAlias(String alias) {
    return $ChannelsTable(attachedDatabase, alias);
  }
}

class ChannelRecord extends DataClass implements Insertable<ChannelRecord> {
  final int id;
  final int providerId;
  final String providerChannelKey;
  final String name;
  final String? logoUrl;
  final int? number;
  final bool isRadio;
  final String? streamUrlTemplate;
  final DateTime? lastSeenAt;
  const ChannelRecord({
    required this.id,
    required this.providerId,
    required this.providerChannelKey,
    required this.name,
    this.logoUrl,
    this.number,
    required this.isRadio,
    this.streamUrlTemplate,
    this.lastSeenAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['provider_id'] = Variable<int>(providerId);
    map['provider_channel_key'] = Variable<String>(providerChannelKey);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || logoUrl != null) {
      map['logo_url'] = Variable<String>(logoUrl);
    }
    if (!nullToAbsent || number != null) {
      map['number'] = Variable<int>(number);
    }
    map['is_radio'] = Variable<bool>(isRadio);
    if (!nullToAbsent || streamUrlTemplate != null) {
      map['stream_url_template'] = Variable<String>(streamUrlTemplate);
    }
    if (!nullToAbsent || lastSeenAt != null) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt);
    }
    return map;
  }

  ChannelsCompanion toCompanion(bool nullToAbsent) {
    return ChannelsCompanion(
      id: Value(id),
      providerId: Value(providerId),
      providerChannelKey: Value(providerChannelKey),
      name: Value(name),
      logoUrl: logoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(logoUrl),
      number: number == null && nullToAbsent
          ? const Value.absent()
          : Value(number),
      isRadio: Value(isRadio),
      streamUrlTemplate: streamUrlTemplate == null && nullToAbsent
          ? const Value.absent()
          : Value(streamUrlTemplate),
      lastSeenAt: lastSeenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeenAt),
    );
  }

  factory ChannelRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChannelRecord(
      id: serializer.fromJson<int>(json['id']),
      providerId: serializer.fromJson<int>(json['providerId']),
      providerChannelKey: serializer.fromJson<String>(
        json['providerChannelKey'],
      ),
      name: serializer.fromJson<String>(json['name']),
      logoUrl: serializer.fromJson<String?>(json['logoUrl']),
      number: serializer.fromJson<int?>(json['number']),
      isRadio: serializer.fromJson<bool>(json['isRadio']),
      streamUrlTemplate: serializer.fromJson<String?>(
        json['streamUrlTemplate'],
      ),
      lastSeenAt: serializer.fromJson<DateTime?>(json['lastSeenAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'providerId': serializer.toJson<int>(providerId),
      'providerChannelKey': serializer.toJson<String>(providerChannelKey),
      'name': serializer.toJson<String>(name),
      'logoUrl': serializer.toJson<String?>(logoUrl),
      'number': serializer.toJson<int?>(number),
      'isRadio': serializer.toJson<bool>(isRadio),
      'streamUrlTemplate': serializer.toJson<String?>(streamUrlTemplate),
      'lastSeenAt': serializer.toJson<DateTime?>(lastSeenAt),
    };
  }

  ChannelRecord copyWith({
    int? id,
    int? providerId,
    String? providerChannelKey,
    String? name,
    Value<String?> logoUrl = const Value.absent(),
    Value<int?> number = const Value.absent(),
    bool? isRadio,
    Value<String?> streamUrlTemplate = const Value.absent(),
    Value<DateTime?> lastSeenAt = const Value.absent(),
  }) => ChannelRecord(
    id: id ?? this.id,
    providerId: providerId ?? this.providerId,
    providerChannelKey: providerChannelKey ?? this.providerChannelKey,
    name: name ?? this.name,
    logoUrl: logoUrl.present ? logoUrl.value : this.logoUrl,
    number: number.present ? number.value : this.number,
    isRadio: isRadio ?? this.isRadio,
    streamUrlTemplate: streamUrlTemplate.present
        ? streamUrlTemplate.value
        : this.streamUrlTemplate,
    lastSeenAt: lastSeenAt.present ? lastSeenAt.value : this.lastSeenAt,
  );
  ChannelRecord copyWithCompanion(ChannelsCompanion data) {
    return ChannelRecord(
      id: data.id.present ? data.id.value : this.id,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      providerChannelKey: data.providerChannelKey.present
          ? data.providerChannelKey.value
          : this.providerChannelKey,
      name: data.name.present ? data.name.value : this.name,
      logoUrl: data.logoUrl.present ? data.logoUrl.value : this.logoUrl,
      number: data.number.present ? data.number.value : this.number,
      isRadio: data.isRadio.present ? data.isRadio.value : this.isRadio,
      streamUrlTemplate: data.streamUrlTemplate.present
          ? data.streamUrlTemplate.value
          : this.streamUrlTemplate,
      lastSeenAt: data.lastSeenAt.present
          ? data.lastSeenAt.value
          : this.lastSeenAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChannelRecord(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('providerChannelKey: $providerChannelKey, ')
          ..write('name: $name, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('number: $number, ')
          ..write('isRadio: $isRadio, ')
          ..write('streamUrlTemplate: $streamUrlTemplate, ')
          ..write('lastSeenAt: $lastSeenAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    providerId,
    providerChannelKey,
    name,
    logoUrl,
    number,
    isRadio,
    streamUrlTemplate,
    lastSeenAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChannelRecord &&
          other.id == this.id &&
          other.providerId == this.providerId &&
          other.providerChannelKey == this.providerChannelKey &&
          other.name == this.name &&
          other.logoUrl == this.logoUrl &&
          other.number == this.number &&
          other.isRadio == this.isRadio &&
          other.streamUrlTemplate == this.streamUrlTemplate &&
          other.lastSeenAt == this.lastSeenAt);
}

class ChannelsCompanion extends UpdateCompanion<ChannelRecord> {
  final Value<int> id;
  final Value<int> providerId;
  final Value<String> providerChannelKey;
  final Value<String> name;
  final Value<String?> logoUrl;
  final Value<int?> number;
  final Value<bool> isRadio;
  final Value<String?> streamUrlTemplate;
  final Value<DateTime?> lastSeenAt;
  const ChannelsCompanion({
    this.id = const Value.absent(),
    this.providerId = const Value.absent(),
    this.providerChannelKey = const Value.absent(),
    this.name = const Value.absent(),
    this.logoUrl = const Value.absent(),
    this.number = const Value.absent(),
    this.isRadio = const Value.absent(),
    this.streamUrlTemplate = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
  });
  ChannelsCompanion.insert({
    this.id = const Value.absent(),
    required int providerId,
    required String providerChannelKey,
    required String name,
    this.logoUrl = const Value.absent(),
    this.number = const Value.absent(),
    this.isRadio = const Value.absent(),
    this.streamUrlTemplate = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
  }) : providerId = Value(providerId),
       providerChannelKey = Value(providerChannelKey),
       name = Value(name);
  static Insertable<ChannelRecord> custom({
    Expression<int>? id,
    Expression<int>? providerId,
    Expression<String>? providerChannelKey,
    Expression<String>? name,
    Expression<String>? logoUrl,
    Expression<int>? number,
    Expression<bool>? isRadio,
    Expression<String>? streamUrlTemplate,
    Expression<DateTime>? lastSeenAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (providerId != null) 'provider_id': providerId,
      if (providerChannelKey != null)
        'provider_channel_key': providerChannelKey,
      if (name != null) 'name': name,
      if (logoUrl != null) 'logo_url': logoUrl,
      if (number != null) 'number': number,
      if (isRadio != null) 'is_radio': isRadio,
      if (streamUrlTemplate != null) 'stream_url_template': streamUrlTemplate,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
    });
  }

  ChannelsCompanion copyWith({
    Value<int>? id,
    Value<int>? providerId,
    Value<String>? providerChannelKey,
    Value<String>? name,
    Value<String?>? logoUrl,
    Value<int?>? number,
    Value<bool>? isRadio,
    Value<String?>? streamUrlTemplate,
    Value<DateTime?>? lastSeenAt,
  }) {
    return ChannelsCompanion(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      providerChannelKey: providerChannelKey ?? this.providerChannelKey,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      number: number ?? this.number,
      isRadio: isRadio ?? this.isRadio,
      streamUrlTemplate: streamUrlTemplate ?? this.streamUrlTemplate,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<int>(providerId.value);
    }
    if (providerChannelKey.present) {
      map['provider_channel_key'] = Variable<String>(providerChannelKey.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (logoUrl.present) {
      map['logo_url'] = Variable<String>(logoUrl.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (isRadio.present) {
      map['is_radio'] = Variable<bool>(isRadio.value);
    }
    if (streamUrlTemplate.present) {
      map['stream_url_template'] = Variable<String>(streamUrlTemplate.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChannelsCompanion(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('providerChannelKey: $providerChannelKey, ')
          ..write('name: $name, ')
          ..write('logoUrl: $logoUrl, ')
          ..write('number: $number, ')
          ..write('isRadio: $isRadio, ')
          ..write('streamUrlTemplate: $streamUrlTemplate, ')
          ..write('lastSeenAt: $lastSeenAt')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<int> providerId = GeneratedColumn<int>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES providers (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<CategoryKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CategoryKind>($CategoriesTable.$converterkind);
  static const VerificationMeta _providerCategoryKeyMeta =
      const VerificationMeta('providerCategoryKey');
  @override
  late final GeneratedColumn<String> providerCategoryKey =
      GeneratedColumn<String>(
        'provider_category_key',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
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
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    providerId,
    kind,
    providerCategoryKey,
    name,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('provider_category_key')) {
      context.handle(
        _providerCategoryKeyMeta,
        providerCategoryKey.isAcceptableOrUnknown(
          data['provider_category_key']!,
          _providerCategoryKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_providerCategoryKeyMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {providerId, kind, providerCategoryKey},
  ];
  @override
  CategoryRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}provider_id'],
      )!,
      kind: $CategoriesTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      providerCategoryKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_category_key'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      ),
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CategoryKind, String, String> $converterkind =
      const EnumNameConverter<CategoryKind>(CategoryKind.values);
}

class CategoryRecord extends DataClass implements Insertable<CategoryRecord> {
  final int id;
  final int providerId;
  final CategoryKind kind;
  final String providerCategoryKey;
  final String name;
  final int? position;
  const CategoryRecord({
    required this.id,
    required this.providerId,
    required this.kind,
    required this.providerCategoryKey,
    required this.name,
    this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['provider_id'] = Variable<int>(providerId);
    {
      map['kind'] = Variable<String>(
        $CategoriesTable.$converterkind.toSql(kind),
      );
    }
    map['provider_category_key'] = Variable<String>(providerCategoryKey);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || position != null) {
      map['position'] = Variable<int>(position);
    }
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      providerId: Value(providerId),
      kind: Value(kind),
      providerCategoryKey: Value(providerCategoryKey),
      name: Value(name),
      position: position == null && nullToAbsent
          ? const Value.absent()
          : Value(position),
    );
  }

  factory CategoryRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRecord(
      id: serializer.fromJson<int>(json['id']),
      providerId: serializer.fromJson<int>(json['providerId']),
      kind: $CategoriesTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      providerCategoryKey: serializer.fromJson<String>(
        json['providerCategoryKey'],
      ),
      name: serializer.fromJson<String>(json['name']),
      position: serializer.fromJson<int?>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'providerId': serializer.toJson<int>(providerId),
      'kind': serializer.toJson<String>(
        $CategoriesTable.$converterkind.toJson(kind),
      ),
      'providerCategoryKey': serializer.toJson<String>(providerCategoryKey),
      'name': serializer.toJson<String>(name),
      'position': serializer.toJson<int?>(position),
    };
  }

  CategoryRecord copyWith({
    int? id,
    int? providerId,
    CategoryKind? kind,
    String? providerCategoryKey,
    String? name,
    Value<int?> position = const Value.absent(),
  }) => CategoryRecord(
    id: id ?? this.id,
    providerId: providerId ?? this.providerId,
    kind: kind ?? this.kind,
    providerCategoryKey: providerCategoryKey ?? this.providerCategoryKey,
    name: name ?? this.name,
    position: position.present ? position.value : this.position,
  );
  CategoryRecord copyWithCompanion(CategoriesCompanion data) {
    return CategoryRecord(
      id: data.id.present ? data.id.value : this.id,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      kind: data.kind.present ? data.kind.value : this.kind,
      providerCategoryKey: data.providerCategoryKey.present
          ? data.providerCategoryKey.value
          : this.providerCategoryKey,
      name: data.name.present ? data.name.value : this.name,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRecord(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('kind: $kind, ')
          ..write('providerCategoryKey: $providerCategoryKey, ')
          ..write('name: $name, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, providerId, kind, providerCategoryKey, name, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRecord &&
          other.id == this.id &&
          other.providerId == this.providerId &&
          other.kind == this.kind &&
          other.providerCategoryKey == this.providerCategoryKey &&
          other.name == this.name &&
          other.position == this.position);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRecord> {
  final Value<int> id;
  final Value<int> providerId;
  final Value<CategoryKind> kind;
  final Value<String> providerCategoryKey;
  final Value<String> name;
  final Value<int?> position;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.providerId = const Value.absent(),
    this.kind = const Value.absent(),
    this.providerCategoryKey = const Value.absent(),
    this.name = const Value.absent(),
    this.position = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required int providerId,
    required CategoryKind kind,
    required String providerCategoryKey,
    required String name,
    this.position = const Value.absent(),
  }) : providerId = Value(providerId),
       kind = Value(kind),
       providerCategoryKey = Value(providerCategoryKey),
       name = Value(name);
  static Insertable<CategoryRecord> custom({
    Expression<int>? id,
    Expression<int>? providerId,
    Expression<String>? kind,
    Expression<String>? providerCategoryKey,
    Expression<String>? name,
    Expression<int>? position,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (providerId != null) 'provider_id': providerId,
      if (kind != null) 'kind': kind,
      if (providerCategoryKey != null)
        'provider_category_key': providerCategoryKey,
      if (name != null) 'name': name,
      if (position != null) 'position': position,
    });
  }

  CategoriesCompanion copyWith({
    Value<int>? id,
    Value<int>? providerId,
    Value<CategoryKind>? kind,
    Value<String>? providerCategoryKey,
    Value<String>? name,
    Value<int?>? position,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      kind: kind ?? this.kind,
      providerCategoryKey: providerCategoryKey ?? this.providerCategoryKey,
      name: name ?? this.name,
      position: position ?? this.position,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<int>(providerId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $CategoriesTable.$converterkind.toSql(kind.value),
      );
    }
    if (providerCategoryKey.present) {
      map['provider_category_key'] = Variable<String>(
        providerCategoryKey.value,
      );
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('kind: $kind, ')
          ..write('providerCategoryKey: $providerCategoryKey, ')
          ..write('name: $name, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }
}

class $ChannelCategoriesTable extends ChannelCategories
    with TableInfo<$ChannelCategoriesTable, ChannelCategoryRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChannelCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _channelIdMeta = const VerificationMeta(
    'channelId',
  );
  @override
  late final GeneratedColumn<int> channelId = GeneratedColumn<int>(
    'channel_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES channels (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [channelId, categoryId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'channel_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChannelCategoryRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('channel_id')) {
      context.handle(
        _channelIdMeta,
        channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_channelIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {channelId, categoryId};
  @override
  ChannelCategoryRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChannelCategoryRecord(
      channelId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}channel_id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      )!,
    );
  }

  @override
  $ChannelCategoriesTable createAlias(String alias) {
    return $ChannelCategoriesTable(attachedDatabase, alias);
  }
}

class ChannelCategoryRecord extends DataClass
    implements Insertable<ChannelCategoryRecord> {
  final int channelId;
  final int categoryId;
  const ChannelCategoryRecord({
    required this.channelId,
    required this.categoryId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['channel_id'] = Variable<int>(channelId);
    map['category_id'] = Variable<int>(categoryId);
    return map;
  }

  ChannelCategoriesCompanion toCompanion(bool nullToAbsent) {
    return ChannelCategoriesCompanion(
      channelId: Value(channelId),
      categoryId: Value(categoryId),
    );
  }

  factory ChannelCategoryRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChannelCategoryRecord(
      channelId: serializer.fromJson<int>(json['channelId']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'channelId': serializer.toJson<int>(channelId),
      'categoryId': serializer.toJson<int>(categoryId),
    };
  }

  ChannelCategoryRecord copyWith({int? channelId, int? categoryId}) =>
      ChannelCategoryRecord(
        channelId: channelId ?? this.channelId,
        categoryId: categoryId ?? this.categoryId,
      );
  ChannelCategoryRecord copyWithCompanion(ChannelCategoriesCompanion data) {
    return ChannelCategoryRecord(
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChannelCategoryRecord(')
          ..write('channelId: $channelId, ')
          ..write('categoryId: $categoryId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(channelId, categoryId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChannelCategoryRecord &&
          other.channelId == this.channelId &&
          other.categoryId == this.categoryId);
}

class ChannelCategoriesCompanion
    extends UpdateCompanion<ChannelCategoryRecord> {
  final Value<int> channelId;
  final Value<int> categoryId;
  final Value<int> rowid;
  const ChannelCategoriesCompanion({
    this.channelId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChannelCategoriesCompanion.insert({
    required int channelId,
    required int categoryId,
    this.rowid = const Value.absent(),
  }) : channelId = Value(channelId),
       categoryId = Value(categoryId);
  static Insertable<ChannelCategoryRecord> custom({
    Expression<int>? channelId,
    Expression<int>? categoryId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (channelId != null) 'channel_id': channelId,
      if (categoryId != null) 'category_id': categoryId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChannelCategoriesCompanion copyWith({
    Value<int>? channelId,
    Value<int>? categoryId,
    Value<int>? rowid,
  }) {
    return ChannelCategoriesCompanion(
      channelId: channelId ?? this.channelId,
      categoryId: categoryId ?? this.categoryId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (channelId.present) {
      map['channel_id'] = Variable<int>(channelId.value);
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
    return (StringBuffer('ChannelCategoriesCompanion(')
          ..write('channelId: $channelId, ')
          ..write('categoryId: $categoryId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SummariesTable extends Summaries
    with TableInfo<$SummariesTable, SummaryRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SummariesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<int> providerId = GeneratedColumn<int>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES providers (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<CategoryKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<CategoryKind>($SummariesTable.$converterkind);
  static const VerificationMeta _totalItemsMeta = const VerificationMeta(
    'totalItems',
  );
  @override
  late final GeneratedColumn<int> totalItems = GeneratedColumn<int>(
    'total_items',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    providerId,
    kind,
    totalItems,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'summaries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SummaryRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('total_items')) {
      context.handle(
        _totalItemsMeta,
        totalItems.isAcceptableOrUnknown(data['total_items']!, _totalItemsMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {providerId, kind},
  ];
  @override
  SummaryRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SummaryRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}provider_id'],
      )!,
      kind: $SummariesTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      totalItems: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_items'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SummariesTable createAlias(String alias) {
    return $SummariesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CategoryKind, String, String> $converterkind =
      const EnumNameConverter<CategoryKind>(CategoryKind.values);
}

class SummaryRecord extends DataClass implements Insertable<SummaryRecord> {
  final int id;
  final int providerId;
  final CategoryKind kind;
  final int totalItems;
  final DateTime updatedAt;
  const SummaryRecord({
    required this.id,
    required this.providerId,
    required this.kind,
    required this.totalItems,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['provider_id'] = Variable<int>(providerId);
    {
      map['kind'] = Variable<String>(
        $SummariesTable.$converterkind.toSql(kind),
      );
    }
    map['total_items'] = Variable<int>(totalItems);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SummariesCompanion toCompanion(bool nullToAbsent) {
    return SummariesCompanion(
      id: Value(id),
      providerId: Value(providerId),
      kind: Value(kind),
      totalItems: Value(totalItems),
      updatedAt: Value(updatedAt),
    );
  }

  factory SummaryRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SummaryRecord(
      id: serializer.fromJson<int>(json['id']),
      providerId: serializer.fromJson<int>(json['providerId']),
      kind: $SummariesTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      totalItems: serializer.fromJson<int>(json['totalItems']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'providerId': serializer.toJson<int>(providerId),
      'kind': serializer.toJson<String>(
        $SummariesTable.$converterkind.toJson(kind),
      ),
      'totalItems': serializer.toJson<int>(totalItems),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SummaryRecord copyWith({
    int? id,
    int? providerId,
    CategoryKind? kind,
    int? totalItems,
    DateTime? updatedAt,
  }) => SummaryRecord(
    id: id ?? this.id,
    providerId: providerId ?? this.providerId,
    kind: kind ?? this.kind,
    totalItems: totalItems ?? this.totalItems,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SummaryRecord copyWithCompanion(SummariesCompanion data) {
    return SummaryRecord(
      id: data.id.present ? data.id.value : this.id,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      kind: data.kind.present ? data.kind.value : this.kind,
      totalItems: data.totalItems.present
          ? data.totalItems.value
          : this.totalItems,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SummaryRecord(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('kind: $kind, ')
          ..write('totalItems: $totalItems, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, providerId, kind, totalItems, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SummaryRecord &&
          other.id == this.id &&
          other.providerId == this.providerId &&
          other.kind == this.kind &&
          other.totalItems == this.totalItems &&
          other.updatedAt == this.updatedAt);
}

class SummariesCompanion extends UpdateCompanion<SummaryRecord> {
  final Value<int> id;
  final Value<int> providerId;
  final Value<CategoryKind> kind;
  final Value<int> totalItems;
  final Value<DateTime> updatedAt;
  const SummariesCompanion({
    this.id = const Value.absent(),
    this.providerId = const Value.absent(),
    this.kind = const Value.absent(),
    this.totalItems = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SummariesCompanion.insert({
    this.id = const Value.absent(),
    required int providerId,
    required CategoryKind kind,
    this.totalItems = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : providerId = Value(providerId),
       kind = Value(kind);
  static Insertable<SummaryRecord> custom({
    Expression<int>? id,
    Expression<int>? providerId,
    Expression<String>? kind,
    Expression<int>? totalItems,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (providerId != null) 'provider_id': providerId,
      if (kind != null) 'kind': kind,
      if (totalItems != null) 'total_items': totalItems,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SummariesCompanion copyWith({
    Value<int>? id,
    Value<int>? providerId,
    Value<CategoryKind>? kind,
    Value<int>? totalItems,
    Value<DateTime>? updatedAt,
  }) {
    return SummariesCompanion(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      kind: kind ?? this.kind,
      totalItems: totalItems ?? this.totalItems,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<int>(providerId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $SummariesTable.$converterkind.toSql(kind.value),
      );
    }
    if (totalItems.present) {
      map['total_items'] = Variable<int>(totalItems.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SummariesCompanion(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('kind: $kind, ')
          ..write('totalItems: $totalItems, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $EpgProgramsTable extends EpgPrograms
    with TableInfo<$EpgProgramsTable, EpgProgramRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EpgProgramsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _channelIdMeta = const VerificationMeta(
    'channelId',
  );
  @override
  late final GeneratedColumn<int> channelId = GeneratedColumn<int>(
    'channel_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES channels (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _startUtcMeta = const VerificationMeta(
    'startUtc',
  );
  @override
  late final GeneratedColumn<DateTime> startUtc = GeneratedColumn<DateTime>(
    'start_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endUtcMeta = const VerificationMeta('endUtc');
  @override
  late final GeneratedColumn<DateTime> endUtc = GeneratedColumn<DateTime>(
    'end_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subtitleMeta = const VerificationMeta(
    'subtitle',
  );
  @override
  late final GeneratedColumn<String> subtitle = GeneratedColumn<String>(
    'subtitle',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    channelId,
    startUtc,
    endUtc,
    title,
    subtitle,
    description,
    season,
    episode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'epg_programs';
  @override
  VerificationContext validateIntegrity(
    Insertable<EpgProgramRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('channel_id')) {
      context.handle(
        _channelIdMeta,
        channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_channelIdMeta);
    }
    if (data.containsKey('start_utc')) {
      context.handle(
        _startUtcMeta,
        startUtc.isAcceptableOrUnknown(data['start_utc']!, _startUtcMeta),
      );
    } else if (isInserting) {
      context.missing(_startUtcMeta);
    }
    if (data.containsKey('end_utc')) {
      context.handle(
        _endUtcMeta,
        endUtc.isAcceptableOrUnknown(data['end_utc']!, _endUtcMeta),
      );
    } else if (isInserting) {
      context.missing(_endUtcMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('subtitle')) {
      context.handle(
        _subtitleMeta,
        subtitle.isAcceptableOrUnknown(data['subtitle']!, _subtitleMeta),
      );
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {channelId, startUtc},
  ];
  @override
  EpgProgramRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EpgProgramRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      channelId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}channel_id'],
      )!,
      startUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_utc'],
      )!,
      endUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_utc'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      subtitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtitle'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      season: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}season'],
      ),
      episode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}episode'],
      ),
    );
  }

  @override
  $EpgProgramsTable createAlias(String alias) {
    return $EpgProgramsTable(attachedDatabase, alias);
  }
}

class EpgProgramRecord extends DataClass
    implements Insertable<EpgProgramRecord> {
  final int id;
  final int channelId;
  final DateTime startUtc;
  final DateTime endUtc;
  final String? title;
  final String? subtitle;
  final String? description;
  final int? season;
  final int? episode;
  const EpgProgramRecord({
    required this.id,
    required this.channelId,
    required this.startUtc,
    required this.endUtc,
    this.title,
    this.subtitle,
    this.description,
    this.season,
    this.episode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['channel_id'] = Variable<int>(channelId);
    map['start_utc'] = Variable<DateTime>(startUtc);
    map['end_utc'] = Variable<DateTime>(endUtc);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || subtitle != null) {
      map['subtitle'] = Variable<String>(subtitle);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || season != null) {
      map['season'] = Variable<int>(season);
    }
    if (!nullToAbsent || episode != null) {
      map['episode'] = Variable<int>(episode);
    }
    return map;
  }

  EpgProgramsCompanion toCompanion(bool nullToAbsent) {
    return EpgProgramsCompanion(
      id: Value(id),
      channelId: Value(channelId),
      startUtc: Value(startUtc),
      endUtc: Value(endUtc),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      subtitle: subtitle == null && nullToAbsent
          ? const Value.absent()
          : Value(subtitle),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      season: season == null && nullToAbsent
          ? const Value.absent()
          : Value(season),
      episode: episode == null && nullToAbsent
          ? const Value.absent()
          : Value(episode),
    );
  }

  factory EpgProgramRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EpgProgramRecord(
      id: serializer.fromJson<int>(json['id']),
      channelId: serializer.fromJson<int>(json['channelId']),
      startUtc: serializer.fromJson<DateTime>(json['startUtc']),
      endUtc: serializer.fromJson<DateTime>(json['endUtc']),
      title: serializer.fromJson<String?>(json['title']),
      subtitle: serializer.fromJson<String?>(json['subtitle']),
      description: serializer.fromJson<String?>(json['description']),
      season: serializer.fromJson<int?>(json['season']),
      episode: serializer.fromJson<int?>(json['episode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'channelId': serializer.toJson<int>(channelId),
      'startUtc': serializer.toJson<DateTime>(startUtc),
      'endUtc': serializer.toJson<DateTime>(endUtc),
      'title': serializer.toJson<String?>(title),
      'subtitle': serializer.toJson<String?>(subtitle),
      'description': serializer.toJson<String?>(description),
      'season': serializer.toJson<int?>(season),
      'episode': serializer.toJson<int?>(episode),
    };
  }

  EpgProgramRecord copyWith({
    int? id,
    int? channelId,
    DateTime? startUtc,
    DateTime? endUtc,
    Value<String?> title = const Value.absent(),
    Value<String?> subtitle = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<int?> season = const Value.absent(),
    Value<int?> episode = const Value.absent(),
  }) => EpgProgramRecord(
    id: id ?? this.id,
    channelId: channelId ?? this.channelId,
    startUtc: startUtc ?? this.startUtc,
    endUtc: endUtc ?? this.endUtc,
    title: title.present ? title.value : this.title,
    subtitle: subtitle.present ? subtitle.value : this.subtitle,
    description: description.present ? description.value : this.description,
    season: season.present ? season.value : this.season,
    episode: episode.present ? episode.value : this.episode,
  );
  EpgProgramRecord copyWithCompanion(EpgProgramsCompanion data) {
    return EpgProgramRecord(
      id: data.id.present ? data.id.value : this.id,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      startUtc: data.startUtc.present ? data.startUtc.value : this.startUtc,
      endUtc: data.endUtc.present ? data.endUtc.value : this.endUtc,
      title: data.title.present ? data.title.value : this.title,
      subtitle: data.subtitle.present ? data.subtitle.value : this.subtitle,
      description: data.description.present
          ? data.description.value
          : this.description,
      season: data.season.present ? data.season.value : this.season,
      episode: data.episode.present ? data.episode.value : this.episode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EpgProgramRecord(')
          ..write('id: $id, ')
          ..write('channelId: $channelId, ')
          ..write('startUtc: $startUtc, ')
          ..write('endUtc: $endUtc, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('description: $description, ')
          ..write('season: $season, ')
          ..write('episode: $episode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    channelId,
    startUtc,
    endUtc,
    title,
    subtitle,
    description,
    season,
    episode,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EpgProgramRecord &&
          other.id == this.id &&
          other.channelId == this.channelId &&
          other.startUtc == this.startUtc &&
          other.endUtc == this.endUtc &&
          other.title == this.title &&
          other.subtitle == this.subtitle &&
          other.description == this.description &&
          other.season == this.season &&
          other.episode == this.episode);
}

class EpgProgramsCompanion extends UpdateCompanion<EpgProgramRecord> {
  final Value<int> id;
  final Value<int> channelId;
  final Value<DateTime> startUtc;
  final Value<DateTime> endUtc;
  final Value<String?> title;
  final Value<String?> subtitle;
  final Value<String?> description;
  final Value<int?> season;
  final Value<int?> episode;
  const EpgProgramsCompanion({
    this.id = const Value.absent(),
    this.channelId = const Value.absent(),
    this.startUtc = const Value.absent(),
    this.endUtc = const Value.absent(),
    this.title = const Value.absent(),
    this.subtitle = const Value.absent(),
    this.description = const Value.absent(),
    this.season = const Value.absent(),
    this.episode = const Value.absent(),
  });
  EpgProgramsCompanion.insert({
    this.id = const Value.absent(),
    required int channelId,
    required DateTime startUtc,
    required DateTime endUtc,
    this.title = const Value.absent(),
    this.subtitle = const Value.absent(),
    this.description = const Value.absent(),
    this.season = const Value.absent(),
    this.episode = const Value.absent(),
  }) : channelId = Value(channelId),
       startUtc = Value(startUtc),
       endUtc = Value(endUtc);
  static Insertable<EpgProgramRecord> custom({
    Expression<int>? id,
    Expression<int>? channelId,
    Expression<DateTime>? startUtc,
    Expression<DateTime>? endUtc,
    Expression<String>? title,
    Expression<String>? subtitle,
    Expression<String>? description,
    Expression<int>? season,
    Expression<int>? episode,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (channelId != null) 'channel_id': channelId,
      if (startUtc != null) 'start_utc': startUtc,
      if (endUtc != null) 'end_utc': endUtc,
      if (title != null) 'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (description != null) 'description': description,
      if (season != null) 'season': season,
      if (episode != null) 'episode': episode,
    });
  }

  EpgProgramsCompanion copyWith({
    Value<int>? id,
    Value<int>? channelId,
    Value<DateTime>? startUtc,
    Value<DateTime>? endUtc,
    Value<String?>? title,
    Value<String?>? subtitle,
    Value<String?>? description,
    Value<int?>? season,
    Value<int?>? episode,
  }) {
    return EpgProgramsCompanion(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      startUtc: startUtc ?? this.startUtc,
      endUtc: endUtc ?? this.endUtc,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      season: season ?? this.season,
      episode: episode ?? this.episode,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (channelId.present) {
      map['channel_id'] = Variable<int>(channelId.value);
    }
    if (startUtc.present) {
      map['start_utc'] = Variable<DateTime>(startUtc.value);
    }
    if (endUtc.present) {
      map['end_utc'] = Variable<DateTime>(endUtc.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subtitle.present) {
      map['subtitle'] = Variable<String>(subtitle.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (season.present) {
      map['season'] = Variable<int>(season.value);
    }
    if (episode.present) {
      map['episode'] = Variable<int>(episode.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EpgProgramsCompanion(')
          ..write('id: $id, ')
          ..write('channelId: $channelId, ')
          ..write('startUtc: $startUtc, ')
          ..write('endUtc: $endUtc, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('description: $description, ')
          ..write('season: $season, ')
          ..write('episode: $episode')
          ..write(')'))
        .toString();
  }
}

abstract class _$OpenIptvDb extends GeneratedDatabase {
  _$OpenIptvDb(QueryExecutor e) : super(e);
  $OpenIptvDbManager get managers => $OpenIptvDbManager(this);
  late final $ProvidersTable providers = $ProvidersTable(this);
  late final $ChannelsTable channels = $ChannelsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $ChannelCategoriesTable channelCategories =
      $ChannelCategoriesTable(this);
  late final $SummariesTable summaries = $SummariesTable(this);
  late final $EpgProgramsTable epgPrograms = $EpgProgramsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    providers,
    channels,
    categories,
    channelCategories,
    summaries,
    epgPrograms,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'providers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('channels', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'providers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('categories', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'channels',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('channel_categories', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'categories',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('channel_categories', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'providers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('summaries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'channels',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('epg_programs', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ProvidersTableCreateCompanionBuilder =
    ProvidersCompanion Function({
      Value<int> id,
      required ProviderKind kind,
      Value<String> displayName,
      required String lockedBase,
      Value<bool> needsUa,
      Value<bool> allowSelfSigned,
      Value<DateTime?> lastSyncAt,
      Value<String?> etagHash,
    });
typedef $$ProvidersTableUpdateCompanionBuilder =
    ProvidersCompanion Function({
      Value<int> id,
      Value<ProviderKind> kind,
      Value<String> displayName,
      Value<String> lockedBase,
      Value<bool> needsUa,
      Value<bool> allowSelfSigned,
      Value<DateTime?> lastSyncAt,
      Value<String?> etagHash,
    });

final class $$ProvidersTableReferences
    extends BaseReferences<_$OpenIptvDb, $ProvidersTable, ProviderRecord> {
  $$ProvidersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ChannelsTable, List<ChannelRecord>>
  _channelsRefsTable(_$OpenIptvDb db) => MultiTypedResultKey.fromTable(
    db.channels,
    aliasName: $_aliasNameGenerator(db.providers.id, db.channels.providerId),
  );

  $$ChannelsTableProcessedTableManager get channelsRefs {
    final manager = $$ChannelsTableTableManager(
      $_db,
      $_db.channels,
    ).filter((f) => f.providerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_channelsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CategoriesTable, List<CategoryRecord>>
  _categoriesRefsTable(_$OpenIptvDb db) => MultiTypedResultKey.fromTable(
    db.categories,
    aliasName: $_aliasNameGenerator(db.providers.id, db.categories.providerId),
  );

  $$CategoriesTableProcessedTableManager get categoriesRefs {
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.providerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_categoriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SummariesTable, List<SummaryRecord>>
  _summariesRefsTable(_$OpenIptvDb db) => MultiTypedResultKey.fromTable(
    db.summaries,
    aliasName: $_aliasNameGenerator(db.providers.id, db.summaries.providerId),
  );

  $$SummariesTableProcessedTableManager get summariesRefs {
    final manager = $$SummariesTableTableManager(
      $_db,
      $_db.summaries,
    ).filter((f) => f.providerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_summariesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProvidersTableFilterComposer
    extends Composer<_$OpenIptvDb, $ProvidersTable> {
  $$ProvidersTableFilterComposer({
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

  ColumnWithTypeConverterFilters<ProviderKind, ProviderKind, String> get kind =>
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

  ColumnFilters<bool> get needsUa => $composableBuilder(
    column: $table.needsUa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get allowSelfSigned => $composableBuilder(
    column: $table.allowSelfSigned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etagHash => $composableBuilder(
    column: $table.etagHash,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> channelsRefs(
    Expression<bool> Function($$ChannelsTableFilterComposer f) f,
  ) {
    final $$ChannelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.channels,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableFilterComposer(
            $db: $db,
            $table: $db.channels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> categoriesRefs(
    Expression<bool> Function($$CategoriesTableFilterComposer f) f,
  ) {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> summariesRefs(
    Expression<bool> Function($$SummariesTableFilterComposer f) f,
  ) {
    final $$SummariesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.summaries,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SummariesTableFilterComposer(
            $db: $db,
            $table: $db.summaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProvidersTableOrderingComposer
    extends Composer<_$OpenIptvDb, $ProvidersTable> {
  $$ProvidersTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
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

  ColumnOrderings<bool> get needsUa => $composableBuilder(
    column: $table.needsUa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get allowSelfSigned => $composableBuilder(
    column: $table.allowSelfSigned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etagHash => $composableBuilder(
    column: $table.etagHash,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProvidersTableAnnotationComposer
    extends Composer<_$OpenIptvDb, $ProvidersTable> {
  $$ProvidersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ProviderKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lockedBase => $composableBuilder(
    column: $table.lockedBase,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get needsUa =>
      $composableBuilder(column: $table.needsUa, builder: (column) => column);

  GeneratedColumn<bool> get allowSelfSigned => $composableBuilder(
    column: $table.allowSelfSigned,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get etagHash =>
      $composableBuilder(column: $table.etagHash, builder: (column) => column);

  Expression<T> channelsRefs<T extends Object>(
    Expression<T> Function($$ChannelsTableAnnotationComposer a) f,
  ) {
    final $$ChannelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.channels,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableAnnotationComposer(
            $db: $db,
            $table: $db.channels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> categoriesRefs<T extends Object>(
    Expression<T> Function($$CategoriesTableAnnotationComposer a) f,
  ) {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> summariesRefs<T extends Object>(
    Expression<T> Function($$SummariesTableAnnotationComposer a) f,
  ) {
    final $$SummariesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.summaries,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SummariesTableAnnotationComposer(
            $db: $db,
            $table: $db.summaries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProvidersTableTableManager
    extends
        RootTableManager<
          _$OpenIptvDb,
          $ProvidersTable,
          ProviderRecord,
          $$ProvidersTableFilterComposer,
          $$ProvidersTableOrderingComposer,
          $$ProvidersTableAnnotationComposer,
          $$ProvidersTableCreateCompanionBuilder,
          $$ProvidersTableUpdateCompanionBuilder,
          (ProviderRecord, $$ProvidersTableReferences),
          ProviderRecord,
          PrefetchHooks Function({
            bool channelsRefs,
            bool categoriesRefs,
            bool summariesRefs,
          })
        > {
  $$ProvidersTableTableManager(_$OpenIptvDb db, $ProvidersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProvidersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProvidersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProvidersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<ProviderKind> kind = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> lockedBase = const Value.absent(),
                Value<bool> needsUa = const Value.absent(),
                Value<bool> allowSelfSigned = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
                Value<String?> etagHash = const Value.absent(),
              }) => ProvidersCompanion(
                id: id,
                kind: kind,
                displayName: displayName,
                lockedBase: lockedBase,
                needsUa: needsUa,
                allowSelfSigned: allowSelfSigned,
                lastSyncAt: lastSyncAt,
                etagHash: etagHash,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required ProviderKind kind,
                Value<String> displayName = const Value.absent(),
                required String lockedBase,
                Value<bool> needsUa = const Value.absent(),
                Value<bool> allowSelfSigned = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
                Value<String?> etagHash = const Value.absent(),
              }) => ProvidersCompanion.insert(
                id: id,
                kind: kind,
                displayName: displayName,
                lockedBase: lockedBase,
                needsUa: needsUa,
                allowSelfSigned: allowSelfSigned,
                lastSyncAt: lastSyncAt,
                etagHash: etagHash,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProvidersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                channelsRefs = false,
                categoriesRefs = false,
                summariesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (channelsRefs) db.channels,
                    if (categoriesRefs) db.categories,
                    if (summariesRefs) db.summaries,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (channelsRefs)
                        await $_getPrefetchedData<
                          ProviderRecord,
                          $ProvidersTable,
                          ChannelRecord
                        >(
                          currentTable: table,
                          referencedTable: $$ProvidersTableReferences
                              ._channelsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProvidersTableReferences(
                                db,
                                table,
                                p0,
                              ).channelsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.providerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (categoriesRefs)
                        await $_getPrefetchedData<
                          ProviderRecord,
                          $ProvidersTable,
                          CategoryRecord
                        >(
                          currentTable: table,
                          referencedTable: $$ProvidersTableReferences
                              ._categoriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProvidersTableReferences(
                                db,
                                table,
                                p0,
                              ).categoriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.providerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (summariesRefs)
                        await $_getPrefetchedData<
                          ProviderRecord,
                          $ProvidersTable,
                          SummaryRecord
                        >(
                          currentTable: table,
                          referencedTable: $$ProvidersTableReferences
                              ._summariesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProvidersTableReferences(
                                db,
                                table,
                                p0,
                              ).summariesRefs,
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

typedef $$ProvidersTableProcessedTableManager =
    ProcessedTableManager<
      _$OpenIptvDb,
      $ProvidersTable,
      ProviderRecord,
      $$ProvidersTableFilterComposer,
      $$ProvidersTableOrderingComposer,
      $$ProvidersTableAnnotationComposer,
      $$ProvidersTableCreateCompanionBuilder,
      $$ProvidersTableUpdateCompanionBuilder,
      (ProviderRecord, $$ProvidersTableReferences),
      ProviderRecord,
      PrefetchHooks Function({
        bool channelsRefs,
        bool categoriesRefs,
        bool summariesRefs,
      })
    >;
typedef $$ChannelsTableCreateCompanionBuilder =
    ChannelsCompanion Function({
      Value<int> id,
      required int providerId,
      required String providerChannelKey,
      required String name,
      Value<String?> logoUrl,
      Value<int?> number,
      Value<bool> isRadio,
      Value<String?> streamUrlTemplate,
      Value<DateTime?> lastSeenAt,
    });
typedef $$ChannelsTableUpdateCompanionBuilder =
    ChannelsCompanion Function({
      Value<int> id,
      Value<int> providerId,
      Value<String> providerChannelKey,
      Value<String> name,
      Value<String?> logoUrl,
      Value<int?> number,
      Value<bool> isRadio,
      Value<String?> streamUrlTemplate,
      Value<DateTime?> lastSeenAt,
    });

final class $$ChannelsTableReferences
    extends BaseReferences<_$OpenIptvDb, $ChannelsTable, ChannelRecord> {
  $$ChannelsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProvidersTable _providerIdTable(_$OpenIptvDb db) =>
      db.providers.createAlias(
        $_aliasNameGenerator(db.channels.providerId, db.providers.id),
      );

  $$ProvidersTableProcessedTableManager get providerId {
    final $_column = $_itemColumn<int>('provider_id')!;

    final manager = $$ProvidersTableTableManager(
      $_db,
      $_db.providers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_providerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $ChannelCategoriesTable,
    List<ChannelCategoryRecord>
  >
  _channelCategoriesRefsTable(_$OpenIptvDb db) => MultiTypedResultKey.fromTable(
    db.channelCategories,
    aliasName: $_aliasNameGenerator(
      db.channels.id,
      db.channelCategories.channelId,
    ),
  );

  $$ChannelCategoriesTableProcessedTableManager get channelCategoriesRefs {
    final manager = $$ChannelCategoriesTableTableManager(
      $_db,
      $_db.channelCategories,
    ).filter((f) => f.channelId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _channelCategoriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EpgProgramsTable, List<EpgProgramRecord>>
  _epgProgramsRefsTable(_$OpenIptvDb db) => MultiTypedResultKey.fromTable(
    db.epgPrograms,
    aliasName: $_aliasNameGenerator(db.channels.id, db.epgPrograms.channelId),
  );

  $$EpgProgramsTableProcessedTableManager get epgProgramsRefs {
    final manager = $$EpgProgramsTableTableManager(
      $_db,
      $_db.epgPrograms,
    ).filter((f) => f.channelId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_epgProgramsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ChannelsTableFilterComposer
    extends Composer<_$OpenIptvDb, $ChannelsTable> {
  $$ChannelsTableFilterComposer({
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

  ColumnFilters<String> get providerChannelKey => $composableBuilder(
    column: $table.providerChannelKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logoUrl => $composableBuilder(
    column: $table.logoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRadio => $composableBuilder(
    column: $table.isRadio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get streamUrlTemplate => $composableBuilder(
    column: $table.streamUrlTemplate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ProvidersTableFilterComposer get providerId {
    final $$ProvidersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProvidersTableFilterComposer(
            $db: $db,
            $table: $db.providers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> channelCategoriesRefs(
    Expression<bool> Function($$ChannelCategoriesTableFilterComposer f) f,
  ) {
    final $$ChannelCategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.channelCategories,
      getReferencedColumn: (t) => t.channelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelCategoriesTableFilterComposer(
            $db: $db,
            $table: $db.channelCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> epgProgramsRefs(
    Expression<bool> Function($$EpgProgramsTableFilterComposer f) f,
  ) {
    final $$EpgProgramsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.epgPrograms,
      getReferencedColumn: (t) => t.channelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpgProgramsTableFilterComposer(
            $db: $db,
            $table: $db.epgPrograms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChannelsTableOrderingComposer
    extends Composer<_$OpenIptvDb, $ChannelsTable> {
  $$ChannelsTableOrderingComposer({
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

  ColumnOrderings<String> get providerChannelKey => $composableBuilder(
    column: $table.providerChannelKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logoUrl => $composableBuilder(
    column: $table.logoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRadio => $composableBuilder(
    column: $table.isRadio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get streamUrlTemplate => $composableBuilder(
    column: $table.streamUrlTemplate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProvidersTableOrderingComposer get providerId {
    final $$ProvidersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProvidersTableOrderingComposer(
            $db: $db,
            $table: $db.providers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChannelsTableAnnotationComposer
    extends Composer<_$OpenIptvDb, $ChannelsTable> {
  $$ChannelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get providerChannelKey => $composableBuilder(
    column: $table.providerChannelKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get logoUrl =>
      $composableBuilder(column: $table.logoUrl, builder: (column) => column);

  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<bool> get isRadio =>
      $composableBuilder(column: $table.isRadio, builder: (column) => column);

  GeneratedColumn<String> get streamUrlTemplate => $composableBuilder(
    column: $table.streamUrlTemplate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => column,
  );

  $$ProvidersTableAnnotationComposer get providerId {
    final $$ProvidersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProvidersTableAnnotationComposer(
            $db: $db,
            $table: $db.providers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> channelCategoriesRefs<T extends Object>(
    Expression<T> Function($$ChannelCategoriesTableAnnotationComposer a) f,
  ) {
    final $$ChannelCategoriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.channelCategories,
          getReferencedColumn: (t) => t.channelId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ChannelCategoriesTableAnnotationComposer(
                $db: $db,
                $table: $db.channelCategories,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> epgProgramsRefs<T extends Object>(
    Expression<T> Function($$EpgProgramsTableAnnotationComposer a) f,
  ) {
    final $$EpgProgramsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.epgPrograms,
      getReferencedColumn: (t) => t.channelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpgProgramsTableAnnotationComposer(
            $db: $db,
            $table: $db.epgPrograms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ChannelsTableTableManager
    extends
        RootTableManager<
          _$OpenIptvDb,
          $ChannelsTable,
          ChannelRecord,
          $$ChannelsTableFilterComposer,
          $$ChannelsTableOrderingComposer,
          $$ChannelsTableAnnotationComposer,
          $$ChannelsTableCreateCompanionBuilder,
          $$ChannelsTableUpdateCompanionBuilder,
          (ChannelRecord, $$ChannelsTableReferences),
          ChannelRecord,
          PrefetchHooks Function({
            bool providerId,
            bool channelCategoriesRefs,
            bool epgProgramsRefs,
          })
        > {
  $$ChannelsTableTableManager(_$OpenIptvDb db, $ChannelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChannelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChannelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChannelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> providerId = const Value.absent(),
                Value<String> providerChannelKey = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> logoUrl = const Value.absent(),
                Value<int?> number = const Value.absent(),
                Value<bool> isRadio = const Value.absent(),
                Value<String?> streamUrlTemplate = const Value.absent(),
                Value<DateTime?> lastSeenAt = const Value.absent(),
              }) => ChannelsCompanion(
                id: id,
                providerId: providerId,
                providerChannelKey: providerChannelKey,
                name: name,
                logoUrl: logoUrl,
                number: number,
                isRadio: isRadio,
                streamUrlTemplate: streamUrlTemplate,
                lastSeenAt: lastSeenAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int providerId,
                required String providerChannelKey,
                required String name,
                Value<String?> logoUrl = const Value.absent(),
                Value<int?> number = const Value.absent(),
                Value<bool> isRadio = const Value.absent(),
                Value<String?> streamUrlTemplate = const Value.absent(),
                Value<DateTime?> lastSeenAt = const Value.absent(),
              }) => ChannelsCompanion.insert(
                id: id,
                providerId: providerId,
                providerChannelKey: providerChannelKey,
                name: name,
                logoUrl: logoUrl,
                number: number,
                isRadio: isRadio,
                streamUrlTemplate: streamUrlTemplate,
                lastSeenAt: lastSeenAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ChannelsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                providerId = false,
                channelCategoriesRefs = false,
                epgProgramsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (channelCategoriesRefs) db.channelCategories,
                    if (epgProgramsRefs) db.epgPrograms,
                  ],
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
                                    referencedTable: $$ChannelsTableReferences
                                        ._providerIdTable(db),
                                    referencedColumn: $$ChannelsTableReferences
                                        ._providerIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (channelCategoriesRefs)
                        await $_getPrefetchedData<
                          ChannelRecord,
                          $ChannelsTable,
                          ChannelCategoryRecord
                        >(
                          currentTable: table,
                          referencedTable: $$ChannelsTableReferences
                              ._channelCategoriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChannelsTableReferences(
                                db,
                                table,
                                p0,
                              ).channelCategoriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.channelId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (epgProgramsRefs)
                        await $_getPrefetchedData<
                          ChannelRecord,
                          $ChannelsTable,
                          EpgProgramRecord
                        >(
                          currentTable: table,
                          referencedTable: $$ChannelsTableReferences
                              ._epgProgramsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChannelsTableReferences(
                                db,
                                table,
                                p0,
                              ).epgProgramsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.channelId == item.id,
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

typedef $$ChannelsTableProcessedTableManager =
    ProcessedTableManager<
      _$OpenIptvDb,
      $ChannelsTable,
      ChannelRecord,
      $$ChannelsTableFilterComposer,
      $$ChannelsTableOrderingComposer,
      $$ChannelsTableAnnotationComposer,
      $$ChannelsTableCreateCompanionBuilder,
      $$ChannelsTableUpdateCompanionBuilder,
      (ChannelRecord, $$ChannelsTableReferences),
      ChannelRecord,
      PrefetchHooks Function({
        bool providerId,
        bool channelCategoriesRefs,
        bool epgProgramsRefs,
      })
    >;
typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> id,
      required int providerId,
      required CategoryKind kind,
      required String providerCategoryKey,
      required String name,
      Value<int?> position,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<int> id,
      Value<int> providerId,
      Value<CategoryKind> kind,
      Value<String> providerCategoryKey,
      Value<String> name,
      Value<int?> position,
    });

final class $$CategoriesTableReferences
    extends BaseReferences<_$OpenIptvDb, $CategoriesTable, CategoryRecord> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProvidersTable _providerIdTable(_$OpenIptvDb db) =>
      db.providers.createAlias(
        $_aliasNameGenerator(db.categories.providerId, db.providers.id),
      );

  $$ProvidersTableProcessedTableManager get providerId {
    final $_column = $_itemColumn<int>('provider_id')!;

    final manager = $$ProvidersTableTableManager(
      $_db,
      $_db.providers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_providerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $ChannelCategoriesTable,
    List<ChannelCategoryRecord>
  >
  _channelCategoriesRefsTable(_$OpenIptvDb db) => MultiTypedResultKey.fromTable(
    db.channelCategories,
    aliasName: $_aliasNameGenerator(
      db.categories.id,
      db.channelCategories.categoryId,
    ),
  );

  $$ChannelCategoriesTableProcessedTableManager get channelCategoriesRefs {
    final manager = $$ChannelCategoriesTableTableManager(
      $_db,
      $_db.channelCategories,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _channelCategoriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$OpenIptvDb, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
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

  ColumnWithTypeConverterFilters<CategoryKind, CategoryKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get providerCategoryKey => $composableBuilder(
    column: $table.providerCategoryKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$ProvidersTableFilterComposer get providerId {
    final $$ProvidersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProvidersTableFilterComposer(
            $db: $db,
            $table: $db.providers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> channelCategoriesRefs(
    Expression<bool> Function($$ChannelCategoriesTableFilterComposer f) f,
  ) {
    final $$ChannelCategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.channelCategories,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelCategoriesTableFilterComposer(
            $db: $db,
            $table: $db.channelCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$OpenIptvDb, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerCategoryKey => $composableBuilder(
    column: $table.providerCategoryKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProvidersTableOrderingComposer get providerId {
    final $$ProvidersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProvidersTableOrderingComposer(
            $db: $db,
            $table: $db.providers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$OpenIptvDb, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CategoryKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get providerCategoryKey => $composableBuilder(
    column: $table.providerCategoryKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$ProvidersTableAnnotationComposer get providerId {
    final $$ProvidersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProvidersTableAnnotationComposer(
            $db: $db,
            $table: $db.providers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> channelCategoriesRefs<T extends Object>(
    Expression<T> Function($$ChannelCategoriesTableAnnotationComposer a) f,
  ) {
    final $$ChannelCategoriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.channelCategories,
          getReferencedColumn: (t) => t.categoryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ChannelCategoriesTableAnnotationComposer(
                $db: $db,
                $table: $db.channelCategories,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$OpenIptvDb,
          $CategoriesTable,
          CategoryRecord,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (CategoryRecord, $$CategoriesTableReferences),
          CategoryRecord,
          PrefetchHooks Function({bool providerId, bool channelCategoriesRefs})
        > {
  $$CategoriesTableTableManager(_$OpenIptvDb db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> providerId = const Value.absent(),
                Value<CategoryKind> kind = const Value.absent(),
                Value<String> providerCategoryKey = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int?> position = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                providerId: providerId,
                kind: kind,
                providerCategoryKey: providerCategoryKey,
                name: name,
                position: position,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int providerId,
                required CategoryKind kind,
                required String providerCategoryKey,
                required String name,
                Value<int?> position = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                providerId: providerId,
                kind: kind,
                providerCategoryKey: providerCategoryKey,
                name: name,
                position: position,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({providerId = false, channelCategoriesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (channelCategoriesRefs) db.channelCategories,
                  ],
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
                                    referencedTable: $$CategoriesTableReferences
                                        ._providerIdTable(db),
                                    referencedColumn:
                                        $$CategoriesTableReferences
                                            ._providerIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (channelCategoriesRefs)
                        await $_getPrefetchedData<
                          CategoryRecord,
                          $CategoriesTable,
                          ChannelCategoryRecord
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._channelCategoriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).channelCategoriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
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

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$OpenIptvDb,
      $CategoriesTable,
      CategoryRecord,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (CategoryRecord, $$CategoriesTableReferences),
      CategoryRecord,
      PrefetchHooks Function({bool providerId, bool channelCategoriesRefs})
    >;
typedef $$ChannelCategoriesTableCreateCompanionBuilder =
    ChannelCategoriesCompanion Function({
      required int channelId,
      required int categoryId,
      Value<int> rowid,
    });
typedef $$ChannelCategoriesTableUpdateCompanionBuilder =
    ChannelCategoriesCompanion Function({
      Value<int> channelId,
      Value<int> categoryId,
      Value<int> rowid,
    });

final class $$ChannelCategoriesTableReferences
    extends
        BaseReferences<
          _$OpenIptvDb,
          $ChannelCategoriesTable,
          ChannelCategoryRecord
        > {
  $$ChannelCategoriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ChannelsTable _channelIdTable(_$OpenIptvDb db) =>
      db.channels.createAlias(
        $_aliasNameGenerator(db.channelCategories.channelId, db.channels.id),
      );

  $$ChannelsTableProcessedTableManager get channelId {
    final $_column = $_itemColumn<int>('channel_id')!;

    final manager = $$ChannelsTableTableManager(
      $_db,
      $_db.channels,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_channelIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CategoriesTable _categoryIdTable(_$OpenIptvDb db) =>
      db.categories.createAlias(
        $_aliasNameGenerator(db.channelCategories.categoryId, db.categories.id),
      );

  $$CategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<int>('category_id')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ChannelCategoriesTableFilterComposer
    extends Composer<_$OpenIptvDb, $ChannelCategoriesTable> {
  $$ChannelCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ChannelsTableFilterComposer get channelId {
    final $$ChannelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.channelId,
      referencedTable: $db.channels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableFilterComposer(
            $db: $db,
            $table: $db.channels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChannelCategoriesTableOrderingComposer
    extends Composer<_$OpenIptvDb, $ChannelCategoriesTable> {
  $$ChannelCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ChannelsTableOrderingComposer get channelId {
    final $$ChannelsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.channelId,
      referencedTable: $db.channels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableOrderingComposer(
            $db: $db,
            $table: $db.channels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChannelCategoriesTableAnnotationComposer
    extends Composer<_$OpenIptvDb, $ChannelCategoriesTable> {
  $$ChannelCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ChannelsTableAnnotationComposer get channelId {
    final $$ChannelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.channelId,
      referencedTable: $db.channels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableAnnotationComposer(
            $db: $db,
            $table: $db.channels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ChannelCategoriesTableTableManager
    extends
        RootTableManager<
          _$OpenIptvDb,
          $ChannelCategoriesTable,
          ChannelCategoryRecord,
          $$ChannelCategoriesTableFilterComposer,
          $$ChannelCategoriesTableOrderingComposer,
          $$ChannelCategoriesTableAnnotationComposer,
          $$ChannelCategoriesTableCreateCompanionBuilder,
          $$ChannelCategoriesTableUpdateCompanionBuilder,
          (ChannelCategoryRecord, $$ChannelCategoriesTableReferences),
          ChannelCategoryRecord,
          PrefetchHooks Function({bool channelId, bool categoryId})
        > {
  $$ChannelCategoriesTableTableManager(
    _$OpenIptvDb db,
    $ChannelCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChannelCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChannelCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChannelCategoriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> channelId = const Value.absent(),
                Value<int> categoryId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChannelCategoriesCompanion(
                channelId: channelId,
                categoryId: categoryId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int channelId,
                required int categoryId,
                Value<int> rowid = const Value.absent(),
              }) => ChannelCategoriesCompanion.insert(
                channelId: channelId,
                categoryId: categoryId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ChannelCategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({channelId = false, categoryId = false}) {
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
                    if (channelId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.channelId,
                                referencedTable:
                                    $$ChannelCategoriesTableReferences
                                        ._channelIdTable(db),
                                referencedColumn:
                                    $$ChannelCategoriesTableReferences
                                        ._channelIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (categoryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.categoryId,
                                referencedTable:
                                    $$ChannelCategoriesTableReferences
                                        ._categoryIdTable(db),
                                referencedColumn:
                                    $$ChannelCategoriesTableReferences
                                        ._categoryIdTable(db)
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

typedef $$ChannelCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$OpenIptvDb,
      $ChannelCategoriesTable,
      ChannelCategoryRecord,
      $$ChannelCategoriesTableFilterComposer,
      $$ChannelCategoriesTableOrderingComposer,
      $$ChannelCategoriesTableAnnotationComposer,
      $$ChannelCategoriesTableCreateCompanionBuilder,
      $$ChannelCategoriesTableUpdateCompanionBuilder,
      (ChannelCategoryRecord, $$ChannelCategoriesTableReferences),
      ChannelCategoryRecord,
      PrefetchHooks Function({bool channelId, bool categoryId})
    >;
typedef $$SummariesTableCreateCompanionBuilder =
    SummariesCompanion Function({
      Value<int> id,
      required int providerId,
      required CategoryKind kind,
      Value<int> totalItems,
      Value<DateTime> updatedAt,
    });
typedef $$SummariesTableUpdateCompanionBuilder =
    SummariesCompanion Function({
      Value<int> id,
      Value<int> providerId,
      Value<CategoryKind> kind,
      Value<int> totalItems,
      Value<DateTime> updatedAt,
    });

final class $$SummariesTableReferences
    extends BaseReferences<_$OpenIptvDb, $SummariesTable, SummaryRecord> {
  $$SummariesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProvidersTable _providerIdTable(_$OpenIptvDb db) =>
      db.providers.createAlias(
        $_aliasNameGenerator(db.summaries.providerId, db.providers.id),
      );

  $$ProvidersTableProcessedTableManager get providerId {
    final $_column = $_itemColumn<int>('provider_id')!;

    final manager = $$ProvidersTableTableManager(
      $_db,
      $_db.providers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_providerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SummariesTableFilterComposer
    extends Composer<_$OpenIptvDb, $SummariesTable> {
  $$SummariesTableFilterComposer({
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

  ColumnWithTypeConverterFilters<CategoryKind, CategoryKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get totalItems => $composableBuilder(
    column: $table.totalItems,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ProvidersTableFilterComposer get providerId {
    final $$ProvidersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProvidersTableFilterComposer(
            $db: $db,
            $table: $db.providers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SummariesTableOrderingComposer
    extends Composer<_$OpenIptvDb, $SummariesTable> {
  $$SummariesTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalItems => $composableBuilder(
    column: $table.totalItems,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProvidersTableOrderingComposer get providerId {
    final $$ProvidersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProvidersTableOrderingComposer(
            $db: $db,
            $table: $db.providers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SummariesTableAnnotationComposer
    extends Composer<_$OpenIptvDb, $SummariesTable> {
  $$SummariesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CategoryKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get totalItems => $composableBuilder(
    column: $table.totalItems,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ProvidersTableAnnotationComposer get providerId {
    final $$ProvidersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.providerId,
      referencedTable: $db.providers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProvidersTableAnnotationComposer(
            $db: $db,
            $table: $db.providers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SummariesTableTableManager
    extends
        RootTableManager<
          _$OpenIptvDb,
          $SummariesTable,
          SummaryRecord,
          $$SummariesTableFilterComposer,
          $$SummariesTableOrderingComposer,
          $$SummariesTableAnnotationComposer,
          $$SummariesTableCreateCompanionBuilder,
          $$SummariesTableUpdateCompanionBuilder,
          (SummaryRecord, $$SummariesTableReferences),
          SummaryRecord,
          PrefetchHooks Function({bool providerId})
        > {
  $$SummariesTableTableManager(_$OpenIptvDb db, $SummariesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SummariesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SummariesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SummariesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> providerId = const Value.absent(),
                Value<CategoryKind> kind = const Value.absent(),
                Value<int> totalItems = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SummariesCompanion(
                id: id,
                providerId: providerId,
                kind: kind,
                totalItems: totalItems,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int providerId,
                required CategoryKind kind,
                Value<int> totalItems = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SummariesCompanion.insert(
                id: id,
                providerId: providerId,
                kind: kind,
                totalItems: totalItems,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SummariesTableReferences(db, table, e),
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
                                referencedTable: $$SummariesTableReferences
                                    ._providerIdTable(db),
                                referencedColumn: $$SummariesTableReferences
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

typedef $$SummariesTableProcessedTableManager =
    ProcessedTableManager<
      _$OpenIptvDb,
      $SummariesTable,
      SummaryRecord,
      $$SummariesTableFilterComposer,
      $$SummariesTableOrderingComposer,
      $$SummariesTableAnnotationComposer,
      $$SummariesTableCreateCompanionBuilder,
      $$SummariesTableUpdateCompanionBuilder,
      (SummaryRecord, $$SummariesTableReferences),
      SummaryRecord,
      PrefetchHooks Function({bool providerId})
    >;
typedef $$EpgProgramsTableCreateCompanionBuilder =
    EpgProgramsCompanion Function({
      Value<int> id,
      required int channelId,
      required DateTime startUtc,
      required DateTime endUtc,
      Value<String?> title,
      Value<String?> subtitle,
      Value<String?> description,
      Value<int?> season,
      Value<int?> episode,
    });
typedef $$EpgProgramsTableUpdateCompanionBuilder =
    EpgProgramsCompanion Function({
      Value<int> id,
      Value<int> channelId,
      Value<DateTime> startUtc,
      Value<DateTime> endUtc,
      Value<String?> title,
      Value<String?> subtitle,
      Value<String?> description,
      Value<int?> season,
      Value<int?> episode,
    });

final class $$EpgProgramsTableReferences
    extends BaseReferences<_$OpenIptvDb, $EpgProgramsTable, EpgProgramRecord> {
  $$EpgProgramsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ChannelsTable _channelIdTable(_$OpenIptvDb db) =>
      db.channels.createAlias(
        $_aliasNameGenerator(db.epgPrograms.channelId, db.channels.id),
      );

  $$ChannelsTableProcessedTableManager get channelId {
    final $_column = $_itemColumn<int>('channel_id')!;

    final manager = $$ChannelsTableTableManager(
      $_db,
      $_db.channels,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_channelIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EpgProgramsTableFilterComposer
    extends Composer<_$OpenIptvDb, $EpgProgramsTable> {
  $$EpgProgramsTableFilterComposer({
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

  ColumnFilters<DateTime> get startUtc => $composableBuilder(
    column: $table.startUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endUtc => $composableBuilder(
    column: $table.endUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
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

  $$ChannelsTableFilterComposer get channelId {
    final $$ChannelsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.channelId,
      referencedTable: $db.channels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableFilterComposer(
            $db: $db,
            $table: $db.channels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EpgProgramsTableOrderingComposer
    extends Composer<_$OpenIptvDb, $EpgProgramsTable> {
  $$EpgProgramsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get startUtc => $composableBuilder(
    column: $table.startUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endUtc => $composableBuilder(
    column: $table.endUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
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

  $$ChannelsTableOrderingComposer get channelId {
    final $$ChannelsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.channelId,
      referencedTable: $db.channels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableOrderingComposer(
            $db: $db,
            $table: $db.channels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EpgProgramsTableAnnotationComposer
    extends Composer<_$OpenIptvDb, $EpgProgramsTable> {
  $$EpgProgramsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startUtc =>
      $composableBuilder(column: $table.startUtc, builder: (column) => column);

  GeneratedColumn<DateTime> get endUtc =>
      $composableBuilder(column: $table.endUtc, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get subtitle =>
      $composableBuilder(column: $table.subtitle, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get season =>
      $composableBuilder(column: $table.season, builder: (column) => column);

  GeneratedColumn<int> get episode =>
      $composableBuilder(column: $table.episode, builder: (column) => column);

  $$ChannelsTableAnnotationComposer get channelId {
    final $$ChannelsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.channelId,
      referencedTable: $db.channels,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ChannelsTableAnnotationComposer(
            $db: $db,
            $table: $db.channels,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EpgProgramsTableTableManager
    extends
        RootTableManager<
          _$OpenIptvDb,
          $EpgProgramsTable,
          EpgProgramRecord,
          $$EpgProgramsTableFilterComposer,
          $$EpgProgramsTableOrderingComposer,
          $$EpgProgramsTableAnnotationComposer,
          $$EpgProgramsTableCreateCompanionBuilder,
          $$EpgProgramsTableUpdateCompanionBuilder,
          (EpgProgramRecord, $$EpgProgramsTableReferences),
          EpgProgramRecord,
          PrefetchHooks Function({bool channelId})
        > {
  $$EpgProgramsTableTableManager(_$OpenIptvDb db, $EpgProgramsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EpgProgramsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EpgProgramsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EpgProgramsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> channelId = const Value.absent(),
                Value<DateTime> startUtc = const Value.absent(),
                Value<DateTime> endUtc = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> subtitle = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int?> season = const Value.absent(),
                Value<int?> episode = const Value.absent(),
              }) => EpgProgramsCompanion(
                id: id,
                channelId: channelId,
                startUtc: startUtc,
                endUtc: endUtc,
                title: title,
                subtitle: subtitle,
                description: description,
                season: season,
                episode: episode,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int channelId,
                required DateTime startUtc,
                required DateTime endUtc,
                Value<String?> title = const Value.absent(),
                Value<String?> subtitle = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int?> season = const Value.absent(),
                Value<int?> episode = const Value.absent(),
              }) => EpgProgramsCompanion.insert(
                id: id,
                channelId: channelId,
                startUtc: startUtc,
                endUtc: endUtc,
                title: title,
                subtitle: subtitle,
                description: description,
                season: season,
                episode: episode,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EpgProgramsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({channelId = false}) {
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
                    if (channelId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.channelId,
                                referencedTable: $$EpgProgramsTableReferences
                                    ._channelIdTable(db),
                                referencedColumn: $$EpgProgramsTableReferences
                                    ._channelIdTable(db)
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

typedef $$EpgProgramsTableProcessedTableManager =
    ProcessedTableManager<
      _$OpenIptvDb,
      $EpgProgramsTable,
      EpgProgramRecord,
      $$EpgProgramsTableFilterComposer,
      $$EpgProgramsTableOrderingComposer,
      $$EpgProgramsTableAnnotationComposer,
      $$EpgProgramsTableCreateCompanionBuilder,
      $$EpgProgramsTableUpdateCompanionBuilder,
      (EpgProgramRecord, $$EpgProgramsTableReferences),
      EpgProgramRecord,
      PrefetchHooks Function({bool channelId})
    >;

class $OpenIptvDbManager {
  final _$OpenIptvDb _db;
  $OpenIptvDbManager(this._db);
  $$ProvidersTableTableManager get providers =>
      $$ProvidersTableTableManager(_db, _db.providers);
  $$ChannelsTableTableManager get channels =>
      $$ChannelsTableTableManager(_db, _db.channels);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$ChannelCategoriesTableTableManager get channelCategories =>
      $$ChannelCategoriesTableTableManager(_db, _db.channelCategories);
  $$SummariesTableTableManager get summaries =>
      $$SummariesTableTableManager(_db, _db.summaries);
  $$EpgProgramsTableTableManager get epgPrograms =>
      $$EpgProgramsTableTableManager(_db, _db.epgPrograms);
}
