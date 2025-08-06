import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _controller = TextEditingController();
  final _authService = AuthService();
  bool _isSaving = false;

  Future<void> _savePost() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    final user = await _authService.getCurrentUser();
    final now = DateTime.now();
    final uuid = const Uuid().v4();

    final key = uuid;
    await prefs.setString('${key}_content', content);
    await prefs.setString('${key}_author', user?.username ?? 'Anonymous');
    await prefs.setString('${key}_timestamp', now.toIso8601String());
    await prefs.setString('${key}_visibility', 'Public');

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Create Post', style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 8,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Write your post here...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white),
                ),
                filled: true,
                fillColor: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _savePost,
              icon: const Icon(Icons.save),
              label: const Text('Post'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
