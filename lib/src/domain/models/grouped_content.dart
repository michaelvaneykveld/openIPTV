

class GroupedContent {
  final List<MainCategory> categories;

  const GroupedContent({
    required this.categories,
  });
}

class MainCategory {
  final String name;
  final List<SubCategory> subCategories;

  const MainCategory({
    required this.name,
    required this.subCategories,
  });
}

class SubCategory {
  final String name;
  final List<PlayableItem> items;

  const SubCategory({
    required this.name,
    required this.items,
  });
}

class PlayableItem {
  final String id;
  final String name;
  final String? logoUrl;

  const PlayableItem({
    required this.id,
    required this.name,
    this.logoUrl,
  });
}