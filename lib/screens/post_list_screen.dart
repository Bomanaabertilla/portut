import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class PostListScreen extends StatefulWidget {
  const PostListScreen({super.key});

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  final _authService = AuthService();
  dynamic _currentUser;
  List<Map<String, String>> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadPosts();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  Future<void> _loadPosts() async {
    if (_currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where((key) => key.startsWith('post_'))
        .toList();
    final posts = <Map<String, String>>[];

    for (var key in keys) {
      final author = prefs.getString('${key}_author');
      if (author == _currentUser!.username) {
        posts.add({
          'key': key,
          'content': prefs.getString('${key}_content') ?? '',
          'author': author ?? '',
          'timestamp': prefs.getString('${key}_timestamp') ?? '',
          'visibility': prefs.getString('${key}_visibility') ?? 'Public',
          'file': prefs.getString('${key}_file') ?? '',
        });
      }
    }

    if (mounted) {
      setState(() {
        _posts = posts;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Posts'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
          ? const Center(child: Text('No posts yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                final post = _posts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: ListTile(
                    title: Text(
                      post['content']!.isNotEmpty
                          ? post['content']!
                          : 'No content',
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Author: ${post['author']}'),
                        Text('Visibility: ${post['visibility']}'),
                        Text('Date: ${post['timestamp']}'),
                        if (post['file']!.isNotEmpty)
                          Text('File: ${post['file']!.split('/').last}'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/create',
                          arguments: post['key'],
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
