/// Captures the behavioural quirks ("dialect") observed for a specific
/// Stalker/Ministra portal so subsequent runs can skip expensive probes.
class StalkerPortalDialect {
  StalkerPortalDialect({
    Map<String, String>? categoryActions,
    Map<String, StalkerDerivedCategorySet>? derivedCategories,
    this.requiresParentalUnlock = false,
    DateTime? updatedAt,
  })  : categoryActions = Map.unmodifiable(categoryActions ?? const {}),
        derivedCategories = Map.unmodifiable(derivedCategories ?? const {}),
        updatedAt = (updatedAt ?? DateTime.now().toUtc()).toUtc();

  /// Preferred category action per module (e.g. vod -> get_genres).
  final Map<String, String> categoryActions;

  /// Cached derived categories keyed by module, allowing portals that only
  /// expose "*" buckets to hydrate the UI immediately.
  final Map<String, StalkerDerivedCategorySet> derivedCategories;

  /// Hint surfaced to the UI so it can prompt for the parental password.
  final bool requiresParentalUnlock;

  /// Timestamp tracking when this dialect snapshot was last updated.
  final DateTime updatedAt;

  /// Returns the preferred category action for the supplied module.
  String? preferredActionFor(String module) => categoryActions[module];

  /// Returns true when cached derived categories exist for the module.
  bool hasDerivedCategories(String module) =>
      derivedCategories[module]?.categories.isNotEmpty ?? false;

  /// Returns the derived category cache entry for the supplied module.
  StalkerDerivedCategorySet? derivedCategoriesFor(String module) =>
      derivedCategories[module];

  /// Convenience flag used by the resume store to drop stale entries.
  bool isExpired(Duration ttl) =>
      DateTime.now().toUtc().difference(updatedAt) > ttl;

  /// Records which category action succeeded for a module.
  StalkerPortalDialect recordPreferredAction(String module, String action) {
    if (categoryActions[module] == action) {
      return this;
    }
    final updated = Map<String, String>.from(categoryActions)
      ..[module] = action;
    return _rebuild(categoryActions: updated);
  }

  /// Stores derived categories for a module so future runs can reuse them.
  StalkerPortalDialect recordDerivedCategories(
    String module,
    List<StalkerDerivedCategory> categories,
  ) {
    if (categories.isEmpty) {
      return this;
    }
    final updated = Map<String, StalkerDerivedCategorySet>.from(
      derivedCategories,
    )..[module] = StalkerDerivedCategorySet(categories: categories);
    return _rebuild(derivedCategories: updated);
  }

  /// Clears the derived category cache for the supplied module.
  StalkerPortalDialect clearDerivedCategories(String module) {
    if (!derivedCategories.containsKey(module)) {
      return this;
    }
    final updated = Map<String, StalkerDerivedCategorySet>.from(
      derivedCategories,
    )..remove(module);
    return _rebuild(derivedCategories: updated);
  }

  /// Updates the parental-unlock hint.
  StalkerPortalDialect updateParentalUnlock(bool required) {
    if (requiresParentalUnlock == required) {
      return this;
    }
    return _rebuild(requiresParentalUnlock: required);
  }

  /// Serialises the dialect into a JSON-friendly map.
  Map<String, dynamic> toJson() => {
        'updatedAt': updatedAt.toIso8601String(),
        'requiresParentalUnlock': requiresParentalUnlock,
        'categoryActions': categoryActions,
        'derivedCategories': derivedCategories.map(
          (module, set) => MapEntry(module, set.toJson()),
        ),
      };

  /// Deserialises a dialect from JSON.
  factory StalkerPortalDialect.fromJson(Map<String, dynamic> json) {
    final rawActions = json['categoryActions'];
    final actions = <String, String>{};
    if (rawActions is Map) {
      rawActions.forEach((key, value) {
        final stringKey = '$key';
        final stringValue = value?.toString() ?? '';
        if (stringValue.isNotEmpty) {
          actions[stringKey] = stringValue;
        }
      });
    }

    final rawDerived = json['derivedCategories'];
    final derived = <String, StalkerDerivedCategorySet>{};
    if (rawDerived is Map) {
      rawDerived.forEach((module, payload) {
        if (payload is Map) {
          derived['$module'] = StalkerDerivedCategorySet.fromJson(
            payload.map((key, value) => MapEntry('$key', value)),
          );
        }
      });
    }

    final updatedAt =
        DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final requiresUnlock = json['requiresParentalUnlock'] == true;

    return StalkerPortalDialect(
      categoryActions: actions,
      derivedCategories: derived,
      requiresParentalUnlock: requiresUnlock,
      updatedAt: updatedAt,
    );
  }

  StalkerPortalDialect _rebuild({
    Map<String, String>? categoryActions,
    Map<String, StalkerDerivedCategorySet>? derivedCategories,
    bool? requiresParentalUnlock,
  }) {
    return StalkerPortalDialect(
      categoryActions: categoryActions ?? this.categoryActions,
      derivedCategories: derivedCategories ?? this.derivedCategories,
      requiresParentalUnlock:
          requiresParentalUnlock ?? this.requiresParentalUnlock,
    );
  }
}

/// Represents a cached derived category set for a specific module.
class StalkerDerivedCategorySet {
  StalkerDerivedCategorySet({
    required List<StalkerDerivedCategory> categories,
    DateTime? learnedAt,
  })  : categories = List.unmodifiable(categories),
        learnedAt = (learnedAt ?? DateTime.now().toUtc()).toUtc();

  final List<StalkerDerivedCategory> categories;
  final DateTime learnedAt;

  bool isExpired(Duration ttl) =>
      DateTime.now().toUtc().difference(learnedAt) > ttl;

  List<Map<String, dynamic>> toPortalCategories() {
    return categories.map((category) => category.toPortalPayload()).toList();
  }

  Map<String, dynamic> toJson() => {
        'learnedAt': learnedAt.toIso8601String(),
        'categories': categories.map((cat) => cat.toJson()).toList(),
      };

  factory StalkerDerivedCategorySet.fromJson(Map<String, dynamic> json) {
    final learnedAt =
        DateTime.tryParse(json['learnedAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final items = (json['categories'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (entry) => StalkerDerivedCategory.fromJson(
            entry.map((key, value) => MapEntry('$key', value)),
          ),
        )
        .toList();
    return StalkerDerivedCategorySet(
      categories: items,
      learnedAt: learnedAt,
    );
  }
}

/// Normalised representation of a derived category entry.
class StalkerDerivedCategory {
  const StalkerDerivedCategory({
    required this.id,
    required this.title,
  });

  final String id;
  final String title;

  Map<String, dynamic> toPortalPayload() => {
        'id': id,
        'title': title,
        'name': title,
      };

  Map<String, dynamic> toJson() => {'id': id, 'title': title};

  factory StalkerDerivedCategory.fromJson(Map<String, dynamic> json) {
    final rawId = json['id']?.toString();
    final rawTitle = json['title']?.toString() ?? json['name']?.toString();
    final resolvedId =
        rawId == null || rawId.isEmpty ? _hashFromTitle(rawTitle) : rawId;
    final resolvedTitle =
        rawTitle == null || rawTitle.isEmpty ? resolvedId : rawTitle;
    return StalkerDerivedCategory(id: resolvedId, title: resolvedTitle);
  }

  static String _hashFromTitle(String? title) {
    final seed = title?.trim() ?? '';
    return 'derived:${seed.hashCode}';
  }
}
