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
  Future<void> _saveDraft(Color primaryColor) async {
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
        SnackBar(
          content: const Text('Draft saved'),
          backgroundColor: primaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _showDraftsSheet(
    bool isDark,
    Color primaryColor,
    Color cardBg,
    Color textColor,
    Color hintColor,
    Color dividerColor,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final drafts = prefs.getStringList('post_drafts') ?? [];

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
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
                        Text(
                          'Drafts',
                          style: TextStyle(
                            color: textColor,
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
                    Divider(color: dividerColor),
                    if (drafts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No saved drafts',
                            style: TextStyle(color: hintColor),
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: drafts.length,
                          separatorBuilder: (_, __) =>
                              Divider(color: dividerColor, height: 1),
                          itemBuilder: (context, i) {
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                drafts[i],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: textColor),
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.close,
                                  color: hintColor,
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
  void _showReplyAudienceSheet(
    Color cardBg,
    Color textColor,
    Color hintColor,
    Color primaryColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
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
                Text(
                  'Who can reply?',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose who can reply to this post. Anyone mentioned can always reply.',
                  style: TextStyle(color: hintColor, fontSize: 13.5),
                ),
                const SizedBox(height: 16),
                _buildAudienceOption(
                  icon: Icons.public,
                  title: 'Everyone',
                  selected: _replyAudience == 'Everyone can reply',
                  textColor: textColor,
                  primaryColor: primaryColor,
                  onTap: () {
                    setState(() => _replyAudience = 'Everyone can reply');
                    Navigator.pop(ctx);
                  },
                ),
                _buildAudienceOption(
                  icon: Icons.people_outline,
                  title: 'Accounts you follow',
                  selected: _replyAudience == 'Accounts you follow can reply',
                  textColor: textColor,
                  primaryColor: primaryColor,
                  onTap: () {
                    setState(() => _replyAudience = 'Accounts you follow can reply');
                    Navigator.pop(ctx);
                  },
                ),
                _buildAudienceOption(
                  icon: Icons.alternate_email,
                  title: 'Only accounts you mention',
                  selected: _replyAudience == 'Only mentioned accounts can reply',
                  textColor: textColor,
                  primaryColor: primaryColor,
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
    required Color textColor,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: selected
          ? Icon(Icons.check, color: primaryColor, size: 20)
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF1D9BF0) : theme.colorScheme.primary;
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : const Color(0xFF424242);
    final hintColor = isDark ? const Color(0xFF71767B) : Colors.grey[600]!;
    final dividerColor = isDark ? const Color(0xFF2F3336) : Colors.black.withValues(alpha: 0.12);
    final cardBg = isDark ? const Color(0xFF16181C) : Colors.white;

    final bool canPost = _contentController.text.trim().isNotEmpty ||
        _selectedMedia.isNotEmpty;
    final double progress = (_charCount / _maxChars).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: scaffoldBg,
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
                    icon: Icon(Icons.close, color: textColor, size: 26),
                    onPressed: () {
                      if (_contentController.text.trim().isNotEmpty) {
                        _showDiscardDialog(cardBg, textColor, hintColor, primaryColor);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const Spacer(),
                  // Drafts Button
                  TextButton(
                    onPressed: () => _showDraftsSheet(
                      isDark,
                      primaryColor,
                      cardBg,
                      textColor,
                      hintColor,
                      dividerColor,
                    ),
                    child: Text(
                      'Drafts',
                      style: TextStyle(
                        color: primaryColor,
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
                            ? primaryColor
                            : primaryColor.withValues(alpha: 0.5),
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
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              height: 1.35,
                            ),
                            decoration: InputDecoration(
                              hintText: "What's happening?",
                              hintStyle: TextStyle(
                                color: hintColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.only(top: 8, bottom: 12),
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
                                        color: cardBg,
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
                                                  color: Colors.grey,
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
                    onTap: () => _showReplyAudienceSheet(
                      cardBg,
                      textColor,
                      hintColor,
                      primaryColor,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.public,
                          color: primaryColor,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _replyAudience,
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Divider(
                  color: dividerColor,
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
                        color: primaryColor,
                        onTap: () => _pickMedia(FileType.image),
                      ),
                      // Camera Icon
                      _buildToolbarIconButton(
                        icon: Icons.camera_alt_outlined,
                        color: primaryColor,
                        onTap: () => _pickMedia(FileType.image),
                      ),
                      // Poll Icon
                      _buildToolbarIconButton(
                        icon: Icons.poll_outlined,
                        color: primaryColor,
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
                              color: primaryColor,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'GIF',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // Tune / Sliders Icon
                      _buildToolbarIconButton(
                        icon: Icons.tune_outlined,
                        color: primaryColor,
                        onTap: () {},
                      ),
                      // Location Pin Icon
                      _buildToolbarIconButton(
                        icon: Icons.location_on_outlined,
                        color: primaryColor,
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
                        color: dividerColor,
                      ),
                      const SizedBox(width: 10),

                      // Circular Character Limit Ring
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 2.2,
                          backgroundColor: dividerColor,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _charCount > _maxChars
                                ? Colors.red
                                : _charCount > 260
                                    ? Colors.orange
                                    : primaryColor,
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
                          decoration: BoxDecoration(
                            color: primaryColor,
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
    required Color color,
    required VoidCallback onTap,
  }) {
    return IconButton(
      icon: Icon(icon, color: color, size: 22),
      onPressed: onTap,
      splashRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      constraints: const BoxConstraints(),
    );
  }

  void _showDiscardDialog(
    Color cardBg,
    Color textColor,
    Color hintColor,
    Color primaryColor,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: cardBg,
          title: Text(
            'Save post as draft?',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'You can save this to drafts or discard it.',
            style: TextStyle(color: hintColor),
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
                backgroundColor: primaryColor,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _saveDraft(primaryColor);
              },
              child: const Text('Save Draft', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
