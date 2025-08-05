import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
        print('Current User: ${_currentUser?.username}'); // Debug print
      });
    }
  }

  Future<void> _loadPosts() async {
    if (_currentUser == null) {
      print('No current user loaded'); // Debug print
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where((key) => key.startsWith('post_'))
        .toList();
    print('Found keys: $keys'); // Debug print
    final posts = <Map<String, String>>[];

    for (var key in keys) {
      final author = prefs.getString('${key}_author');
      print('Checking key $key, author: $author'); // Debug print
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
        print('Loaded posts: $_posts'); // Debug print
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Posts'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/create');
            },
            tooltip: 'Create New Post',
          ),
        ],
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
                        print(
                          'Navigating to edit for post key: ${post['key']}',
                        ); // Debug print
                        Navigator.pushNamed(
                          context,
                          '/create',
                          arguments: post['key'],
                        );
                      },
                      tooltip: 'Edit Post',
                    ),
                  ),
                );
              },
            ),
    );
  }
}
