import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'create_post_screen.dart';
import 'profile_screen.dart';
import 'blog_post_screen.dart';
import 'bookmarks_screen.dart';
import '../services/post_service.dart';
import '../services/auth_service.dart';
import '../providers/theme_provider.dart';
import '../widgets/initials_avatar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/post.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showAllPosts = true; // Toggle between All Posts and My Posts
  String? _currentUserId;
  List<Post> _posts = [];
  bool _isLoading = true;
  Set<String> _bookmarkedPostIds = {};

  final PostService _postService = PostService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _initScreen();
  }

  Future<void> _initScreen() async {
    await _purgeSamplePosts();
    await _loadCurrentUser();
    await _loadBookmarks();
  }

  Future<void> _purgeSamplePosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Purge known dummy user posts
      await prefs.remove('user_posts:mike_chen');
      await prefs.remove('user_posts:emma_davis');

      // Purge dummy post IDs ('1', '2', '3') from any user's post list
      final keys = prefs.getKeys().where((k) => k.startsWith('user_posts:')).toList();
      for (final key in keys) {
        final jsonStr = prefs.getString(key);
        if (jsonStr != null) {
          final List<dynamic> list = jsonDecode(jsonStr);
          final filtered = list.where((p) {
            final id = p['id']?.toString();
            final author = p['authorName']?.toString();
            return id != '1' &&
                id != '2' &&
                id != '3' &&
                author != 'Mike Chen' &&
                author != 'Emma Davis';
          }).toList();
          if (filtered.length != list.length) {
            await prefs.setString(key, jsonEncode(filtered));
          }
        }
      }
    } catch (e) {
      print('Error purging sample posts: $e');
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUserId = user?.username ?? 'current_user';
        });
        await _loadPosts();
        await _loadBookmarks();
      }
    } catch (e) {
      print('Error loading current user: $e');
      if (mounted) {
        setState(() {
          _currentUserId = 'current_user';
        });
        await _loadPosts();
        await _loadBookmarks();
      }
    }
  }

  Future<void> _loadBookmarks() async {
    if (_currentUserId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('bookmarks_$_currentUserId') ?? [];
      if (mounted) {
        setState(() {
          _bookmarkedPostIds = saved.toSet();
        });
      }
    } catch (e) {
      print('Error loading bookmarks: $e');
    }
  }

  Future<void> _toggleBookmark(Post post) async {
    if (_currentUserId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final isBookmarked = _bookmarkedPostIds.contains(post.id);
      setState(() {
        if (isBookmarked) {
          _bookmarkedPostIds.remove(post.id);
        } else {
          _bookmarkedPostIds.add(post.id);
        }
      });
      await prefs.setStringList(
        'bookmarks_$_currentUserId',
        _bookmarkedPostIds.toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBookmarked ? 'Bookmark removed' : 'Post bookmarked!',
            ),
            backgroundColor: const Color(0xFF8B4513),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('Error toggling bookmark: $e');
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> postsData;

      if (_showAllPosts) {
        // Load all public posts
        postsData = await _postService.getAllPosts();
      } else {
        // Load current user's posts (both public and private)
        if (_currentUserId != null) {
          postsData = await _postService.getPosts(_currentUserId!);
        } else {
          postsData = [];
        }
      }

      // Convert to Post objects
      final List<Post> posts = [];
      for (final postData in postsData) {
        final authorId = postData['authorId'] ?? _currentUserId ?? 'unknown';
        posts.add(Post.fromMap(postData, authorId));
      }

      // Sort by timestamp (newest first)
      posts.sort((a, b) {
        final aTime = DateTime.tryParse(a.timestamp) ?? DateTime.now();
        final bTime = DateTime.tryParse(b.timestamp) ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading posts: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Clear all posts (for testing)
  Future<void> _clearAllPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final postKeys = keys
        .where((key) => key.startsWith('user_posts:'))
        .toList();

    for (final key in postKeys) {
      await prefs.remove(key);
    }
    if (_currentUserId != null) {
      await prefs.remove('bookmarks_$_currentUserId');
      _bookmarkedPostIds.clear();
    }

    print('Cleared all posts.');
    await _loadPosts();
  }

  // Get filtered posts based on current view
  List<Post> get _filteredPosts {
    List<Post> filtered;

    if (_showAllPosts) {
      // Show only public posts in All Posts
      filtered = _posts.where((post) => post.isPublic).toList();
      print(
        'All Posts tab: ${filtered.length} public posts out of ${_posts.length} total posts',
      );
    } else {
      // Show all posts by current user in My Posts
      filtered = _posts
          .where((post) => post.authorId == _currentUserId)
          .toList();
      print(
        'My Posts tab: ${filtered.length} posts for user $_currentUserId out of ${_posts.length} total posts',
      );
    }

    return filtered;
  }

  // Add a new post to the list
  Future<void> _addNewPost(Post newPost) async {
    try {
      // Save to service
      await _postService.savePost(
        _currentUserId ?? newPost.authorId,
        newPost.toMap(),
      );

      if (mounted) {
        setState(() {
          _posts.removeWhere((p) => p.id == newPost.id);
          _posts.insert(0, newPost);
        });
      }

      print(
        'New post saved to service: "${newPost.title}" by ${newPost.authorName}',
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post "${newPost.title}" created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error adding new post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error saving post'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Handle like/unlike functionality
  Future<void> _toggleLike(Post post) async {
    if (_currentUserId == null) return;

    try {
      final isLiked = post.likedUsers.contains(_currentUserId);
      final updatedLikedUsers = List<String>.from(post.likedUsers);

      if (isLiked) {
        updatedLikedUsers.remove(_currentUserId);
      } else {
        updatedLikedUsers.add(_currentUserId!);
      }

      final updatedPost = post.copyWith(
        likes: updatedLikedUsers.length,
        likedUsers: updatedLikedUsers,
      );

      // Update in service
      await _postService.updatePostStats(
        post.authorId,
        post.id,
        likes: updatedPost.likes,
        likedUsers: updatedPost.likedUsers,
      );

      // Update local list
      setState(() {
        final index = _posts.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          _posts[index] = updatedPost;
        }
      });
    } catch (e) {
      print('Error toggling like: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error updating like')));
    }
  }

  // Handle comment functionality
  Future<void> _addComment(Post post) async {
    if (_currentUserId == null) return;

    final TextEditingController commentController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Comment'),
          content: TextField(
            controller: commentController,
            decoration: const InputDecoration(
              hintText: 'Write your comment...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(commentController.text),
              child: const Text('Comment'),
            ),
          ],
        );
      },
    );

    if (result != null && result.trim().isNotEmpty) {
      try {
        final updatedComments = List<String>.from(post.commentsList);
        final user = await _authService.getCurrentUser();
        final username = user?.username ?? 'Anonymous';
        final timestamp = DateTime.now().toIso8601String();
        updatedComments.add('$username: ${result.trim()} ($timestamp)');

        final updatedPost = post.copyWith(
          comments: updatedComments.length,
          commentsList: updatedComments,
        );

        // Update in service
        await _postService.updatePostStats(
          post.authorId,
          post.id,
          comments: updatedPost.commentsList,
        );

        // Update local list
        setState(() {
          final index = _posts.indexWhere((p) => p.id == post.id);
          if (index != -1) {
            _posts[index] = updatedPost;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment added successfully!')),
        );
      } catch (e) {
        print('Error adding comment: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error adding comment')));
      }
    }
  }

  // Update an existing post in the list
  void _updatePost(Post updatedPost) {
    setState(() {
      final index = _posts.indexWhere((post) => post.id == updatedPost.id);
      if (index != -1) {
        _posts[index] = updatedPost;
      }
    });
  }

  // Debug method to check current state
  void _debugCurrentState() {
    print('=== DEBUG CURRENT STATE ===');
    print('Current User ID: $_currentUserId');
    print('Show All Posts: $_showAllPosts');
    print('Total Posts in Memory: ${_posts.length}');
    print('Filtered Posts: ${_filteredPosts.length}');

    for (int i = 0; i < _posts.length; i++) {
      final post = _posts[i];
      print(
        'Post $i: "${post.title}" by ${post.authorName} (${post.authorId}) - Public: ${post.isPublic}',
      );
    }

    print('Filtered Posts:');
    for (int i = 0; i < _filteredPosts.length; i++) {
      final post = _filteredPosts[i];
      print(
        '  $i: "${post.title}" by ${post.authorName} (${post.authorId}) - Public: ${post.isPublic}',
      );
    }
    print('=== END DEBUG ===');
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: theme.appBarTheme.backgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  // App Title
                  Text('PorTuT', style: theme.textTheme.headlineLarge),
                  const Spacer(),
                  // Theme Toggle Button
                  GestureDetector(
                    onTap: () => themeProvider.toggleTheme(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        themeProvider.isDarkMode
                            ? Icons.light_mode
                            : Icons.dark_mode,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Refresh Button
                  GestureDetector(
                    onTap: _loadPosts,
                    onLongPress: _clearAllPosts,
                    onDoubleTap: _debugCurrentState,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.refresh,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Bookmark Icon
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BookmarksScreen(),
                        ),
                      );
                      _loadBookmarks();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.bookmark_border,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // User Profile Picture
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                    child: InitialsAvatar(
                      name: _currentUserId ?? 'User',
                      size: 40,
                      fontSize: 16,
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Tabs
            Container(
              color: theme.appBarTheme.backgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // All Posts Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showAllPosts = true;
                        });
                        _loadPosts();
                      },
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: _showAllPosts
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'All Posts',
                            style: TextStyle(
                              color: _showAllPosts
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // My Posts Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showAllPosts = false;
                        });
                        _loadPosts();
                      },
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: !_showAllPosts
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'My Posts',
                            style: TextStyle(
                              color: !_showAllPosts
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Posts List
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : _filteredPosts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _showAllPosts ? Icons.public : Icons.person,
                            size: 64,
                            color: theme.colorScheme.onBackground.withValues(
                              alpha: 0.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _showAllPosts
                                ? 'No public posts available'
                                : 'No posts yet',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.colorScheme.onBackground.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              _showAllPosts
                                  ? 'Public posts will appear here'
                                  : 'Create your first post!',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onBackground
                                    .withValues(alpha: 0.5),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPosts,
                      color: theme.colorScheme.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredPosts.length,
                        itemBuilder: (context, index) {
                          return _buildPostCard(_filteredPosts[index]);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
          // Handle the result from create post screen
          if (result != null && result is Post) {
            print('Received new post from create screen: ${result.title}');
            // Switch to "All Posts" to show the new post on the All posts screen
            setState(() {
              _showAllPosts = true;
            });
            await _addNewPost(result);
            // Force refresh to ensure posts are loaded correctly
            await _loadPosts();
          }
        },
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    final isLiked =
        _currentUserId != null && post.likedUsers.contains(_currentUserId);
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BlogPostScreen(post: post)),
        );
        // Handle the result from blog post screen
        if (result != null && result is Post) {
          _updatePost(result);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.onBackground.withValues(alpha: 0.05),
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
              // Post Title and Privacy Indicator
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      post.title,
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  if (!post.isPublic)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onBackground.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock,
                            size: 12,
                            color: theme.colorScheme.onBackground.withValues(
                              alpha: 0.6,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Private',
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onBackground.withValues(
                                alpha: 0.6,
                              ),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Post Content Snippet
              Text(
                post.description,
                style: theme.textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),

              // Author Information
              Row(
                children: [
                  // Author Initials Avatar
                  InitialsAvatar(
                    name: post.authorName,
                    size: 32,
                    fontSize: 12,
                  ),
                  const SizedBox(width: 8),
                  // Author Name
                  Expanded(
                    child: Text(
                      post.authorName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Dot separator
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onBackground,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Timestamp
                  Flexible(
                    child: Text(
                      _formatTimestamp(post.timestamp),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onBackground.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Interaction Icons
              Row(
                children: [
                  // Likes
                  GestureDetector(
                    onTap: () => _toggleLike(post),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked
                              ? Colors.red
                              : theme.colorScheme.onBackground,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          post.likes.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            color: isLiked
                                ? Colors.red
                                : theme.colorScheme.onBackground,
                            fontWeight: isLiked
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Comments
                  GestureDetector(
                    onTap: () => _addComment(post),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          color: theme.colorScheme.onBackground,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          post.comments.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onBackground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Bookmark
                  GestureDetector(
                    onTap: () => _toggleBookmark(post),
                    child: Icon(
                      _bookmarkedPostIds.contains(post.id)
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      color: _bookmarkedPostIds.contains(post.id)
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onBackground,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dateTime);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${(diff.inDays / 7).floor()}w ago';
    } catch (e) {
      return timestamp;
    }
  }
}
