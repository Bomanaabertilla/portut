import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/post.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final List<PlatformFile> _selectedMedia = [];
  bool _isPickingMedia = false;
  bool _isPublic = true; // Toggle for visibility
  String? _currentUserId;
  String _currentUserName = 'Current User';

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUserId = user?.username ?? 'current_user';
          _currentUserName = user?.displayName ?? 'Current User';
        });
      }
    } catch (e) {
      print('Error loading current user: $e');
      setState(() {
        _currentUserId = 'current_user';
        _currentUserName = 'Current User';
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _uploadMedia() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Attach Media',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF424242),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B4513).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library, color: Color(0xFF8B4513)),
                ),
                title: const Text(
                  'Upload Images',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF424242)),
                ),
                subtitle: const Text('PNG, JPG, JPEG, WEBP, GIF'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickMedia(FileType.image);
                },
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                ),
                title: const Text(
                  'Upload PDF Document',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF424242)),
                ),
                subtitle: const Text('PDF documents and files'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickMedia(FileType.custom, extensions: ['pdf']);
                },
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.folder_open, color: Colors.blueAccent),
                ),
                title: const Text(
                  'Browse All Supported Files',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF424242)),
                ),
                subtitle: const Text('Images and PDF documents'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickMedia(
                    FileType.custom,
                    extensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'pdf'],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickMedia(FileType type, {List<String>? extensions}) async {
    setState(() => _isPickingMedia = true);

    try {
      final files = await FilePicker.pickFiles(
        type: type,
        allowedExtensions: extensions,
      );

      if (files.isNotEmpty && mounted) {
        int addedCount = 0;
        setState(() {
          for (final file in files) {
            final exists = _selectedMedia.any(
              (f) =>
                  (f.path != null && f.path == file.path) || f.name == file.name,
            );
            if (!exists) {
              _selectedMedia.add(file);
              addedCount++;
            }
          }
        });

        if (mounted && addedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$addedCount media file${addedCount == 1 ? '' : 's'} added',
              ),
              backgroundColor: const Color(0xFF8B4513),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick files: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingMedia = false);
      }
    }
  }

  void _removeMedia(int index) {
    if (index >= 0 && index < _selectedMedia.length) {
      setState(() {
        _selectedMedia.removeAt(index);
      });
    }
  }

  bool _isImageFile(PlatformFile file) {
    final ext = file.extension?.toLowerCase() ?? '';
    return ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'].contains(ext);
  }

  bool _isPdfFile(PlatformFile file) {
    final ext = file.extension?.toLowerCase() ?? '';
    return ext == 'pdf';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _publishPost() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title for your post'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write some content for your post'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final mediaUrls = _selectedMedia
        .map((f) => f.path ?? f.name)
        .where((p) => p.isNotEmpty)
        .toList();

    // Create new post
    final newPost = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _contentController.text.trim(),
      authorName: _currentUserName,
      authorAvatar: '',
      timestamp: DateTime.now().toIso8601String(),
      likes: 0,
      comments: 0,
      isPublic: _isPublic,
      authorId: _currentUserId ?? 'current_user',
      mediaUrls: mediaUrls,
    );

    print('Creating post: "${newPost.title}"');
    print('Author: ${newPost.authorName} (ID: ${newPost.authorId})');
    print('Public: ${newPost.isPublic}');
    print('Current user ID: $_currentUserId');

    // Save to PostService so it's immediately persisted
    final postService = PostService();
    await postService.savePost(
      _currentUserId ?? 'current_user',
      newPost.toMap(),
    );

    if (mounted) {
      // Return the post to the previous screen and navigate back
      Navigator.pop(context, newPost);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC), // Light beige background
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF424242),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Create Post',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF424242),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Section
                    const Text(
                      'Title',
                      style: TextStyle(
                        color: Color(0xFF424242),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _titleController,
                        style: const TextStyle(color: Colors.black),
                        decoration: const InputDecoration(
                          hintText: 'Enter your post title...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Content Section
                    const Text(
                      'Content',
                      style: TextStyle(
                        color: Color(0xFF424242),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _contentController,
                        decoration: const InputDecoration(
                          hintText: 'Write your post content here...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        maxLines: 8,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Media Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Media',
                          style: TextStyle(
                            color: Color(0xFF424242),
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        if (_selectedMedia.isNotEmpty)
                          Text(
                            '${_selectedMedia.length} attached',
                            style: const TextStyle(
                              color: Color(0xFF8B4513),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_selectedMedia.isNotEmpty) ...[
                      Column(
                        children: List.generate(_selectedMedia.length, (index) {
                          final file = _selectedMedia[index];
                          final isImage = _isImageFile(file);
                          final isPdf = _isPdfFile(file);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF8B4513).withValues(alpha: 0.2),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Thumbnail / Icon preview
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 52,
                                    height: 52,
                                    color: isImage
                                        ? const Color(0xFF8B4513).withValues(alpha: 0.08)
                                        : isPdf
                                            ? Colors.red.withValues(alpha: 0.08)
                                            : Colors.blue.withValues(alpha: 0.08),
                                    child: isImage &&
                                            file.path != null &&
                                            File(file.path!).existsSync()
                                        ? Image.file(
                                            File(file.path!),
                                            width: 52,
                                            height: 52,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => const Icon(
                                              Icons.image,
                                              color: Color(0xFF8B4513),
                                            ),
                                          )
                                        : Icon(
                                            isImage
                                                ? Icons.image
                                                : isPdf
                                                    ? Icons.picture_as_pdf
                                                    : Icons.insert_drive_file,
                                            color: isImage
                                                ? const Color(0xFF8B4513)
                                                : isPdf
                                                    ? Colors.redAccent
                                                    : Colors.blueAccent,
                                            size: 28,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        file.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: Color(0xFF424242),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isPdf
                                                  ? Colors.red.withValues(alpha: 0.1)
                                                  : const Color(0xFF8B4513).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              (file.extension ?? (isPdf ? 'PDF' : 'FILE')).toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: isPdf
                                                    ? Colors.red
                                                    : const Color(0xFF8B4513),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _formatFileSize(file.lengthSync() ?? 0),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Remove button
                                IconButton(
                                  icon: const Icon(
                                    Icons.cancel,
                                    color: Colors.grey,
                                    size: 22,
                                  ),
                                  onPressed: () => _removeMedia(index),
                                  tooltip: 'Remove',
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 6),
                      // Add more media button
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: _isPickingMedia ? null : _uploadMedia,
                          icon: const Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 20,
                            color: Color(0xFF8B4513),
                          ),
                          label: const Text(
                            'Add More Files',
                            style: TextStyle(
                              color: Color(0xFF8B4513),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF8B4513)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Empty state upload dropzone
                      GestureDetector(
                        onTap: _isPickingMedia ? null : _uploadMedia,
                        child: Container(
                          width: double.infinity,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF8B4513).withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _isPickingMedia
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Color(0xFF8B4513),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        'Opening file picker...',
                                        style: TextStyle(
                                          color: Color(0xFF8B4513),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF8B4513).withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.cloud_upload,
                                        color: Color(0xFF8B4513),
                                        size: 32,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Upload Images or PDFs',
                                      style: TextStyle(
                                        color: Color(0xFF8B4513),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Tap to select files from device',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Visibility Section
                    Row(
                      children: [
                        const Text(
                          'Visibility',
                          style: TextStyle(
                            color: Color(0xFF424242),
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        // Toggle Switch
                        Row(
                          children: [
                            Text(
                              'Private',
                              style: TextStyle(
                                color: _isPublic
                                    ? Colors.grey
                                    : const Color(0xFF424242),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isPublic = !_isPublic;
                                });
                              },
                              child: Container(
                                width: 48,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _isPublic
                                      ? const Color(0xFF8B4513)
                                      : Colors.grey,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: _isPublic ? 26 : 2,
                                      top: 2,
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Public',
                              style: TextStyle(
                                color: _isPublic
                                    ? const Color(0xFF8B4513)
                                    : Colors.grey,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Privacy Info
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isPublic ? Colors.blue[50] : Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isPublic
                              ? Colors.blue[200]!
                              : Colors.orange[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isPublic ? Icons.public : Icons.lock,
                            color: _isPublic
                                ? Colors.blue[600]
                                : Colors.orange[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isPublic
                                  ? 'This post will be visible to everyone in All Posts'
                                  : 'This post will only be visible to you in My Posts',
                              style: TextStyle(
                                fontSize: 12,
                                color: _isPublic
                                    ? Colors.blue[700]
                                    : Colors.orange[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Publish Post Button
            Container(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF8B4513), // Dark brown background
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B4513).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _publishPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Publish Post',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
