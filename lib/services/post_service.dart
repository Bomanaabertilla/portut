import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:portut/utils/notifiers.dart';

class PostService {
  static const String _postsKey = 'user_posts';

  // Save a new post
  Future<void> savePost(String userId, Map<String, dynamic> post) async {
    final prefs = await SharedPreferences.getInstance();
    final posts = await _getPosts(userId);
    final updatedPost = {
      ...post,
      'comments': post['comments'] ?? [],
      'replies': post['replies'] ?? [],
    };
    posts.add(updatedPost);
    await prefs.setString('$_postsKey:$userId', jsonEncode(posts));
    print(
      'PostService: Saved post "${post['title']}" for user $userId. Total posts for user: ${posts.length}',
    );
    statsNotifier.notifyStatsChanged(); // Notify UI
  }

  // Fetch user stats (posts count, total likes, total views, total comments)
  Future<Map<String, int>> getUserStats(String userId) async {
    try {
      final posts = await _getPosts(userId);
      int totalLikes = 0;
      int totalViews = 0;
      int totalComments = 0;

      for (var post in posts) {
        totalLikes += (post['likes'] as num?)?.toInt() ?? 0;
        totalViews += (post['views'] as num?)?.toInt() ?? 0;
        final comments = post['comments'] as List? ?? [];
        totalComments += comments.length;
        final replies = post['replies'] as List? ?? [];
        totalComments += replies.length;
      }

      return {
        'posts': posts.length,
        'likes': totalLikes,
        'views': totalViews,
        'comments': totalComments,
      };
    } catch (e) {
      print('Error fetching user stats: $e');
      return {'posts': 0, 'likes': 0, 'views': 0, 'comments': 0};
    }
  }

  // Add a reply to a comment
  Future<void> addReply(
    String userId,
    String postId,
    int commentIndex,
    String reply,
    String username,
  ) async {
    final posts = await _getPosts(userId);
    final updatedPosts = posts.map((post) {
      if (post['id'] == postId) {
        final replies = List<String>.from(post['replies'] ?? []);
        final timestamp = DateTime.now().toIso8601String();
        replies.add(
          'reply_to_${commentIndex}_${username}: $reply ($timestamp)',
        );
        return {...post, 'replies': replies};
      }
      return post;
    }).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_postsKey:$userId', jsonEncode(updatedPosts));
    statsNotifier.notifyStatsChanged(); // Notify UI
  }

  // Update post stats (likes, views, likedUsers, bookmarkedUsers, comments, replies)
  Future<void> updatePostStats(
    String userId,
    String postId, {
    int? likes,
    int? views,
    List<String>? likedUsers,
    List<String>? bookmarkedUsers,
    List<String>? comments,
    List<String>? replies,
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
          'replies': replies ?? post['replies'] ?? [],
        };
      }
      return post;
    }).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_postsKey:$userId', jsonEncode(updatedPosts));
    statsNotifier.notifyStatsChanged(); // Notify UI
  }

  // Delete a post
  Future<void> deletePost(String userId, String postId) async {
    final posts = await _getPosts(userId);
    final updatedPosts = posts.where((post) => post['id'] != postId).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_postsKey:$userId', jsonEncode(updatedPosts));
    statsNotifier.notifyStatsChanged(); // Notify UI
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

    print('PostService: Found user IDs: $userIds');

    final allPosts = <Map<String, dynamic>>[];
    for (final uid in userIds) {
      final posts = await _getPosts(uid);
      print('PostService: User $uid has ${posts.length} posts');
      if (userId == null) {
        final publicPosts = posts
            .where((post) => post['visibility'] == 'Public')
            .toList();
        print('PostService: User $uid has ${publicPosts.length} public posts');
        allPosts.addAll(publicPosts);
      } else if (userId == uid) {
        allPosts.addAll(posts);
      }
    }

    print('PostService: Returning ${allPosts.length} total posts');
    return allPosts;
  }
}
