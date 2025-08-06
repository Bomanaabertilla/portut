import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class PostListScreen extends StatefulWidget {
  const PostListScreen({super.key});

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  final _authService = AuthService();
  User? _currentUser;
  List<BlogPost> _posts = [];
  bool _isLoading = true;
  bool _showPublicOnly = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
      await _loadPosts();
    }
  }

  Future<void> _loadPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final List<BlogPost> posts = [];

    final postKeys = keys
        .where((key) => key.endsWith('_timestamp'))
        .map((key) => key.replaceAll('_timestamp', ''))
        .toList();

    for (final postKey in postKeys) {
      final content = prefs.getString('${postKey}_content') ?? '';
      final author = prefs.getString('${postKey}_author') ?? '';
      final timestamp = prefs.getString('${postKey}_timestamp') ?? '';
      final visibility = prefs.getString('${postKey}_visibility') ?? 'Public';
      final filePath = prefs.getString('${postKey}_file');

      // Filter posts based on visibility and current user
      if (_showPublicOnly) {
        if (visibility == 'Public') {
          posts.add(
            BlogPost(
              key: postKey,
              content: content,
              author: author,
              timestamp: DateTime.tryParse(timestamp) ?? DateTime.now(),
              visibility: visibility,
              filePath: filePath,
            ),
          );
        }
      } else {
        // Show all posts for logged-in user
        if (_currentUser != null &&
            (visibility == 'Public' || author == _currentUser!.username)) {
          posts.add(
            BlogPost(
              key: postKey,
              content: content,
              author: author,
              timestamp: DateTime.tryParse(timestamp) ?? DateTime.now(),
              visibility: visibility,
              filePath: filePath,
            ),
          );
        }
      }
    }

    // Sort posts by timestamp (newest first)
    posts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (mounted) {
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${(difference.inDays / 7).floor()}w';
    }
  }

  Widget _buildPostCard(BlogPost post) {
    final isMyPost =
        _currentUser != null && post.author == _currentUser!.username;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post header with avatar, name, and timestamp
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  radius: 20,
                  child: Text(
                    post.author.isNotEmpty ? post.author[0].toUpperCase() : 'A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            post.author,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (post.visibility == 'Private')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Private',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        _formatTimestamp(post.timestamp),
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                if (isMyPost)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey[400]),
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.pushNamed(
                          context,
                          '/create',
                          arguments: post.key,
                        ).then((_) => _loadPosts());
                      } else if (value == 'delete') {
                        _deletePost(post.key);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Post content
            if (post.content.isNotEmpty)
              Text(
                post.content,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),

            // File attachment indicator
            if (post.filePath != null)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getFileIcon(post.filePath!),
                      color: Colors.deepPurple,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        post.filePath!.split('/').last,
                        style: TextStyle(color: Colors.grey[300], fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Action buttons (like, comment, share - for UI consistency)
            Row(
              children: [
                _buildActionButton(Icons.favorite_border, '0'),
                const SizedBox(width: 24),
                _buildActionButton(Icons.chat_bubble_outline, '0'),
                const SizedBox(width: 24),
                _buildActionButton(Icons.share, '0'),
                const Spacer(),
                _buildActionButton(Icons.bookmark_border, ''),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[400], size: 20),
        if (count.isNotEmpty) ...[
          const SizedBox(width: 4),
          Text(count, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        ],
      ],
    );
  }

  IconData _getFileIcon(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'png':
        return Icons.image;
      default:
        return Icons.attach_file;
    }
  }

  Future<void> _deletePost(String postKey) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: const Text('Delete Post', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this post?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${postKey}_content');
      await prefs.remove('${postKey}_author');
      await prefs.remove('${postKey}_timestamp');
      await prefs.remove('${postKey}_visibility');
      await prefs.remove('${postKey}_file');

      await _loadPosts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully')),
        );
      }
    }
  }

  void _navigateToCreatePost() {
    Navigator.pushNamed(context, '/create').then((_) => _loadPosts());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Posts',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _showPublicOnly ? Icons.public : Icons.person,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showPublicOnly = !_showPublicOnly;
              });
              _loadPosts();
            },
            tooltip: _showPublicOnly ? 'Show All Posts' : 'Show Public Posts',
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _navigateToCreatePost,
            tooltip: 'Create New Post',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            )
          : _posts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 64,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No posts yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to create a post!',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _navigateToCreatePost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Create Post'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadPosts,
              backgroundColor: Colors.grey[800],
              color: Colors.deepPurple,
              child: ListView.builder(
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  return _buildPostCard(_posts[index]);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreatePost,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class BlogPost {
  final String key;
  final String content;
  final String author;
  final DateTime timestamp;
  final String visibility;
  final String? filePath;

  BlogPost({
    required this.key,
    required this.content,
    required this.author,
    required this.timestamp,
    required this.visibility,
    this.filePath,
  });
}
