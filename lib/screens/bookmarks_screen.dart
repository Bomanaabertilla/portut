import 'package:flutter/material.dart';
import 'blog_post_screen.dart';

class BookmarkedPost {
  final String id;
  final String title;
  final String author;
  final String date;
  bool isBookmarked;

  BookmarkedPost({
    required this.id,
    required this.title,
    required this.author,
    required this.date,
    this.isBookmarked = true,
  });
}

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<BookmarkedPost> _bookmarkedPosts = [
    BookmarkedPost(
      id: '1',
      title: 'The Art of Modern Web Design',
      author: 'Sarah Johnson',
      date: 'Dec 15, 2024',
    ),
    BookmarkedPost(
      id: '2',
      title: 'CSS Grid vs Flexbox: A Complete Guide',
      author: 'Mike Chen',
      date: 'Dec 12, 2024',
    ),
    BookmarkedPost(
      id: '3',
      title: 'JavaScript Async/Await Best Practices',
      author: 'Alex Rivera',
      date: 'Dec 10, 2024',
    ),
  ];

  void _removeBookmark(String postId) {
    setState(() {
      _bookmarkedPosts.removeWhere((post) => post.id == postId);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Bookmark removed')));
  }

  void _viewPost(BookmarkedPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BlogPostScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC), // Light beige background
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF424242),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Bookmarks',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF424242),
                    ),
                  ),
                ],
              ),
            ),

            // Bookmarked Posts List
            Expanded(
              child: _bookmarkedPosts.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bookmark_border,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No bookmarks yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Bookmark posts to read them later',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _bookmarkedPosts.length,
                      itemBuilder: (context, index) {
                        final post = _bookmarkedPosts[index];
                        return _buildBookmarkCard(post);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkCard(BookmarkedPost post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post title and bookmark icon
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF424242),
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Bookmark icon
                Icon(Icons.bookmark, color: const Color(0xFF8B4513), size: 20),
              ],
            ),
            const SizedBox(height: 8),

            // Author and date
            Row(
              children: [
                Text(
                  'By ${post.author}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                // Dot separator
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  post.date,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                // View button
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B4513),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ElevatedButton(
                      onPressed: () => _viewPost(post),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'View',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Remove button
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF8B4513),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ElevatedButton(
                      onPressed: () => _removeBookmark(post.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Remove',
                        style: TextStyle(
                          color: Color(0xFF8B4513),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
