import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'login_screen.dart';
import 'create_post_screen.dart';
import '../models/user.dart';
import '../models/post.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';
import '../widgets/initials_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  List<Post> _userPosts = [];
  bool _isLoading = true;
  int _selectedTabIndex = 0; // 0=Posts, 1=Replies, 2=Reposts, 3=Media

  final AuthService _authService = AuthService();
  final PostService _postService = PostService();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.getCurrentUser();
      List<Post> posts = [];
      if (user != null) {
        final rawPosts = await _postService.getAllPosts(userId: user.username);
        posts = rawPosts
            .map((p) => Post.fromMap(p, user.username))
            .toList();
        posts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
      if (mounted) {
        setState(() {
          _user = user;
          _userPosts = posts;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _navigateToEditProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
    );
    _loadProfileData();
  }

  void _navigateToChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF16181C) : Colors.white,
          title: Text(
            'Log Out',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF424242),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xFF424242),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _authService.logout();
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              child: const Text('Log Out', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }

  void _showProfileOptionsMenu(Color primaryColor, Color textColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF16181C)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit, color: primaryColor),
                title: Text('Edit Profile', style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.pop(ctx);
                  _navigateToEditProfile();
                },
              ),
              ListTile(
                leading: Icon(Icons.lock_outline, color: primaryColor),
                title: Text('Change Password', style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.pop(ctx);
                  _navigateToChangePassword();
                },
              ),
              ListTile(
                leading: Icon(Icons.share_outlined, color: primaryColor),
                title: Text('Share Profile', style: TextStyle(color: textColor)),
                onTap: () {
                  Navigator.pop(ctx);
                  SharePlus.instance.share(
                    ShareParams(
                      text: 'Check out ${_user?.displayName ?? "User"}\'s profile on PorTuT: @${_user?.username ?? ""}',
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Log Out', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(ctx);
                  _logout();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF1D9BF0) : theme.colorScheme.primary;
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : const Color(0xFF424242);
    final subtextColor = isDark ? const Color(0xFF71767B) : Colors.grey[600]!;
    final dividerColor = isDark ? const Color(0xFF2F3336) : Colors.black.withValues(alpha: 0.1);

    final displayName = _user?.displayName.isNotEmpty == true
        ? _user!.displayName
        : (_user?.username ?? 'User');
    final username = _user?.username ?? 'user';

    return Scaffold(
      backgroundColor: scaffoldBg,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
          );
          if (result != null && result is Post) {
            _loadProfileData();
          }
        },
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 28),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              color: primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- COVER IMAGE & OVERLAPPING AVATAR ---
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Cover Image Banner
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E1E) : primaryColor.withValues(alpha: 0.8),
                            image: _user?.coverPath != null && File(_user!.coverPath!).existsSync()
                                ? DecorationImage(
                                    image: FileImage(File(_user!.coverPath!)),
                                    fit: BoxFit.cover,
                                  )
                                : const DecorationImage(
                                    image: NetworkImage(
                                      'https://images.unsplash.com/photo-1617814076367-b759c7d7e738?auto=format&fit=crop&w=1200&q=80',
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),

                        // Top Action Icons
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 6,
                          left: 12,
                          right: 12,
                          child: Row(
                            children: [
                              // Back Arrow Button
                              _buildCircleIconButton(
                                icon: Icons.arrow_back,
                                onTap: () => Navigator.pop(context),
                              ),
                              const Spacer(),
                              // Notifications / Block Icon
                              _buildCircleIconButton(
                                icon: Icons.block_outlined,
                                onTap: () {},
                              ),
                              const SizedBox(width: 8),
                              // Search Icon
                              _buildCircleIconButton(
                                icon: Icons.search,
                                onTap: () {},
                              ),
                              const SizedBox(width: 8),
                              // Options Menu Icon
                              _buildCircleIconButton(
                                icon: Icons.more_vert,
                                onTap: () => _showProfileOptionsMenu(primaryColor, textColor),
                              ),
                            ],
                          ),
                        ),

                        // Overlapping Avatar
                        Positioned(
                          bottom: -40,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: scaffoldBg,
                              shape: BoxShape.circle,
                            ),
                            child: InitialsAvatar(
                              name: displayName,
                              size: 76,
                              fontSize: 28,
                              imagePath: _user?.avatarPath,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 48),

                    // --- HEADER INFO (Name, Handle, Bio, Stats, Action Buttons) ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Display Name & "Get verified" Row
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  displayName,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // "Get verified" badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF536471)
                                        : primaryColor,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified,
                                      color: isDark
                                          ? const Color(0xFF1D9BF0)
                                          : primaryColor,
                                      size: 15,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Get verified',
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Handle (@username)
                          const SizedBox(height: 2),
                          Text(
                            '@$username',
                            style: TextStyle(
                              fontSize: 14,
                              color: subtextColor,
                            ),
                          ),

                          // Bio
                          if ((_user?.bio ?? 'Nyame ne Hene. 💗').isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              _user?.bio ?? 'Nyame ne Hene. 💗',
                              style: TextStyle(
                                fontSize: 14.5,
                                color: textColor,
                              ),
                            ),
                          ],

                          // Location & Birth Date Info
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if ((_user?.location ?? 'Ghana').isNotEmpty) ...[
                                Icon(
                                  Icons.location_on_outlined,
                                  color: subtextColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _user?.location ?? 'Ghana',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: subtextColor,
                                  ),
                                ),
                                const SizedBox(width: 14),
                              ],
                              Icon(
                                Icons.cake_outlined,
                                color: subtextColor,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _user?.birthDate != null && _user!.birthDate!.isNotEmpty
                                    ? 'Born ${_user!.birthDate}'
                                    : 'Born December 21, 2003',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: subtextColor,
                                ),
                              ),
                            ],
                          ),

                          // Joined Date Row
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                color: subtextColor,
                                size: 15,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Joined March 2025',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: subtextColor,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right,
                                color: subtextColor,
                                size: 16,
                              ),
                            ],
                          ),

                          // Stats Row (Following / Followers)
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Text(
                                '82 ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  fontSize: 14.5,
                                ),
                              ),
                              Text(
                                'Following',
                                style: TextStyle(
                                  color: subtextColor,
                                  fontSize: 14.5,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '11 ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  fontSize: 14.5,
                                ),
                              ),
                              Text(
                                'Followers',
                                style: TextStyle(
                                  color: subtextColor,
                                  fontSize: 14.5,
                                ),
                              ),
                            ],
                          ),

                          // Action Buttons Row (Share / Edit profile)
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 40,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      SharePlus.instance.share(
                                        ShareParams(
                                          text: 'Check out $displayName\'s profile on PorTuT: @$username',
                                        ),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: isDark
                                            ? const Color(0xFF536471)
                                            : primaryColor,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: Text(
                                      'Share',
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SizedBox(
                                  height: 40,
                                  child: OutlinedButton(
                                    onPressed: _navigateToEditProfile,
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: isDark
                                            ? const Color(0xFF536471)
                                            : primaryColor,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: Text(
                                      'Edit profile',
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- TABS BAR (Posts ˅, Replies, Reposts, Media) ---
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: dividerColor, width: 0.8),
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildTabItem(
                            index: 0,
                            label: 'Posts ˅',
                            isDark: isDark,
                            primaryColor: primaryColor,
                          ),
                          _buildTabItem(
                            index: 1,
                            icon: Icons.chat_bubble_outline,
                            isDark: isDark,
                            primaryColor: primaryColor,
                          ),
                          _buildTabItem(
                            index: 2,
                            icon: Icons.repeat,
                            isDark: isDark,
                            primaryColor: primaryColor,
                          ),
                          _buildTabItem(
                            index: 3,
                            icon: Icons.smart_display_outlined,
                            isDark: isDark,
                            primaryColor: primaryColor,
                          ),
                        ],
                      ),
                    ),

                    // --- USER'S POSTS FEED ---
                    if (_selectedTabIndex != 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'No items to display',
                            style: TextStyle(color: subtextColor, fontSize: 15),
                          ),
                        ),
                      )
                    else if (_userPosts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.article_outlined,
                                size: 48,
                                color: subtextColor,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'No posts yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap + to compose a post',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: subtextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _userPosts.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          thickness: 0.6,
                          color: dividerColor,
                        ),
                        itemBuilder: (context, index) {
                          return _buildTweetCard(
                            _userPosts[index],
                            isDark,
                            primaryColor,
                            textColor,
                            subtextColor,
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    String? label,
    IconData? icon,
    required bool isDark,
    required Color primaryColor,
  }) {
    final isSelected = _selectedTabIndex == index;
    final textColor = isDark ? Colors.white : const Color(0xFF424242);
    final inactiveColor = isDark ? const Color(0xFF71767B) : Colors.grey[600]!;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? primaryColor : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: label != null
              ? Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? textColor : inactiveColor,
                  ),
                )
              : Icon(
                  icon,
                  size: 20,
                  color: isSelected ? textColor : inactiveColor,
                ),
        ),
      ),
    );
  }

  Widget _buildTweetCard(
    Post post,
    bool isDark,
    Color primaryColor,
    Color textColor,
    Color subtextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InitialsAvatar(
                name: post.authorName,
                size: 38,
                fontSize: 14,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          post.authorName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '@${post.authorId}',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: subtextColor,
                          ),
                        ),
                        Text(
                          ' · ',
                          style: TextStyle(color: subtextColor),
                        ),
                        Text(
                          _formatTimestamp(post.timestamp),
                          style: TextStyle(
                            fontSize: 13.5,
                            color: subtextColor,
                          ),
                        ),
                      ],
                    ),
                    if (post.title.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        post.title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      post.description,
                      style: TextStyle(
                        fontSize: 14.5,
                        height: 1.35,
                        color: textColor,
                      ),
                    ),

                    // Media preview
                    if (post.mediaUrls.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.file(
                            File(post.mediaUrls.first),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[200],
                              child: const Icon(Icons.image, size: 40, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Action buttons (reply, repost, like, views, share)
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPostAction(
                          icon: Icons.chat_bubble_outline,
                          count: post.comments,
                          color: subtextColor,
                        ),
                        _buildPostAction(
                          icon: Icons.repeat,
                          count: post.reposts,
                          color: subtextColor,
                        ),
                        _buildPostAction(
                          icon: Icons.favorite_border,
                          count: post.likes,
                          color: subtextColor,
                        ),
                        _buildPostAction(
                          icon: Icons.bar_chart,
                          count: post.views,
                          color: subtextColor,
                        ),
                        GestureDetector(
                          onTap: () => SharePlus.instance.share(
                            ShareParams(
                              text: '${post.title}\n\n${post.description}',
                            ),
                          ),
                          child: Icon(
                            Icons.share_outlined,
                            size: 17,
                            color: subtextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostAction({
    required IconData icon,
    required int count,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 17, color: color),
        if (count > 0) ...[
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ],
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dateTime);

      if (diff.inMinutes < 1) return 'now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return '${(diff.inDays / 7).floor()}w';
    } catch (_) {
      return timestamp;
    }
  }
}
