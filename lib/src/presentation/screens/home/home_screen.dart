
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openiptv/src/application/services/content_grouping_service.dart';
import 'package:openiptv/src/domain/models/grouped_content.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  MainCategory? _selectedMainCategory;
  SubCategory? _selectedSubCategory;

  @override
  Widget build(BuildContext context) {
    final groupedContentAsyncValue = ref.watch(contentGroupingServiceProvider).getGroupedContent();

    return Scaffold(
      appBar: AppBar(
        title: const Text('openIPTV'),
      ),
      body: FutureBuilder<GroupedContent>(
        future: groupedContentAsyncValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.categories.isEmpty) {
            return const Center(child: Text('No content found.'));
          }

          final groupedContent = snapshot.data!;

          return Row(
            children: [
              // Column 1: Main Categories
              SizedBox(
                width: 200,
                child: ListView.builder(
                  itemCount: groupedContent.categories.length,
                  itemBuilder: (context, index) {
                    final mainCategory = groupedContent.categories[index];
                    return ListTile(
                      title: Text(mainCategory.name),
                      selected: _selectedMainCategory == mainCategory,
                      onTap: () {
                        setState(() {
                          _selectedMainCategory = mainCategory;
                          _selectedSubCategory = null; // Reset sub-category selection
                        });
                      },
                    );
                  },
                ),
              ),
              const VerticalDivider(width: 1),

              // Column 2: Sub Categories
              if (_selectedMainCategory != null)
                SizedBox(
                  width: 250,
                  child: ListView.builder(
                    itemCount: _selectedMainCategory!.subCategories.length,
                    itemBuilder: (context, index) {
                      final subCategory = _selectedMainCategory!.subCategories[index];
                      return ListTile(
                        title: Text(subCategory.name),
                        selected: _selectedSubCategory == subCategory,
                        onTap: () {
                          setState(() {
                            _selectedSubCategory = subCategory;
                          });
                        },
                      );
                    },
                  ),
                ),
              const VerticalDivider(width: 1),

              // Column 3: Playable Items
              if (_selectedSubCategory != null)
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8.0),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 150,
                      childAspectRatio: 2 / 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _selectedSubCategory!.items.length,
                    itemBuilder: (context, index) {
                      final item = _selectedSubCategory!.items[index];
                      String name = '';
                      String logoUrl = '';

                      item.when(
                        channel: (channel) {
                          name = channel.name;
                          logoUrl = channel.logo ?? '';
                        },
                        vod: (vod) {
                          name = vod.name;
                          logoUrl = vod.logo ?? '';
                        },
                      );

                      return Card(
                        child: Column(
                          children: [
                            Expanded(
                              child: logoUrl.isNotEmpty
                                  ? Image.network(
                                      logoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => 
                                        const Center(child: Icon(Icons.tv)),
                                    )
                                  : const Center(child: Icon(Icons.tv)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
