import 'package:flutter/material.dart';
import 'create_post_screen.dart';
import 'profile_screen.dart';
import 'blog_post_screen.dart';
import 'bookmarks_screen.dart';
import '../services/post_service.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Post {
  final String id;
  final String title;
  final String description;
  final String authorName;
  final String authorAvatar;
  final String timestamp;
  final int likes;
  final int comments;
  final bool isPublic;
  final String authorId;
  final List<String> likedUsers;
  final List<String> commentsList;

  Post({
    required this.id,
    required this.title,
    required this.description,
    required this.authorName,
    required this.authorAvatar,
    required this.timestamp,
    required this.likes,
    required this.comments,
    required this.isPublic,
    required this.authorId,
    this.likedUsers = const [],
    this.commentsList = const [],
  });

  // Factory constructor to create Post from Map
  factory Post.fromMap(Map<String, dynamic> map, String authorId) {
    return Post(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['content'] ?? map['description'] ?? '',
      authorName: map['authorName'] ?? map['author'] ?? 'Unknown',
      authorAvatar:
          map['authorAvatar'] ??
          'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=50&h=50&fit=crop&crop=face',
      timestamp: map['timestamp'] ?? DateTime.now().toIso8601String(),
      likes: (map['likes'] as num?)?.toInt() ?? 0,
      comments: (map['comments'] as List?)?.length ?? 0,
      isPublic: map['visibility'] == 'Public' || map['isPublic'] == true,
      authorId: authorId,
      likedUsers: List<String>.from(map['likedUsers'] ?? []),
      commentsList: List<String>.from(map['comments'] ?? []),
    );
  }

  // Convert Post to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': description,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'timestamp': timestamp,
      'likes': likes,
      'comments': commentsList,
      'visibility': isPublic ? 'Public' : 'Private',
      'likedUsers': likedUsers,
    };
  }

  // Create a copy with updated properties
  Post copyWith({
    String? id,
    String? title,
    String? description,
    String? authorName,
    String? authorAvatar,
    String? timestamp,
    int? likes,
    int? comments,
    bool? isPublic,
    String? authorId,
    List<String>? likedUsers,
    List<String>? commentsList,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      timestamp: timestamp ?? this.timestamp,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      isPublic: isPublic ?? this.isPublic,
      authorId: authorId ?? this.authorId,
      likedUsers: likedUsers ?? this.likedUsers,
      commentsList: commentsList ?? this.commentsList,
    );
  }
}

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

  final PostService _postService = PostService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUserId = user?.username ?? 'current_user';
        });
        print('Current user ID set to: $_currentUserId');
        await _loadPosts();
      }
    } catch (e) {
      print('Error loading current user: $e');
      setState(() {
        _currentUserId = 'current_user';
      });
      print('Current user ID set to fallback: $_currentUserId');
      await _loadPosts();
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
        print('Loading all posts. Found ${postsData.length} posts');
      } else {
        // Load current user's posts (both public and private)
        if (_currentUserId != null) {
          postsData = await _postService.getPosts(_currentUserId!);
          print(
            'Loading user posts for $_currentUserId. Found ${postsData.length} posts',
          );
        } else {
          postsData = [];
          print('No current user ID available');
        }
      }

      // If no posts exist, initialize with sample posts
      if (postsData.isEmpty) {
        print('No posts found, initializing sample posts...');
        await _initializeSamplePosts();
        // Reload posts after initialization
        if (_showAllPosts) {
          postsData = await _postService.getAllPosts();
          print('After initialization - All posts: ${postsData.length}');
        } else {
          if (_currentUserId != null) {
            postsData = await _postService.getPosts(_currentUserId!);
            print('After initialization - User posts: ${postsData.length}');
          } else {
            postsData = [];
          }
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
        print('Final posts count: ${_posts.length}');
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

  // Initialize sample posts if none exist
  Future<void> _initializeSamplePosts() async {
    final currentUserId = _currentUserId ?? 'current_user';

    final samplePosts = [
      {
        'id': '1',
        'title': 'Building Responsive Layouts with Tailwind CSS',
        'content':
            'Discover how to create beautiful, responsive designs using Tailwind CSS utility classes. This comprehensive guide covers everything from basic setup to advanced techniques for creating modern web applications.',
        'authorName': 'Mike Chen',
        'authorAvatar':
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=50&h=50&fit=crop&crop=face',
        'timestamp': DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
        'likes': 18,
        'comments': [],
        'visibility': 'Public',
        'likedUsers': [],
        'authorId': 'mike_chen',
      },
      {
        'id': '2',
        'title': 'JavaScript ES6 Features You Should Know',
        'content':
            'Explore the most useful ES6 features that will make your JavaScript code more modern and efficient. From arrow functions to destructuring, learn how to write cleaner and more maintainable code.',
        'authorName': 'Emma Davis',
        'authorAvatar':
            'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=50&h=50&fit=crop&crop=face',
        'timestamp': DateTime.now()
            .subtract(const Duration(days: 2))
            .toIso8601String(),
        'likes': 31,
        'comments': [],
        'visibility': 'Public',
        'likedUsers': [],
        'authorId': 'emma_davis',
      },
      {
        'id': '3',
        'title': 'My Private Thoughts on Flutter',
        'content':
            'This is a private post that should only be visible to me in My Posts section. Here I share my personal thoughts about Flutter development and my learning journey.',
        'authorName': 'Current User',
        'authorAvatar':
            'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=50&h=50&fit=crop&crop=face',
        'timestamp': DateTime.now()
            .subtract(const Duration(hours: 3))
            .toIso8601String(),
        'likes': 0,
        'comments': [],
        'visibility': 'Private',
        'likedUsers': [],
        'authorId': currentUserId,
      },
    ];

    // Save sample posts to their respective authors
    for (final post in samplePosts) {
      final authorId = post['authorId'] as String;
      await _postService.savePost(authorId, post);
    }

    print(
      'Sample posts initialized for authors: ${samplePosts.map((p) => p['authorId']).toList()}',
    );
    print('Current user ID: $currentUserId');
  }

  // Clear all posts and reinitialize (for testing)
  Future<void> _clearAndReinitializePosts() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final postKeys = keys
        .where((key) => key.startsWith('user_posts:'))
        .toList();

    for (final key in postKeys) {
      await prefs.remove(key);
    }

    print('Cleared all posts. Reinitializing...');
    await _initializeSamplePosts();
    await _loadPosts();
  }

  // Get filtered posts based on current view
  List<Post> get _filteredPosts {
    if (_showAllPosts) {
      // Show only public posts in All Posts
      return _posts.where((post) => post.isPublic).toList();
    } else {
      // Show all posts by current user in My Posts
      return _posts.where((post) => post.authorId == _currentUserId).toList();
    }
  }

  // Add a new post to the list
  Future<void> _addNewPost(Post newPost) async {
    try {
      // Save to service
      await _postService.savePost(
        _currentUserId ?? 'current_user',
        newPost.toMap(),
      );

      // Update local list
      setState(() {
        _posts.insert(0, newPost);
      });
    } catch (e) {
      print('Error adding new post: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error saving post')));
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
                  // App Title
                  const Text(
                    'PorTuT',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B4513), // Dark brown
                    ),
                  ),
                  const Spacer(),
                  // Refresh Button
                  GestureDetector(
                    onTap: _loadPosts,
                    onLongPress: _clearAndReinitializePosts,
                    child: const Icon(
                      Icons.refresh,
                      color: Color(0xFF8B4513),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Bookmark Icon
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BookmarksScreen(),
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.bookmark_border,
                      color: Color(0xFF8B4513),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
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
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: ClipOval(
                        child: Image.network(
                          'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=50&h=50&fit=crop&crop=face',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.person,
                                size: 24,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Tabs
            Container(
              color: Colors.white,
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
                              ? const Color(0xFF8B4513)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF8B4513),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'All Posts',
                            style: TextStyle(
                              color: _showAllPosts
                                  ? Colors.white
                                  : const Color(0xFF8B4513),
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
                              ? const Color(0xFF8B4513)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF8B4513),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'My Posts',
                            style: TextStyle(
                              color: !_showAllPosts
                                  ? Colors.white
                                  : const Color(0xFF8B4513),
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
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF8B4513),
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
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _showAllPosts
                                ? 'No public posts available'
                                : 'No posts yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _showAllPosts
                                ? 'Public posts will appear here'
                                : 'Create your first post!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPosts,
                      color: const Color(0xFF8B4513),
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
            await _addNewPost(result);
          }
        },
        backgroundColor: const Color(0xFF8B4513),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    final isLiked =
        _currentUserId != null && post.likedUsers.contains(_currentUserId);

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
              // Post Title and Privacy Indicator
              Row(
                children: [
                  Expanded(
                    child: Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF424242),
                      ),
                    ),
                  ),
                  if (!post.isPublic)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Private',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
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
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF424242),
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),

              // Author Information
              Row(
                children: [
                  // Author Profile Picture
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        post.authorAvatar,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.person,
                              size: 20,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Author Name
                  Text(
                    post.authorName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF424242),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Dot separator
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xFF424242),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Timestamp
                  Text(
                    _formatTimestamp(post.timestamp),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : const Color(0xFF424242),
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          post.likes.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            color: isLiked
                                ? Colors.red
                                : const Color(0xFF424242),
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
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          color: Color(0xFF424242),
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          post.comments.toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF424242),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Bookmark
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Post bookmarked!')),
                      );
                    },
                    child: const Icon(
                      Icons.bookmark_border,
                      color: Color(0xFF424242),
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
