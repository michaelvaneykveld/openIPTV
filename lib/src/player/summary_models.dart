import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'package:openiptv/storage/provider_profile_repository.dart';
import 'package:openiptv/src/protocols/discovery/portal_discovery.dart';

/// Combined view of a persisted provider profile with its resolved secrets.
@immutable
class ResolvedProviderProfile {
  ResolvedProviderProfile({
    required this.record,
    Map<String, String>? secrets,
    this.providerDbId,
  }) : secrets = secrets == null
           ? const {}
           : Map.unmodifiable(Map.of(secrets));

  final ProviderProfileRecord record;
  final Map<String, String> secrets;
  final int? providerDbId;

  ProviderKind get kind => record.kind;
  Uri get lockedBase => record.lockedBase;

  static const MapEquality<String, String> _mapEquality =
      MapEquality<String, String>();

  @override
  bool operator ==(Object other) {
    return other is ResolvedProviderProfile &&
        other.record.id == record.id &&
        _mapEquality.equals(other.secrets, secrets) &&
        other.providerDbId == providerDbId;
  }

  @override
  int get hashCode => Object.hash(
    record.id,
    Object.hashAll(
      secrets.entries.map((entry) => Object.hash(entry.key, entry.value)),
    ),
    providerDbId,
  );
}

/// Aggregated summary describing the provider's account and server footprint.
@immutable
class SummaryData {
  SummaryData({
    required this.kind,
    Map<String, String>? fields,
    Map<String, int>? counts,
    DateTime? fetchedAt,
  }) : fields = fields == null
           ? const {}
           : Map.unmodifiable(
               Map.fromEntries(
                 fields.entries.where(
                   (entry) =>
                       entry.value.isNotEmpty && entry.value.trim().isNotEmpty,
                 ),
               ),
             ),
       counts = counts == null
           ? const {}
           : Map.unmodifiable(
               Map.fromEntries(
                 counts.entries.where((entry) => entry.value >= 0),
               ),
             ),
       fetchedAt = fetchedAt ?? DateTime.now();

  final ProviderKind kind;
  final Map<String, String> fields;
  final Map<String, int> counts;
  final DateTime fetchedAt;

  bool get hasFields => fields.isNotEmpty;
  bool get hasCounts => counts.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'kind': kind.index,
        'fields': fields,
        'counts': counts,
        'fetchedAt': fetchedAt.toUtc().toIso8601String(),
      };

  factory SummaryData.fromJson(Map<String, dynamic> json) {
    Map<String, String>? parseFields(dynamic value) {
      if (value is Map) {
        return value.map(
          (key, value) => MapEntry('$key', value?.toString() ?? ''),
        );
      }
      return null;
    }

    Map<String, int>? parseCounts(dynamic value) {
      if (value is Map) {
        return value.map(
          (key, value) =>
              MapEntry('$key', value is int ? value : int.tryParse('$value') ?? 0),
        );
      }
      return null;
    }

    var kindIndex = json['kind'] is int
        ? json['kind'] as int
        : int.tryParse('${json['kind']}') ?? 0;
    if (kindIndex < 0 || kindIndex >= ProviderKind.values.length) {
      kindIndex = 0;
    }
    final fetchedAtRaw = json['fetchedAt'] as String?;
    return SummaryData(
      kind: ProviderKind.values[kindIndex.clamp(0, ProviderKind.values.length - 1)],
      fields: parseFields(json['fields']),
      counts: parseCounts(json['counts']),
      fetchedAt: fetchedAtRaw == null
          ? DateTime.now()
          : DateTime.tryParse(fetchedAtRaw)?.toLocal() ?? DateTime.now(),
    );
  }
}
