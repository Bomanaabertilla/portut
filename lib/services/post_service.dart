import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PostService {
  static const String _postsKey = 'user_posts';

  // Save a new post
  Future<void> savePost(String userId, Map<String, dynamic> post) async {
    final prefs = await SharedPreferences.getInstance();
    final posts = await _getPosts(userId);
    posts.add(post);
    await prefs.setString('$_postsKey:$userId', jsonEncode(posts));
  }

  // Fetch user stats (posts count, total likes, total views, total comments)
  Future<Map<String, int>> getUserStats(String userId) async {
    try {
      final posts = await _getPosts(userId);
      int totalLikes = 0;
      int totalViews = 0;
      int totalComments = 0;

      for (var post in posts) {
        totalLikes += (post['likes'] ?? 0) as int;
        totalViews += (post['views'] ?? 0) as int;
        totalComments += (post['comments'] ?? []).length as int;
      }

      return {
        'posts': posts.length,
        'likes': totalLikes,
        'views': totalViews,
        'comments': totalComments, // Added for comment count
      };
    } catch (e) {
      print('Error fetching user stats: $e');
      return {'posts': 0, 'likes': 0, 'views': 0, 'comments': 0};
    }
  }

  // Update post stats (likes, views, likedUsers, bookmarkedUsers, comments)
  Future<void> updatePostStats(
    String userId,
    String postId, {
    int? likes,
    int? views,
    List<String>? likedUsers,
    List<String>? bookmarkedUsers,
    List<String>? comments,
  }) async {
    final posts = await _getPosts(userId);
    final updatedPosts = posts.map((post) {
      if (post['id'] == postId) {
        return {
          ...post,
          'likes': likes ?? post['likes'] ?? 0,
          'views': views ?? post['views'] ?? 0,
          'likedUsers': likedUsers ?? post['likedUsers'] ?? [],
          'bookmarkedUsers': bookmarkedUsers ?? post['bookmarkedUsers'] ?? [],
          'comments': comments ?? post['comments'] ?? [],
        };
      }
      return post;
    }).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_postsKey:$userId', jsonEncode(updatedPosts));
  }

  // Delete a post
  Future<void> deletePost(String userId, String postId) async {
    final posts = await _getPosts(userId);
    final updatedPosts = posts.where((post) => post['id'] != postId).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_postsKey:$userId', jsonEncode(updatedPosts));
  }

  // Get posts for a user
  Future<List<Map<String, dynamic>>> getPosts(String userId) async {
    return _getPosts(userId);
  }

  // Helper to get posts for a user
  Future<List<Map<String, dynamic>>> _getPosts(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final postsJson = prefs.getString('$_postsKey:$userId');
    if (postsJson == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(postsJson));
  }

  // Get all posts (for public posts or user-specific)
  Future<List<Map<String, dynamic>>> getAllPosts({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final userIds = keys
        .where((key) => key.startsWith(_postsKey))
        .map((key) => key.split(':').last)
        .toSet();

    final allPosts = <Map<String, dynamic>>[];
    for (final uid in userIds) {
      final posts = await _getPosts(uid);
      if (userId == null || userId == uid) {
        allPosts.addAll(posts);
      }
    }
    return allPosts;
  }
}