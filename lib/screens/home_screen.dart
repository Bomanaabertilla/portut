import 'package:flutter/material.dart';
import 'create_post_screen.dart';
import 'profile_screen.dart';
import 'comment_screen.dart';
import 'blog_post_screen.dart';
import 'bookmarks_screen.dart';

class Post {
  final String id;
  final String title;
  final String description;
  final String authorName;
  final String authorAvatar;
  final String timestamp;
  final int likes;
  final int comments;

  Post({
    required this.id,
    required this.title,
    required this.description,
    required this.authorName,
    required this.authorAvatar,
    required this.timestamp,
    required this.likes,
    required this.comments,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showAllPosts = true; // Toggle between All Posts and My Posts

  final List<Post> _posts = [
    Post(
      id: '1',
      title: 'Building Responsive Layouts with Tailwind CSS',
      description:
          'Discover how to create beautiful, responsive designs using Tailwind CSS utility classes...',
      authorName: 'Mike Chen',
      authorAvatar:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=50&h=50&fit=crop&crop=face',
      timestamp: '1 day ago',
      likes: 18,
      comments: 6,
    ),
    Post(
      id: '2',
      title: 'JavaScript ES6 Features You Should Know',
      description:
          'Explore the most useful ES6 features that will make your JavaScript code more modern and efficient...',
      authorName: 'Emma Davis',
      authorAvatar:
          'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=50&h=50&fit=crop&crop=face',
      timestamp: '2 days ago',
      likes: 31,
      comments: 12,
    ),
  ];

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
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  return _buildPostCard(_posts[index]);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
        },
        backgroundColor: const Color(0xFF8B4513),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BlogPostScreen()),
        );
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
              // Post Title
              Text(
                post.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
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
                    post.timestamp,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Interaction Icons
              Row(
                children: [
                  // Likes
                  Row(
                    children: [
                      const Icon(
                        Icons.favorite_border,
                        color: Color(0xFF424242),
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        post.likes.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF424242),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  // Comments
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CommentScreen(),
                        ),
                      );
                    },
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
}
