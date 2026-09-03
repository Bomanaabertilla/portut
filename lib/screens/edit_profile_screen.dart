import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/auth_service.dart';
import '../widgets/initials_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _websiteController = TextEditingController();
  final _birthDateController = TextEditingController();

  bool _isLoading = false;
  String? _avatarPath;
  String? _coverPath;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await _authService.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _nameController.text = user.displayName;
        _bioController.text = user.bio ?? 'Nyame ne Hene. 💗';
        _locationController.text = user.location ?? 'Ghana';
        _websiteController.text = user.website ?? '';
        _birthDateController.text = user.birthDate ?? 'December 21, 2003';
        _avatarPath = user.avatarPath;
        _coverPath = user.coverPath;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({required bool isCover}) async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.image);
      if (result.isNotEmpty && result.first.path != null) {
        final path = result.first.path!;
        setState(() {
          if (isCover) {
            _coverPath = path;
          } else {
            _avatarPath = path;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _saveChanges(Color primaryColor) async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name cannot be empty'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        final updatedUser = user.copyWith(
          displayName: _nameController.text.trim(),
          bio: _bioController.text.trim(),
          location: _locationController.text.trim(),
          website: _websiteController.text.trim(),
          birthDate: _birthDateController.text.trim(),
          avatarPath: _avatarPath,
          coverPath: _coverPath,
        );

        await _authService.updateUserProfile(updatedUser);
      }
    } catch (e) {
      print('Error saving user profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile saved successfully!'),
            backgroundColor: primaryColor,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _selectBirthDate(Color primaryColor, Color cardBg, Color textColor) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2003, 12, 21),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: primaryColor,
                  onPrimary: Colors.white,
                  surface: cardBg,
                  onSurface: textColor,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      setState(() {
        _birthDateController.text =
            '${months[picked.month - 1]} ${picked.day}, ${picked.year}';
      });
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

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // --- TOP NAVIGATION BAR ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Close 'X' Button
                  IconButton(
                    icon: Icon(Icons.close, color: textColor, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  // Title
                  Text(
                    'Edit profile',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  // Save Button
                  GestureDetector(
                    onTap: _isLoading ? null : () => _saveChanges(primaryColor),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 6.5,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save',
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

            Divider(color: dividerColor, height: 1),

            // --- MAIN FORM BODY ---
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- COVER BANNER & AVATAR IMAGE SECTION ---
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Cover Banner Image
                        GestureDetector(
                          onTap: () => _pickImage(isCover: true),
                          child: Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF202327) : primaryColor.withValues(alpha: 0.6),
                              image: _coverPath != null && File(_coverPath!).existsSync()
                                  ? DecorationImage(
                                      image: FileImage(File(_coverPath!)),
                                      fit: BoxFit.cover,
                                    )
                                  : const DecorationImage(
                                      image: NetworkImage(
                                        'https://images.unsplash.com/photo-1617814076367-b759c7d7e738?auto=format&fit=crop&w=1200&q=80',
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Camera Add Icon
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.55),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add_a_photo_outlined,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                  if (_coverPath != null) ...[
                                    const SizedBox(width: 14),
                                    GestureDetector(
                                      onTap: () => setState(() => _coverPath = null),
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.55),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Avatar Image with Camera Overlay
                        Positioned(
                          bottom: -40,
                          left: 16,
                          child: GestureDetector(
                            onTap: () => _pickImage(isCover: false),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: scaffoldBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: InitialsAvatar(
                                    name: _nameController.text.isNotEmpty
                                        ? _nameController.text
                                        : 'User',
                                    size: 76,
                                    fontSize: 28,
                                    imagePath: _avatarPath,
                                  ),
                                ),
                                // Translucent camera overlay badge
                                Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add_a_photo_outlined,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 54),

                    // --- FORM FIELDS ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _buildProfileTextField(
                            label: 'Name',
                            controller: _nameController,
                            textColor: textColor,
                            hintColor: hintColor,
                            dividerColor: dividerColor,
                            primaryColor: primaryColor,
                          ),
                          const SizedBox(height: 20),
                          _buildProfileTextField(
                            label: 'Bio',
                            controller: _bioController,
                            maxLines: 3,
                            textColor: textColor,
                            hintColor: hintColor,
                            dividerColor: dividerColor,
                            primaryColor: primaryColor,
                          ),
                          const SizedBox(height: 20),
                          _buildProfileTextField(
                            label: 'Location',
                            controller: _locationController,
                            textColor: textColor,
                            hintColor: hintColor,
                            dividerColor: dividerColor,
                            primaryColor: primaryColor,
                          ),
                          const SizedBox(height: 20),
                          _buildProfileTextField(
                            label: 'Website',
                            controller: _websiteController,
                            textColor: textColor,
                            hintColor: hintColor,
                            dividerColor: dividerColor,
                            primaryColor: primaryColor,
                          ),
                          const SizedBox(height: 20),

                          // Birth Date Selector Field
                          GestureDetector(
                            onTap: () => _selectBirthDate(
                              primaryColor,
                              cardBg,
                              textColor,
                            ),
                            child: AbsorbPointer(
                              child: _buildProfileTextField(
                                label: 'Birth date',
                                controller: _birthDateController,
                                textColor: textColor,
                                hintColor: hintColor,
                                dividerColor: dividerColor,
                                primaryColor: primaryColor,
                                suffixIcon: Icon(
                                  Icons.chevron_right,
                                  color: hintColor,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Switch to Professional Row
                          Divider(color: dividerColor, height: 1),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Switch to Professional',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: hintColor,
                            ),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Professional tools coming soon'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                          Divider(color: dividerColor, height: 1),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    required Color textColor,
    required Color hintColor,
    required Color dividerColor,
    required Color primaryColor,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            color: hintColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: dividerColor, width: 1),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: primaryColor, width: 1.5),
            ),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
