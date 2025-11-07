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
  static const VerificationMeta _legacyProfileIdMeta = const VerificationMeta(
    'legacyProfileId',
  );
  @override
  late final GeneratedColumn<String> legacyProfileId = GeneratedColumn<String>(
    'legacy_profile_id',
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
    legacyProfileId,
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
    if (data.containsKey('legacy_profile_id')) {
      context.handle(
        _legacyProfileIdMeta,
        legacyProfileId.isAcceptableOrUnknown(
          data['legacy_profile_id']!,
          _legacyProfileIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {legacyProfileId},
  ];
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
      legacyProfileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}legacy_profile_id'],
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
  final String? legacyProfileId;
  const ProviderRecord({
    required this.id,
    required this.kind,
    required this.displayName,
    required this.lockedBase,
    required this.needsUa,
    required this.allowSelfSigned,
    this.lastSyncAt,
    this.etagHash,
    this.legacyProfileId,
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
    if (!nullToAbsent || legacyProfileId != null) {
      map['legacy_profile_id'] = Variable<String>(legacyProfileId);
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
      legacyProfileId: legacyProfileId == null && nullToAbsent
          ? const Value.absent()
          : Value(legacyProfileId),
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
      legacyProfileId: serializer.fromJson<String?>(json['legacyProfileId']),
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
      'legacyProfileId': serializer.toJson<String?>(legacyProfileId),
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
    Value<String?> legacyProfileId = const Value.absent(),
  }) => ProviderRecord(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    displayName: displayName ?? this.displayName,
    lockedBase: lockedBase ?? this.lockedBase,
    needsUa: needsUa ?? this.needsUa,
    allowSelfSigned: allowSelfSigned ?? this.allowSelfSigned,
    lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
    etagHash: etagHash.present ? etagHash.value : this.etagHash,
    legacyProfileId: legacyProfileId.present
        ? legacyProfileId.value
        : this.legacyProfileId,
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
      legacyProfileId: data.legacyProfileId.present
          ? data.legacyProfileId.value
          : this.legacyProfileId,
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
          ..write('etagHash: $etagHash, ')
          ..write('legacyProfileId: $legacyProfileId')
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
    legacyProfileId,
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
          other.etagHash == this.etagHash &&
          other.legacyProfileId == this.legacyProfileId);
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
  final Value<String?> legacyProfileId;
  const ProvidersCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.displayName = const Value.absent(),
    this.lockedBase = const Value.absent(),
    this.needsUa = const Value.absent(),
    this.allowSelfSigned = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.etagHash = const Value.absent(),
    this.legacyProfileId = const Value.absent(),
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
    this.legacyProfileId = const Value.absent(),
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
    Expression<String>? legacyProfileId,
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
      if (legacyProfileId != null) 'legacy_profile_id': legacyProfileId,
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
    Value<String?>? legacyProfileId,
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
      legacyProfileId: legacyProfileId ?? this.legacyProfileId,
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
    if (legacyProfileId.present) {
      map['legacy_profile_id'] = Variable<String>(legacyProfileId.value);
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
          ..write('etagHash: $etagHash, ')
          ..write('legacyProfileId: $legacyProfileId')
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

class $MoviesTable extends Movies with TableInfo<$MoviesTable, MovieRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MoviesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _providerVodKeyMeta = const VerificationMeta(
    'providerVodKey',
  );
  @override
  late final GeneratedColumn<String> providerVodKey = GeneratedColumn<String>(
    'provider_vod_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id) ON DELETE SET NULL',
    ),
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
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overviewMeta = const VerificationMeta(
    'overview',
  );
  @override
  late final GeneratedColumn<String> overview = GeneratedColumn<String>(
    'overview',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _posterUrlMeta = const VerificationMeta(
    'posterUrl',
  );
  @override
  late final GeneratedColumn<String> posterUrl = GeneratedColumn<String>(
    'poster_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecMeta = const VerificationMeta(
    'durationSec',
  );
  @override
  late final GeneratedColumn<int> durationSec = GeneratedColumn<int>(
    'duration_sec',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
    providerVodKey,
    categoryId,
    title,
    year,
    overview,
    posterUrl,
    durationSec,
    streamUrlTemplate,
    lastSeenAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'movies';
  @override
  VerificationContext validateIntegrity(
    Insertable<MovieRecord> instance, {
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
    if (data.containsKey('provider_vod_key')) {
      context.handle(
        _providerVodKeyMeta,
        providerVodKey.isAcceptableOrUnknown(
          data['provider_vod_key']!,
          _providerVodKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_providerVodKeyMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('overview')) {
      context.handle(
        _overviewMeta,
        overview.isAcceptableOrUnknown(data['overview']!, _overviewMeta),
      );
    }
    if (data.containsKey('poster_url')) {
      context.handle(
        _posterUrlMeta,
        posterUrl.isAcceptableOrUnknown(data['poster_url']!, _posterUrlMeta),
      );
    }
    if (data.containsKey('duration_sec')) {
      context.handle(
        _durationSecMeta,
        durationSec.isAcceptableOrUnknown(
          data['duration_sec']!,
          _durationSecMeta,
        ),
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
    {providerId, providerVodKey},
  ];
  @override
  MovieRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MovieRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}provider_id'],
      )!,
      providerVodKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_vod_key'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      overview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}overview'],
      ),
      posterUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}poster_url'],
      ),
      durationSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_sec'],
      ),
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
  $MoviesTable createAlias(String alias) {
    return $MoviesTable(attachedDatabase, alias);
  }
}

class MovieRecord extends DataClass implements Insertable<MovieRecord> {
  final int id;
  final int providerId;
  final String providerVodKey;
  final int? categoryId;
  final String title;
  final int? year;
  final String? overview;
  final String? posterUrl;
  final int? durationSec;
  final String? streamUrlTemplate;
  final DateTime? lastSeenAt;
  const MovieRecord({
    required this.id,
    required this.providerId,
    required this.providerVodKey,
    this.categoryId,
    required this.title,
    this.year,
    this.overview,
    this.posterUrl,
    this.durationSec,
    this.streamUrlTemplate,
    this.lastSeenAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['provider_id'] = Variable<int>(providerId);
    map['provider_vod_key'] = Variable<String>(providerVodKey);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    if (!nullToAbsent || overview != null) {
      map['overview'] = Variable<String>(overview);
    }
    if (!nullToAbsent || posterUrl != null) {
      map['poster_url'] = Variable<String>(posterUrl);
    }
    if (!nullToAbsent || durationSec != null) {
      map['duration_sec'] = Variable<int>(durationSec);
    }
    if (!nullToAbsent || streamUrlTemplate != null) {
      map['stream_url_template'] = Variable<String>(streamUrlTemplate);
    }
    if (!nullToAbsent || lastSeenAt != null) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt);
    }
    return map;
  }

  MoviesCompanion toCompanion(bool nullToAbsent) {
    return MoviesCompanion(
      id: Value(id),
      providerId: Value(providerId),
      providerVodKey: Value(providerVodKey),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      title: Value(title),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      overview: overview == null && nullToAbsent
          ? const Value.absent()
          : Value(overview),
      posterUrl: posterUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(posterUrl),
      durationSec: durationSec == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSec),
      streamUrlTemplate: streamUrlTemplate == null && nullToAbsent
          ? const Value.absent()
          : Value(streamUrlTemplate),
      lastSeenAt: lastSeenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeenAt),
    );
  }

  factory MovieRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MovieRecord(
      id: serializer.fromJson<int>(json['id']),
      providerId: serializer.fromJson<int>(json['providerId']),
      providerVodKey: serializer.fromJson<String>(json['providerVodKey']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      title: serializer.fromJson<String>(json['title']),
      year: serializer.fromJson<int?>(json['year']),
      overview: serializer.fromJson<String?>(json['overview']),
      posterUrl: serializer.fromJson<String?>(json['posterUrl']),
      durationSec: serializer.fromJson<int?>(json['durationSec']),
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
      'providerVodKey': serializer.toJson<String>(providerVodKey),
      'categoryId': serializer.toJson<int?>(categoryId),
      'title': serializer.toJson<String>(title),
      'year': serializer.toJson<int?>(year),
      'overview': serializer.toJson<String?>(overview),
      'posterUrl': serializer.toJson<String?>(posterUrl),
      'durationSec': serializer.toJson<int?>(durationSec),
      'streamUrlTemplate': serializer.toJson<String?>(streamUrlTemplate),
      'lastSeenAt': serializer.toJson<DateTime?>(lastSeenAt),
    };
  }

  MovieRecord copyWith({
    int? id,
    int? providerId,
    String? providerVodKey,
    Value<int?> categoryId = const Value.absent(),
    String? title,
    Value<int?> year = const Value.absent(),
    Value<String?> overview = const Value.absent(),
    Value<String?> posterUrl = const Value.absent(),
    Value<int?> durationSec = const Value.absent(),
    Value<String?> streamUrlTemplate = const Value.absent(),
    Value<DateTime?> lastSeenAt = const Value.absent(),
  }) => MovieRecord(
    id: id ?? this.id,
    providerId: providerId ?? this.providerId,
    providerVodKey: providerVodKey ?? this.providerVodKey,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    title: title ?? this.title,
    year: year.present ? year.value : this.year,
    overview: overview.present ? overview.value : this.overview,
    posterUrl: posterUrl.present ? posterUrl.value : this.posterUrl,
    durationSec: durationSec.present ? durationSec.value : this.durationSec,
    streamUrlTemplate: streamUrlTemplate.present
        ? streamUrlTemplate.value
        : this.streamUrlTemplate,
    lastSeenAt: lastSeenAt.present ? lastSeenAt.value : this.lastSeenAt,
  );
  MovieRecord copyWithCompanion(MoviesCompanion data) {
    return MovieRecord(
      id: data.id.present ? data.id.value : this.id,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      providerVodKey: data.providerVodKey.present
          ? data.providerVodKey.value
          : this.providerVodKey,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      title: data.title.present ? data.title.value : this.title,
      year: data.year.present ? data.year.value : this.year,
      overview: data.overview.present ? data.overview.value : this.overview,
      posterUrl: data.posterUrl.present ? data.posterUrl.value : this.posterUrl,
      durationSec: data.durationSec.present
          ? data.durationSec.value
          : this.durationSec,
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
    return (StringBuffer('MovieRecord(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('providerVodKey: $providerVodKey, ')
          ..write('categoryId: $categoryId, ')
          ..write('title: $title, ')
          ..write('year: $year, ')
          ..write('overview: $overview, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('durationSec: $durationSec, ')
          ..write('streamUrlTemplate: $streamUrlTemplate, ')
          ..write('lastSeenAt: $lastSeenAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    providerId,
    providerVodKey,
    categoryId,
    title,
    year,
    overview,
    posterUrl,
    durationSec,
    streamUrlTemplate,
    lastSeenAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MovieRecord &&
          other.id == this.id &&
          other.providerId == this.providerId &&
          other.providerVodKey == this.providerVodKey &&
          other.categoryId == this.categoryId &&
          other.title == this.title &&
          other.year == this.year &&
          other.overview == this.overview &&
          other.posterUrl == this.posterUrl &&
          other.durationSec == this.durationSec &&
          other.streamUrlTemplate == this.streamUrlTemplate &&
          other.lastSeenAt == this.lastSeenAt);
}

class MoviesCompanion extends UpdateCompanion<MovieRecord> {
  final Value<int> id;
  final Value<int> providerId;
  final Value<String> providerVodKey;
  final Value<int?> categoryId;
  final Value<String> title;
  final Value<int?> year;
  final Value<String?> overview;
  final Value<String?> posterUrl;
  final Value<int?> durationSec;
  final Value<String?> streamUrlTemplate;
  final Value<DateTime?> lastSeenAt;
  const MoviesCompanion({
    this.id = const Value.absent(),
    this.providerId = const Value.absent(),
    this.providerVodKey = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.title = const Value.absent(),
    this.year = const Value.absent(),
    this.overview = const Value.absent(),
    this.posterUrl = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.streamUrlTemplate = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
  });
  MoviesCompanion.insert({
    this.id = const Value.absent(),
    required int providerId,
    required String providerVodKey,
    this.categoryId = const Value.absent(),
    required String title,
    this.year = const Value.absent(),
    this.overview = const Value.absent(),
    this.posterUrl = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.streamUrlTemplate = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
  }) : providerId = Value(providerId),
       providerVodKey = Value(providerVodKey),
       title = Value(title);
  static Insertable<MovieRecord> custom({
    Expression<int>? id,
    Expression<int>? providerId,
    Expression<String>? providerVodKey,
    Expression<int>? categoryId,
    Expression<String>? title,
    Expression<int>? year,
    Expression<String>? overview,
    Expression<String>? posterUrl,
    Expression<int>? durationSec,
    Expression<String>? streamUrlTemplate,
    Expression<DateTime>? lastSeenAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (providerId != null) 'provider_id': providerId,
      if (providerVodKey != null) 'provider_vod_key': providerVodKey,
      if (categoryId != null) 'category_id': categoryId,
      if (title != null) 'title': title,
      if (year != null) 'year': year,
      if (overview != null) 'overview': overview,
      if (posterUrl != null) 'poster_url': posterUrl,
      if (durationSec != null) 'duration_sec': durationSec,
      if (streamUrlTemplate != null) 'stream_url_template': streamUrlTemplate,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
    });
  }

  MoviesCompanion copyWith({
    Value<int>? id,
    Value<int>? providerId,
    Value<String>? providerVodKey,
    Value<int?>? categoryId,
    Value<String>? title,
    Value<int?>? year,
    Value<String?>? overview,
    Value<String?>? posterUrl,
    Value<int?>? durationSec,
    Value<String?>? streamUrlTemplate,
    Value<DateTime?>? lastSeenAt,
  }) {
    return MoviesCompanion(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      providerVodKey: providerVodKey ?? this.providerVodKey,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      year: year ?? this.year,
      overview: overview ?? this.overview,
      posterUrl: posterUrl ?? this.posterUrl,
      durationSec: durationSec ?? this.durationSec,
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
    if (providerVodKey.present) {
      map['provider_vod_key'] = Variable<String>(providerVodKey.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (overview.present) {
      map['overview'] = Variable<String>(overview.value);
    }
    if (posterUrl.present) {
      map['poster_url'] = Variable<String>(posterUrl.value);
    }
    if (durationSec.present) {
      map['duration_sec'] = Variable<int>(durationSec.value);
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
    return (StringBuffer('MoviesCompanion(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('providerVodKey: $providerVodKey, ')
          ..write('categoryId: $categoryId, ')
          ..write('title: $title, ')
          ..write('year: $year, ')
          ..write('overview: $overview, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('durationSec: $durationSec, ')
          ..write('streamUrlTemplate: $streamUrlTemplate, ')
          ..write('lastSeenAt: $lastSeenAt')
          ..write(')'))
        .toString();
  }
}

class $SeriesTable extends Series with TableInfo<$SeriesTable, SeriesRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _providerSeriesKeyMeta = const VerificationMeta(
    'providerSeriesKey',
  );
  @override
  late final GeneratedColumn<String> providerSeriesKey =
      GeneratedColumn<String>(
        'provider_series_key',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id) ON DELETE SET NULL',
    ),
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
  static const VerificationMeta _posterUrlMeta = const VerificationMeta(
    'posterUrl',
  );
  @override
  late final GeneratedColumn<String> posterUrl = GeneratedColumn<String>(
    'poster_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overviewMeta = const VerificationMeta(
    'overview',
  );
  @override
  late final GeneratedColumn<String> overview = GeneratedColumn<String>(
    'overview',
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
    providerSeriesKey,
    categoryId,
    title,
    posterUrl,
    year,
    overview,
    lastSeenAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'series';
  @override
  VerificationContext validateIntegrity(
    Insertable<SeriesRecord> instance, {
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
    if (data.containsKey('provider_series_key')) {
      context.handle(
        _providerSeriesKeyMeta,
        providerSeriesKey.isAcceptableOrUnknown(
          data['provider_series_key']!,
          _providerSeriesKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_providerSeriesKeyMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('poster_url')) {
      context.handle(
        _posterUrlMeta,
        posterUrl.isAcceptableOrUnknown(data['poster_url']!, _posterUrlMeta),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('overview')) {
      context.handle(
        _overviewMeta,
        overview.isAcceptableOrUnknown(data['overview']!, _overviewMeta),
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
    {providerId, providerSeriesKey},
  ];
  @override
  SeriesRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeriesRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}provider_id'],
      )!,
      providerSeriesKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_series_key'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      posterUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}poster_url'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      overview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}overview'],
      ),
      lastSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_seen_at'],
      ),
    );
  }

  @override
  $SeriesTable createAlias(String alias) {
    return $SeriesTable(attachedDatabase, alias);
  }
}

class SeriesRecord extends DataClass implements Insertable<SeriesRecord> {
  final int id;
  final int providerId;
  final String providerSeriesKey;
  final int? categoryId;
  final String title;
  final String? posterUrl;
  final int? year;
  final String? overview;
  final DateTime? lastSeenAt;
  const SeriesRecord({
    required this.id,
    required this.providerId,
    required this.providerSeriesKey,
    this.categoryId,
    required this.title,
    this.posterUrl,
    this.year,
    this.overview,
    this.lastSeenAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['provider_id'] = Variable<int>(providerId);
    map['provider_series_key'] = Variable<String>(providerSeriesKey);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || posterUrl != null) {
      map['poster_url'] = Variable<String>(posterUrl);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    if (!nullToAbsent || overview != null) {
      map['overview'] = Variable<String>(overview);
    }
    if (!nullToAbsent || lastSeenAt != null) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt);
    }
    return map;
  }

  SeriesCompanion toCompanion(bool nullToAbsent) {
    return SeriesCompanion(
      id: Value(id),
      providerId: Value(providerId),
      providerSeriesKey: Value(providerSeriesKey),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      title: Value(title),
      posterUrl: posterUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(posterUrl),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      overview: overview == null && nullToAbsent
          ? const Value.absent()
          : Value(overview),
      lastSeenAt: lastSeenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeenAt),
    );
  }

  factory SeriesRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeriesRecord(
      id: serializer.fromJson<int>(json['id']),
      providerId: serializer.fromJson<int>(json['providerId']),
      providerSeriesKey: serializer.fromJson<String>(json['providerSeriesKey']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      title: serializer.fromJson<String>(json['title']),
      posterUrl: serializer.fromJson<String?>(json['posterUrl']),
      year: serializer.fromJson<int?>(json['year']),
      overview: serializer.fromJson<String?>(json['overview']),
      lastSeenAt: serializer.fromJson<DateTime?>(json['lastSeenAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'providerId': serializer.toJson<int>(providerId),
      'providerSeriesKey': serializer.toJson<String>(providerSeriesKey),
      'categoryId': serializer.toJson<int?>(categoryId),
      'title': serializer.toJson<String>(title),
      'posterUrl': serializer.toJson<String?>(posterUrl),
      'year': serializer.toJson<int?>(year),
      'overview': serializer.toJson<String?>(overview),
      'lastSeenAt': serializer.toJson<DateTime?>(lastSeenAt),
    };
  }

  SeriesRecord copyWith({
    int? id,
    int? providerId,
    String? providerSeriesKey,
    Value<int?> categoryId = const Value.absent(),
    String? title,
    Value<String?> posterUrl = const Value.absent(),
    Value<int?> year = const Value.absent(),
    Value<String?> overview = const Value.absent(),
    Value<DateTime?> lastSeenAt = const Value.absent(),
  }) => SeriesRecord(
    id: id ?? this.id,
    providerId: providerId ?? this.providerId,
    providerSeriesKey: providerSeriesKey ?? this.providerSeriesKey,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    title: title ?? this.title,
    posterUrl: posterUrl.present ? posterUrl.value : this.posterUrl,
    year: year.present ? year.value : this.year,
    overview: overview.present ? overview.value : this.overview,
    lastSeenAt: lastSeenAt.present ? lastSeenAt.value : this.lastSeenAt,
  );
  SeriesRecord copyWithCompanion(SeriesCompanion data) {
    return SeriesRecord(
      id: data.id.present ? data.id.value : this.id,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      providerSeriesKey: data.providerSeriesKey.present
          ? data.providerSeriesKey.value
          : this.providerSeriesKey,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      title: data.title.present ? data.title.value : this.title,
      posterUrl: data.posterUrl.present ? data.posterUrl.value : this.posterUrl,
      year: data.year.present ? data.year.value : this.year,
      overview: data.overview.present ? data.overview.value : this.overview,
      lastSeenAt: data.lastSeenAt.present
          ? data.lastSeenAt.value
          : this.lastSeenAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeriesRecord(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('providerSeriesKey: $providerSeriesKey, ')
          ..write('categoryId: $categoryId, ')
          ..write('title: $title, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('year: $year, ')
          ..write('overview: $overview, ')
          ..write('lastSeenAt: $lastSeenAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    providerId,
    providerSeriesKey,
    categoryId,
    title,
    posterUrl,
    year,
    overview,
    lastSeenAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeriesRecord &&
          other.id == this.id &&
          other.providerId == this.providerId &&
          other.providerSeriesKey == this.providerSeriesKey &&
          other.categoryId == this.categoryId &&
          other.title == this.title &&
          other.posterUrl == this.posterUrl &&
          other.year == this.year &&
          other.overview == this.overview &&
          other.lastSeenAt == this.lastSeenAt);
}

class SeriesCompanion extends UpdateCompanion<SeriesRecord> {
  final Value<int> id;
  final Value<int> providerId;
  final Value<String> providerSeriesKey;
  final Value<int?> categoryId;
  final Value<String> title;
  final Value<String?> posterUrl;
  final Value<int?> year;
  final Value<String?> overview;
  final Value<DateTime?> lastSeenAt;
  const SeriesCompanion({
    this.id = const Value.absent(),
    this.providerId = const Value.absent(),
    this.providerSeriesKey = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.title = const Value.absent(),
    this.posterUrl = const Value.absent(),
    this.year = const Value.absent(),
    this.overview = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
  });
  SeriesCompanion.insert({
    this.id = const Value.absent(),
    required int providerId,
    required String providerSeriesKey,
    this.categoryId = const Value.absent(),
    required String title,
    this.posterUrl = const Value.absent(),
    this.year = const Value.absent(),
    this.overview = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
  }) : providerId = Value(providerId),
       providerSeriesKey = Value(providerSeriesKey),
       title = Value(title);
  static Insertable<SeriesRecord> custom({
    Expression<int>? id,
    Expression<int>? providerId,
    Expression<String>? providerSeriesKey,
    Expression<int>? categoryId,
    Expression<String>? title,
    Expression<String>? posterUrl,
    Expression<int>? year,
    Expression<String>? overview,
    Expression<DateTime>? lastSeenAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (providerId != null) 'provider_id': providerId,
      if (providerSeriesKey != null) 'provider_series_key': providerSeriesKey,
      if (categoryId != null) 'category_id': categoryId,
      if (title != null) 'title': title,
      if (posterUrl != null) 'poster_url': posterUrl,
      if (year != null) 'year': year,
      if (overview != null) 'overview': overview,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
    });
  }

  SeriesCompanion copyWith({
    Value<int>? id,
    Value<int>? providerId,
    Value<String>? providerSeriesKey,
    Value<int?>? categoryId,
    Value<String>? title,
    Value<String?>? posterUrl,
    Value<int?>? year,
    Value<String?>? overview,
    Value<DateTime?>? lastSeenAt,
  }) {
    return SeriesCompanion(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      providerSeriesKey: providerSeriesKey ?? this.providerSeriesKey,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      posterUrl: posterUrl ?? this.posterUrl,
      year: year ?? this.year,
      overview: overview ?? this.overview,
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
    if (providerSeriesKey.present) {
      map['provider_series_key'] = Variable<String>(providerSeriesKey.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (posterUrl.present) {
      map['poster_url'] = Variable<String>(posterUrl.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (overview.present) {
      map['overview'] = Variable<String>(overview.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeriesCompanion(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('providerSeriesKey: $providerSeriesKey, ')
          ..write('categoryId: $categoryId, ')
          ..write('title: $title, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('year: $year, ')
          ..write('overview: $overview, ')
          ..write('lastSeenAt: $lastSeenAt')
          ..write(')'))
        .toString();
  }
}

class $SeasonsTable extends Seasons
    with TableInfo<$SeasonsTable, SeasonRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeasonsTable(this.attachedDatabase, [this._alias]);
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES series (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _seasonNumberMeta = const VerificationMeta(
    'seasonNumber',
  );
  @override
  late final GeneratedColumn<int> seasonNumber = GeneratedColumn<int>(
    'season_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, seriesId, seasonNumber, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'seasons';
  @override
  VerificationContext validateIntegrity(
    Insertable<SeasonRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    } else if (isInserting) {
      context.missing(_seriesIdMeta);
    }
    if (data.containsKey('season_number')) {
      context.handle(
        _seasonNumberMeta,
        seasonNumber.isAcceptableOrUnknown(
          data['season_number']!,
          _seasonNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_seasonNumberMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {seriesId, seasonNumber},
  ];
  @override
  SeasonRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeasonRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}series_id'],
      )!,
      seasonNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}season_number'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
    );
  }

  @override
  $SeasonsTable createAlias(String alias) {
    return $SeasonsTable(attachedDatabase, alias);
  }
}

class SeasonRecord extends DataClass implements Insertable<SeasonRecord> {
  final int id;
  final int seriesId;
  final int seasonNumber;
  final String? name;
  const SeasonRecord({
    required this.id,
    required this.seriesId,
    required this.seasonNumber,
    this.name,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['series_id'] = Variable<int>(seriesId);
    map['season_number'] = Variable<int>(seasonNumber);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    return map;
  }

  SeasonsCompanion toCompanion(bool nullToAbsent) {
    return SeasonsCompanion(
      id: Value(id),
      seriesId: Value(seriesId),
      seasonNumber: Value(seasonNumber),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
    );
  }

  factory SeasonRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeasonRecord(
      id: serializer.fromJson<int>(json['id']),
      seriesId: serializer.fromJson<int>(json['seriesId']),
      seasonNumber: serializer.fromJson<int>(json['seasonNumber']),
      name: serializer.fromJson<String?>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'seriesId': serializer.toJson<int>(seriesId),
      'seasonNumber': serializer.toJson<int>(seasonNumber),
      'name': serializer.toJson<String?>(name),
    };
  }

  SeasonRecord copyWith({
    int? id,
    int? seriesId,
    int? seasonNumber,
    Value<String?> name = const Value.absent(),
  }) => SeasonRecord(
    id: id ?? this.id,
    seriesId: seriesId ?? this.seriesId,
    seasonNumber: seasonNumber ?? this.seasonNumber,
    name: name.present ? name.value : this.name,
  );
  SeasonRecord copyWithCompanion(SeasonsCompanion data) {
    return SeasonRecord(
      id: data.id.present ? data.id.value : this.id,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      seasonNumber: data.seasonNumber.present
          ? data.seasonNumber.value
          : this.seasonNumber,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeasonRecord(')
          ..write('id: $id, ')
          ..write('seriesId: $seriesId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, seriesId, seasonNumber, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeasonRecord &&
          other.id == this.id &&
          other.seriesId == this.seriesId &&
          other.seasonNumber == this.seasonNumber &&
          other.name == this.name);
}

class SeasonsCompanion extends UpdateCompanion<SeasonRecord> {
  final Value<int> id;
  final Value<int> seriesId;
  final Value<int> seasonNumber;
  final Value<String?> name;
  const SeasonsCompanion({
    this.id = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.seasonNumber = const Value.absent(),
    this.name = const Value.absent(),
  });
  SeasonsCompanion.insert({
    this.id = const Value.absent(),
    required int seriesId,
    required int seasonNumber,
    this.name = const Value.absent(),
  }) : seriesId = Value(seriesId),
       seasonNumber = Value(seasonNumber);
  static Insertable<SeasonRecord> custom({
    Expression<int>? id,
    Expression<int>? seriesId,
    Expression<int>? seasonNumber,
    Expression<String>? name,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (seriesId != null) 'series_id': seriesId,
      if (seasonNumber != null) 'season_number': seasonNumber,
      if (name != null) 'name': name,
    });
  }

  SeasonsCompanion copyWith({
    Value<int>? id,
    Value<int>? seriesId,
    Value<int>? seasonNumber,
    Value<String?>? name,
  }) {
    return SeasonsCompanion(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      name: name ?? this.name,
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
    if (seasonNumber.present) {
      map['season_number'] = Variable<int>(seasonNumber.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeasonsCompanion(')
          ..write('id: $id, ')
          ..write('seriesId: $seriesId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }
}

class $EpisodesTable extends Episodes
    with TableInfo<$EpisodesTable, EpisodeRecord> {
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
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES series (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _seasonIdMeta = const VerificationMeta(
    'seasonId',
  );
  @override
  late final GeneratedColumn<int> seasonId = GeneratedColumn<int>(
    'season_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES seasons (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _providerEpisodeKeyMeta =
      const VerificationMeta('providerEpisodeKey');
  @override
  late final GeneratedColumn<String> providerEpisodeKey =
      GeneratedColumn<String>(
        'provider_episode_key',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _seasonNumberMeta = const VerificationMeta(
    'seasonNumber',
  );
  @override
  late final GeneratedColumn<int> seasonNumber = GeneratedColumn<int>(
    'season_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _episodeNumberMeta = const VerificationMeta(
    'episodeNumber',
  );
  @override
  late final GeneratedColumn<int> episodeNumber = GeneratedColumn<int>(
    'episode_number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  static const VerificationMeta _overviewMeta = const VerificationMeta(
    'overview',
  );
  @override
  late final GeneratedColumn<String> overview = GeneratedColumn<String>(
    'overview',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecMeta = const VerificationMeta(
    'durationSec',
  );
  @override
  late final GeneratedColumn<int> durationSec = GeneratedColumn<int>(
    'duration_sec',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
    seriesId,
    seasonId,
    providerEpisodeKey,
    seasonNumber,
    episodeNumber,
    title,
    overview,
    durationSec,
    streamUrlTemplate,
    lastSeenAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'episodes';
  @override
  VerificationContext validateIntegrity(
    Insertable<EpisodeRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    } else if (isInserting) {
      context.missing(_seriesIdMeta);
    }
    if (data.containsKey('season_id')) {
      context.handle(
        _seasonIdMeta,
        seasonId.isAcceptableOrUnknown(data['season_id']!, _seasonIdMeta),
      );
    } else if (isInserting) {
      context.missing(_seasonIdMeta);
    }
    if (data.containsKey('provider_episode_key')) {
      context.handle(
        _providerEpisodeKeyMeta,
        providerEpisodeKey.isAcceptableOrUnknown(
          data['provider_episode_key']!,
          _providerEpisodeKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_providerEpisodeKeyMeta);
    }
    if (data.containsKey('season_number')) {
      context.handle(
        _seasonNumberMeta,
        seasonNumber.isAcceptableOrUnknown(
          data['season_number']!,
          _seasonNumberMeta,
        ),
      );
    }
    if (data.containsKey('episode_number')) {
      context.handle(
        _episodeNumberMeta,
        episodeNumber.isAcceptableOrUnknown(
          data['episode_number']!,
          _episodeNumberMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('overview')) {
      context.handle(
        _overviewMeta,
        overview.isAcceptableOrUnknown(data['overview']!, _overviewMeta),
      );
    }
    if (data.containsKey('duration_sec')) {
      context.handle(
        _durationSecMeta,
        durationSec.isAcceptableOrUnknown(
          data['duration_sec']!,
          _durationSecMeta,
        ),
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
    {seriesId, providerEpisodeKey},
  ];
  @override
  EpisodeRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EpisodeRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}series_id'],
      )!,
      seasonId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}season_id'],
      )!,
      providerEpisodeKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_episode_key'],
      )!,
      seasonNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}season_number'],
      ),
      episodeNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}episode_number'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      overview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}overview'],
      ),
      durationSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_sec'],
      ),
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
  $EpisodesTable createAlias(String alias) {
    return $EpisodesTable(attachedDatabase, alias);
  }
}

class EpisodeRecord extends DataClass implements Insertable<EpisodeRecord> {
  final int id;
  final int seriesId;
  final int seasonId;
  final String providerEpisodeKey;
  final int? seasonNumber;
  final int? episodeNumber;
  final String? title;
  final String? overview;
  final int? durationSec;
  final String? streamUrlTemplate;
  final DateTime? lastSeenAt;
  const EpisodeRecord({
    required this.id,
    required this.seriesId,
    required this.seasonId,
    required this.providerEpisodeKey,
    this.seasonNumber,
    this.episodeNumber,
    this.title,
    this.overview,
    this.durationSec,
    this.streamUrlTemplate,
    this.lastSeenAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['series_id'] = Variable<int>(seriesId);
    map['season_id'] = Variable<int>(seasonId);
    map['provider_episode_key'] = Variable<String>(providerEpisodeKey);
    if (!nullToAbsent || seasonNumber != null) {
      map['season_number'] = Variable<int>(seasonNumber);
    }
    if (!nullToAbsent || episodeNumber != null) {
      map['episode_number'] = Variable<int>(episodeNumber);
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || overview != null) {
      map['overview'] = Variable<String>(overview);
    }
    if (!nullToAbsent || durationSec != null) {
      map['duration_sec'] = Variable<int>(durationSec);
    }
    if (!nullToAbsent || streamUrlTemplate != null) {
      map['stream_url_template'] = Variable<String>(streamUrlTemplate);
    }
    if (!nullToAbsent || lastSeenAt != null) {
      map['last_seen_at'] = Variable<DateTime>(lastSeenAt);
    }
    return map;
  }

  EpisodesCompanion toCompanion(bool nullToAbsent) {
    return EpisodesCompanion(
      id: Value(id),
      seriesId: Value(seriesId),
      seasonId: Value(seasonId),
      providerEpisodeKey: Value(providerEpisodeKey),
      seasonNumber: seasonNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(seasonNumber),
      episodeNumber: episodeNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(episodeNumber),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      overview: overview == null && nullToAbsent
          ? const Value.absent()
          : Value(overview),
      durationSec: durationSec == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSec),
      streamUrlTemplate: streamUrlTemplate == null && nullToAbsent
          ? const Value.absent()
          : Value(streamUrlTemplate),
      lastSeenAt: lastSeenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeenAt),
    );
  }

  factory EpisodeRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EpisodeRecord(
      id: serializer.fromJson<int>(json['id']),
      seriesId: serializer.fromJson<int>(json['seriesId']),
      seasonId: serializer.fromJson<int>(json['seasonId']),
      providerEpisodeKey: serializer.fromJson<String>(
        json['providerEpisodeKey'],
      ),
      seasonNumber: serializer.fromJson<int?>(json['seasonNumber']),
      episodeNumber: serializer.fromJson<int?>(json['episodeNumber']),
      title: serializer.fromJson<String?>(json['title']),
      overview: serializer.fromJson<String?>(json['overview']),
      durationSec: serializer.fromJson<int?>(json['durationSec']),
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
      'seriesId': serializer.toJson<int>(seriesId),
      'seasonId': serializer.toJson<int>(seasonId),
      'providerEpisodeKey': serializer.toJson<String>(providerEpisodeKey),
      'seasonNumber': serializer.toJson<int?>(seasonNumber),
      'episodeNumber': serializer.toJson<int?>(episodeNumber),
      'title': serializer.toJson<String?>(title),
      'overview': serializer.toJson<String?>(overview),
      'durationSec': serializer.toJson<int?>(durationSec),
      'streamUrlTemplate': serializer.toJson<String?>(streamUrlTemplate),
      'lastSeenAt': serializer.toJson<DateTime?>(lastSeenAt),
    };
  }

  EpisodeRecord copyWith({
    int? id,
    int? seriesId,
    int? seasonId,
    String? providerEpisodeKey,
    Value<int?> seasonNumber = const Value.absent(),
    Value<int?> episodeNumber = const Value.absent(),
    Value<String?> title = const Value.absent(),
    Value<String?> overview = const Value.absent(),
    Value<int?> durationSec = const Value.absent(),
    Value<String?> streamUrlTemplate = const Value.absent(),
    Value<DateTime?> lastSeenAt = const Value.absent(),
  }) => EpisodeRecord(
    id: id ?? this.id,
    seriesId: seriesId ?? this.seriesId,
    seasonId: seasonId ?? this.seasonId,
    providerEpisodeKey: providerEpisodeKey ?? this.providerEpisodeKey,
    seasonNumber: seasonNumber.present ? seasonNumber.value : this.seasonNumber,
    episodeNumber: episodeNumber.present
        ? episodeNumber.value
        : this.episodeNumber,
    title: title.present ? title.value : this.title,
    overview: overview.present ? overview.value : this.overview,
    durationSec: durationSec.present ? durationSec.value : this.durationSec,
    streamUrlTemplate: streamUrlTemplate.present
        ? streamUrlTemplate.value
        : this.streamUrlTemplate,
    lastSeenAt: lastSeenAt.present ? lastSeenAt.value : this.lastSeenAt,
  );
  EpisodeRecord copyWithCompanion(EpisodesCompanion data) {
    return EpisodeRecord(
      id: data.id.present ? data.id.value : this.id,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      seasonId: data.seasonId.present ? data.seasonId.value : this.seasonId,
      providerEpisodeKey: data.providerEpisodeKey.present
          ? data.providerEpisodeKey.value
          : this.providerEpisodeKey,
      seasonNumber: data.seasonNumber.present
          ? data.seasonNumber.value
          : this.seasonNumber,
      episodeNumber: data.episodeNumber.present
          ? data.episodeNumber.value
          : this.episodeNumber,
      title: data.title.present ? data.title.value : this.title,
      overview: data.overview.present ? data.overview.value : this.overview,
      durationSec: data.durationSec.present
          ? data.durationSec.value
          : this.durationSec,
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
    return (StringBuffer('EpisodeRecord(')
          ..write('id: $id, ')
          ..write('seriesId: $seriesId, ')
          ..write('seasonId: $seasonId, ')
          ..write('providerEpisodeKey: $providerEpisodeKey, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('title: $title, ')
          ..write('overview: $overview, ')
          ..write('durationSec: $durationSec, ')
          ..write('streamUrlTemplate: $streamUrlTemplate, ')
          ..write('lastSeenAt: $lastSeenAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    seriesId,
    seasonId,
    providerEpisodeKey,
    seasonNumber,
    episodeNumber,
    title,
    overview,
    durationSec,
    streamUrlTemplate,
    lastSeenAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EpisodeRecord &&
          other.id == this.id &&
          other.seriesId == this.seriesId &&
          other.seasonId == this.seasonId &&
          other.providerEpisodeKey == this.providerEpisodeKey &&
          other.seasonNumber == this.seasonNumber &&
          other.episodeNumber == this.episodeNumber &&
          other.title == this.title &&
          other.overview == this.overview &&
          other.durationSec == this.durationSec &&
          other.streamUrlTemplate == this.streamUrlTemplate &&
          other.lastSeenAt == this.lastSeenAt);
}

class EpisodesCompanion extends UpdateCompanion<EpisodeRecord> {
  final Value<int> id;
  final Value<int> seriesId;
  final Value<int> seasonId;
  final Value<String> providerEpisodeKey;
  final Value<int?> seasonNumber;
  final Value<int?> episodeNumber;
  final Value<String?> title;
  final Value<String?> overview;
  final Value<int?> durationSec;
  final Value<String?> streamUrlTemplate;
  final Value<DateTime?> lastSeenAt;
  const EpisodesCompanion({
    this.id = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.seasonId = const Value.absent(),
    this.providerEpisodeKey = const Value.absent(),
    this.seasonNumber = const Value.absent(),
    this.episodeNumber = const Value.absent(),
    this.title = const Value.absent(),
    this.overview = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.streamUrlTemplate = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
  });
  EpisodesCompanion.insert({
    this.id = const Value.absent(),
    required int seriesId,
    required int seasonId,
    required String providerEpisodeKey,
    this.seasonNumber = const Value.absent(),
    this.episodeNumber = const Value.absent(),
    this.title = const Value.absent(),
    this.overview = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.streamUrlTemplate = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
  }) : seriesId = Value(seriesId),
       seasonId = Value(seasonId),
       providerEpisodeKey = Value(providerEpisodeKey);
  static Insertable<EpisodeRecord> custom({
    Expression<int>? id,
    Expression<int>? seriesId,
    Expression<int>? seasonId,
    Expression<String>? providerEpisodeKey,
    Expression<int>? seasonNumber,
    Expression<int>? episodeNumber,
    Expression<String>? title,
    Expression<String>? overview,
    Expression<int>? durationSec,
    Expression<String>? streamUrlTemplate,
    Expression<DateTime>? lastSeenAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (seriesId != null) 'series_id': seriesId,
      if (seasonId != null) 'season_id': seasonId,
      if (providerEpisodeKey != null)
        'provider_episode_key': providerEpisodeKey,
      if (seasonNumber != null) 'season_number': seasonNumber,
      if (episodeNumber != null) 'episode_number': episodeNumber,
      if (title != null) 'title': title,
      if (overview != null) 'overview': overview,
      if (durationSec != null) 'duration_sec': durationSec,
      if (streamUrlTemplate != null) 'stream_url_template': streamUrlTemplate,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
    });
  }

  EpisodesCompanion copyWith({
    Value<int>? id,
    Value<int>? seriesId,
    Value<int>? seasonId,
    Value<String>? providerEpisodeKey,
    Value<int?>? seasonNumber,
    Value<int?>? episodeNumber,
    Value<String?>? title,
    Value<String?>? overview,
    Value<int?>? durationSec,
    Value<String?>? streamUrlTemplate,
    Value<DateTime?>? lastSeenAt,
  }) {
    return EpisodesCompanion(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      seasonId: seasonId ?? this.seasonId,
      providerEpisodeKey: providerEpisodeKey ?? this.providerEpisodeKey,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      title: title ?? this.title,
      overview: overview ?? this.overview,
      durationSec: durationSec ?? this.durationSec,
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
    if (seriesId.present) {
      map['series_id'] = Variable<int>(seriesId.value);
    }
    if (seasonId.present) {
      map['season_id'] = Variable<int>(seasonId.value);
    }
    if (providerEpisodeKey.present) {
      map['provider_episode_key'] = Variable<String>(providerEpisodeKey.value);
    }
    if (seasonNumber.present) {
      map['season_number'] = Variable<int>(seasonNumber.value);
    }
    if (episodeNumber.present) {
      map['episode_number'] = Variable<int>(episodeNumber.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (overview.present) {
      map['overview'] = Variable<String>(overview.value);
    }
    if (durationSec.present) {
      map['duration_sec'] = Variable<int>(durationSec.value);
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
    return (StringBuffer('EpisodesCompanion(')
          ..write('id: $id, ')
          ..write('seriesId: $seriesId, ')
          ..write('seasonId: $seasonId, ')
          ..write('providerEpisodeKey: $providerEpisodeKey, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('title: $title, ')
          ..write('overview: $overview, ')
          ..write('durationSec: $durationSec, ')
          ..write('streamUrlTemplate: $streamUrlTemplate, ')
          ..write('lastSeenAt: $lastSeenAt')
          ..write(')'))
        .toString();
  }
}

class $ArtworkCacheTable extends ArtworkCache
    with TableInfo<$ArtworkCacheTable, ArtworkCacheRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArtworkCacheTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<String> hash = GeneratedColumn<String>(
    'hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  @override
  late final GeneratedColumn<Uint8List> bytes = GeneratedColumn<Uint8List>(
    'bytes',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _byteSizeMeta = const VerificationMeta(
    'byteSize',
  );
  @override
  late final GeneratedColumn<int> byteSize = GeneratedColumn<int>(
    'byte_size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastAccessedAtMeta = const VerificationMeta(
    'lastAccessedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAccessedAt =
      GeneratedColumn<DateTime>(
        'last_accessed_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _needsRefreshMeta = const VerificationMeta(
    'needsRefresh',
  );
  @override
  late final GeneratedColumn<bool> needsRefresh = GeneratedColumn<bool>(
    'needs_refresh',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("needs_refresh" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    url,
    etag,
    hash,
    bytes,
    filePath,
    byteSize,
    width,
    height,
    fetchedAt,
    lastAccessedAt,
    expiresAt,
    needsRefresh,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'artwork_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<ArtworkCacheRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    }
    if (data.containsKey('hash')) {
      context.handle(
        _hashMeta,
        hash.isAcceptableOrUnknown(data['hash']!, _hashMeta),
      );
    }
    if (data.containsKey('bytes')) {
      context.handle(
        _bytesMeta,
        bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta),
      );
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    }
    if (data.containsKey('byte_size')) {
      context.handle(
        _byteSizeMeta,
        byteSize.isAcceptableOrUnknown(data['byte_size']!, _byteSizeMeta),
      );
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    if (data.containsKey('last_accessed_at')) {
      context.handle(
        _lastAccessedAtMeta,
        lastAccessedAt.isAcceptableOrUnknown(
          data['last_accessed_at']!,
          _lastAccessedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastAccessedAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    }
    if (data.containsKey('needs_refresh')) {
      context.handle(
        _needsRefreshMeta,
        needsRefresh.isAcceptableOrUnknown(
          data['needs_refresh']!,
          _needsRefreshMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {url},
  ];
  @override
  ArtworkCacheRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ArtworkCacheRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      ),
      hash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash'],
      ),
      bytes: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}bytes'],
      ),
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      ),
      byteSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}byte_size'],
      ),
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      ),
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      ),
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
      lastAccessedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_accessed_at'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      ),
      needsRefresh: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}needs_refresh'],
      )!,
    );
  }

  @override
  $ArtworkCacheTable createAlias(String alias) {
    return $ArtworkCacheTable(attachedDatabase, alias);
  }
}

class ArtworkCacheRecord extends DataClass
    implements Insertable<ArtworkCacheRecord> {
  final int id;
  final String url;
  final String? etag;
  final String? hash;
  final Uint8List? bytes;
  final String? filePath;
  final int? byteSize;
  final int? width;
  final int? height;
  final DateTime fetchedAt;
  final DateTime lastAccessedAt;
  final DateTime? expiresAt;
  final bool needsRefresh;
  const ArtworkCacheRecord({
    required this.id,
    required this.url,
    this.etag,
    this.hash,
    this.bytes,
    this.filePath,
    this.byteSize,
    this.width,
    this.height,
    required this.fetchedAt,
    required this.lastAccessedAt,
    this.expiresAt,
    required this.needsRefresh,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['url'] = Variable<String>(url);
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    if (!nullToAbsent || hash != null) {
      map['hash'] = Variable<String>(hash);
    }
    if (!nullToAbsent || bytes != null) {
      map['bytes'] = Variable<Uint8List>(bytes);
    }
    if (!nullToAbsent || filePath != null) {
      map['file_path'] = Variable<String>(filePath);
    }
    if (!nullToAbsent || byteSize != null) {
      map['byte_size'] = Variable<int>(byteSize);
    }
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt);
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<DateTime>(expiresAt);
    }
    map['needs_refresh'] = Variable<bool>(needsRefresh);
    return map;
  }

  ArtworkCacheCompanion toCompanion(bool nullToAbsent) {
    return ArtworkCacheCompanion(
      id: Value(id),
      url: Value(url),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
      hash: hash == null && nullToAbsent ? const Value.absent() : Value(hash),
      bytes: bytes == null && nullToAbsent
          ? const Value.absent()
          : Value(bytes),
      filePath: filePath == null && nullToAbsent
          ? const Value.absent()
          : Value(filePath),
      byteSize: byteSize == null && nullToAbsent
          ? const Value.absent()
          : Value(byteSize),
      width: width == null && nullToAbsent
          ? const Value.absent()
          : Value(width),
      height: height == null && nullToAbsent
          ? const Value.absent()
          : Value(height),
      fetchedAt: Value(fetchedAt),
      lastAccessedAt: Value(lastAccessedAt),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
      needsRefresh: Value(needsRefresh),
    );
  }

  factory ArtworkCacheRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ArtworkCacheRecord(
      id: serializer.fromJson<int>(json['id']),
      url: serializer.fromJson<String>(json['url']),
      etag: serializer.fromJson<String?>(json['etag']),
      hash: serializer.fromJson<String?>(json['hash']),
      bytes: serializer.fromJson<Uint8List?>(json['bytes']),
      filePath: serializer.fromJson<String?>(json['filePath']),
      byteSize: serializer.fromJson<int?>(json['byteSize']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
      lastAccessedAt: serializer.fromJson<DateTime>(json['lastAccessedAt']),
      expiresAt: serializer.fromJson<DateTime?>(json['expiresAt']),
      needsRefresh: serializer.fromJson<bool>(json['needsRefresh']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'url': serializer.toJson<String>(url),
      'etag': serializer.toJson<String?>(etag),
      'hash': serializer.toJson<String?>(hash),
      'bytes': serializer.toJson<Uint8List?>(bytes),
      'filePath': serializer.toJson<String?>(filePath),
      'byteSize': serializer.toJson<int?>(byteSize),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
      'lastAccessedAt': serializer.toJson<DateTime>(lastAccessedAt),
      'expiresAt': serializer.toJson<DateTime?>(expiresAt),
      'needsRefresh': serializer.toJson<bool>(needsRefresh),
    };
  }

  ArtworkCacheRecord copyWith({
    int? id,
    String? url,
    Value<String?> etag = const Value.absent(),
    Value<String?> hash = const Value.absent(),
    Value<Uint8List?> bytes = const Value.absent(),
    Value<String?> filePath = const Value.absent(),
    Value<int?> byteSize = const Value.absent(),
    Value<int?> width = const Value.absent(),
    Value<int?> height = const Value.absent(),
    DateTime? fetchedAt,
    DateTime? lastAccessedAt,
    Value<DateTime?> expiresAt = const Value.absent(),
    bool? needsRefresh,
  }) => ArtworkCacheRecord(
    id: id ?? this.id,
    url: url ?? this.url,
    etag: etag.present ? etag.value : this.etag,
    hash: hash.present ? hash.value : this.hash,
    bytes: bytes.present ? bytes.value : this.bytes,
    filePath: filePath.present ? filePath.value : this.filePath,
    byteSize: byteSize.present ? byteSize.value : this.byteSize,
    width: width.present ? width.value : this.width,
    height: height.present ? height.value : this.height,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
    expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
    needsRefresh: needsRefresh ?? this.needsRefresh,
  );
  ArtworkCacheRecord copyWithCompanion(ArtworkCacheCompanion data) {
    return ArtworkCacheRecord(
      id: data.id.present ? data.id.value : this.id,
      url: data.url.present ? data.url.value : this.url,
      etag: data.etag.present ? data.etag.value : this.etag,
      hash: data.hash.present ? data.hash.value : this.hash,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      byteSize: data.byteSize.present ? data.byteSize.value : this.byteSize,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      lastAccessedAt: data.lastAccessedAt.present
          ? data.lastAccessedAt.value
          : this.lastAccessedAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      needsRefresh: data.needsRefresh.present
          ? data.needsRefresh.value
          : this.needsRefresh,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ArtworkCacheRecord(')
          ..write('id: $id, ')
          ..write('url: $url, ')
          ..write('etag: $etag, ')
          ..write('hash: $hash, ')
          ..write('bytes: $bytes, ')
          ..write('filePath: $filePath, ')
          ..write('byteSize: $byteSize, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('lastAccessedAt: $lastAccessedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('needsRefresh: $needsRefresh')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    url,
    etag,
    hash,
    $driftBlobEquality.hash(bytes),
    filePath,
    byteSize,
    width,
    height,
    fetchedAt,
    lastAccessedAt,
    expiresAt,
    needsRefresh,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArtworkCacheRecord &&
          other.id == this.id &&
          other.url == this.url &&
          other.etag == this.etag &&
          other.hash == this.hash &&
          $driftBlobEquality.equals(other.bytes, this.bytes) &&
          other.filePath == this.filePath &&
          other.byteSize == this.byteSize &&
          other.width == this.width &&
          other.height == this.height &&
          other.fetchedAt == this.fetchedAt &&
          other.lastAccessedAt == this.lastAccessedAt &&
          other.expiresAt == this.expiresAt &&
          other.needsRefresh == this.needsRefresh);
}

class ArtworkCacheCompanion extends UpdateCompanion<ArtworkCacheRecord> {
  final Value<int> id;
  final Value<String> url;
  final Value<String?> etag;
  final Value<String?> hash;
  final Value<Uint8List?> bytes;
  final Value<String?> filePath;
  final Value<int?> byteSize;
  final Value<int?> width;
  final Value<int?> height;
  final Value<DateTime> fetchedAt;
  final Value<DateTime> lastAccessedAt;
  final Value<DateTime?> expiresAt;
  final Value<bool> needsRefresh;
  const ArtworkCacheCompanion({
    this.id = const Value.absent(),
    this.url = const Value.absent(),
    this.etag = const Value.absent(),
    this.hash = const Value.absent(),
    this.bytes = const Value.absent(),
    this.filePath = const Value.absent(),
    this.byteSize = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.lastAccessedAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.needsRefresh = const Value.absent(),
  });
  ArtworkCacheCompanion.insert({
    this.id = const Value.absent(),
    required String url,
    this.etag = const Value.absent(),
    this.hash = const Value.absent(),
    this.bytes = const Value.absent(),
    this.filePath = const Value.absent(),
    this.byteSize = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    required DateTime fetchedAt,
    required DateTime lastAccessedAt,
    this.expiresAt = const Value.absent(),
    this.needsRefresh = const Value.absent(),
  }) : url = Value(url),
       fetchedAt = Value(fetchedAt),
       lastAccessedAt = Value(lastAccessedAt);
  static Insertable<ArtworkCacheRecord> custom({
    Expression<int>? id,
    Expression<String>? url,
    Expression<String>? etag,
    Expression<String>? hash,
    Expression<Uint8List>? bytes,
    Expression<String>? filePath,
    Expression<int>? byteSize,
    Expression<int>? width,
    Expression<int>? height,
    Expression<DateTime>? fetchedAt,
    Expression<DateTime>? lastAccessedAt,
    Expression<DateTime>? expiresAt,
    Expression<bool>? needsRefresh,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (url != null) 'url': url,
      if (etag != null) 'etag': etag,
      if (hash != null) 'hash': hash,
      if (bytes != null) 'bytes': bytes,
      if (filePath != null) 'file_path': filePath,
      if (byteSize != null) 'byte_size': byteSize,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (lastAccessedAt != null) 'last_accessed_at': lastAccessedAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (needsRefresh != null) 'needs_refresh': needsRefresh,
    });
  }

  ArtworkCacheCompanion copyWith({
    Value<int>? id,
    Value<String>? url,
    Value<String?>? etag,
    Value<String?>? hash,
    Value<Uint8List?>? bytes,
    Value<String?>? filePath,
    Value<int?>? byteSize,
    Value<int?>? width,
    Value<int?>? height,
    Value<DateTime>? fetchedAt,
    Value<DateTime>? lastAccessedAt,
    Value<DateTime?>? expiresAt,
    Value<bool>? needsRefresh,
  }) {
    return ArtworkCacheCompanion(
      id: id ?? this.id,
      url: url ?? this.url,
      etag: etag ?? this.etag,
      hash: hash ?? this.hash,
      bytes: bytes ?? this.bytes,
      filePath: filePath ?? this.filePath,
      byteSize: byteSize ?? this.byteSize,
      width: width ?? this.width,
      height: height ?? this.height,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      needsRefresh: needsRefresh ?? this.needsRefresh,
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
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (hash.present) {
      map['hash'] = Variable<String>(hash.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<Uint8List>(bytes.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (byteSize.present) {
      map['byte_size'] = Variable<int>(byteSize.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (lastAccessedAt.present) {
      map['last_accessed_at'] = Variable<DateTime>(lastAccessedAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (needsRefresh.present) {
      map['needs_refresh'] = Variable<bool>(needsRefresh.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArtworkCacheCompanion(')
          ..write('id: $id, ')
          ..write('url: $url, ')
          ..write('etag: $etag, ')
          ..write('hash: $hash, ')
          ..write('bytes: $bytes, ')
          ..write('filePath: $filePath, ')
          ..write('byteSize: $byteSize, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('lastAccessedAt: $lastAccessedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('needsRefresh: $needsRefresh')
          ..write(')'))
        .toString();
  }
}

class $PlaybackHistoryTable extends PlaybackHistory
    with TableInfo<$PlaybackHistoryTable, PlaybackHistoryRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaybackHistoryTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
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
  static const VerificationMeta _positionSecMeta = const VerificationMeta(
    'positionSec',
  );
  @override
  late final GeneratedColumn<int> positionSec = GeneratedColumn<int>(
    'position_sec',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _durationSecMeta = const VerificationMeta(
    'durationSec',
  );
  @override
  late final GeneratedColumn<int> durationSec = GeneratedColumn<int>(
    'duration_sec',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    providerId,
    channelId,
    startedAt,
    updatedAt,
    positionSec,
    durationSec,
    completed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playback_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaybackHistoryRecord> instance, {
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
    if (data.containsKey('channel_id')) {
      context.handle(
        _channelIdMeta,
        channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_channelIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('position_sec')) {
      context.handle(
        _positionSecMeta,
        positionSec.isAcceptableOrUnknown(
          data['position_sec']!,
          _positionSecMeta,
        ),
      );
    }
    if (data.containsKey('duration_sec')) {
      context.handle(
        _durationSecMeta,
        durationSec.isAcceptableOrUnknown(
          data['duration_sec']!,
          _durationSecMeta,
        ),
      );
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {channelId},
  ];
  @override
  PlaybackHistoryRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaybackHistoryRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}provider_id'],
      )!,
      channelId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}channel_id'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      positionSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_sec'],
      )!,
      durationSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_sec'],
      ),
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
    );
  }

  @override
  $PlaybackHistoryTable createAlias(String alias) {
    return $PlaybackHistoryTable(attachedDatabase, alias);
  }
}

class PlaybackHistoryRecord extends DataClass
    implements Insertable<PlaybackHistoryRecord> {
  final int id;
  final int providerId;
  final int channelId;
  final DateTime startedAt;
  final DateTime updatedAt;
  final int positionSec;
  final int? durationSec;
  final bool completed;
  const PlaybackHistoryRecord({
    required this.id,
    required this.providerId,
    required this.channelId,
    required this.startedAt,
    required this.updatedAt,
    required this.positionSec,
    this.durationSec,
    required this.completed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['provider_id'] = Variable<int>(providerId);
    map['channel_id'] = Variable<int>(channelId);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['position_sec'] = Variable<int>(positionSec);
    if (!nullToAbsent || durationSec != null) {
      map['duration_sec'] = Variable<int>(durationSec);
    }
    map['completed'] = Variable<bool>(completed);
    return map;
  }

  PlaybackHistoryCompanion toCompanion(bool nullToAbsent) {
    return PlaybackHistoryCompanion(
      id: Value(id),
      providerId: Value(providerId),
      channelId: Value(channelId),
      startedAt: Value(startedAt),
      updatedAt: Value(updatedAt),
      positionSec: Value(positionSec),
      durationSec: durationSec == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSec),
      completed: Value(completed),
    );
  }

  factory PlaybackHistoryRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaybackHistoryRecord(
      id: serializer.fromJson<int>(json['id']),
      providerId: serializer.fromJson<int>(json['providerId']),
      channelId: serializer.fromJson<int>(json['channelId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      positionSec: serializer.fromJson<int>(json['positionSec']),
      durationSec: serializer.fromJson<int?>(json['durationSec']),
      completed: serializer.fromJson<bool>(json['completed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'providerId': serializer.toJson<int>(providerId),
      'channelId': serializer.toJson<int>(channelId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'positionSec': serializer.toJson<int>(positionSec),
      'durationSec': serializer.toJson<int?>(durationSec),
      'completed': serializer.toJson<bool>(completed),
    };
  }

  PlaybackHistoryRecord copyWith({
    int? id,
    int? providerId,
    int? channelId,
    DateTime? startedAt,
    DateTime? updatedAt,
    int? positionSec,
    Value<int?> durationSec = const Value.absent(),
    bool? completed,
  }) => PlaybackHistoryRecord(
    id: id ?? this.id,
    providerId: providerId ?? this.providerId,
    channelId: channelId ?? this.channelId,
    startedAt: startedAt ?? this.startedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    positionSec: positionSec ?? this.positionSec,
    durationSec: durationSec.present ? durationSec.value : this.durationSec,
    completed: completed ?? this.completed,
  );
  PlaybackHistoryRecord copyWithCompanion(PlaybackHistoryCompanion data) {
    return PlaybackHistoryRecord(
      id: data.id.present ? data.id.value : this.id,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      positionSec: data.positionSec.present
          ? data.positionSec.value
          : this.positionSec,
      durationSec: data.durationSec.present
          ? data.durationSec.value
          : this.durationSec,
      completed: data.completed.present ? data.completed.value : this.completed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackHistoryRecord(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('channelId: $channelId, ')
          ..write('startedAt: $startedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('positionSec: $positionSec, ')
          ..write('durationSec: $durationSec, ')
          ..write('completed: $completed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    providerId,
    channelId,
    startedAt,
    updatedAt,
    positionSec,
    durationSec,
    completed,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaybackHistoryRecord &&
          other.id == this.id &&
          other.providerId == this.providerId &&
          other.channelId == this.channelId &&
          other.startedAt == this.startedAt &&
          other.updatedAt == this.updatedAt &&
          other.positionSec == this.positionSec &&
          other.durationSec == this.durationSec &&
          other.completed == this.completed);
}

class PlaybackHistoryCompanion extends UpdateCompanion<PlaybackHistoryRecord> {
  final Value<int> id;
  final Value<int> providerId;
  final Value<int> channelId;
  final Value<DateTime> startedAt;
  final Value<DateTime> updatedAt;
  final Value<int> positionSec;
  final Value<int?> durationSec;
  final Value<bool> completed;
  const PlaybackHistoryCompanion({
    this.id = const Value.absent(),
    this.providerId = const Value.absent(),
    this.channelId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.positionSec = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.completed = const Value.absent(),
  });
  PlaybackHistoryCompanion.insert({
    this.id = const Value.absent(),
    required int providerId,
    required int channelId,
    required DateTime startedAt,
    required DateTime updatedAt,
    this.positionSec = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.completed = const Value.absent(),
  }) : providerId = Value(providerId),
       channelId = Value(channelId),
       startedAt = Value(startedAt),
       updatedAt = Value(updatedAt);
  static Insertable<PlaybackHistoryRecord> custom({
    Expression<int>? id,
    Expression<int>? providerId,
    Expression<int>? channelId,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? positionSec,
    Expression<int>? durationSec,
    Expression<bool>? completed,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (providerId != null) 'provider_id': providerId,
      if (channelId != null) 'channel_id': channelId,
      if (startedAt != null) 'started_at': startedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (positionSec != null) 'position_sec': positionSec,
      if (durationSec != null) 'duration_sec': durationSec,
      if (completed != null) 'completed': completed,
    });
  }

  PlaybackHistoryCompanion copyWith({
    Value<int>? id,
    Value<int>? providerId,
    Value<int>? channelId,
    Value<DateTime>? startedAt,
    Value<DateTime>? updatedAt,
    Value<int>? positionSec,
    Value<int?>? durationSec,
    Value<bool>? completed,
  }) {
    return PlaybackHistoryCompanion(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      channelId: channelId ?? this.channelId,
      startedAt: startedAt ?? this.startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      positionSec: positionSec ?? this.positionSec,
      durationSec: durationSec ?? this.durationSec,
      completed: completed ?? this.completed,
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
    if (channelId.present) {
      map['channel_id'] = Variable<int>(channelId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (positionSec.present) {
      map['position_sec'] = Variable<int>(positionSec.value);
    }
    if (durationSec.present) {
      map['duration_sec'] = Variable<int>(durationSec.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackHistoryCompanion(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('channelId: $channelId, ')
          ..write('startedAt: $startedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('positionSec: $positionSec, ')
          ..write('durationSec: $durationSec, ')
          ..write('completed: $completed')
          ..write(')'))
        .toString();
  }
}

class $UserFlagsTable extends UserFlags
    with TableInfo<$UserFlagsTable, UserFlagRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserFlagsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isHiddenMeta = const VerificationMeta(
    'isHidden',
  );
  @override
  late final GeneratedColumn<bool> isHidden = GeneratedColumn<bool>(
    'is_hidden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_hidden" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isPinnedMeta = const VerificationMeta(
    'isPinned',
  );
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
    'is_pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    providerId,
    channelId,
    isFavorite,
    isHidden,
    isPinned,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_flags';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserFlagRecord> instance, {
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
    if (data.containsKey('channel_id')) {
      context.handle(
        _channelIdMeta,
        channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_channelIdMeta);
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('is_hidden')) {
      context.handle(
        _isHiddenMeta,
        isHidden.isAcceptableOrUnknown(data['is_hidden']!, _isHiddenMeta),
      );
    }
    if (data.containsKey('is_pinned')) {
      context.handle(
        _isPinnedMeta,
        isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta),
      );
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
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {channelId},
  ];
  @override
  UserFlagRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserFlagRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}provider_id'],
      )!,
      channelId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}channel_id'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      isHidden: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_hidden'],
      )!,
      isPinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pinned'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UserFlagsTable createAlias(String alias) {
    return $UserFlagsTable(attachedDatabase, alias);
  }
}

class UserFlagRecord extends DataClass implements Insertable<UserFlagRecord> {
  final int id;
  final int providerId;
  final int channelId;
  final bool isFavorite;
  final bool isHidden;
  final bool isPinned;
  final DateTime updatedAt;
  const UserFlagRecord({
    required this.id,
    required this.providerId,
    required this.channelId,
    required this.isFavorite,
    required this.isHidden,
    required this.isPinned,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['provider_id'] = Variable<int>(providerId);
    map['channel_id'] = Variable<int>(channelId);
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['is_hidden'] = Variable<bool>(isHidden);
    map['is_pinned'] = Variable<bool>(isPinned);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserFlagsCompanion toCompanion(bool nullToAbsent) {
    return UserFlagsCompanion(
      id: Value(id),
      providerId: Value(providerId),
      channelId: Value(channelId),
      isFavorite: Value(isFavorite),
      isHidden: Value(isHidden),
      isPinned: Value(isPinned),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserFlagRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserFlagRecord(
      id: serializer.fromJson<int>(json['id']),
      providerId: serializer.fromJson<int>(json['providerId']),
      channelId: serializer.fromJson<int>(json['channelId']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      isHidden: serializer.fromJson<bool>(json['isHidden']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'providerId': serializer.toJson<int>(providerId),
      'channelId': serializer.toJson<int>(channelId),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'isHidden': serializer.toJson<bool>(isHidden),
      'isPinned': serializer.toJson<bool>(isPinned),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserFlagRecord copyWith({
    int? id,
    int? providerId,
    int? channelId,
    bool? isFavorite,
    bool? isHidden,
    bool? isPinned,
    DateTime? updatedAt,
  }) => UserFlagRecord(
    id: id ?? this.id,
    providerId: providerId ?? this.providerId,
    channelId: channelId ?? this.channelId,
    isFavorite: isFavorite ?? this.isFavorite,
    isHidden: isHidden ?? this.isHidden,
    isPinned: isPinned ?? this.isPinned,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UserFlagRecord copyWithCompanion(UserFlagsCompanion data) {
    return UserFlagRecord(
      id: data.id.present ? data.id.value : this.id,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      isHidden: data.isHidden.present ? data.isHidden.value : this.isHidden,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserFlagRecord(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('channelId: $channelId, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isHidden: $isHidden, ')
          ..write('isPinned: $isPinned, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    providerId,
    channelId,
    isFavorite,
    isHidden,
    isPinned,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserFlagRecord &&
          other.id == this.id &&
          other.providerId == this.providerId &&
          other.channelId == this.channelId &&
          other.isFavorite == this.isFavorite &&
          other.isHidden == this.isHidden &&
          other.isPinned == this.isPinned &&
          other.updatedAt == this.updatedAt);
}

class UserFlagsCompanion extends UpdateCompanion<UserFlagRecord> {
  final Value<int> id;
  final Value<int> providerId;
  final Value<int> channelId;
  final Value<bool> isFavorite;
  final Value<bool> isHidden;
  final Value<bool> isPinned;
  final Value<DateTime> updatedAt;
  const UserFlagsCompanion({
    this.id = const Value.absent(),
    this.providerId = const Value.absent(),
    this.channelId = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isHidden = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  UserFlagsCompanion.insert({
    this.id = const Value.absent(),
    required int providerId,
    required int channelId,
    this.isFavorite = const Value.absent(),
    this.isHidden = const Value.absent(),
    this.isPinned = const Value.absent(),
    required DateTime updatedAt,
  }) : providerId = Value(providerId),
       channelId = Value(channelId),
       updatedAt = Value(updatedAt);
  static Insertable<UserFlagRecord> custom({
    Expression<int>? id,
    Expression<int>? providerId,
    Expression<int>? channelId,
    Expression<bool>? isFavorite,
    Expression<bool>? isHidden,
    Expression<bool>? isPinned,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (providerId != null) 'provider_id': providerId,
      if (channelId != null) 'channel_id': channelId,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (isHidden != null) 'is_hidden': isHidden,
      if (isPinned != null) 'is_pinned': isPinned,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  UserFlagsCompanion copyWith({
    Value<int>? id,
    Value<int>? providerId,
    Value<int>? channelId,
    Value<bool>? isFavorite,
    Value<bool>? isHidden,
    Value<bool>? isPinned,
    Value<DateTime>? updatedAt,
  }) {
    return UserFlagsCompanion(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      channelId: channelId ?? this.channelId,
      isFavorite: isFavorite ?? this.isFavorite,
      isHidden: isHidden ?? this.isHidden,
      isPinned: isPinned ?? this.isPinned,
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
    if (channelId.present) {
      map['channel_id'] = Variable<int>(channelId.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (isHidden.present) {
      map['is_hidden'] = Variable<bool>(isHidden.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserFlagsCompanion(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('channelId: $channelId, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isHidden: $isHidden, ')
          ..write('isPinned: $isPinned, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $MaintenanceLogTable extends MaintenanceLog
    with TableInfo<$MaintenanceLogTable, MaintenanceLogRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MaintenanceLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _taskMeta = const VerificationMeta('task');
  @override
  late final GeneratedColumn<String> task = GeneratedColumn<String>(
    'task',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastRunAtMeta = const VerificationMeta(
    'lastRunAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastRunAt = GeneratedColumn<DateTime>(
    'last_run_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [task, lastRunAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'maintenance_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<MaintenanceLogRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('task')) {
      context.handle(
        _taskMeta,
        task.isAcceptableOrUnknown(data['task']!, _taskMeta),
      );
    } else if (isInserting) {
      context.missing(_taskMeta);
    }
    if (data.containsKey('last_run_at')) {
      context.handle(
        _lastRunAtMeta,
        lastRunAt.isAcceptableOrUnknown(data['last_run_at']!, _lastRunAtMeta),
      );
    } else if (isInserting) {
      context.missing(_lastRunAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {task};
  @override
  MaintenanceLogRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MaintenanceLogRecord(
      task: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task'],
      )!,
      lastRunAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_run_at'],
      )!,
    );
  }

  @override
  $MaintenanceLogTable createAlias(String alias) {
    return $MaintenanceLogTable(attachedDatabase, alias);
  }
}

class MaintenanceLogRecord extends DataClass
    implements Insertable<MaintenanceLogRecord> {
  final String task;
  final DateTime lastRunAt;
  const MaintenanceLogRecord({required this.task, required this.lastRunAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['task'] = Variable<String>(task);
    map['last_run_at'] = Variable<DateTime>(lastRunAt);
    return map;
  }

  MaintenanceLogCompanion toCompanion(bool nullToAbsent) {
    return MaintenanceLogCompanion(
      task: Value(task),
      lastRunAt: Value(lastRunAt),
    );
  }

  factory MaintenanceLogRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MaintenanceLogRecord(
      task: serializer.fromJson<String>(json['task']),
      lastRunAt: serializer.fromJson<DateTime>(json['lastRunAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'task': serializer.toJson<String>(task),
      'lastRunAt': serializer.toJson<DateTime>(lastRunAt),
    };
  }

  MaintenanceLogRecord copyWith({String? task, DateTime? lastRunAt}) =>
      MaintenanceLogRecord(
        task: task ?? this.task,
        lastRunAt: lastRunAt ?? this.lastRunAt,
      );
  MaintenanceLogRecord copyWithCompanion(MaintenanceLogCompanion data) {
    return MaintenanceLogRecord(
      task: data.task.present ? data.task.value : this.task,
      lastRunAt: data.lastRunAt.present ? data.lastRunAt.value : this.lastRunAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MaintenanceLogRecord(')
          ..write('task: $task, ')
          ..write('lastRunAt: $lastRunAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(task, lastRunAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MaintenanceLogRecord &&
          other.task == this.task &&
          other.lastRunAt == this.lastRunAt);
}

class MaintenanceLogCompanion extends UpdateCompanion<MaintenanceLogRecord> {
  final Value<String> task;
  final Value<DateTime> lastRunAt;
  final Value<int> rowid;
  const MaintenanceLogCompanion({
    this.task = const Value.absent(),
    this.lastRunAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MaintenanceLogCompanion.insert({
    required String task,
    required DateTime lastRunAt,
    this.rowid = const Value.absent(),
  }) : task = Value(task),
       lastRunAt = Value(lastRunAt);
  static Insertable<MaintenanceLogRecord> custom({
    Expression<String>? task,
    Expression<DateTime>? lastRunAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (task != null) 'task': task,
      if (lastRunAt != null) 'last_run_at': lastRunAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MaintenanceLogCompanion copyWith({
    Value<String>? task,
    Value<DateTime>? lastRunAt,
    Value<int>? rowid,
  }) {
    return MaintenanceLogCompanion(
      task: task ?? this.task,
      lastRunAt: lastRunAt ?? this.lastRunAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (task.present) {
      map['task'] = Variable<String>(task.value);
    }
    if (lastRunAt.present) {
      map['last_run_at'] = Variable<DateTime>(lastRunAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MaintenanceLogCompanion(')
          ..write('task: $task, ')
          ..write('lastRunAt: $lastRunAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImportRunsTable extends ImportRuns
    with TableInfo<$ImportRunsTable, ImportRunRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImportRunsTable(this.attachedDatabase, [this._alias]);
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
  late final GeneratedColumnWithTypeConverter<ProviderKind, String>
  providerKind = GeneratedColumn<String>(
    'provider_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<ProviderKind>($ImportRunsTable.$converterproviderKind);
  static const VerificationMeta _importTypeMeta = const VerificationMeta(
    'importType',
  );
  @override
  late final GeneratedColumn<String> importType = GeneratedColumn<String>(
    'import_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _channelsUpsertedMeta = const VerificationMeta(
    'channelsUpserted',
  );
  @override
  late final GeneratedColumn<int> channelsUpserted = GeneratedColumn<int>(
    'channels_upserted',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoriesUpsertedMeta =
      const VerificationMeta('categoriesUpserted');
  @override
  late final GeneratedColumn<int> categoriesUpserted = GeneratedColumn<int>(
    'categories_upserted',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _moviesUpsertedMeta = const VerificationMeta(
    'moviesUpserted',
  );
  @override
  late final GeneratedColumn<int> moviesUpserted = GeneratedColumn<int>(
    'movies_upserted',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seriesUpsertedMeta = const VerificationMeta(
    'seriesUpserted',
  );
  @override
  late final GeneratedColumn<int> seriesUpserted = GeneratedColumn<int>(
    'series_upserted',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seasonsUpsertedMeta = const VerificationMeta(
    'seasonsUpserted',
  );
  @override
  late final GeneratedColumn<int> seasonsUpserted = GeneratedColumn<int>(
    'seasons_upserted',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _episodesUpsertedMeta = const VerificationMeta(
    'episodesUpserted',
  );
  @override
  late final GeneratedColumn<int> episodesUpserted = GeneratedColumn<int>(
    'episodes_upserted',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _channelsDeletedMeta = const VerificationMeta(
    'channelsDeleted',
  );
  @override
  late final GeneratedColumn<int> channelsDeleted = GeneratedColumn<int>(
    'channels_deleted',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    providerId,
    providerKind,
    importType,
    startedAt,
    durationMs,
    channelsUpserted,
    categoriesUpserted,
    moviesUpserted,
    seriesUpserted,
    seasonsUpserted,
    episodesUpserted,
    channelsDeleted,
    error,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'import_runs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImportRunRecord> instance, {
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
    if (data.containsKey('import_type')) {
      context.handle(
        _importTypeMeta,
        importType.isAcceptableOrUnknown(data['import_type']!, _importTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_importTypeMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('channels_upserted')) {
      context.handle(
        _channelsUpsertedMeta,
        channelsUpserted.isAcceptableOrUnknown(
          data['channels_upserted']!,
          _channelsUpsertedMeta,
        ),
      );
    }
    if (data.containsKey('categories_upserted')) {
      context.handle(
        _categoriesUpsertedMeta,
        categoriesUpserted.isAcceptableOrUnknown(
          data['categories_upserted']!,
          _categoriesUpsertedMeta,
        ),
      );
    }
    if (data.containsKey('movies_upserted')) {
      context.handle(
        _moviesUpsertedMeta,
        moviesUpserted.isAcceptableOrUnknown(
          data['movies_upserted']!,
          _moviesUpsertedMeta,
        ),
      );
    }
    if (data.containsKey('series_upserted')) {
      context.handle(
        _seriesUpsertedMeta,
        seriesUpserted.isAcceptableOrUnknown(
          data['series_upserted']!,
          _seriesUpsertedMeta,
        ),
      );
    }
    if (data.containsKey('seasons_upserted')) {
      context.handle(
        _seasonsUpsertedMeta,
        seasonsUpserted.isAcceptableOrUnknown(
          data['seasons_upserted']!,
          _seasonsUpsertedMeta,
        ),
      );
    }
    if (data.containsKey('episodes_upserted')) {
      context.handle(
        _episodesUpsertedMeta,
        episodesUpserted.isAcceptableOrUnknown(
          data['episodes_upserted']!,
          _episodesUpsertedMeta,
        ),
      );
    }
    if (data.containsKey('channels_deleted')) {
      context.handle(
        _channelsDeletedMeta,
        channelsDeleted.isAcceptableOrUnknown(
          data['channels_deleted']!,
          _channelsDeletedMeta,
        ),
      );
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ImportRunRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImportRunRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}provider_id'],
      )!,
      providerKind: $ImportRunsTable.$converterproviderKind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}provider_kind'],
        )!,
      ),
      importType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}import_type'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
      channelsUpserted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}channels_upserted'],
      ),
      categoriesUpserted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}categories_upserted'],
      ),
      moviesUpserted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}movies_upserted'],
      ),
      seriesUpserted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}series_upserted'],
      ),
      seasonsUpserted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seasons_upserted'],
      ),
      episodesUpserted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}episodes_upserted'],
      ),
      channelsDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}channels_deleted'],
      ),
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
    );
  }

  @override
  $ImportRunsTable createAlias(String alias) {
    return $ImportRunsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ProviderKind, String, String>
  $converterproviderKind = const EnumNameConverter<ProviderKind>(
    ProviderKind.values,
  );
}

class ImportRunRecord extends DataClass implements Insertable<ImportRunRecord> {
  final int id;
  final int providerId;
  final ProviderKind providerKind;
  final String importType;
  final DateTime startedAt;
  final int? durationMs;
  final int? channelsUpserted;
  final int? categoriesUpserted;
  final int? moviesUpserted;
  final int? seriesUpserted;
  final int? seasonsUpserted;
  final int? episodesUpserted;
  final int? channelsDeleted;
  final String? error;
  const ImportRunRecord({
    required this.id,
    required this.providerId,
    required this.providerKind,
    required this.importType,
    required this.startedAt,
    this.durationMs,
    this.channelsUpserted,
    this.categoriesUpserted,
    this.moviesUpserted,
    this.seriesUpserted,
    this.seasonsUpserted,
    this.episodesUpserted,
    this.channelsDeleted,
    this.error,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['provider_id'] = Variable<int>(providerId);
    {
      map['provider_kind'] = Variable<String>(
        $ImportRunsTable.$converterproviderKind.toSql(providerKind),
      );
    }
    map['import_type'] = Variable<String>(importType);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    if (!nullToAbsent || channelsUpserted != null) {
      map['channels_upserted'] = Variable<int>(channelsUpserted);
    }
    if (!nullToAbsent || categoriesUpserted != null) {
      map['categories_upserted'] = Variable<int>(categoriesUpserted);
    }
    if (!nullToAbsent || moviesUpserted != null) {
      map['movies_upserted'] = Variable<int>(moviesUpserted);
    }
    if (!nullToAbsent || seriesUpserted != null) {
      map['series_upserted'] = Variable<int>(seriesUpserted);
    }
    if (!nullToAbsent || seasonsUpserted != null) {
      map['seasons_upserted'] = Variable<int>(seasonsUpserted);
    }
    if (!nullToAbsent || episodesUpserted != null) {
      map['episodes_upserted'] = Variable<int>(episodesUpserted);
    }
    if (!nullToAbsent || channelsDeleted != null) {
      map['channels_deleted'] = Variable<int>(channelsDeleted);
    }
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    return map;
  }

  ImportRunsCompanion toCompanion(bool nullToAbsent) {
    return ImportRunsCompanion(
      id: Value(id),
      providerId: Value(providerId),
      providerKind: Value(providerKind),
      importType: Value(importType),
      startedAt: Value(startedAt),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      channelsUpserted: channelsUpserted == null && nullToAbsent
          ? const Value.absent()
          : Value(channelsUpserted),
      categoriesUpserted: categoriesUpserted == null && nullToAbsent
          ? const Value.absent()
          : Value(categoriesUpserted),
      moviesUpserted: moviesUpserted == null && nullToAbsent
          ? const Value.absent()
          : Value(moviesUpserted),
      seriesUpserted: seriesUpserted == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesUpserted),
      seasonsUpserted: seasonsUpserted == null && nullToAbsent
          ? const Value.absent()
          : Value(seasonsUpserted),
      episodesUpserted: episodesUpserted == null && nullToAbsent
          ? const Value.absent()
          : Value(episodesUpserted),
      channelsDeleted: channelsDeleted == null && nullToAbsent
          ? const Value.absent()
          : Value(channelsDeleted),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
    );
  }

  factory ImportRunRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImportRunRecord(
      id: serializer.fromJson<int>(json['id']),
      providerId: serializer.fromJson<int>(json['providerId']),
      providerKind: $ImportRunsTable.$converterproviderKind.fromJson(
        serializer.fromJson<String>(json['providerKind']),
      ),
      importType: serializer.fromJson<String>(json['importType']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      channelsUpserted: serializer.fromJson<int?>(json['channelsUpserted']),
      categoriesUpserted: serializer.fromJson<int?>(json['categoriesUpserted']),
      moviesUpserted: serializer.fromJson<int?>(json['moviesUpserted']),
      seriesUpserted: serializer.fromJson<int?>(json['seriesUpserted']),
      seasonsUpserted: serializer.fromJson<int?>(json['seasonsUpserted']),
      episodesUpserted: serializer.fromJson<int?>(json['episodesUpserted']),
      channelsDeleted: serializer.fromJson<int?>(json['channelsDeleted']),
      error: serializer.fromJson<String?>(json['error']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'providerId': serializer.toJson<int>(providerId),
      'providerKind': serializer.toJson<String>(
        $ImportRunsTable.$converterproviderKind.toJson(providerKind),
      ),
      'importType': serializer.toJson<String>(importType),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'durationMs': serializer.toJson<int?>(durationMs),
      'channelsUpserted': serializer.toJson<int?>(channelsUpserted),
      'categoriesUpserted': serializer.toJson<int?>(categoriesUpserted),
      'moviesUpserted': serializer.toJson<int?>(moviesUpserted),
      'seriesUpserted': serializer.toJson<int?>(seriesUpserted),
      'seasonsUpserted': serializer.toJson<int?>(seasonsUpserted),
      'episodesUpserted': serializer.toJson<int?>(episodesUpserted),
      'channelsDeleted': serializer.toJson<int?>(channelsDeleted),
      'error': serializer.toJson<String?>(error),
    };
  }

  ImportRunRecord copyWith({
    int? id,
    int? providerId,
    ProviderKind? providerKind,
    String? importType,
    DateTime? startedAt,
    Value<int?> durationMs = const Value.absent(),
    Value<int?> channelsUpserted = const Value.absent(),
    Value<int?> categoriesUpserted = const Value.absent(),
    Value<int?> moviesUpserted = const Value.absent(),
    Value<int?> seriesUpserted = const Value.absent(),
    Value<int?> seasonsUpserted = const Value.absent(),
    Value<int?> episodesUpserted = const Value.absent(),
    Value<int?> channelsDeleted = const Value.absent(),
    Value<String?> error = const Value.absent(),
  }) => ImportRunRecord(
    id: id ?? this.id,
    providerId: providerId ?? this.providerId,
    providerKind: providerKind ?? this.providerKind,
    importType: importType ?? this.importType,
    startedAt: startedAt ?? this.startedAt,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    channelsUpserted: channelsUpserted.present
        ? channelsUpserted.value
        : this.channelsUpserted,
    categoriesUpserted: categoriesUpserted.present
        ? categoriesUpserted.value
        : this.categoriesUpserted,
    moviesUpserted: moviesUpserted.present
        ? moviesUpserted.value
        : this.moviesUpserted,
    seriesUpserted: seriesUpserted.present
        ? seriesUpserted.value
        : this.seriesUpserted,
    seasonsUpserted: seasonsUpserted.present
        ? seasonsUpserted.value
        : this.seasonsUpserted,
    episodesUpserted: episodesUpserted.present
        ? episodesUpserted.value
        : this.episodesUpserted,
    channelsDeleted: channelsDeleted.present
        ? channelsDeleted.value
        : this.channelsDeleted,
    error: error.present ? error.value : this.error,
  );
  ImportRunRecord copyWithCompanion(ImportRunsCompanion data) {
    return ImportRunRecord(
      id: data.id.present ? data.id.value : this.id,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      providerKind: data.providerKind.present
          ? data.providerKind.value
          : this.providerKind,
      importType: data.importType.present
          ? data.importType.value
          : this.importType,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      channelsUpserted: data.channelsUpserted.present
          ? data.channelsUpserted.value
          : this.channelsUpserted,
      categoriesUpserted: data.categoriesUpserted.present
          ? data.categoriesUpserted.value
          : this.categoriesUpserted,
      moviesUpserted: data.moviesUpserted.present
          ? data.moviesUpserted.value
          : this.moviesUpserted,
      seriesUpserted: data.seriesUpserted.present
          ? data.seriesUpserted.value
          : this.seriesUpserted,
      seasonsUpserted: data.seasonsUpserted.present
          ? data.seasonsUpserted.value
          : this.seasonsUpserted,
      episodesUpserted: data.episodesUpserted.present
          ? data.episodesUpserted.value
          : this.episodesUpserted,
      channelsDeleted: data.channelsDeleted.present
          ? data.channelsDeleted.value
          : this.channelsDeleted,
      error: data.error.present ? data.error.value : this.error,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImportRunRecord(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('providerKind: $providerKind, ')
          ..write('importType: $importType, ')
          ..write('startedAt: $startedAt, ')
          ..write('durationMs: $durationMs, ')
          ..write('channelsUpserted: $channelsUpserted, ')
          ..write('categoriesUpserted: $categoriesUpserted, ')
          ..write('moviesUpserted: $moviesUpserted, ')
          ..write('seriesUpserted: $seriesUpserted, ')
          ..write('seasonsUpserted: $seasonsUpserted, ')
          ..write('episodesUpserted: $episodesUpserted, ')
          ..write('channelsDeleted: $channelsDeleted, ')
          ..write('error: $error')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    providerId,
    providerKind,
    importType,
    startedAt,
    durationMs,
    channelsUpserted,
    categoriesUpserted,
    moviesUpserted,
    seriesUpserted,
    seasonsUpserted,
    episodesUpserted,
    channelsDeleted,
    error,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImportRunRecord &&
          other.id == this.id &&
          other.providerId == this.providerId &&
          other.providerKind == this.providerKind &&
          other.importType == this.importType &&
          other.startedAt == this.startedAt &&
          other.durationMs == this.durationMs &&
          other.channelsUpserted == this.channelsUpserted &&
          other.categoriesUpserted == this.categoriesUpserted &&
          other.moviesUpserted == this.moviesUpserted &&
          other.seriesUpserted == this.seriesUpserted &&
          other.seasonsUpserted == this.seasonsUpserted &&
          other.episodesUpserted == this.episodesUpserted &&
          other.channelsDeleted == this.channelsDeleted &&
          other.error == this.error);
}

class ImportRunsCompanion extends UpdateCompanion<ImportRunRecord> {
  final Value<int> id;
  final Value<int> providerId;
  final Value<ProviderKind> providerKind;
  final Value<String> importType;
  final Value<DateTime> startedAt;
  final Value<int?> durationMs;
  final Value<int?> channelsUpserted;
  final Value<int?> categoriesUpserted;
  final Value<int?> moviesUpserted;
  final Value<int?> seriesUpserted;
  final Value<int?> seasonsUpserted;
  final Value<int?> episodesUpserted;
  final Value<int?> channelsDeleted;
  final Value<String?> error;
  const ImportRunsCompanion({
    this.id = const Value.absent(),
    this.providerId = const Value.absent(),
    this.providerKind = const Value.absent(),
    this.importType = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.channelsUpserted = const Value.absent(),
    this.categoriesUpserted = const Value.absent(),
    this.moviesUpserted = const Value.absent(),
    this.seriesUpserted = const Value.absent(),
    this.seasonsUpserted = const Value.absent(),
    this.episodesUpserted = const Value.absent(),
    this.channelsDeleted = const Value.absent(),
    this.error = const Value.absent(),
  });
  ImportRunsCompanion.insert({
    this.id = const Value.absent(),
    required int providerId,
    required ProviderKind providerKind,
    required String importType,
    required DateTime startedAt,
    this.durationMs = const Value.absent(),
    this.channelsUpserted = const Value.absent(),
    this.categoriesUpserted = const Value.absent(),
    this.moviesUpserted = const Value.absent(),
    this.seriesUpserted = const Value.absent(),
    this.seasonsUpserted = const Value.absent(),
    this.episodesUpserted = const Value.absent(),
    this.channelsDeleted = const Value.absent(),
    this.error = const Value.absent(),
  }) : providerId = Value(providerId),
       providerKind = Value(providerKind),
       importType = Value(importType),
       startedAt = Value(startedAt);
  static Insertable<ImportRunRecord> custom({
    Expression<int>? id,
    Expression<int>? providerId,
    Expression<String>? providerKind,
    Expression<String>? importType,
    Expression<DateTime>? startedAt,
    Expression<int>? durationMs,
    Expression<int>? channelsUpserted,
    Expression<int>? categoriesUpserted,
    Expression<int>? moviesUpserted,
    Expression<int>? seriesUpserted,
    Expression<int>? seasonsUpserted,
    Expression<int>? episodesUpserted,
    Expression<int>? channelsDeleted,
    Expression<String>? error,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (providerId != null) 'provider_id': providerId,
      if (providerKind != null) 'provider_kind': providerKind,
      if (importType != null) 'import_type': importType,
      if (startedAt != null) 'started_at': startedAt,
      if (durationMs != null) 'duration_ms': durationMs,
      if (channelsUpserted != null) 'channels_upserted': channelsUpserted,
      if (categoriesUpserted != null) 'categories_upserted': categoriesUpserted,
      if (moviesUpserted != null) 'movies_upserted': moviesUpserted,
      if (seriesUpserted != null) 'series_upserted': seriesUpserted,
      if (seasonsUpserted != null) 'seasons_upserted': seasonsUpserted,
      if (episodesUpserted != null) 'episodes_upserted': episodesUpserted,
      if (channelsDeleted != null) 'channels_deleted': channelsDeleted,
      if (error != null) 'error': error,
    });
  }

  ImportRunsCompanion copyWith({
    Value<int>? id,
    Value<int>? providerId,
    Value<ProviderKind>? providerKind,
    Value<String>? importType,
    Value<DateTime>? startedAt,
    Value<int?>? durationMs,
    Value<int?>? channelsUpserted,
    Value<int?>? categoriesUpserted,
    Value<int?>? moviesUpserted,
    Value<int?>? seriesUpserted,
    Value<int?>? seasonsUpserted,
    Value<int?>? episodesUpserted,
    Value<int?>? channelsDeleted,
    Value<String?>? error,
  }) {
    return ImportRunsCompanion(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      providerKind: providerKind ?? this.providerKind,
      importType: importType ?? this.importType,
      startedAt: startedAt ?? this.startedAt,
      durationMs: durationMs ?? this.durationMs,
      channelsUpserted: channelsUpserted ?? this.channelsUpserted,
      categoriesUpserted: categoriesUpserted ?? this.categoriesUpserted,
      moviesUpserted: moviesUpserted ?? this.moviesUpserted,
      seriesUpserted: seriesUpserted ?? this.seriesUpserted,
      seasonsUpserted: seasonsUpserted ?? this.seasonsUpserted,
      episodesUpserted: episodesUpserted ?? this.episodesUpserted,
      channelsDeleted: channelsDeleted ?? this.channelsDeleted,
      error: error ?? this.error,
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
    if (providerKind.present) {
      map['provider_kind'] = Variable<String>(
        $ImportRunsTable.$converterproviderKind.toSql(providerKind.value),
      );
    }
    if (importType.present) {
      map['import_type'] = Variable<String>(importType.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (channelsUpserted.present) {
      map['channels_upserted'] = Variable<int>(channelsUpserted.value);
    }
    if (categoriesUpserted.present) {
      map['categories_upserted'] = Variable<int>(categoriesUpserted.value);
    }
    if (moviesUpserted.present) {
      map['movies_upserted'] = Variable<int>(moviesUpserted.value);
    }
    if (seriesUpserted.present) {
      map['series_upserted'] = Variable<int>(seriesUpserted.value);
    }
    if (seasonsUpserted.present) {
      map['seasons_upserted'] = Variable<int>(seasonsUpserted.value);
    }
    if (episodesUpserted.present) {
      map['episodes_upserted'] = Variable<int>(episodesUpserted.value);
    }
    if (channelsDeleted.present) {
      map['channels_deleted'] = Variable<int>(channelsDeleted.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImportRunsCompanion(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('providerKind: $providerKind, ')
          ..write('importType: $importType, ')
          ..write('startedAt: $startedAt, ')
          ..write('durationMs: $durationMs, ')
          ..write('channelsUpserted: $channelsUpserted, ')
          ..write('categoriesUpserted: $categoriesUpserted, ')
          ..write('moviesUpserted: $moviesUpserted, ')
          ..write('seriesUpserted: $seriesUpserted, ')
          ..write('seasonsUpserted: $seasonsUpserted, ')
          ..write('episodesUpserted: $episodesUpserted, ')
          ..write('channelsDeleted: $channelsDeleted, ')
          ..write('error: $error')
          ..write(')'))
        .toString();
  }
}

class $EpgProgramsFtsTable extends EpgProgramsFts
    with TableInfo<$EpgProgramsFtsTable, EpgProgramsFt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EpgProgramsFtsTable(this.attachedDatabase, [this._alias]);
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _programIdMeta = const VerificationMeta(
    'programId',
  );
  @override
  late final GeneratedColumn<int> programId = GeneratedColumn<int>(
    'program_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL REFERENCES epg_programs(id) ON DELETE CASCADE',
  );
  @override
  List<GeneratedColumn> get $columns => [title, description, programId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'epg_programs_fts';
  @override
  VerificationContext validateIntegrity(
    Insertable<EpgProgramsFt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
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
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('program_id')) {
      context.handle(
        _programIdMeta,
        programId.isAcceptableOrUnknown(data['program_id']!, _programIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {programId};
  @override
  EpgProgramsFt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EpgProgramsFt(
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      programId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}program_id'],
      )!,
    );
  }

  @override
  $EpgProgramsFtsTable createAlias(String alias) {
    return $EpgProgramsFtsTable(attachedDatabase, alias);
  }
}

class EpgProgramsFt extends DataClass implements Insertable<EpgProgramsFt> {
  final String title;
  final String description;
  final int programId;
  const EpgProgramsFt({
    required this.title,
    required this.description,
    required this.programId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['program_id'] = Variable<int>(programId);
    return map;
  }

  EpgProgramsFtsCompanion toCompanion(bool nullToAbsent) {
    return EpgProgramsFtsCompanion(
      title: Value(title),
      description: Value(description),
      programId: Value(programId),
    );
  }

  factory EpgProgramsFt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EpgProgramsFt(
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      programId: serializer.fromJson<int>(json['programId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'programId': serializer.toJson<int>(programId),
    };
  }

  EpgProgramsFt copyWith({
    String? title,
    String? description,
    int? programId,
  }) => EpgProgramsFt(
    title: title ?? this.title,
    description: description ?? this.description,
    programId: programId ?? this.programId,
  );
  EpgProgramsFt copyWithCompanion(EpgProgramsFtsCompanion data) {
    return EpgProgramsFt(
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      programId: data.programId.present ? data.programId.value : this.programId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EpgProgramsFt(')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('programId: $programId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(title, description, programId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EpgProgramsFt &&
          other.title == this.title &&
          other.description == this.description &&
          other.programId == this.programId);
}

class EpgProgramsFtsCompanion extends UpdateCompanion<EpgProgramsFt> {
  final Value<String> title;
  final Value<String> description;
  final Value<int> programId;
  const EpgProgramsFtsCompanion({
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.programId = const Value.absent(),
  });
  EpgProgramsFtsCompanion.insert({
    required String title,
    required String description,
    this.programId = const Value.absent(),
  }) : title = Value(title),
       description = Value(description);
  static Insertable<EpgProgramsFt> custom({
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? programId,
  }) {
    return RawValuesInsertable({
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (programId != null) 'program_id': programId,
    });
  }

  EpgProgramsFtsCompanion copyWith({
    Value<String>? title,
    Value<String>? description,
    Value<int>? programId,
  }) {
    return EpgProgramsFtsCompanion(
      title: title ?? this.title,
      description: description ?? this.description,
      programId: programId ?? this.programId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (programId.present) {
      map['program_id'] = Variable<int>(programId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EpgProgramsFtsCompanion(')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('programId: $programId')
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
  late final $MoviesTable movies = $MoviesTable(this);
  late final $SeriesTable series = $SeriesTable(this);
  late final $SeasonsTable seasons = $SeasonsTable(this);
  late final $EpisodesTable episodes = $EpisodesTable(this);
  late final $ArtworkCacheTable artworkCache = $ArtworkCacheTable(this);
  late final $PlaybackHistoryTable playbackHistory = $PlaybackHistoryTable(
    this,
  );
  late final $UserFlagsTable userFlags = $UserFlagsTable(this);
  late final $MaintenanceLogTable maintenanceLog = $MaintenanceLogTable(this);
  late final $ImportRunsTable importRuns = $ImportRunsTable(this);
  late final $EpgProgramsFtsTable epgProgramsFts = $EpgProgramsFtsTable(this);
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
    movies,
    series,
    seasons,
    episodes,
    artworkCache,
    playbackHistory,
    userFlags,
    maintenanceLog,
    importRuns,
    epgProgramsFts,
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
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'providers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('movies', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'categories',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('movies', kind: UpdateKind.update)],
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
        'categories',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('series', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'series',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('seasons', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'series',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('episodes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'seasons',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('episodes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'providers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('playback_history', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'channels',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('playback_history', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'providers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('user_flags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'channels',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('user_flags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'providers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('import_runs', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'epg_programs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('epg_programs_fts', kind: UpdateKind.delete)],
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
      Value<String?> legacyProfileId,
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
      Value<String?> legacyProfileId,
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

  static MultiTypedResultKey<$MoviesTable, List<MovieRecord>> _moviesRefsTable(
    _$OpenIptvDb db,
  ) => MultiTypedResultKey.fromTable(
    db.movies,
    aliasName: $_aliasNameGenerator(db.providers.id, db.movies.providerId),
  );

  $$MoviesTableProcessedTableManager get moviesRefs {
    final manager = $$MoviesTableTableManager(
      $_db,
      $_db.movies,
    ).filter((f) => f.providerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_moviesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SeriesTable, List<SeriesRecord>> _seriesRefsTable(
    _$OpenIptvDb db,
  ) => MultiTypedResultKey.fromTable(
    db.series,
    aliasName: $_aliasNameGenerator(db.providers.id, db.series.providerId),
  );

  $$SeriesTableProcessedTableManager get seriesRefs {
    final manager = $$SeriesTableTableManager(
      $_db,
      $_db.series,
    ).filter((f) => f.providerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_seriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PlaybackHistoryTable, List<PlaybackHistoryRecord>>
  _playbackHistoryRefsTable(_$OpenIptvDb db) => MultiTypedResultKey.fromTable(
    db.playbackHistory,
    aliasName: $_aliasNameGenerator(
      db.providers.id,
      db.playbackHistory.providerId,
    ),
  );

  $$PlaybackHistoryTableProcessedTableManager get playbackHistoryRefs {
    final manager = $$PlaybackHistoryTableTableManager(
      $_db,
      $_db.playbackHistory,
    ).filter((f) => f.providerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _playbackHistoryRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$UserFlagsTable, List<UserFlagRecord>>
  _userFlagsRefsTable(_$OpenIptvDb db) => MultiTypedResultKey.fromTable(
    db.userFlags,
    aliasName: $_aliasNameGenerator(db.providers.id, db.userFlags.providerId),
  );

  $$UserFlagsTableProcessedTableManager get userFlagsRefs {
    final manager = $$UserFlagsTableTableManager(
      $_db,
      $_db.userFlags,
    ).filter((f) => f.providerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_userFlagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ImportRunsTable, List<ImportRunRecord>>
  _importRunsRefsTable(_$OpenIptvDb db) => MultiTypedResultKey.fromTable(
    db.importRuns,
    aliasName: $_aliasNameGenerator(db.providers.id, db.importRuns.providerId),
  );

  $$ImportRunsTableProcessedTableManager get importRunsRefs {
    final manager = $$ImportRunsTableTableManager(
      $_db,
      $_db.importRuns,
    ).filter((f) => f.providerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_importRunsRefsTable($_db));
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

  ColumnFilters<String> get legacyProfileId => $composableBuilder(
    column: $table.legacyProfileId,
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

  Expression<bool> moviesRefs(
    Expression<bool> Function($$MoviesTableFilterComposer f) f,
  ) {
    final $$MoviesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movies,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MoviesTableFilterComposer(
            $db: $db,
            $table: $db.movies,
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

  Expression<bool> userFlagsRefs(
    Expression<bool> Function($$UserFlagsTableFilterComposer f) f,
  ) {
    final $$UserFlagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userFlags,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserFlagsTableFilterComposer(
            $db: $db,
            $table: $db.userFlags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> importRunsRefs(
    Expression<bool> Function($$ImportRunsTableFilterComposer f) f,
  ) {
    final $$ImportRunsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.importRuns,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImportRunsTableFilterComposer(
            $db: $db,
            $table: $db.importRuns,
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

  ColumnOrderings<String> get legacyProfileId => $composableBuilder(
    column: $table.legacyProfileId,
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

  GeneratedColumn<String> get legacyProfileId => $composableBuilder(
    column: $table.legacyProfileId,
    builder: (column) => column,
  );

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

  Expression<T> moviesRefs<T extends Object>(
    Expression<T> Function($$MoviesTableAnnotationComposer a) f,
  ) {
    final $$MoviesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movies,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MoviesTableAnnotationComposer(
            $db: $db,
            $table: $db.movies,
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

  Expression<T> userFlagsRefs<T extends Object>(
    Expression<T> Function($$UserFlagsTableAnnotationComposer a) f,
  ) {
    final $$UserFlagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userFlags,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserFlagsTableAnnotationComposer(
            $db: $db,
            $table: $db.userFlags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> importRunsRefs<T extends Object>(
    Expression<T> Function($$ImportRunsTableAnnotationComposer a) f,
  ) {
    final $$ImportRunsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.importRuns,
      getReferencedColumn: (t) => t.providerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImportRunsTableAnnotationComposer(
            $db: $db,
            $table: $db.importRuns,
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
            bool moviesRefs,
            bool seriesRefs,
            bool playbackHistoryRefs,
            bool userFlagsRefs,
            bool importRunsRefs,
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
                Value<String?> legacyProfileId = const Value.absent(),
              }) => ProvidersCompanion(
                id: id,
                kind: kind,
                displayName: displayName,
                lockedBase: lockedBase,
                needsUa: needsUa,
                allowSelfSigned: allowSelfSigned,
                lastSyncAt: lastSyncAt,
                etagHash: etagHash,
                legacyProfileId: legacyProfileId,
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
                Value<String?> legacyProfileId = const Value.absent(),
              }) => ProvidersCompanion.insert(
                id: id,
                kind: kind,
                displayName: displayName,
                lockedBase: lockedBase,
                needsUa: needsUa,
                allowSelfSigned: allowSelfSigned,
                lastSyncAt: lastSyncAt,
                etagHash: etagHash,
                legacyProfileId: legacyProfileId,
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
                moviesRefs = false,
                seriesRefs = false,
                playbackHistoryRefs = false,
                userFlagsRefs = false,
                importRunsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (channelsRefs) db.channels,
                    if (categoriesRefs) db.categories,
                    if (summariesRefs) db.summaries,
                    if (moviesRefs) db.movies,
                    if (seriesRefs) db.series,
                    if (playbackHistoryRefs) db.playbackHistory,
                    if (userFlagsRefs) db.userFlags,
                    if (importRunsRefs) db.importRuns,
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
                      if (moviesRefs)
                        await $_getPrefetchedData<
                          ProviderRecord,
                          $ProvidersTable,
                          MovieRecord
                        >(
                          currentTable: table,
                          referencedTable: $$ProvidersTableReferences
                              ._moviesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProvidersTableReferences(
                                db,
                                table,
                                p0,
                              ).moviesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.providerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (seriesRefs)
                        await $_getPrefetchedData<
                          ProviderRecord,
                          $ProvidersTable,
                          SeriesRecord
                        >(
                          currentTable: table,
                          referencedTable: $$ProvidersTableReferences
                              ._seriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProvidersTableReferences(
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
                      if (playbackHistoryRefs)
                        await $_getPrefetchedData<
                          ProviderRecord,
                          $ProvidersTable,
                          PlaybackHistoryRecord
                        >(
                          currentTable: table,
                          referencedTable: $$ProvidersTableReferences
                              ._playbackHistoryRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProvidersTableReferences(
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
                      if (userFlagsRefs)
                        await $_getPrefetchedData<
                          ProviderRecord,
                          $ProvidersTable,
                          UserFlagRecord
                        >(
                          currentTable: table,
                          referencedTable: $$ProvidersTableReferences
                              ._userFlagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProvidersTableReferences(
                                db,
                                table,
                                p0,
                              ).userFlagsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.providerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (importRunsRefs)
                        await $_getPrefetchedData<
                          ProviderRecord,
                          $ProvidersTable,
                          ImportRunRecord
                        >(
                          currentTable: table,
                          referencedTable: $$ProvidersTableReferences
                              ._importRunsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProvidersTableReferences(
                                db,
                                table,
                                p0,
                              ).importRunsRefs,
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
        bool moviesRefs,
        bool seriesRefs,
        bool playbackHistoryRefs,
        bool userFlagsRefs,
        bool importRunsRefs,
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

  static MultiTypedResultKey<$PlaybackHistoryTable, List<PlaybackHistoryRecord>>
  _playbackHistoryRefsTable(_$OpenIptvDb db) => MultiTypedResultKey.fromTable(
    db.playbackHistory,
    aliasName: $_aliasNameGenerator(
      db.channels.id,
      db.playbackHistory.channelId,
    ),
  );

  $$PlaybackHistoryTableProcessedTableManager get playbackHistoryRefs {
    final manager = $$PlaybackHistoryTableTableManager(
      $_db,
      $_db.playbackHistory,
    ).filter((f) => f.channelId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _playbackHistoryRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$UserFlagsTable, List<UserFlagRecord>>
  _userFlagsRefsTable(_$OpenIptvDb db) => MultiTypedResultKey.fromTable(
    db.userFlags,
    aliasName: $_aliasNameGenerator(db.channels.id, db.userFlags.channelId),
  );

  $$UserFlagsTableProcessedTableManager get userFlagsRefs {
    final manager = $$UserFlagsTableTableManager(
      $_db,
      $_db.userFlags,
    ).filter((f) => f.channelId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_userFlagsRefsTable($_db));
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

  Expression<bool> playbackHistoryRefs(
    Expression<bool> Function($$PlaybackHistoryTableFilterComposer f) f,
  ) {
    final $$PlaybackHistoryTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playbackHistory,
      getReferencedColumn: (t) => t.channelId,
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

  Expression<bool> userFlagsRefs(
    Expression<bool> Function($$UserFlagsTableFilterComposer f) f,
  ) {
    final $$UserFlagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userFlags,
      getReferencedColumn: (t) => t.channelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserFlagsTableFilterComposer(
            $db: $db,
            $table: $db.userFlags,
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

  Expression<T> playbackHistoryRefs<T extends Object>(
    Expression<T> Function($$PlaybackHistoryTableAnnotationComposer a) f,
  ) {
    final $$PlaybackHistoryTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playbackHistory,
      getReferencedColumn: (t) => t.channelId,
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

  Expression<T> userFlagsRefs<T extends Object>(
    Expression<T> Function($$UserFlagsTableAnnotationComposer a) f,
  ) {
    final $$UserFlagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userFlags,
      getReferencedColumn: (t) => t.channelId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserFlagsTableAnnotationComposer(
            $db: $db,
            $table: $db.userFlags,
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
            bool playbackHistoryRefs,
            bool userFlagsRefs,
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
                playbackHistoryRefs = false,
                userFlagsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (channelCategoriesRefs) db.channelCategories,
                    if (epgProgramsRefs) db.epgPrograms,
                    if (playbackHistoryRefs) db.playbackHistory,
                    if (userFlagsRefs) db.userFlags,
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
                      if (playbackHistoryRefs)
                        await $_getPrefetchedData<
                          ChannelRecord,
                          $ChannelsTable,
                          PlaybackHistoryRecord
                        >(
                          currentTable: table,
                          referencedTable: $$ChannelsTableReferences
                              ._playbackHistoryRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChannelsTableReferences(
                                db,
                                table,
                                p0,
                              ).playbackHistoryRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.channelId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (userFlagsRefs)
                        await $_getPrefetchedData<
                          ChannelRecord,
                          $ChannelsTable,
                          UserFlagRecord
                        >(
                          currentTable: table,
                          referencedTable: $$ChannelsTableReferences
                              ._userFlagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ChannelsTableReferences(
                                db,
                                table,
                                p0,
                              ).userFlagsRefs,
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
        bool playbackHistoryRefs,
        bool userFlagsRefs,
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

  static MultiTypedResultKey<$MoviesTable, List<MovieRecord>> _moviesRefsTable(
    _$OpenIptvDb db,
  ) => MultiTypedResultKey.fromTable(
    db.movies,
    aliasName: $_aliasNameGenerator(db.categories.id, db.movies.categoryId),
  );

  $$MoviesTableProcessedTableManager get moviesRefs {
    final manager = $$MoviesTableTableManager(
      $_db,
      $_db.movies,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_moviesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SeriesTable, List<SeriesRecord>> _seriesRefsTable(
    _$OpenIptvDb db,
  ) => MultiTypedResultKey.fromTable(
    db.series,
    aliasName: $_aliasNameGenerator(db.categories.id, db.series.categoryId),
  );

  $$SeriesTableProcessedTableManager get seriesRefs {
    final manager = $$SeriesTableTableManager(
      $_db,
      $_db.series,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_seriesRefsTable($_db));
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

  Expression<bool> moviesRefs(
    Expression<bool> Function($$MoviesTableFilterComposer f) f,
  ) {
    final $$MoviesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movies,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MoviesTableFilterComposer(
            $db: $db,
            $table: $db.movies,
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
      getReferencedColumn: (t) => t.categoryId,
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

  Expression<T> moviesRefs<T extends Object>(
    Expression<T> Function($$MoviesTableAnnotationComposer a) f,
  ) {
    final $$MoviesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.movies,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MoviesTableAnnotationComposer(
            $db: $db,
            $table: $db.movies,
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
      getReferencedColumn: (t) => t.categoryId,
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
          PrefetchHooks Function({
            bool providerId,
            bool channelCategoriesRefs,
            bool moviesRefs,
            bool seriesRefs,
          })
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
              ({
                providerId = false,
                channelCategoriesRefs = false,
                moviesRefs = false,
                seriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (channelCategoriesRefs) db.channelCategories,
                    if (moviesRefs) db.movies,
                    if (seriesRefs) db.series,
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
                      if (moviesRefs)
                        await $_getPrefetchedData<
                          CategoryRecord,
                          $CategoriesTable,
                          MovieRecord
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._moviesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).moviesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (seriesRefs)
                        await $_getPrefetchedData<
                          CategoryRecord,
                          $CategoriesTable,
                          SeriesRecord
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._seriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).seriesRefs,
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
      PrefetchHooks Function({
        bool providerId,
        bool channelCategoriesRefs,
        bool moviesRefs,
        bool seriesRefs,
      })
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

  static MultiTypedResultKey<$EpgProgramsFtsTable, List<EpgProgramsFt>>
  _epgProgramsFtsRefsTable(_$OpenIptvDb db) => MultiTypedResultKey.fromTable(
    db.epgProgramsFts,
    aliasName: $_aliasNameGenerator(
      db.epgPrograms.id,
      db.epgProgramsFts.programId,
    ),
  );

  $$EpgProgramsFtsTableProcessedTableManager get epgProgramsFtsRefs {
    final manager = $$EpgProgramsFtsTableTableManager(
      $_db,
      $_db.epgProgramsFts,
    ).filter((f) => f.programId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_epgProgramsFtsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
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

  Expression<bool> epgProgramsFtsRefs(
    Expression<bool> Function($$EpgProgramsFtsTableFilterComposer f) f,
  ) {
    final $$EpgProgramsFtsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.epgProgramsFts,
      getReferencedColumn: (t) => t.programId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpgProgramsFtsTableFilterComposer(
            $db: $db,
            $table: $db.epgProgramsFts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
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

  Expression<T> epgProgramsFtsRefs<T extends Object>(
    Expression<T> Function($$EpgProgramsFtsTableAnnotationComposer a) f,
  ) {
    final $$EpgProgramsFtsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.epgProgramsFts,
      getReferencedColumn: (t) => t.programId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpgProgramsFtsTableAnnotationComposer(
            $db: $db,
            $table: $db.epgProgramsFts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
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
          PrefetchHooks Function({bool channelId, bool epgProgramsFtsRefs})
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
          prefetchHooksCallback:
              ({channelId = false, epgProgramsFtsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (epgProgramsFtsRefs) db.epgProgramsFts,
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
                        if (channelId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.channelId,
                                    referencedTable:
                                        $$EpgProgramsTableReferences
                                            ._channelIdTable(db),
                                    referencedColumn:
                                        $$EpgProgramsTableReferences
                                            ._channelIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (epgProgramsFtsRefs)
                        await $_getPrefetchedData<
                          EpgProgramRecord,
                          $EpgProgramsTable,
                          EpgProgramsFt
                        >(
                          currentTable: table,
                          referencedTable: $$EpgProgramsTableReferences
                              ._epgProgramsFtsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EpgProgramsTableReferences(
                                db,
                                table,
                                p0,
                              ).epgProgramsFtsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.programId == item.id,
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
      PrefetchHooks Function({bool channelId, bool epgProgramsFtsRefs})
    >;
typedef $$MoviesTableCreateCompanionBuilder =
    MoviesCompanion Function({
      Value<int> id,
      required int providerId,
      required String providerVodKey,
      Value<int?> categoryId,
      required String title,
      Value<int?> year,
      Value<String?> overview,
      Value<String?> posterUrl,
      Value<int?> durationSec,
      Value<String?> streamUrlTemplate,
      Value<DateTime?> lastSeenAt,
    });
typedef $$MoviesTableUpdateCompanionBuilder =
    MoviesCompanion Function({
      Value<int> id,
      Value<int> providerId,
      Value<String> providerVodKey,
      Value<int?> categoryId,
      Value<String> title,
      Value<int?> year,
      Value<String?> overview,
      Value<String?> posterUrl,
      Value<int?> durationSec,
      Value<String?> streamUrlTemplate,
      Value<DateTime?> lastSeenAt,
    });

final class $$MoviesTableReferences
    extends BaseReferences<_$OpenIptvDb, $MoviesTable, MovieRecord> {
  $$MoviesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProvidersTable _providerIdTable(_$OpenIptvDb db) => db.providers
      .createAlias($_aliasNameGenerator(db.movies.providerId, db.providers.id));

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

  static $CategoriesTable _categoryIdTable(_$OpenIptvDb db) =>
      db.categories.createAlias(
        $_aliasNameGenerator(db.movies.categoryId, db.categories.id),
      );

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<int>('category_id');
    if ($_column == null) return null;
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

class $$MoviesTableFilterComposer extends Composer<_$OpenIptvDb, $MoviesTable> {
  $$MoviesTableFilterComposer({
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

  ColumnFilters<String> get providerVodKey => $composableBuilder(
    column: $table.providerVodKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get posterUrl => $composableBuilder(
    column: $table.posterUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
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

class $$MoviesTableOrderingComposer
    extends Composer<_$OpenIptvDb, $MoviesTable> {
  $$MoviesTableOrderingComposer({
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

  ColumnOrderings<String> get providerVodKey => $composableBuilder(
    column: $table.providerVodKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get posterUrl => $composableBuilder(
    column: $table.posterUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
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

class $$MoviesTableAnnotationComposer
    extends Composer<_$OpenIptvDb, $MoviesTable> {
  $$MoviesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get providerVodKey => $composableBuilder(
    column: $table.providerVodKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => column);

  GeneratedColumn<String> get posterUrl =>
      $composableBuilder(column: $table.posterUrl, builder: (column) => column);

  GeneratedColumn<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => column,
  );

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

class $$MoviesTableTableManager
    extends
        RootTableManager<
          _$OpenIptvDb,
          $MoviesTable,
          MovieRecord,
          $$MoviesTableFilterComposer,
          $$MoviesTableOrderingComposer,
          $$MoviesTableAnnotationComposer,
          $$MoviesTableCreateCompanionBuilder,
          $$MoviesTableUpdateCompanionBuilder,
          (MovieRecord, $$MoviesTableReferences),
          MovieRecord,
          PrefetchHooks Function({bool providerId, bool categoryId})
        > {
  $$MoviesTableTableManager(_$OpenIptvDb db, $MoviesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MoviesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MoviesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MoviesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> providerId = const Value.absent(),
                Value<String> providerVodKey = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<String?> posterUrl = const Value.absent(),
                Value<int?> durationSec = const Value.absent(),
                Value<String?> streamUrlTemplate = const Value.absent(),
                Value<DateTime?> lastSeenAt = const Value.absent(),
              }) => MoviesCompanion(
                id: id,
                providerId: providerId,
                providerVodKey: providerVodKey,
                categoryId: categoryId,
                title: title,
                year: year,
                overview: overview,
                posterUrl: posterUrl,
                durationSec: durationSec,
                streamUrlTemplate: streamUrlTemplate,
                lastSeenAt: lastSeenAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int providerId,
                required String providerVodKey,
                Value<int?> categoryId = const Value.absent(),
                required String title,
                Value<int?> year = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<String?> posterUrl = const Value.absent(),
                Value<int?> durationSec = const Value.absent(),
                Value<String?> streamUrlTemplate = const Value.absent(),
                Value<DateTime?> lastSeenAt = const Value.absent(),
              }) => MoviesCompanion.insert(
                id: id,
                providerId: providerId,
                providerVodKey: providerVodKey,
                categoryId: categoryId,
                title: title,
                year: year,
                overview: overview,
                posterUrl: posterUrl,
                durationSec: durationSec,
                streamUrlTemplate: streamUrlTemplate,
                lastSeenAt: lastSeenAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$MoviesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({providerId = false, categoryId = false}) {
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
                                referencedTable: $$MoviesTableReferences
                                    ._providerIdTable(db),
                                referencedColumn: $$MoviesTableReferences
                                    ._providerIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (categoryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.categoryId,
                                referencedTable: $$MoviesTableReferences
                                    ._categoryIdTable(db),
                                referencedColumn: $$MoviesTableReferences
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

typedef $$MoviesTableProcessedTableManager =
    ProcessedTableManager<
      _$OpenIptvDb,
      $MoviesTable,
      MovieRecord,
      $$MoviesTableFilterComposer,
      $$MoviesTableOrderingComposer,
      $$MoviesTableAnnotationComposer,
      $$MoviesTableCreateCompanionBuilder,
      $$MoviesTableUpdateCompanionBuilder,
      (MovieRecord, $$MoviesTableReferences),
      MovieRecord,
      PrefetchHooks Function({bool providerId, bool categoryId})
    >;
typedef $$SeriesTableCreateCompanionBuilder =
    SeriesCompanion Function({
      Value<int> id,
      required int providerId,
      required String providerSeriesKey,
      Value<int?> categoryId,
      required String title,
      Value<String?> posterUrl,
      Value<int?> year,
      Value<String?> overview,
      Value<DateTime?> lastSeenAt,
    });
typedef $$SeriesTableUpdateCompanionBuilder =
    SeriesCompanion Function({
      Value<int> id,
      Value<int> providerId,
      Value<String> providerSeriesKey,
      Value<int?> categoryId,
      Value<String> title,
      Value<String?> posterUrl,
      Value<int?> year,
      Value<String?> overview,
      Value<DateTime?> lastSeenAt,
    });

final class $$SeriesTableReferences
    extends BaseReferences<_$OpenIptvDb, $SeriesTable, SeriesRecord> {
  $$SeriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProvidersTable _providerIdTable(_$OpenIptvDb db) => db.providers
      .createAlias($_aliasNameGenerator(db.series.providerId, db.providers.id));

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

  static $CategoriesTable _categoryIdTable(_$OpenIptvDb db) =>
      db.categories.createAlias(
        $_aliasNameGenerator(db.series.categoryId, db.categories.id),
      );

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<int>('category_id');
    if ($_column == null) return null;
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

  static MultiTypedResultKey<$SeasonsTable, List<SeasonRecord>>
  _seasonsRefsTable(_$OpenIptvDb db) => MultiTypedResultKey.fromTable(
    db.seasons,
    aliasName: $_aliasNameGenerator(db.series.id, db.seasons.seriesId),
  );

  $$SeasonsTableProcessedTableManager get seasonsRefs {
    final manager = $$SeasonsTableTableManager(
      $_db,
      $_db.seasons,
    ).filter((f) => f.seriesId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_seasonsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EpisodesTable, List<EpisodeRecord>>
  _episodesRefsTable(_$OpenIptvDb db) => MultiTypedResultKey.fromTable(
    db.episodes,
    aliasName: $_aliasNameGenerator(db.series.id, db.episodes.seriesId),
  );

  $$EpisodesTableProcessedTableManager get episodesRefs {
    final manager = $$EpisodesTableTableManager(
      $_db,
      $_db.episodes,
    ).filter((f) => f.seriesId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_episodesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SeriesTableFilterComposer extends Composer<_$OpenIptvDb, $SeriesTable> {
  $$SeriesTableFilterComposer({
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

  ColumnFilters<String> get providerSeriesKey => $composableBuilder(
    column: $table.providerSeriesKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get posterUrl => $composableBuilder(
    column: $table.posterUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overview => $composableBuilder(
    column: $table.overview,
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

  Expression<bool> seasonsRefs(
    Expression<bool> Function($$SeasonsTableFilterComposer f) f,
  ) {
    final $$SeasonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.seasons,
      getReferencedColumn: (t) => t.seriesId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SeasonsTableFilterComposer(
            $db: $db,
            $table: $db.seasons,
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
      getReferencedColumn: (t) => t.seriesId,
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
}

class $$SeriesTableOrderingComposer
    extends Composer<_$OpenIptvDb, $SeriesTable> {
  $$SeriesTableOrderingComposer({
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

  ColumnOrderings<String> get providerSeriesKey => $composableBuilder(
    column: $table.providerSeriesKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get posterUrl => $composableBuilder(
    column: $table.posterUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overview => $composableBuilder(
    column: $table.overview,
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

class $$SeriesTableAnnotationComposer
    extends Composer<_$OpenIptvDb, $SeriesTable> {
  $$SeriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get providerSeriesKey => $composableBuilder(
    column: $table.providerSeriesKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get posterUrl =>
      $composableBuilder(column: $table.posterUrl, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => column);

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

  Expression<T> seasonsRefs<T extends Object>(
    Expression<T> Function($$SeasonsTableAnnotationComposer a) f,
  ) {
    final $$SeasonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.seasons,
      getReferencedColumn: (t) => t.seriesId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SeasonsTableAnnotationComposer(
            $db: $db,
            $table: $db.seasons,
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
      getReferencedColumn: (t) => t.seriesId,
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
}

class $$SeriesTableTableManager
    extends
        RootTableManager<
          _$OpenIptvDb,
          $SeriesTable,
          SeriesRecord,
          $$SeriesTableFilterComposer,
          $$SeriesTableOrderingComposer,
          $$SeriesTableAnnotationComposer,
          $$SeriesTableCreateCompanionBuilder,
          $$SeriesTableUpdateCompanionBuilder,
          (SeriesRecord, $$SeriesTableReferences),
          SeriesRecord,
          PrefetchHooks Function({
            bool providerId,
            bool categoryId,
            bool seasonsRefs,
            bool episodesRefs,
          })
        > {
  $$SeriesTableTableManager(_$OpenIptvDb db, $SeriesTable table)
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
                Value<int> id = const Value.absent(),
                Value<int> providerId = const Value.absent(),
                Value<String> providerSeriesKey = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> posterUrl = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<DateTime?> lastSeenAt = const Value.absent(),
              }) => SeriesCompanion(
                id: id,
                providerId: providerId,
                providerSeriesKey: providerSeriesKey,
                categoryId: categoryId,
                title: title,
                posterUrl: posterUrl,
                year: year,
                overview: overview,
                lastSeenAt: lastSeenAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int providerId,
                required String providerSeriesKey,
                Value<int?> categoryId = const Value.absent(),
                required String title,
                Value<String?> posterUrl = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<DateTime?> lastSeenAt = const Value.absent(),
              }) => SeriesCompanion.insert(
                id: id,
                providerId: providerId,
                providerSeriesKey: providerSeriesKey,
                categoryId: categoryId,
                title: title,
                posterUrl: posterUrl,
                year: year,
                overview: overview,
                lastSeenAt: lastSeenAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$SeriesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                providerId = false,
                categoryId = false,
                seasonsRefs = false,
                episodesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (seasonsRefs) db.seasons,
                    if (episodesRefs) db.episodes,
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
                                    referencedTable: $$SeriesTableReferences
                                        ._providerIdTable(db),
                                    referencedColumn: $$SeriesTableReferences
                                        ._providerIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (categoryId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.categoryId,
                                    referencedTable: $$SeriesTableReferences
                                        ._categoryIdTable(db),
                                    referencedColumn: $$SeriesTableReferences
                                        ._categoryIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (seasonsRefs)
                        await $_getPrefetchedData<
                          SeriesRecord,
                          $SeriesTable,
                          SeasonRecord
                        >(
                          currentTable: table,
                          referencedTable: $$SeriesTableReferences
                              ._seasonsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SeriesTableReferences(
                                db,
                                table,
                                p0,
                              ).seasonsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.seriesId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (episodesRefs)
                        await $_getPrefetchedData<
                          SeriesRecord,
                          $SeriesTable,
                          EpisodeRecord
                        >(
                          currentTable: table,
                          referencedTable: $$SeriesTableReferences
                              ._episodesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SeriesTableReferences(
                                db,
                                table,
                                p0,
                              ).episodesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.seriesId == item.id,
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

typedef $$SeriesTableProcessedTableManager =
    ProcessedTableManager<
      _$OpenIptvDb,
      $SeriesTable,
      SeriesRecord,
      $$SeriesTableFilterComposer,
      $$SeriesTableOrderingComposer,
      $$SeriesTableAnnotationComposer,
      $$SeriesTableCreateCompanionBuilder,
      $$SeriesTableUpdateCompanionBuilder,
      (SeriesRecord, $$SeriesTableReferences),
      SeriesRecord,
      PrefetchHooks Function({
        bool providerId,
        bool categoryId,
        bool seasonsRefs,
        bool episodesRefs,
      })
    >;
typedef $$SeasonsTableCreateCompanionBuilder =
    SeasonsCompanion Function({
      Value<int> id,
      required int seriesId,
      required int seasonNumber,
      Value<String?> name,
    });
typedef $$SeasonsTableUpdateCompanionBuilder =
    SeasonsCompanion Function({
      Value<int> id,
      Value<int> seriesId,
      Value<int> seasonNumber,
      Value<String?> name,
    });

final class $$SeasonsTableReferences
    extends BaseReferences<_$OpenIptvDb, $SeasonsTable, SeasonRecord> {
  $$SeasonsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SeriesTable _seriesIdTable(_$OpenIptvDb db) => db.series.createAlias(
    $_aliasNameGenerator(db.seasons.seriesId, db.series.id),
  );

  $$SeriesTableProcessedTableManager get seriesId {
    final $_column = $_itemColumn<int>('series_id')!;

    final manager = $$SeriesTableTableManager(
      $_db,
      $_db.series,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_seriesIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$EpisodesTable, List<EpisodeRecord>>
  _episodesRefsTable(_$OpenIptvDb db) => MultiTypedResultKey.fromTable(
    db.episodes,
    aliasName: $_aliasNameGenerator(db.seasons.id, db.episodes.seasonId),
  );

  $$EpisodesTableProcessedTableManager get episodesRefs {
    final manager = $$EpisodesTableTableManager(
      $_db,
      $_db.episodes,
    ).filter((f) => f.seasonId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_episodesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SeasonsTableFilterComposer
    extends Composer<_$OpenIptvDb, $SeasonsTable> {
  $$SeasonsTableFilterComposer({
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

  ColumnFilters<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  $$SeriesTableFilterComposer get seriesId {
    final $$SeriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.series,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }

  Expression<bool> episodesRefs(
    Expression<bool> Function($$EpisodesTableFilterComposer f) f,
  ) {
    final $$EpisodesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.episodes,
      getReferencedColumn: (t) => t.seasonId,
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
}

class $$SeasonsTableOrderingComposer
    extends Composer<_$OpenIptvDb, $SeasonsTable> {
  $$SeasonsTableOrderingComposer({
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

  ColumnOrderings<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  $$SeriesTableOrderingComposer get seriesId {
    final $$SeriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.series,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SeriesTableOrderingComposer(
            $db: $db,
            $table: $db.series,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SeasonsTableAnnotationComposer
    extends Composer<_$OpenIptvDb, $SeasonsTable> {
  $$SeasonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  $$SeriesTableAnnotationComposer get seriesId {
    final $$SeriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.series,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }

  Expression<T> episodesRefs<T extends Object>(
    Expression<T> Function($$EpisodesTableAnnotationComposer a) f,
  ) {
    final $$EpisodesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.episodes,
      getReferencedColumn: (t) => t.seasonId,
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
}

class $$SeasonsTableTableManager
    extends
        RootTableManager<
          _$OpenIptvDb,
          $SeasonsTable,
          SeasonRecord,
          $$SeasonsTableFilterComposer,
          $$SeasonsTableOrderingComposer,
          $$SeasonsTableAnnotationComposer,
          $$SeasonsTableCreateCompanionBuilder,
          $$SeasonsTableUpdateCompanionBuilder,
          (SeasonRecord, $$SeasonsTableReferences),
          SeasonRecord,
          PrefetchHooks Function({bool seriesId, bool episodesRefs})
        > {
  $$SeasonsTableTableManager(_$OpenIptvDb db, $SeasonsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SeasonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SeasonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SeasonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> seriesId = const Value.absent(),
                Value<int> seasonNumber = const Value.absent(),
                Value<String?> name = const Value.absent(),
              }) => SeasonsCompanion(
                id: id,
                seriesId: seriesId,
                seasonNumber: seasonNumber,
                name: name,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int seriesId,
                required int seasonNumber,
                Value<String?> name = const Value.absent(),
              }) => SeasonsCompanion.insert(
                id: id,
                seriesId: seriesId,
                seasonNumber: seasonNumber,
                name: name,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SeasonsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({seriesId = false, episodesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (episodesRefs) db.episodes],
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
                    if (seriesId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.seriesId,
                                referencedTable: $$SeasonsTableReferences
                                    ._seriesIdTable(db),
                                referencedColumn: $$SeasonsTableReferences
                                    ._seriesIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (episodesRefs)
                    await $_getPrefetchedData<
                      SeasonRecord,
                      $SeasonsTable,
                      EpisodeRecord
                    >(
                      currentTable: table,
                      referencedTable: $$SeasonsTableReferences
                          ._episodesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SeasonsTableReferences(db, table, p0).episodesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.seasonId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SeasonsTableProcessedTableManager =
    ProcessedTableManager<
      _$OpenIptvDb,
      $SeasonsTable,
      SeasonRecord,
      $$SeasonsTableFilterComposer,
      $$SeasonsTableOrderingComposer,
      $$SeasonsTableAnnotationComposer,
      $$SeasonsTableCreateCompanionBuilder,
      $$SeasonsTableUpdateCompanionBuilder,
      (SeasonRecord, $$SeasonsTableReferences),
      SeasonRecord,
      PrefetchHooks Function({bool seriesId, bool episodesRefs})
    >;
typedef $$EpisodesTableCreateCompanionBuilder =
    EpisodesCompanion Function({
      Value<int> id,
      required int seriesId,
      required int seasonId,
      required String providerEpisodeKey,
      Value<int?> seasonNumber,
      Value<int?> episodeNumber,
      Value<String?> title,
      Value<String?> overview,
      Value<int?> durationSec,
      Value<String?> streamUrlTemplate,
      Value<DateTime?> lastSeenAt,
    });
typedef $$EpisodesTableUpdateCompanionBuilder =
    EpisodesCompanion Function({
      Value<int> id,
      Value<int> seriesId,
      Value<int> seasonId,
      Value<String> providerEpisodeKey,
      Value<int?> seasonNumber,
      Value<int?> episodeNumber,
      Value<String?> title,
      Value<String?> overview,
      Value<int?> durationSec,
      Value<String?> streamUrlTemplate,
      Value<DateTime?> lastSeenAt,
    });

final class $$EpisodesTableReferences
    extends BaseReferences<_$OpenIptvDb, $EpisodesTable, EpisodeRecord> {
  $$EpisodesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SeriesTable _seriesIdTable(_$OpenIptvDb db) => db.series.createAlias(
    $_aliasNameGenerator(db.episodes.seriesId, db.series.id),
  );

  $$SeriesTableProcessedTableManager get seriesId {
    final $_column = $_itemColumn<int>('series_id')!;

    final manager = $$SeriesTableTableManager(
      $_db,
      $_db.series,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_seriesIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SeasonsTable _seasonIdTable(_$OpenIptvDb db) => db.seasons
      .createAlias($_aliasNameGenerator(db.episodes.seasonId, db.seasons.id));

  $$SeasonsTableProcessedTableManager get seasonId {
    final $_column = $_itemColumn<int>('season_id')!;

    final manager = $$SeasonsTableTableManager(
      $_db,
      $_db.seasons,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_seasonIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EpisodesTableFilterComposer
    extends Composer<_$OpenIptvDb, $EpisodesTable> {
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

  ColumnFilters<String> get providerEpisodeKey => $composableBuilder(
    column: $table.providerEpisodeKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get episodeNumber => $composableBuilder(
    column: $table.episodeNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
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

  $$SeriesTableFilterComposer get seriesId {
    final $$SeriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.series,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }

  $$SeasonsTableFilterComposer get seasonId {
    final $$SeasonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seasonId,
      referencedTable: $db.seasons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SeasonsTableFilterComposer(
            $db: $db,
            $table: $db.seasons,
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
    extends Composer<_$OpenIptvDb, $EpisodesTable> {
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

  ColumnOrderings<String> get providerEpisodeKey => $composableBuilder(
    column: $table.providerEpisodeKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get episodeNumber => $composableBuilder(
    column: $table.episodeNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
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

  $$SeriesTableOrderingComposer get seriesId {
    final $$SeriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.series,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SeriesTableOrderingComposer(
            $db: $db,
            $table: $db.series,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SeasonsTableOrderingComposer get seasonId {
    final $$SeasonsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seasonId,
      referencedTable: $db.seasons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SeasonsTableOrderingComposer(
            $db: $db,
            $table: $db.seasons,
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
    extends Composer<_$OpenIptvDb, $EpisodesTable> {
  $$EpisodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get providerEpisodeKey => $composableBuilder(
    column: $table.providerEpisodeKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get episodeNumber => $composableBuilder(
    column: $table.episodeNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => column);

  GeneratedColumn<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => column,
  );

  GeneratedColumn<String> get streamUrlTemplate => $composableBuilder(
    column: $table.streamUrlTemplate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => column,
  );

  $$SeriesTableAnnotationComposer get seriesId {
    final $$SeriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seriesId,
      referencedTable: $db.series,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }

  $$SeasonsTableAnnotationComposer get seasonId {
    final $$SeasonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.seasonId,
      referencedTable: $db.seasons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SeasonsTableAnnotationComposer(
            $db: $db,
            $table: $db.seasons,
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
          _$OpenIptvDb,
          $EpisodesTable,
          EpisodeRecord,
          $$EpisodesTableFilterComposer,
          $$EpisodesTableOrderingComposer,
          $$EpisodesTableAnnotationComposer,
          $$EpisodesTableCreateCompanionBuilder,
          $$EpisodesTableUpdateCompanionBuilder,
          (EpisodeRecord, $$EpisodesTableReferences),
          EpisodeRecord,
          PrefetchHooks Function({bool seriesId, bool seasonId})
        > {
  $$EpisodesTableTableManager(_$OpenIptvDb db, $EpisodesTable table)
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
                Value<int> seasonId = const Value.absent(),
                Value<String> providerEpisodeKey = const Value.absent(),
                Value<int?> seasonNumber = const Value.absent(),
                Value<int?> episodeNumber = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<int?> durationSec = const Value.absent(),
                Value<String?> streamUrlTemplate = const Value.absent(),
                Value<DateTime?> lastSeenAt = const Value.absent(),
              }) => EpisodesCompanion(
                id: id,
                seriesId: seriesId,
                seasonId: seasonId,
                providerEpisodeKey: providerEpisodeKey,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber,
                title: title,
                overview: overview,
                durationSec: durationSec,
                streamUrlTemplate: streamUrlTemplate,
                lastSeenAt: lastSeenAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int seriesId,
                required int seasonId,
                required String providerEpisodeKey,
                Value<int?> seasonNumber = const Value.absent(),
                Value<int?> episodeNumber = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> overview = const Value.absent(),
                Value<int?> durationSec = const Value.absent(),
                Value<String?> streamUrlTemplate = const Value.absent(),
                Value<DateTime?> lastSeenAt = const Value.absent(),
              }) => EpisodesCompanion.insert(
                id: id,
                seriesId: seriesId,
                seasonId: seasonId,
                providerEpisodeKey: providerEpisodeKey,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber,
                title: title,
                overview: overview,
                durationSec: durationSec,
                streamUrlTemplate: streamUrlTemplate,
                lastSeenAt: lastSeenAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EpisodesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({seriesId = false, seasonId = false}) {
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
                    if (seriesId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.seriesId,
                                referencedTable: $$EpisodesTableReferences
                                    ._seriesIdTable(db),
                                referencedColumn: $$EpisodesTableReferences
                                    ._seriesIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (seasonId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.seasonId,
                                referencedTable: $$EpisodesTableReferences
                                    ._seasonIdTable(db),
                                referencedColumn: $$EpisodesTableReferences
                                    ._seasonIdTable(db)
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
      _$OpenIptvDb,
      $EpisodesTable,
      EpisodeRecord,
      $$EpisodesTableFilterComposer,
      $$EpisodesTableOrderingComposer,
      $$EpisodesTableAnnotationComposer,
      $$EpisodesTableCreateCompanionBuilder,
      $$EpisodesTableUpdateCompanionBuilder,
      (EpisodeRecord, $$EpisodesTableReferences),
      EpisodeRecord,
      PrefetchHooks Function({bool seriesId, bool seasonId})
    >;
typedef $$ArtworkCacheTableCreateCompanionBuilder =
    ArtworkCacheCompanion Function({
      Value<int> id,
      required String url,
      Value<String?> etag,
      Value<String?> hash,
      Value<Uint8List?> bytes,
      Value<String?> filePath,
      Value<int?> byteSize,
      Value<int?> width,
      Value<int?> height,
      required DateTime fetchedAt,
      required DateTime lastAccessedAt,
      Value<DateTime?> expiresAt,
      Value<bool> needsRefresh,
    });
typedef $$ArtworkCacheTableUpdateCompanionBuilder =
    ArtworkCacheCompanion Function({
      Value<int> id,
      Value<String> url,
      Value<String?> etag,
      Value<String?> hash,
      Value<Uint8List?> bytes,
      Value<String?> filePath,
      Value<int?> byteSize,
      Value<int?> width,
      Value<int?> height,
      Value<DateTime> fetchedAt,
      Value<DateTime> lastAccessedAt,
      Value<DateTime?> expiresAt,
      Value<bool> needsRefresh,
    });

class $$ArtworkCacheTableFilterComposer
    extends Composer<_$OpenIptvDb, $ArtworkCacheTable> {
  $$ArtworkCacheTableFilterComposer({
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

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get needsRefresh => $composableBuilder(
    column: $table.needsRefresh,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ArtworkCacheTableOrderingComposer
    extends Composer<_$OpenIptvDb, $ArtworkCacheTable> {
  $$ArtworkCacheTableOrderingComposer({
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

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get needsRefresh => $composableBuilder(
    column: $table.needsRefresh,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ArtworkCacheTableAnnotationComposer
    extends Composer<_$OpenIptvDb, $ArtworkCacheTable> {
  $$ArtworkCacheTableAnnotationComposer({
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

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);

  GeneratedColumn<String> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);

  GeneratedColumn<Uint8List> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get byteSize =>
      $composableBuilder(column: $table.byteSize, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<bool> get needsRefresh => $composableBuilder(
    column: $table.needsRefresh,
    builder: (column) => column,
  );
}

class $$ArtworkCacheTableTableManager
    extends
        RootTableManager<
          _$OpenIptvDb,
          $ArtworkCacheTable,
          ArtworkCacheRecord,
          $$ArtworkCacheTableFilterComposer,
          $$ArtworkCacheTableOrderingComposer,
          $$ArtworkCacheTableAnnotationComposer,
          $$ArtworkCacheTableCreateCompanionBuilder,
          $$ArtworkCacheTableUpdateCompanionBuilder,
          (
            ArtworkCacheRecord,
            BaseReferences<
              _$OpenIptvDb,
              $ArtworkCacheTable,
              ArtworkCacheRecord
            >,
          ),
          ArtworkCacheRecord,
          PrefetchHooks Function()
        > {
  $$ArtworkCacheTableTableManager(_$OpenIptvDb db, $ArtworkCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArtworkCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArtworkCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArtworkCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<String?> hash = const Value.absent(),
                Value<Uint8List?> bytes = const Value.absent(),
                Value<String?> filePath = const Value.absent(),
                Value<int?> byteSize = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<DateTime> lastAccessedAt = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<bool> needsRefresh = const Value.absent(),
              }) => ArtworkCacheCompanion(
                id: id,
                url: url,
                etag: etag,
                hash: hash,
                bytes: bytes,
                filePath: filePath,
                byteSize: byteSize,
                width: width,
                height: height,
                fetchedAt: fetchedAt,
                lastAccessedAt: lastAccessedAt,
                expiresAt: expiresAt,
                needsRefresh: needsRefresh,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String url,
                Value<String?> etag = const Value.absent(),
                Value<String?> hash = const Value.absent(),
                Value<Uint8List?> bytes = const Value.absent(),
                Value<String?> filePath = const Value.absent(),
                Value<int?> byteSize = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                required DateTime fetchedAt,
                required DateTime lastAccessedAt,
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<bool> needsRefresh = const Value.absent(),
              }) => ArtworkCacheCompanion.insert(
                id: id,
                url: url,
                etag: etag,
                hash: hash,
                bytes: bytes,
                filePath: filePath,
                byteSize: byteSize,
                width: width,
                height: height,
                fetchedAt: fetchedAt,
                lastAccessedAt: lastAccessedAt,
                expiresAt: expiresAt,
                needsRefresh: needsRefresh,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ArtworkCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$OpenIptvDb,
      $ArtworkCacheTable,
      ArtworkCacheRecord,
      $$ArtworkCacheTableFilterComposer,
      $$ArtworkCacheTableOrderingComposer,
      $$ArtworkCacheTableAnnotationComposer,
      $$ArtworkCacheTableCreateCompanionBuilder,
      $$ArtworkCacheTableUpdateCompanionBuilder,
      (
        ArtworkCacheRecord,
        BaseReferences<_$OpenIptvDb, $ArtworkCacheTable, ArtworkCacheRecord>,
      ),
      ArtworkCacheRecord,
      PrefetchHooks Function()
    >;
typedef $$PlaybackHistoryTableCreateCompanionBuilder =
    PlaybackHistoryCompanion Function({
      Value<int> id,
      required int providerId,
      required int channelId,
      required DateTime startedAt,
      required DateTime updatedAt,
      Value<int> positionSec,
      Value<int?> durationSec,
      Value<bool> completed,
    });
typedef $$PlaybackHistoryTableUpdateCompanionBuilder =
    PlaybackHistoryCompanion Function({
      Value<int> id,
      Value<int> providerId,
      Value<int> channelId,
      Value<DateTime> startedAt,
      Value<DateTime> updatedAt,
      Value<int> positionSec,
      Value<int?> durationSec,
      Value<bool> completed,
    });

final class $$PlaybackHistoryTableReferences
    extends
        BaseReferences<
          _$OpenIptvDb,
          $PlaybackHistoryTable,
          PlaybackHistoryRecord
        > {
  $$PlaybackHistoryTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProvidersTable _providerIdTable(_$OpenIptvDb db) =>
      db.providers.createAlias(
        $_aliasNameGenerator(db.playbackHistory.providerId, db.providers.id),
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

  static $ChannelsTable _channelIdTable(_$OpenIptvDb db) =>
      db.channels.createAlias(
        $_aliasNameGenerator(db.playbackHistory.channelId, db.channels.id),
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

class $$PlaybackHistoryTableFilterComposer
    extends Composer<_$OpenIptvDb, $PlaybackHistoryTable> {
  $$PlaybackHistoryTableFilterComposer({
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

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get positionSec => $composableBuilder(
    column: $table.positionSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
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

class $$PlaybackHistoryTableOrderingComposer
    extends Composer<_$OpenIptvDb, $PlaybackHistoryTable> {
  $$PlaybackHistoryTableOrderingComposer({
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

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get positionSec => $composableBuilder(
    column: $table.positionSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
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

class $$PlaybackHistoryTableAnnotationComposer
    extends Composer<_$OpenIptvDb, $PlaybackHistoryTable> {
  $$PlaybackHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get positionSec => $composableBuilder(
    column: $table.positionSec,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

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

class $$PlaybackHistoryTableTableManager
    extends
        RootTableManager<
          _$OpenIptvDb,
          $PlaybackHistoryTable,
          PlaybackHistoryRecord,
          $$PlaybackHistoryTableFilterComposer,
          $$PlaybackHistoryTableOrderingComposer,
          $$PlaybackHistoryTableAnnotationComposer,
          $$PlaybackHistoryTableCreateCompanionBuilder,
          $$PlaybackHistoryTableUpdateCompanionBuilder,
          (PlaybackHistoryRecord, $$PlaybackHistoryTableReferences),
          PlaybackHistoryRecord,
          PrefetchHooks Function({bool providerId, bool channelId})
        > {
  $$PlaybackHistoryTableTableManager(
    _$OpenIptvDb db,
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
                Value<int> id = const Value.absent(),
                Value<int> providerId = const Value.absent(),
                Value<int> channelId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> positionSec = const Value.absent(),
                Value<int?> durationSec = const Value.absent(),
                Value<bool> completed = const Value.absent(),
              }) => PlaybackHistoryCompanion(
                id: id,
                providerId: providerId,
                channelId: channelId,
                startedAt: startedAt,
                updatedAt: updatedAt,
                positionSec: positionSec,
                durationSec: durationSec,
                completed: completed,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int providerId,
                required int channelId,
                required DateTime startedAt,
                required DateTime updatedAt,
                Value<int> positionSec = const Value.absent(),
                Value<int?> durationSec = const Value.absent(),
                Value<bool> completed = const Value.absent(),
              }) => PlaybackHistoryCompanion.insert(
                id: id,
                providerId: providerId,
                channelId: channelId,
                startedAt: startedAt,
                updatedAt: updatedAt,
                positionSec: positionSec,
                durationSec: durationSec,
                completed: completed,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlaybackHistoryTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({providerId = false, channelId = false}) {
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
                    if (channelId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.channelId,
                                referencedTable:
                                    $$PlaybackHistoryTableReferences
                                        ._channelIdTable(db),
                                referencedColumn:
                                    $$PlaybackHistoryTableReferences
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

typedef $$PlaybackHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$OpenIptvDb,
      $PlaybackHistoryTable,
      PlaybackHistoryRecord,
      $$PlaybackHistoryTableFilterComposer,
      $$PlaybackHistoryTableOrderingComposer,
      $$PlaybackHistoryTableAnnotationComposer,
      $$PlaybackHistoryTableCreateCompanionBuilder,
      $$PlaybackHistoryTableUpdateCompanionBuilder,
      (PlaybackHistoryRecord, $$PlaybackHistoryTableReferences),
      PlaybackHistoryRecord,
      PrefetchHooks Function({bool providerId, bool channelId})
    >;
typedef $$UserFlagsTableCreateCompanionBuilder =
    UserFlagsCompanion Function({
      Value<int> id,
      required int providerId,
      required int channelId,
      Value<bool> isFavorite,
      Value<bool> isHidden,
      Value<bool> isPinned,
      required DateTime updatedAt,
    });
typedef $$UserFlagsTableUpdateCompanionBuilder =
    UserFlagsCompanion Function({
      Value<int> id,
      Value<int> providerId,
      Value<int> channelId,
      Value<bool> isFavorite,
      Value<bool> isHidden,
      Value<bool> isPinned,
      Value<DateTime> updatedAt,
    });

final class $$UserFlagsTableReferences
    extends BaseReferences<_$OpenIptvDb, $UserFlagsTable, UserFlagRecord> {
  $$UserFlagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProvidersTable _providerIdTable(_$OpenIptvDb db) =>
      db.providers.createAlias(
        $_aliasNameGenerator(db.userFlags.providerId, db.providers.id),
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

  static $ChannelsTable _channelIdTable(_$OpenIptvDb db) =>
      db.channels.createAlias(
        $_aliasNameGenerator(db.userFlags.channelId, db.channels.id),
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

class $$UserFlagsTableFilterComposer
    extends Composer<_$OpenIptvDb, $UserFlagsTable> {
  $$UserFlagsTableFilterComposer({
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

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isHidden => $composableBuilder(
    column: $table.isHidden,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
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

class $$UserFlagsTableOrderingComposer
    extends Composer<_$OpenIptvDb, $UserFlagsTable> {
  $$UserFlagsTableOrderingComposer({
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

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isHidden => $composableBuilder(
    column: $table.isHidden,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
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

class $$UserFlagsTableAnnotationComposer
    extends Composer<_$OpenIptvDb, $UserFlagsTable> {
  $$UserFlagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isHidden =>
      $composableBuilder(column: $table.isHidden, builder: (column) => column);

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

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

class $$UserFlagsTableTableManager
    extends
        RootTableManager<
          _$OpenIptvDb,
          $UserFlagsTable,
          UserFlagRecord,
          $$UserFlagsTableFilterComposer,
          $$UserFlagsTableOrderingComposer,
          $$UserFlagsTableAnnotationComposer,
          $$UserFlagsTableCreateCompanionBuilder,
          $$UserFlagsTableUpdateCompanionBuilder,
          (UserFlagRecord, $$UserFlagsTableReferences),
          UserFlagRecord,
          PrefetchHooks Function({bool providerId, bool channelId})
        > {
  $$UserFlagsTableTableManager(_$OpenIptvDb db, $UserFlagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserFlagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserFlagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserFlagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> providerId = const Value.absent(),
                Value<int> channelId = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<bool> isHidden = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => UserFlagsCompanion(
                id: id,
                providerId: providerId,
                channelId: channelId,
                isFavorite: isFavorite,
                isHidden: isHidden,
                isPinned: isPinned,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int providerId,
                required int channelId,
                Value<bool> isFavorite = const Value.absent(),
                Value<bool> isHidden = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                required DateTime updatedAt,
              }) => UserFlagsCompanion.insert(
                id: id,
                providerId: providerId,
                channelId: channelId,
                isFavorite: isFavorite,
                isHidden: isHidden,
                isPinned: isPinned,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$UserFlagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({providerId = false, channelId = false}) {
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
                                referencedTable: $$UserFlagsTableReferences
                                    ._providerIdTable(db),
                                referencedColumn: $$UserFlagsTableReferences
                                    ._providerIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (channelId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.channelId,
                                referencedTable: $$UserFlagsTableReferences
                                    ._channelIdTable(db),
                                referencedColumn: $$UserFlagsTableReferences
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

typedef $$UserFlagsTableProcessedTableManager =
    ProcessedTableManager<
      _$OpenIptvDb,
      $UserFlagsTable,
      UserFlagRecord,
      $$UserFlagsTableFilterComposer,
      $$UserFlagsTableOrderingComposer,
      $$UserFlagsTableAnnotationComposer,
      $$UserFlagsTableCreateCompanionBuilder,
      $$UserFlagsTableUpdateCompanionBuilder,
      (UserFlagRecord, $$UserFlagsTableReferences),
      UserFlagRecord,
      PrefetchHooks Function({bool providerId, bool channelId})
    >;
typedef $$MaintenanceLogTableCreateCompanionBuilder =
    MaintenanceLogCompanion Function({
      required String task,
      required DateTime lastRunAt,
      Value<int> rowid,
    });
typedef $$MaintenanceLogTableUpdateCompanionBuilder =
    MaintenanceLogCompanion Function({
      Value<String> task,
      Value<DateTime> lastRunAt,
      Value<int> rowid,
    });

class $$MaintenanceLogTableFilterComposer
    extends Composer<_$OpenIptvDb, $MaintenanceLogTable> {
  $$MaintenanceLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get task => $composableBuilder(
    column: $table.task,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastRunAt => $composableBuilder(
    column: $table.lastRunAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MaintenanceLogTableOrderingComposer
    extends Composer<_$OpenIptvDb, $MaintenanceLogTable> {
  $$MaintenanceLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get task => $composableBuilder(
    column: $table.task,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastRunAt => $composableBuilder(
    column: $table.lastRunAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MaintenanceLogTableAnnotationComposer
    extends Composer<_$OpenIptvDb, $MaintenanceLogTable> {
  $$MaintenanceLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get task =>
      $composableBuilder(column: $table.task, builder: (column) => column);

  GeneratedColumn<DateTime> get lastRunAt =>
      $composableBuilder(column: $table.lastRunAt, builder: (column) => column);
}

class $$MaintenanceLogTableTableManager
    extends
        RootTableManager<
          _$OpenIptvDb,
          $MaintenanceLogTable,
          MaintenanceLogRecord,
          $$MaintenanceLogTableFilterComposer,
          $$MaintenanceLogTableOrderingComposer,
          $$MaintenanceLogTableAnnotationComposer,
          $$MaintenanceLogTableCreateCompanionBuilder,
          $$MaintenanceLogTableUpdateCompanionBuilder,
          (
            MaintenanceLogRecord,
            BaseReferences<
              _$OpenIptvDb,
              $MaintenanceLogTable,
              MaintenanceLogRecord
            >,
          ),
          MaintenanceLogRecord,
          PrefetchHooks Function()
        > {
  $$MaintenanceLogTableTableManager(_$OpenIptvDb db, $MaintenanceLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MaintenanceLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MaintenanceLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MaintenanceLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> task = const Value.absent(),
                Value<DateTime> lastRunAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MaintenanceLogCompanion(
                task: task,
                lastRunAt: lastRunAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String task,
                required DateTime lastRunAt,
                Value<int> rowid = const Value.absent(),
              }) => MaintenanceLogCompanion.insert(
                task: task,
                lastRunAt: lastRunAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MaintenanceLogTableProcessedTableManager =
    ProcessedTableManager<
      _$OpenIptvDb,
      $MaintenanceLogTable,
      MaintenanceLogRecord,
      $$MaintenanceLogTableFilterComposer,
      $$MaintenanceLogTableOrderingComposer,
      $$MaintenanceLogTableAnnotationComposer,
      $$MaintenanceLogTableCreateCompanionBuilder,
      $$MaintenanceLogTableUpdateCompanionBuilder,
      (
        MaintenanceLogRecord,
        BaseReferences<
          _$OpenIptvDb,
          $MaintenanceLogTable,
          MaintenanceLogRecord
        >,
      ),
      MaintenanceLogRecord,
      PrefetchHooks Function()
    >;
typedef $$ImportRunsTableCreateCompanionBuilder =
    ImportRunsCompanion Function({
      Value<int> id,
      required int providerId,
      required ProviderKind providerKind,
      required String importType,
      required DateTime startedAt,
      Value<int?> durationMs,
      Value<int?> channelsUpserted,
      Value<int?> categoriesUpserted,
      Value<int?> moviesUpserted,
      Value<int?> seriesUpserted,
      Value<int?> seasonsUpserted,
      Value<int?> episodesUpserted,
      Value<int?> channelsDeleted,
      Value<String?> error,
    });
typedef $$ImportRunsTableUpdateCompanionBuilder =
    ImportRunsCompanion Function({
      Value<int> id,
      Value<int> providerId,
      Value<ProviderKind> providerKind,
      Value<String> importType,
      Value<DateTime> startedAt,
      Value<int?> durationMs,
      Value<int?> channelsUpserted,
      Value<int?> categoriesUpserted,
      Value<int?> moviesUpserted,
      Value<int?> seriesUpserted,
      Value<int?> seasonsUpserted,
      Value<int?> episodesUpserted,
      Value<int?> channelsDeleted,
      Value<String?> error,
    });

final class $$ImportRunsTableReferences
    extends BaseReferences<_$OpenIptvDb, $ImportRunsTable, ImportRunRecord> {
  $$ImportRunsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProvidersTable _providerIdTable(_$OpenIptvDb db) =>
      db.providers.createAlias(
        $_aliasNameGenerator(db.importRuns.providerId, db.providers.id),
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

class $$ImportRunsTableFilterComposer
    extends Composer<_$OpenIptvDb, $ImportRunsTable> {
  $$ImportRunsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<ProviderKind, ProviderKind, String>
  get providerKind => $composableBuilder(
    column: $table.providerKind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get importType => $composableBuilder(
    column: $table.importType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get channelsUpserted => $composableBuilder(
    column: $table.channelsUpserted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get categoriesUpserted => $composableBuilder(
    column: $table.categoriesUpserted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get moviesUpserted => $composableBuilder(
    column: $table.moviesUpserted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seriesUpserted => $composableBuilder(
    column: $table.seriesUpserted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seasonsUpserted => $composableBuilder(
    column: $table.seasonsUpserted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get episodesUpserted => $composableBuilder(
    column: $table.episodesUpserted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get channelsDeleted => $composableBuilder(
    column: $table.channelsDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
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

class $$ImportRunsTableOrderingComposer
    extends Composer<_$OpenIptvDb, $ImportRunsTable> {
  $$ImportRunsTableOrderingComposer({
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

  ColumnOrderings<String> get providerKind => $composableBuilder(
    column: $table.providerKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get importType => $composableBuilder(
    column: $table.importType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get channelsUpserted => $composableBuilder(
    column: $table.channelsUpserted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get categoriesUpserted => $composableBuilder(
    column: $table.categoriesUpserted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get moviesUpserted => $composableBuilder(
    column: $table.moviesUpserted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seriesUpserted => $composableBuilder(
    column: $table.seriesUpserted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seasonsUpserted => $composableBuilder(
    column: $table.seasonsUpserted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get episodesUpserted => $composableBuilder(
    column: $table.episodesUpserted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get channelsDeleted => $composableBuilder(
    column: $table.channelsDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
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

class $$ImportRunsTableAnnotationComposer
    extends Composer<_$OpenIptvDb, $ImportRunsTable> {
  $$ImportRunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ProviderKind, String> get providerKind =>
      $composableBuilder(
        column: $table.providerKind,
        builder: (column) => column,
      );

  GeneratedColumn<String> get importType => $composableBuilder(
    column: $table.importType,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get channelsUpserted => $composableBuilder(
    column: $table.channelsUpserted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get categoriesUpserted => $composableBuilder(
    column: $table.categoriesUpserted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get moviesUpserted => $composableBuilder(
    column: $table.moviesUpserted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get seriesUpserted => $composableBuilder(
    column: $table.seriesUpserted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get seasonsUpserted => $composableBuilder(
    column: $table.seasonsUpserted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get episodesUpserted => $composableBuilder(
    column: $table.episodesUpserted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get channelsDeleted => $composableBuilder(
    column: $table.channelsDeleted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

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

class $$ImportRunsTableTableManager
    extends
        RootTableManager<
          _$OpenIptvDb,
          $ImportRunsTable,
          ImportRunRecord,
          $$ImportRunsTableFilterComposer,
          $$ImportRunsTableOrderingComposer,
          $$ImportRunsTableAnnotationComposer,
          $$ImportRunsTableCreateCompanionBuilder,
          $$ImportRunsTableUpdateCompanionBuilder,
          (ImportRunRecord, $$ImportRunsTableReferences),
          ImportRunRecord,
          PrefetchHooks Function({bool providerId})
        > {
  $$ImportRunsTableTableManager(_$OpenIptvDb db, $ImportRunsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImportRunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImportRunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImportRunsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> providerId = const Value.absent(),
                Value<ProviderKind> providerKind = const Value.absent(),
                Value<String> importType = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<int?> channelsUpserted = const Value.absent(),
                Value<int?> categoriesUpserted = const Value.absent(),
                Value<int?> moviesUpserted = const Value.absent(),
                Value<int?> seriesUpserted = const Value.absent(),
                Value<int?> seasonsUpserted = const Value.absent(),
                Value<int?> episodesUpserted = const Value.absent(),
                Value<int?> channelsDeleted = const Value.absent(),
                Value<String?> error = const Value.absent(),
              }) => ImportRunsCompanion(
                id: id,
                providerId: providerId,
                providerKind: providerKind,
                importType: importType,
                startedAt: startedAt,
                durationMs: durationMs,
                channelsUpserted: channelsUpserted,
                categoriesUpserted: categoriesUpserted,
                moviesUpserted: moviesUpserted,
                seriesUpserted: seriesUpserted,
                seasonsUpserted: seasonsUpserted,
                episodesUpserted: episodesUpserted,
                channelsDeleted: channelsDeleted,
                error: error,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int providerId,
                required ProviderKind providerKind,
                required String importType,
                required DateTime startedAt,
                Value<int?> durationMs = const Value.absent(),
                Value<int?> channelsUpserted = const Value.absent(),
                Value<int?> categoriesUpserted = const Value.absent(),
                Value<int?> moviesUpserted = const Value.absent(),
                Value<int?> seriesUpserted = const Value.absent(),
                Value<int?> seasonsUpserted = const Value.absent(),
                Value<int?> episodesUpserted = const Value.absent(),
                Value<int?> channelsDeleted = const Value.absent(),
                Value<String?> error = const Value.absent(),
              }) => ImportRunsCompanion.insert(
                id: id,
                providerId: providerId,
                providerKind: providerKind,
                importType: importType,
                startedAt: startedAt,
                durationMs: durationMs,
                channelsUpserted: channelsUpserted,
                categoriesUpserted: categoriesUpserted,
                moviesUpserted: moviesUpserted,
                seriesUpserted: seriesUpserted,
                seasonsUpserted: seasonsUpserted,
                episodesUpserted: episodesUpserted,
                channelsDeleted: channelsDeleted,
                error: error,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ImportRunsTableReferences(db, table, e),
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
                                referencedTable: $$ImportRunsTableReferences
                                    ._providerIdTable(db),
                                referencedColumn: $$ImportRunsTableReferences
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

typedef $$ImportRunsTableProcessedTableManager =
    ProcessedTableManager<
      _$OpenIptvDb,
      $ImportRunsTable,
      ImportRunRecord,
      $$ImportRunsTableFilterComposer,
      $$ImportRunsTableOrderingComposer,
      $$ImportRunsTableAnnotationComposer,
      $$ImportRunsTableCreateCompanionBuilder,
      $$ImportRunsTableUpdateCompanionBuilder,
      (ImportRunRecord, $$ImportRunsTableReferences),
      ImportRunRecord,
      PrefetchHooks Function({bool providerId})
    >;
typedef $$EpgProgramsFtsTableCreateCompanionBuilder =
    EpgProgramsFtsCompanion Function({
      required String title,
      required String description,
      Value<int> programId,
    });
typedef $$EpgProgramsFtsTableUpdateCompanionBuilder =
    EpgProgramsFtsCompanion Function({
      Value<String> title,
      Value<String> description,
      Value<int> programId,
    });

final class $$EpgProgramsFtsTableReferences
    extends BaseReferences<_$OpenIptvDb, $EpgProgramsFtsTable, EpgProgramsFt> {
  $$EpgProgramsFtsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $EpgProgramsTable _programIdTable(_$OpenIptvDb db) =>
      db.epgPrograms.createAlias(
        $_aliasNameGenerator(db.epgProgramsFts.programId, db.epgPrograms.id),
      );

  $$EpgProgramsTableProcessedTableManager get programId {
    final $_column = $_itemColumn<int>('program_id')!;

    final manager = $$EpgProgramsTableTableManager(
      $_db,
      $_db.epgPrograms,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_programIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EpgProgramsFtsTableFilterComposer
    extends Composer<_$OpenIptvDb, $EpgProgramsFtsTable> {
  $$EpgProgramsFtsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  $$EpgProgramsTableFilterComposer get programId {
    final $$EpgProgramsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programId,
      referencedTable: $db.epgPrograms,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }
}

class $$EpgProgramsFtsTableOrderingComposer
    extends Composer<_$OpenIptvDb, $EpgProgramsFtsTable> {
  $$EpgProgramsFtsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  $$EpgProgramsTableOrderingComposer get programId {
    final $$EpgProgramsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programId,
      referencedTable: $db.epgPrograms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EpgProgramsTableOrderingComposer(
            $db: $db,
            $table: $db.epgPrograms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EpgProgramsFtsTableAnnotationComposer
    extends Composer<_$OpenIptvDb, $EpgProgramsFtsTable> {
  $$EpgProgramsFtsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  $$EpgProgramsTableAnnotationComposer get programId {
    final $$EpgProgramsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.programId,
      referencedTable: $db.epgPrograms,
      getReferencedColumn: (t) => t.id,
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
    return composer;
  }
}

class $$EpgProgramsFtsTableTableManager
    extends
        RootTableManager<
          _$OpenIptvDb,
          $EpgProgramsFtsTable,
          EpgProgramsFt,
          $$EpgProgramsFtsTableFilterComposer,
          $$EpgProgramsFtsTableOrderingComposer,
          $$EpgProgramsFtsTableAnnotationComposer,
          $$EpgProgramsFtsTableCreateCompanionBuilder,
          $$EpgProgramsFtsTableUpdateCompanionBuilder,
          (EpgProgramsFt, $$EpgProgramsFtsTableReferences),
          EpgProgramsFt,
          PrefetchHooks Function({bool programId})
        > {
  $$EpgProgramsFtsTableTableManager(_$OpenIptvDb db, $EpgProgramsFtsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EpgProgramsFtsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EpgProgramsFtsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EpgProgramsFtsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> programId = const Value.absent(),
              }) => EpgProgramsFtsCompanion(
                title: title,
                description: description,
                programId: programId,
              ),
          createCompanionCallback:
              ({
                required String title,
                required String description,
                Value<int> programId = const Value.absent(),
              }) => EpgProgramsFtsCompanion.insert(
                title: title,
                description: description,
                programId: programId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EpgProgramsFtsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({programId = false}) {
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
                    if (programId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.programId,
                                referencedTable: $$EpgProgramsFtsTableReferences
                                    ._programIdTable(db),
                                referencedColumn:
                                    $$EpgProgramsFtsTableReferences
                                        ._programIdTable(db)
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

typedef $$EpgProgramsFtsTableProcessedTableManager =
    ProcessedTableManager<
      _$OpenIptvDb,
      $EpgProgramsFtsTable,
      EpgProgramsFt,
      $$EpgProgramsFtsTableFilterComposer,
      $$EpgProgramsFtsTableOrderingComposer,
      $$EpgProgramsFtsTableAnnotationComposer,
      $$EpgProgramsFtsTableCreateCompanionBuilder,
      $$EpgProgramsFtsTableUpdateCompanionBuilder,
      (EpgProgramsFt, $$EpgProgramsFtsTableReferences),
      EpgProgramsFt,
      PrefetchHooks Function({bool programId})
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
  $$MoviesTableTableManager get movies =>
      $$MoviesTableTableManager(_db, _db.movies);
  $$SeriesTableTableManager get series =>
      $$SeriesTableTableManager(_db, _db.series);
  $$SeasonsTableTableManager get seasons =>
      $$SeasonsTableTableManager(_db, _db.seasons);
  $$EpisodesTableTableManager get episodes =>
      $$EpisodesTableTableManager(_db, _db.episodes);
  $$ArtworkCacheTableTableManager get artworkCache =>
      $$ArtworkCacheTableTableManager(_db, _db.artworkCache);
  $$PlaybackHistoryTableTableManager get playbackHistory =>
      $$PlaybackHistoryTableTableManager(_db, _db.playbackHistory);
  $$UserFlagsTableTableManager get userFlags =>
      $$UserFlagsTableTableManager(_db, _db.userFlags);
  $$MaintenanceLogTableTableManager get maintenanceLog =>
      $$MaintenanceLogTableTableManager(_db, _db.maintenanceLog);
  $$ImportRunsTableTableManager get importRuns =>
      $$ImportRunsTableTableManager(_db, _db.importRuns);
  $$EpgProgramsFtsTableTableManager get epgProgramsFts =>
      $$EpgProgramsFtsTableTableManager(_db, _db.epgProgramsFts);
}
