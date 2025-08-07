import 'package:flutter/material.dart';

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

class CommentScreen extends StatefulWidget {
  const CommentScreen({super.key});

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC), // Light beige background
      body: SafeArea(
        child: Column(
          children: [
            // Header with interaction icons
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Interaction icons row
                  Row(
                    children: [
                      // Heart icon with count
                      Row(
                        children: [
                          const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '24',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      // Speech bubble icon with count
                      Row(
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline,
                            color: Color(0xFF8B4513),
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '8',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Bookmark icon
                      const Icon(
                        Icons.bookmark_border,
                        color: Color(0xFF8B4513),
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Comments title
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF424242),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Comments List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _comments.length,
                itemBuilder: (context, index) {
                  final comment = _comments[index];
                  return Container(
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
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                  color: Colors.grey.withOpacity(0.2),
                                ),
                              ),
                              child: ClipOval(
                                child: Image.network(
                                  comment.userAvatar,
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
                            // Username and timestamp
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    comment.userName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.black87,
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
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Reply button
                        GestureDetector(
                          onTap: () => _replyToComment(comment.id),
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
                  );
                },
              ),
            ),

            // Add Comment Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
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
          ],
        ),
      ),
    );
  }
}
