import 'package:flutter/material.dart';
import '../models/post.dart';
import 'initials_avatar.dart';

class SearchView extends StatefulWidget {
  final List<Post> posts;
  final Function(Post) onPostTap;

  const SearchView({
    super.key,
    required this.posts,
    required this.onPostTap,
  });

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedTab = 'Top';

  final List<Map<String, String>> _trends = [
    {'category': 'Technology · Trending', 'tag': '#FlutterDev', 'posts': '14.2K'},
    {'category': 'Design · Trending', 'tag': '#UIUXDesign', 'posts': '8.5K'},
    {'category': 'Community · Trending', 'tag': '#PorTuT', 'posts': '23.1K'},
    {'category': 'Mobile · Trending', 'tag': '#MobileApps', 'posts': '11.8K'},
    {'category': 'Software · Trending', 'tag': '#DartLang', 'posts': '5.4K'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Post> get _searchResults {
    if (_searchQuery.trim().isEmpty) return [];
    final q = _searchQuery.toLowerCase().trim();
    return widget.posts.where((post) {
      return post.title.toLowerCase().contains(q) ||
          post.description.toLowerCase().contains(q) ||
          post.authorName.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Column(
      children: [
        // Search Header Bar
        Container(
          color: theme.appBarTheme.backgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEBE6DC),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF424242),
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search PorTuT',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              color: Colors.grey,
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Tabs when searching
        if (_searchQuery.isNotEmpty)
          Container(
            color: theme.appBarTheme.backgroundColor,
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: ['Top', 'Latest', 'People', 'Media'].map((tab) {
                final isSelected = _selectedTab == tab;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTab = tab),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected ? primaryColor : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                    child: Text(
                      tab,
                      style: TextStyle(
                        color: isSelected
                            ? (isDark ? Colors.white : const Color(0xFF424242))
                            : Colors.grey,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

        Divider(
          height: 1,
          thickness: 0.8,
          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
        ),

        // Body
        Expanded(
          child: _searchQuery.isEmpty
              ? _buildTrendsList(context, isDark, primaryColor)
              : _buildSearchResults(context, isDark, primaryColor),
        ),
      ],
    );
  }

  Widget _buildTrendsList(BuildContext context, bool isDark, Color primaryColor) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            'Trends for you',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF424242),
            ),
          ),
        ),
        ..._trends.map((trend) {
          return InkWell(
            onTap: () {
              _searchController.text = trend['tag']!;
              setState(() => _searchQuery = trend['tag']!);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trend['category']!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          trend['tag']!,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF424242),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${trend['posts']} posts',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.more_horiz,
                    size: 18,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSearchResults(BuildContext context, bool isDark, Color primaryColor) {
    final results = _searchResults;

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 56,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            const SizedBox(height: 12),
            Text(
              'No results for "$_searchQuery"',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : const Color(0xFF424242),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try searching for another topic or author',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 0.8,
        color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
      ),
      itemBuilder: (context, index) {
        final post = results[index];
        return InkWell(
          onTap: () => widget.onPostTap(post),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InitialsAvatar(name: post.authorName, size: 40, fontSize: 15),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              post.authorName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDark ? Colors.white : const Color(0xFF424242),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '@${post.authorId}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        post.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF424242),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        post.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[300] : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
