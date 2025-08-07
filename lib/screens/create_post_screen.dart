import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import 'package:path/path.dart' as path;

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _controller = TextEditingController();
  final _authService = AuthService();
  bool _isSaving = false;
  File? _selectedFile;

  // File Picker Function
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      setState(() => _selectedFile = File(result.files.single.path!));
    }
  }

  // Save Post Function
  Future<void> _savePost() async {
    final content = _controller.text.trim();
    if (content.isEmpty && _selectedFile == null) return;

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

    if (_selectedFile != null) {
      await prefs.setString('${key}_file_path', _selectedFile!.path);
    }

    Navigator.pop(context);
  }

  // Get Icon for File
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

            // File preview
            if (_selectedFile != null)
              Row(
                children: [
                  Icon(
                    _getFileIcon(_selectedFile!.path),
                    color: Colors.deepPurpleAccent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      path.basename(_selectedFile!.path),
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.redAccent),
                    onPressed: () => setState(() => _selectedFile = null),
                  ),
                ],
              ),
            const SizedBox(height: 10),

            // File Upload Button
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Attach File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Save Post Button
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
