import 'package:flutter/material.dart';
import 'comment_screen.dart';
import 'home_screen.dart';

class Comment {
  final String id;
  final String userName;
  final String userAvatar;
  final String comment;
  final String timestamp;
  final List<Comment> replies;

  Comment({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.comment,
    required this.timestamp,
    this.replies = const [],
  });
}

class BlogPostScreen extends StatefulWidget {
  final Post? post; // Add post parameter to receive post data

  const BlogPostScreen({super.key, this.post});

  @override
  State<BlogPostScreen> createState() => _BlogPostScreenState();
}

class _BlogPostScreenState extends State<BlogPostScreen> {
  final _commentController = TextEditingController();
  final List<Comment> _comments = [
    Comment(
      id: '1',
      userName: 'Sarah Chen',
      userAvatar:
          'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=50&h=50&fit=crop&crop=face',
      comment:
          'Great explanation! The useState examples really helped me understand the concept better.',
      timestamp: '2h ago',
    ),
    Comment(
      id: '2',
      userName: 'Mike Rodriguez',
      userAvatar:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=50&h=50&fit=crop&crop=face',
      comment:
          'Could you cover useContext in your next post? I\'m struggling with prop drilling.',
      timestamp: '4h ago',
    ),
  ];

  bool _isPublic = true; // Default privacy setting
  final String _currentUserId = 'current_user';

  @override
  void initState() {
    super.initState();
    // Set initial privacy based on post data
    if (widget.post != null) {
      _isPublic = widget.post!.isPublic;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _addComment() {
    if (_commentController.text.trim().isNotEmpty) {
      setState(() {
        _comments.insert(
          0,
          Comment(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            userName: 'Current User',
            userAvatar:
                'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=50&h=50&fit=crop&crop=face',
            comment: _commentController.text.trim(),
            timestamp: 'Just now',
          ),
        );
      });
      _commentController.clear();
    }
  }

  void _replyToComment(String commentId) {
    // Handle reply functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reply functionality coming soon!')),
    );
  }

  void _togglePrivacy() {
    setState(() {
      _isPublic = !_isPublic;
    });

    // Show feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isPublic
              ? 'Post is now public and visible to everyone'
              : 'Post is now private and only visible to you',
        ),
        backgroundColor: _isPublic ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToHome() {
    // Return updated post data to home screen
    if (widget.post != null) {
      final updatedPost = Post(
        id: widget.post!.id,
        title: widget.post!.title,
        description: widget.post!.description,
        authorName: widget.post!.authorName,
        authorAvatar: widget.post!.authorAvatar,
        timestamp: widget.post!.timestamp,
        likes: widget.post!.likes,
        comments: widget.post!.comments,
        isPublic: _isPublic,
        authorId: widget.post!.authorId,
      );
      Navigator.pop(context, updatedPost);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final isCurrentUserPost = post?.authorId == _currentUserId;

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
                    onTap: _navigateToHome,
                    child: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF424242),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      post?.title ?? 'Complete Guide to React',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF424242),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 40), // Balance the back button
                ],
              ),
            ),

            // Privacy Toggle (only for current user's posts)
            if (isCurrentUserPost) ...[
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Text(
                      'Privacy:',
                      style: TextStyle(
                        color: Color(0xFF424242),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Toggle Switch
                    Row(
                      children: [
                        Text(
                          'Private',
                          style: TextStyle(
                            color: _isPublic
                                ? Colors.grey
                                : const Color(0xFF424242),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _togglePrivacy,
                          child: Container(
                            width: 40,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _isPublic
                                  ? const Color(0xFF8B4513)
                                  : Colors.grey,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  left: _isPublic ? 22 : 2,
                                  top: 2,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Public',
                          style: TextStyle(
                            color: _isPublic
                                ? const Color(0xFF8B4513)
                                : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Privacy indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _isPublic ? Colors.blue[50] : Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isPublic
                              ? Colors.blue[200]!
                              : Colors.orange[200]!,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isPublic ? Icons.public : Icons.lock,
                            size: 12,
                            color: _isPublic
                                ? Colors.blue[600]
                                : Colors.orange[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isPublic ? 'Public' : 'Private',
                            style: TextStyle(
                              fontSize: 10,
                              color: _isPublic
                                  ? Colors.blue[700]
                                  : Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: Colors.grey.withOpacity(0.2)),
            ],

            // Article Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Article Title
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post?.title ??
                                'Complete Guide to React Hooks and State Management',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF424242),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Author Information
                          Row(
                            children: [
                              // Author Profile Picture
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.2),
                                  ),
                                ),
                                child: ClipOval(
                                  child: Image.network(
                                    post?.authorAvatar ??
                                        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=50&h=50&fit=crop&crop=face',
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
                              const SizedBox(width: 12),
                              // Author Details
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post?.authorName ?? 'John Developer',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF424242),
                                    ),
                                  ),
                                  Text(
                                    post?.timestamp ?? 'March 15, 2024',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Main Article Image
                    Container(
                      width: double.infinity,
                      height: 200,
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          'https://images.unsplash.com/photo-1518709268805-4e9042af2176?w=400&h=200&fit=crop',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.image,
                                size: 60,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Article Content
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post?.description ??
                                'React Hooks have revolutionized the way we write React components. They allow us to use state and other React features without writing class components.',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF424242),
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'In this comprehensive guide, we\'ll explore the most commonly used hooks like useState, useEffect, useContext, and more. We\'ll also cover best practices and common patterns for state management in React applications.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF424242),
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Comments Section Header
                          const Text(
                            'Comments',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF424242),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Comments List
                          ...(_comments
                              .map(
                                (comment) => Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(16),
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
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // User info row
                                      Row(
                                        children: [
                                          // Profile picture
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.grey.withOpacity(
                                                  0.2,
                                                ),
                                              ),
                                            ),
                                            child: ClipOval(
                                              child: Image.network(
                                                comment.userAvatar,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
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
                                          const SizedBox(width: 12),
                                          // Username and timestamp
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  comment.userName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: Color(0xFF424242),
                                                  ),
                                                ),
                                                Text(
                                                  comment.timestamp,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // Comment text
                                      Text(
                                        comment.comment,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF424242),
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Reply button
                                      GestureDetector(
                                        onTap: () =>
                                            _replyToComment(comment.id),
                                        child: Text(
                                          'Reply',
                                          style: TextStyle(
                                            color: const Color(0xFF8B4513),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList()),

                          // Add Comment Section
                          Container(
                            padding: const EdgeInsets.all(16),
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
                            child: Row(
                              children: [
                                // Current user profile picture
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.grey.withOpacity(0.2),
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: Image.network(
                                      'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=50&h=50&fit=crop&crop=face',
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
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
                                const SizedBox(width: 12),
                                // Comment input field
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: TextField(
                                      controller: _commentController,
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: 'Add a comment...',
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                      ),
                                      maxLines: null,
                                      textInputAction: TextInputAction.send,
                                      onSubmitted: (_) => _addComment(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Post button
                                GestureDetector(
                                  onTap: _addComment,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF8B4513),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Post',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
