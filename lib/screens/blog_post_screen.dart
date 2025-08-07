import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:portut/services/post_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:portut/services/post_service.dart';
import 'package:portut/services/activity_service.dart';

class BlogPostScreen extends StatefulWidget {
  const BlogPostScreen({super.key});

  @override
  State<BlogPostScreen> createState() => _BlogPostScreenState();
}

class _BlogPostScreenState extends State<BlogPostScreen> {
  final TextEditingController _textController = TextEditingController();
  File? _pickedFile;
  String? _filePath;
  final PostService _postService = PostService();

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _filePath = result.files.single.path!;
        _pickedFile = File(_filePath!);
      });
    }
  }

  IconData _getFileIcon(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.attach_file;
    }
  }

  Future<void> _submitPost() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? 'default_user';

    final postId = DateTime.now().millisecondsSinceEpoch.toString();
    final newPost = {
      'id': postId,
      'text': _textController.text.trim(),
      'filePath': _filePath,
      'timestamp': DateTime.now().toIso8601String(),
      'likes': 0,
      'views': 0,
      'likedUsers': [],
      'bookmarkedUsers': [],
      'comments': [],
    };

    await _postService.savePost(userId, newPost);

    // Clear the form
    setState(() {
      _textController.clear();
      _pickedFile = null;
      _filePath = null;
    });

    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post submitted successfully!')),
    );
  }

  Widget _buildPreview() {
    if (_filePath == null) return const SizedBox.shrink();

    final icon = _getFileIcon(_filePath!);
    final name = _filePath!.split('/').last;

    return ListTile(
      leading: Icon(icon, size: 30),
      title: Text(name),
      trailing: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          setState(() {
            _filePath = null;
            _pickedFile = null;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPreview(),
            TextField(
              controller: _textController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Write something...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload File'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitPost,
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }
}
