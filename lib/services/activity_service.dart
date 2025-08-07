import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ActivityService {
  static const String _activityKey = 'user_activity';

  // Update activity stats
  Future<void> updateUserActivity(
    String userId, {
    int posts = 0,
    int likes = 0,
    int comments = 0,
    int views = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final activityData = await getUserActivity(userId);

    final updatedActivity = {
      'posts': (activityData['posts'] ?? 0) + posts,
      'likes': (activityData['likes'] ?? 0) + likes,
      'comments': (activityData['comments'] ?? 0) + comments,
      'views': (activityData['views'] ?? 0) + views,
    };

    await prefs.setString('$_activityKey:$userId', jsonEncode(updatedActivity));
  }

  // Get activity stats for a user
  Future<Map<String, int>> getUserActivity(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('$_activityKey:$userId');
    if (data == null) {
      return {'posts': 0, 'likes': 0, 'comments': 0, 'views': 0};
    }

    final decoded = jsonDecode(data);
    return {
      'posts': decoded['posts'] ?? 0,
      'likes': decoded['likes'] ?? 0,
      'comments': decoded['comments'] ?? 0,
      'views': decoded['views'] ?? 0,
    };
  }

  // Optionally reset activity (if needed)
  Future<void> resetActivity(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_activityKey:$userId');
  }
}
