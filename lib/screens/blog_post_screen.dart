import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

class BlogPostScreen extends StatefulWidget {
  const BlogPostScreen({super.key});

  @override
  State<BlogPostScreen> createState() => _BlogPostScreenState();
}

class _BlogPostScreenState extends State<BlogPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _authorController = TextEditingController();
  File? _selectedFile;
  String? _successMessage;
  bool _isPublic = true; // Default to Public (true), false for Private

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'pdf', 'doc', 'docx'],
      );
      if (result != null &&
          result.files.isNotEmpty &&
          result.files.first.path != null) {
        setState(() {
          _selectedFile = File(result.files.first.path!);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick file: $e')));
    }
  }

  Future<void> _savePost() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final timestamp = DateTime.now().toIso8601String();
    final author = _authorController.text.trim();
    final content = _contentController.text.trim();
    final filePath = _selectedFile?.path;

    if (content.isEmpty && filePath == null) {
      setState(() {
        _successMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide text or a file')),
      );
      return;
    }

    final postKey = 'post_$timestamp';
    await prefs.setString('${postKey}_content', content);
    await prefs.setString('${postKey}_author', author);
    await prefs.setString('${postKey}_timestamp', timestamp);
    await prefs.setString(
      '${postKey}_visibility',
      _isPublic ? 'Public' : 'Private',
    ); // Save visibility
    if (filePath != null) {
      await prefs.setString('${postKey}_file', filePath);
    }

    setState(() {
      _successMessage = 'Post created successfully!';
      _contentController.clear();
      _authorController.clear();
      _selectedFile = null;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Post saved successfully!')));
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/posts',
      (route) => false,
    ); // Navigate to PostListScreen
  }

  void _navigateToHome() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/',
      (route) => false,
    ); // Navigate to HomeScreen (root)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Blog Post'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _navigateToHome,
          tooltip: 'Back to Home',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(labelText: 'Author'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) => null, // No validation, optional field
              ),
              const SizedBox(height: 16),
              const Text('Visibility:', style: TextStyle(fontSize: 16)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Private'),
                  Switch(
                    value: _isPublic,
                    onChanged: (value) {
                      setState(() {
                        _isPublic = value;
                      });
                    },
                  ),
                  const Text('Public'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Visibility: ${_isPublic ? 'Public' : 'Private'}', // Indicate chosen visibility
                style: const TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Upload File'),
              ),
              if (_selectedFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Selected: ${_selectedFile!.path.split('/').last}',
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _savePost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Submit Post'),
              ),
              if (_successMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _successMessage!,
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
              const SizedBox(height: 16), // Spacing for new button
              ElevatedButton(
                onPressed: _navigateToHome,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
