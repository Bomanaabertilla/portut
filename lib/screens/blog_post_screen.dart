import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BlogPostScreen extends StatefulWidget {
  const BlogPostScreen({super.key});

  @override
  State<BlogPostScreen> createState() => _BlogPostScreenState();
}

class _BlogPostScreenState extends State<BlogPostScreen> {
  final List<Map<String, dynamic>> _posts = [];

  void _addPost(String content) {
    setState(() {
      _posts.insert(0, {
        'content': content,
        'likes': 0,
        'comments': <Map<String, String>>[],
        'bookmarked': false,
        'liked': false,
        'showComments': false,
      });
    });
    _showSnackBar('Post added');
  }

  void _toggleLike(int index) {
    setState(() {
      if (_posts[index]['liked']) {
        _posts[index]['likes']--;
        _showSnackBar('Like removed');
      } else {
        _posts[index]['likes']++;
        _showSnackBar('Post liked');
      }
      _posts[index]['liked'] = !_posts[index]['liked'];
    });
  }

  void _toggleBookmark(int index) {
    setState(() {
      _posts[index]['bookmarked'] = !_posts[index]['bookmarked'];
      _showSnackBar(
        _posts[index]['bookmarked'] ? 'Post bookmarked' : 'Bookmark removed',
      );
    });
  }

  void _addComment(int index, String user, String text) {
    final timestamp = DateFormat('MMM d, h:mm a').format(DateTime.now());
    setState(() {
      _posts[index]['comments'].add({
        'user': user,
        'text': text,
        'time': timestamp,
      });
    });
    _showSnackBar('Comment added');
  }

  void _showCommentDialog(int index) {
    String username = '';
    String comment = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Comment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Your Name'),
              onChanged: (value) => username = value,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Comment'),
              onChanged: (value) => comment = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (username.isNotEmpty && comment.isNotEmpty) {
                _addComment(index, username, comment);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  void _toggleComments(int index) {
    setState(() {
      _posts[index]['showComments'] = !_posts[index]['showComments'];
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    return parts.map((e) => e[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blog Posts')),
      body: ListView.builder(
        itemCount: _posts.length,
        itemBuilder: (ctx, index) {
          final post = _posts[index];
          return Card(
            margin: const EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post['content'], style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.favorite,
                          color: post['liked'] ? Colors.red : Colors.grey,
                        ),
                        onPressed: () => _toggleLike(index),
                      ),
                      Text('${post['likes']}'),
                      IconButton(
                        icon: const Icon(Icons.comment),
                        onPressed: () => _showCommentDialog(index),
                      ),
                      Text('${post['comments'].length}'),
                      IconButton(
                        icon: Icon(
                          Icons.bookmark,
                          color: post['bookmarked'] ? Colors.blue : Colors.grey,
                        ),
                        onPressed: () => _toggleBookmark(index),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _toggleComments(index),
                        child: Text(
                          post['showComments']
                              ? 'Hide Comments'
                              : 'Show Comments',
                        ),
                      ),
                    ],
                  ),
                  if (post['showComments'])
                    Column(
                      children: post['comments']
                          .map<Widget>(
                            (comment) => ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  _getInitials(comment['user']!),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              title: Text(comment['user']!),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(comment['text']!),
                                  Text(
                                    comment['time']!,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final controller = TextEditingController();
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('New Post'),
              content: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Write something...',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (controller.text.isNotEmpty) {
                      _addPost(controller.text);
                    }
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Post'),
                ),
              ],
            ),
          );
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
