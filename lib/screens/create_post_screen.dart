import 'package:flutter/material.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  List<String> _uploadedFiles = [];
  bool _isPublic = true; // Toggle for visibility

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _uploadMedia() {
    // Handle media upload functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Media upload functionality coming soon!')),
    );
  }

  void _publishPost() {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write some content for your post'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Handle post publishing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Post published successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
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
                            color: Colors.black.withOpacity(0.05),
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
                    const Text(
                      'Media',
                      style: TextStyle(
                        color: Color(0xFF424242),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _uploadMedia,
                      child: Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                            style: BorderStyle.solid,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.cloud_upload,
                              color: Color(0xFF8B4513),
                              size: 32,
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
                          ],
                        ),
                      ),
                    ),
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

                    // Show uploaded files if any
                    if (_uploadedFiles.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Uploaded Files:',
                        style: TextStyle(
                          color: Color(0xFF424242),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...(_uploadedFiles
                          .map(
                            (file) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.attach_file,
                                    color: Color(0xFF8B4513),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      file,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _uploadedFiles.remove(file);
                                      });
                                    },
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList()),
                    ],
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
                      color: const Color(0xFF8B4513).withOpacity(0.3),
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
