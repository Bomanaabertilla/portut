import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';
import '../widgets/initials_avatar.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final List<PlatformFile> _selectedMedia = [];
  bool _isPickingMedia = false;
  String? _currentUserId;
  String _currentUserName = 'User';
  String _replyAudience = 'Everyone can reply';
  int _charCount = 0;
  static const int _maxChars = 280;

  final AuthService _authService = AuthService();
  final PostService _postService = PostService();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _contentController.addListener(() {
      setState(() {
        _charCount = _contentController.text.length;
      });
    });
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUserId = user?.username ?? 'current_user';
          _currentUserName = user?.displayName ?? (user?.username ?? 'User');
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _currentUserId = 'current_user';
          _currentUserName = 'User';
        });
      }
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia(FileType type, {List<String>? extensions}) async {
    if (_isPickingMedia) return;
    setState(() => _isPickingMedia = true);

    try {
      final files = await FilePicker.pickFiles(
        type: type,
        allowedExtensions: extensions,
      );

      if (files.isNotEmpty && mounted) {
        setState(() {
          for (final file in files) {
            final exists = _selectedMedia.any(
              (f) =>
                  (f.path != null && f.path == file.path) || f.name == file.name,
            );
            if (!exists) {
              _selectedMedia.add(file);
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick file: $e'),
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

  // --- Drafts Management ---
  Future<void> _saveDraft() async {
    if (_contentController.text.trim().isEmpty && _selectedMedia.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final drafts = prefs.getStringList('post_drafts') ?? [];
    drafts.insert(0, _contentController.text.trim());
    await prefs.setStringList('post_drafts', drafts);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draft saved'),
          backgroundColor: Color(0xFF1D9BF0),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _showDraftsSheet() async {
    final prefs = await SharedPreferences.getInstance();
    final drafts = prefs.getStringList('post_drafts') ?? [];

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16181C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Drafts',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (drafts.isNotEmpty)
                          TextButton(
                            onPressed: () async {
                              await prefs.remove('post_drafts');
                              setSheetState(() => drafts.clear());
                            },
                            child: const Text(
                              'Clear All',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                      ],
                    ),
                    const Divider(color: Color(0xFF2F3336)),
                    if (drafts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No saved drafts',
                            style: TextStyle(color: Color(0xFF71767B)),
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: drafts.length,
                          separatorBuilder: (_, __) =>
                              const Divider(color: Color(0xFF2F3336), height: 1),
                          itemBuilder: (context, i) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                drafts[i],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Color(0xFF71767B),
                                  size: 18,
                                ),
                                onPressed: () async {
                                  drafts.removeAt(i);
                                  await prefs.setStringList(
                                    'post_drafts',
                                    drafts,
                                  );
                                  setSheetState(() {});
                                },
                              ),
                              onTap: () {
                                _contentController.text = drafts[i];
                                Navigator.pop(ctx);
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- Reply Privacy Selection Sheet ---
  void _showReplyAudienceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16181C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Who can reply?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose who can reply to this post. Anyone mentioned can always reply.',
                  style: TextStyle(color: Color(0xFF71767B), fontSize: 13.5),
                ),
                const SizedBox(height: 16),
                _buildAudienceOption(
                  icon: Icons.public,
                  title: 'Everyone',
                  selected: _replyAudience == 'Everyone can reply',
                  onTap: () {
                    setState(() => _replyAudience = 'Everyone can reply');
                    Navigator.pop(ctx);
                  },
                ),
                _buildAudienceOption(
                  icon: Icons.people_outline,
                  title: 'Accounts you follow',
                  selected: _replyAudience == 'Accounts you follow can reply',
                  onTap: () {
                    setState(() => _replyAudience = 'Accounts you follow can reply');
                    Navigator.pop(ctx);
                  },
                ),
                _buildAudienceOption(
                  icon: Icons.alternate_email,
                  title: 'Only accounts you mention',
                  selected: _replyAudience == 'Only mentioned accounts can reply',
                  onTap: () {
                    setState(() => _replyAudience = 'Only mentioned accounts can reply');
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAudienceOption({
    required IconData icon,
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Color(0xFF1D9BF0),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check, color: Color(0xFF1D9BF0), size: 20)
          : null,
    );
  }

  Future<void> _publishPost() async {
    final text = _contentController.text.trim();
    if (text.isEmpty && _selectedMedia.isEmpty) return;

    final mediaUrls = _selectedMedia
        .map((f) => f.path ?? f.name)
        .where((p) => p.isNotEmpty)
        .toList();

    final newPost = Post(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '',
      description: text,
      authorName: _currentUserName,
      authorAvatar: '',
      timestamp: DateTime.now().toIso8601String(),
      likes: 0,
      comments: 0,
      isPublic: true,
      authorId: _currentUserId ?? 'current_user',
      mediaUrls: mediaUrls,
    );

    await _postService.savePost(
      _currentUserId ?? 'current_user',
      newPost.toMap(),
    );

    if (mounted) {
      Navigator.pop(context, newPost);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canPost = _contentController.text.trim().isNotEmpty ||
        _selectedMedia.isNotEmpty;
    final double progress = (_charCount / _maxChars).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // --- TOP BAR ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Close 'X' Button
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close, color: Colors.white, size: 26),
                    onPressed: () {
                      if (_contentController.text.trim().isNotEmpty) {
                        _showDiscardDialog();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const Spacer(),
                  // Drafts Button
                  TextButton(
                    onPressed: _showDraftsSheet,
                    child: const Text(
                      'Drafts',
                      style: TextStyle(
                        color: Color(0xFF1D9BF0),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Post Button
                  GestureDetector(
                    onTap: canPost ? _publishPost : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: canPost
                            ? const Color(0xFF1D9BF0)
                            : const Color(0xFF1D9BF0).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Post',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- MAIN COMPOSE BODY ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Avatar
                    InitialsAvatar(
                      name: _currentUserName,
                      size: 40,
                      fontSize: 15,
                    ),
                    const SizedBox(width: 12),
                    // Expanded Text Field & Media Previews
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _contentController,
                            autofocus: true,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              height: 1.35,
                            ),
                            decoration: const InputDecoration(
                              hintText: "What's happening?",
                              hintStyle: TextStyle(
                                color: Color(0xFF71767B),
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.only(top: 8, bottom: 12),
                            ),
                          ),

                          // Media previews grid
                          if (_selectedMedia.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: List.generate(_selectedMedia.length, (i) {
                                final file = _selectedMedia[i];
                                final isImage = _isImageFile(file);

                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        width: 100,
                                        height: 100,
                                        color: const Color(0xFF16181C),
                                        child: isImage &&
                                                file.path != null &&
                                                File(file.path!).existsSync()
                                            ? Image.file(
                                                File(file.path!),
                                                fit: BoxFit.cover,
                                              )
                                            : const Center(
                                                child: Icon(
                                                  Icons.insert_drive_file,
                                                  color: Colors.white70,
                                                  size: 32,
                                                ),
                                              ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => _removeMedia(i),
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.7),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- BOTTOM SECTION (Audience + Toolbar) ---
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Reply audience row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: GestureDetector(
                    onTap: _showReplyAudienceSheet,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.public,
                          color: Color(0xFF1D9BF0),
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _replyAudience,
                          style: const TextStyle(
                            color: Color(0xFF1D9BF0),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(
                  color: Color(0xFF2F3336),
                  height: 1,
                  thickness: 0.6,
                ),

                // Action Icons Row
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      // Media Gallery Icon
                      _buildToolbarIconButton(
                        icon: Icons.image_outlined,
                        onTap: () => _pickMedia(FileType.image),
                      ),
                      // Camera Icon
                      _buildToolbarIconButton(
                        icon: Icons.camera_alt_outlined,
                        onTap: () => _pickMedia(FileType.image),
                      ),
                      // Poll Icon
                      _buildToolbarIconButton(
                        icon: Icons.poll_outlined,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Polls feature coming soon'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      // GIF Badge
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('GIF selector coming soon'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF1D9BF0),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'GIF',
                            style: TextStyle(
                              color: Color(0xFF1D9BF0),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // Tune / Sliders Icon
                      _buildToolbarIconButton(
                        icon: Icons.tune_outlined,
                        onTap: () {},
                      ),
                      // Location Pin Icon
                      _buildToolbarIconButton(
                        icon: Icons.location_on_outlined,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Location attached'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),

                      const Spacer(),

                      // Vertical divider
                      Container(
                        height: 20,
                        width: 1,
                        color: const Color(0xFF2F3336),
                      ),
                      const SizedBox(width: 10),

                      // Circular Character Limit Ring
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 2.2,
                          backgroundColor: const Color(0xFF2F3336),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _charCount > _maxChars
                                ? Colors.red
                                : _charCount > 260
                                    ? Colors.orange
                                    : const Color(0xFF1D9BF0),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Blue Circular "+" Button
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Thread adding coming soon'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1D9BF0),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return IconButton(
      icon: Icon(icon, color: const Color(0xFF1D9BF0), size: 22),
      onPressed: onTap,
      splashRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      constraints: const BoxConstraints(),
    );
  }

  void _showDiscardDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16181C),
          title: const Text(
            'Save post as draft?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'You can save this to drafts or discard it.',
            style: TextStyle(color: Color(0xFF71767B)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Discard', style: TextStyle(color: Colors.redAccent)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D9BF0),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _saveDraft();
              },
              child: const Text('Save Draft', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
