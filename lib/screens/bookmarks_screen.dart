import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'blog_post_screen.dart';
import '../models/post.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';
import '../widgets/initials_avatar.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<Post> _bookmarkedPosts = [];
  bool _isLoading = true;
  String? _currentUserId;

  final PostService _postService = PostService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final user = await _authService.getCurrentUser();
      final userId = user?.username ?? 'current_user';
      _currentUserId = userId;

      final prefs = await SharedPreferences.getInstance();
      final savedIds = prefs.getStringList('bookmarks_$userId') ?? [];

      if (savedIds.isEmpty) {
        if (mounted) {
          setState(() {
            _bookmarkedPosts = [];
            _isLoading = false;
          });
        }
        return;
      }

      final allPostsData = await _postService.getAllPosts();
      final List<Post> loaded = [];
      for (final pData in allPostsData) {
        final id = pData['id']?.toString();
        if (savedIds.contains(id)) {
          final authorId = pData['authorId'] ?? 'unknown';
          loaded.add(Post.fromMap(pData, authorId));
        }
      }

      if (mounted) {
        setState(() {
          _bookmarkedPosts = loaded;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading bookmarks: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeBookmark(String postId) async {
    if (_currentUserId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIds = prefs.getStringList('bookmarks_$_currentUserId') ?? [];
      savedIds.remove(postId);
      await prefs.setStringList('bookmarks_$_currentUserId', savedIds);

      setState(() {
        _bookmarkedPosts.removeWhere((p) => p.id == postId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bookmark removed'),
            backgroundColor: Color(0xFF8B4513),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('Error removing bookmark: $e');
    }
  }

  void _viewPost(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BlogPostScreen(post: post)),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dateTime);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    } catch (e) {
      return timestamp;
    }
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
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF8B4513),
                      ),
                    )
                  : _bookmarkedPosts.isEmpty
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
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
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

  Widget _buildBookmarkCard(Post post) {
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
                const Icon(
                  Icons.bookmark,
                  color: Color(0xFF8B4513),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Author and date with InitialsAvatar
            Row(
              children: [
                InitialsAvatar(
                  name: post.authorName,
                  size: 24,
                  fontSize: 10,
                ),
                const SizedBox(width: 8),
                Text(
                  post.authorName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
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
                  _formatTimestamp(post.timestamp),
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
