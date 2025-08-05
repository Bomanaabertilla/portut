import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class BlogPostScreen extends StatefulWidget {
  final String? postKey; // Pass postKey for editing, null for creating
  const BlogPostScreen({super.key, this.postKey});

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
  final _authService = AuthService();
  User? _currentUser;
  bool _isLoading = true;
  String? _currentFilePath; // New state variable to store the current file path

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadPostData();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPostData() async {
    if (widget.postKey != null && _currentUser != null) {
      final prefs = await SharedPreferences.getInstance();
      final author = prefs.getString('${widget.postKey}_author');
      if (author != _currentUser!.username) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You can only edit your own posts')),
          );
          Navigator.pop(context); // Return to previous screen
        }
        return;
      }
      _contentController.text =
          prefs.getString('${widget.postKey}_content') ?? '';
      _authorController.text = author ?? '';
      _isPublic = prefs.getString('${widget.postKey}_visibility') == 'Public';
      final filePath = prefs.getString('${widget.postKey}_file');
      if (filePath != null) {
        setState(() {
          _selectedFile = File(filePath);
          _currentFilePath = filePath; // Store the current file path in state
        });
      }
    }
  }

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

    final postKey = widget.postKey ?? 'post_$timestamp';
    await prefs.setString('${postKey}_content', content);
    await prefs.setString('${postKey}_author', author);
    await prefs.setString('${postKey}_timestamp', timestamp);
    await prefs.setString(
      '${postKey}_visibility',
      _isPublic ? 'Public' : 'Private',
    );
    if (filePath != null) {
      await prefs.setString('${postKey}_file', filePath);
    } else if (widget.postKey != null) {
      prefs.remove('${widget.postKey}_file');
    }

    setState(() {
      _successMessage = widget.postKey == null
          ? 'Post created successfully!'
          : 'Post updated successfully!';
      _contentController.clear();
      _authorController.clear();
      _selectedFile = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.postKey == null
              ? 'Post saved successfully!'
              : 'Post updated successfully!',
        ),
      ),
    );
    Navigator.pushNamedAndRemoveUntil(context, '/posts', (route) => false);
  }

  void _navigateToHome() {
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.postKey == null ? 'Create Blog Post' : 'Edit Blog Post',
        ),
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
                enabled:
                    widget.postKey ==
                    null, // Disable editing author for existing posts
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
                'Visibility: ${_isPublic ? 'Public' : 'Private'}',
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
              if (widget.postKey != null &&
                  _selectedFile == null &&
                  _currentFilePath != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Current File: ${_currentFilePath!.split('/').last}',
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _savePost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  widget.postKey == null ? 'Submit Post' : 'Update Post',
                ),
              ),
              if (_successMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _successMessage!,
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
              const SizedBox(height: 16),
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
