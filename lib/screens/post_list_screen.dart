import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
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

      final likeCount = prefs.getInt('${postKey}_likes') ?? 0;
      final likedUsers = prefs.getStringList('${postKey}_liked_users') ?? [];
      final isLikedByCurrentUser =
          _currentUser != null && likedUsers.contains(_currentUser!.username);

      final bookmarkedUsers =
          prefs.getStringList('${postKey}_bookmarked_users') ?? [];
      final isBookmarked =
          _currentUser != null &&
          bookmarkedUsers.contains(_currentUser!.username);

      final comments = prefs.getStringList('${postKey}_comments') ?? [];

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
              likeCount: likeCount,
              isLikedByCurrentUser: isLikedByCurrentUser,
              comments: comments,
              bookmarkCount: bookmarkedUsers.length,
              isBookmarked: isBookmarked,
            ),
          );
        }
      } else {
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
              likeCount: likeCount,
              isLikedByCurrentUser: isLikedByCurrentUser,
              comments: comments,
              bookmarkCount: bookmarkedUsers.length,
              isBookmarked: isBookmarked,
            ),
          );
        }
      }
    }

    posts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (mounted) {
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLike(BlogPost post) async {
    if (_currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    final likedUsers = prefs.getStringList('${post.key}_liked_users') ?? [];
    final username = _currentUser!.username;

    if (likedUsers.contains(username)) {
      likedUsers.remove(username);
    } else {
      likedUsers.add(username);
    }

    await prefs.setInt('${post.key}_likes', likedUsers.length);
    await prefs.setStringList('${post.key}_liked_users', likedUsers);

    await _loadPosts();
  }

  Future<void> _toggleBookmark(BlogPost post) async {
    if (_currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    final bookmarkedUsers =
        prefs.getStringList('${post.key}_bookmarked_users') ?? [];
    final username = _currentUser!.username;

    if (bookmarkedUsers.contains(username)) {
      bookmarkedUsers.remove(username);
    } else {
      bookmarkedUsers.add(username);
    }

    await prefs.setStringList('${post.key}_bookmarked_users', bookmarkedUsers);
    await _loadPosts();
  }

  void _showCommentsDialog(BlogPost post) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Comments', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...post.comments.map(
              (c) => Align(
                alignment: Alignment.centerLeft,
                child: Text(c, style: const TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Add a comment',
                hintStyle: TextStyle(color: Colors.grey),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () async {
              final comment = controller.text.trim();
              if (comment.isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                final comments =
                    prefs.getStringList('${post.key}_comments') ?? [];
                comments.add('${_currentUser?.username ?? 'User'}: $comment');
                await prefs.setStringList('${post.key}_comments', comments);
                Navigator.pop(context);
                await _loadPosts();
              }
            },
            child: const Text(
              'Post',
              style: TextStyle(color: Colors.deepPurple),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentButton(BlogPost post) {
    return GestureDetector(
      onTap: () => _showCommentsDialog(post),
      child: Row(
        children: [
          const Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 20),
          if (post.comments.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              '${post.comments.length}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookmarkButton(BlogPost post) {
    return GestureDetector(
      onTap: () => _toggleBookmark(post),
      child: Row(
        children: [
          Icon(
            post.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: post.isBookmarked ? Colors.deepPurple : Colors.grey,
            size: 20,
          ),
          if (post.bookmarkCount > 0) ...[
            const SizedBox(width: 4),
            Text(
              '${post.bookmarkCount}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShareButton(BlogPost post) {
    return GestureDetector(
      onTap: () {
        final content = '${post.author} shared:\n\n${post.content}';
        Share.share(content);
      },
      child: const Icon(Icons.share, color: Colors.grey, size: 20),
    );
  }

  Widget _buildLikeButton(BlogPost post) {
    return GestureDetector(
      onTap: () => _toggleLike(post),
      child: Row(
        children: [
          Icon(
            post.isLikedByCurrentUser ? Icons.favorite : Icons.favorite_border,
            color: post.isLikedByCurrentUser ? Colors.red : Colors.grey,
            size: 20,
          ),
          if (post.likeCount > 0) ...[
            const SizedBox(width: 4),
            Text(
              '${post.likeCount}',
              style: TextStyle(
                color: post.isLikedByCurrentUser ? Colors.red : Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
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
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: Text(
                    post.author.isNotEmpty ? post.author[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
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
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
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
            if (post.content.isNotEmpty)
              Text(post.content, style: const TextStyle(color: Colors.white)),
            if (post.filePath != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Icon(
                      _getFileIcon(post.filePath!),
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        post.filePath!.split('/').last,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildLikeButton(post),
                const SizedBox(width: 24),
                _buildCommentButton(post),
                const SizedBox(width: 24),
                _buildShareButton(post),
                const Spacer(),
                _buildBookmarkButton(post),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePost(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${key}_content');
    await prefs.remove('${key}_author');
    await prefs.remove('${key}_timestamp');
    await prefs.remove('${key}_visibility');
    await prefs.remove('${key}_file');
    await prefs.remove('${key}_likes');
    await prefs.remove('${key}_liked_users');
    await prefs.remove('${key}_bookmarked_users');
    await prefs.remove('${key}_comments');

    await _loadPosts();
  }

  void _navigateToCreatePost() {
    Navigator.pushNamed(context, '/create').then((_) => _loadPosts());
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}w';
  }

  IconData _getFileIcon(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    switch (ext) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Posts', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
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
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _navigateToCreatePost,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            )
          : _posts.isEmpty
          ? const Center(
              child: Text(
                'No posts yet',
                style: TextStyle(color: Colors.white),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadPosts,
              backgroundColor: Colors.grey[800],
              color: Colors.deepPurple,
              child: ListView.builder(
                itemCount: _posts.length,
                itemBuilder: (context, index) => _buildPostCard(_posts[index]),
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
  final int likeCount;
  final bool isLikedByCurrentUser;
  final List<String> comments;
  final int bookmarkCount;
  final bool isBookmarked;

  BlogPost({
    required this.key,
    required this.content,
    required this.author,
    required this.timestamp,
    required this.visibility,
    this.filePath,
    this.likeCount = 0,
    this.isLikedByCurrentUser = false,
    this.comments = const [],
    this.bookmarkCount = 0,
    this.isBookmarked = false,
  });
}
