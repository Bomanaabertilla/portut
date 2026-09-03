import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

import 'create_post_screen.dart';
import 'profile_screen.dart';
import 'blog_post_screen.dart';
import 'bookmarks_screen.dart';
import '../services/post_service.dart';
import '../services/auth_service.dart';
import '../providers/theme_provider.dart';
import '../widgets/initials_avatar.dart';
import '../widgets/search_view.dart';
import '../widgets/notifications_view.dart';
import '../widgets/messages_view.dart';
import '../models/post.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Bottom Navigation: 0=Home, 1=Search, 2=Explore, 3=Notifications, 4=Messages
  int _currentBottomNavIndex = 0;

  // Home Feed Tabs: 0="For you", 1="Following"
  int _currentFeedTabIndex = 0;

  String? _currentUserId;
  String _currentUserName = 'User';
  List<Post> _posts = [];
  bool _isLoading = true;
  Set<String> _bookmarkedPostIds = {};
  bool _showNewPostsPill = false;

  final PostService _postService = PostService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _initScreen();
  }

  Future<void> _initScreen() async {
    await _purgeSamplePosts();
    await _loadCurrentUser();
    await _loadBookmarks();
  }

  Future<void> _purgeSamplePosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_posts:mike_chen');
      await prefs.remove('user_posts:emma_davis');

      final keys = prefs
          .getKeys()
          .where((k) => k.startsWith('user_posts:'))
          .toList();
      for (final key in keys) {
        final jsonStr = prefs.getString(key);
        if (jsonStr != null) {
          final List<dynamic> list = jsonDecode(jsonStr);
          final filtered = list.where((p) {
            final id = p['id']?.toString();
            final author = p['authorName']?.toString();
            return id != '1' &&
                id != '2' &&
                id != '3' &&
                author != 'Mike Chen' &&
                author != 'Emma Davis';
          }).toList();
          if (filtered.length != list.length) {
            await prefs.setString(key, jsonEncode(filtered));
          }
        }
      }
    } catch (e) {
      print('Error purging sample posts: $e');
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUserId = user?.username ?? 'current_user';
          _currentUserName = (user != null && user.displayName.isNotEmpty)
              ? user.displayName
              : (_currentUserId ?? 'User');
        });
        await _loadPosts();
        await _loadBookmarks();
      }
    } catch (e) {
      print('Error loading current user: $e');
      if (mounted) {
        setState(() {
          _currentUserId = 'current_user';
          _currentUserName = 'User';
        });
        await _loadPosts();
        await _loadBookmarks();
      }
    }
  }

  Future<void> _loadBookmarks() async {
    if (_currentUserId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('bookmarks_$_currentUserId') ?? [];
      if (mounted) {
        setState(() {
          _bookmarkedPostIds = saved.toSet();
        });
      }
    } catch (e) {
      print('Error loading bookmarks: $e');
    }
  }

  Future<void> _toggleBookmark(Post post) async {
    if (_currentUserId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final isBookmarked = _bookmarkedPostIds.contains(post.id);
      setState(() {
        if (isBookmarked) {
          _bookmarkedPostIds.remove(post.id);
        } else {
          _bookmarkedPostIds.add(post.id);
        }
      });
      await prefs.setStringList(
        'bookmarks_$_currentUserId',
        _bookmarkedPostIds.toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBookmarked ? 'Removed from Bookmarks' : 'Saved to Bookmarks',
            ),
            backgroundColor: const Color(0xFF8B4513),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('Error toggling bookmark: $e');
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> postsData;

      if (_currentFeedTabIndex == 0) {
        // "For you": All public posts
        postsData = await _postService.getAllPosts();
      } else {
        // "Following": Posts by current user or followed users
        if (_currentUserId != null) {
          postsData = await _postService.getPosts(_currentUserId!);
        } else {
          postsData = [];
        }
      }

      final List<Post> posts = [];
      for (final postData in postsData) {
        final authorId = postData['authorId'] ?? _currentUserId ?? 'unknown';
        posts.add(Post.fromMap(postData, authorId));
      }

      posts.sort((a, b) {
        final aTime = DateTime.tryParse(a.timestamp) ?? DateTime.now();
        final bTime = DateTime.tryParse(b.timestamp) ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading posts: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleLike(Post post) async {
    if (_currentUserId == null) return;

    try {
      final isLiked = post.likedUsers.contains(_currentUserId);
      final updatedLikedUsers = List<String>.from(post.likedUsers);

      if (isLiked) {
        updatedLikedUsers.remove(_currentUserId);
      } else {
        updatedLikedUsers.add(_currentUserId!);
      }

      final updatedPost = post.copyWith(
        likes: updatedLikedUsers.length,
        likedUsers: updatedLikedUsers,
      );

      await _postService.updatePostStats(
        post.authorId,
        post.id,
        likes: updatedPost.likes,
        likedUsers: updatedPost.likedUsers,
      );

      setState(() {
        final index = _posts.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          _posts[index] = updatedPost;
        }
      });
    } catch (e) {
      print('Error toggling like: $e');
    }
  }

  Future<void> _toggleRepost(Post post) async {
    if (_currentUserId == null) return;

    try {
      final isReposted = post.repostedUsers.contains(_currentUserId);
      final updatedRepostedUsers = List<String>.from(post.repostedUsers);

      if (isReposted) {
        updatedRepostedUsers.remove(_currentUserId);
      } else {
        updatedRepostedUsers.add(_currentUserId!);
      }

      final updatedPost = post.copyWith(
        reposts: updatedRepostedUsers.length,
        repostedUsers: updatedRepostedUsers,
      );

      setState(() {
        final index = _posts.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          _posts[index] = updatedPost;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isReposted ? 'Undo repost' : 'Reposted to your feed'),
            backgroundColor: const Color(0xFF8B4513),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('Error toggling repost: $e');
    }
  }

  void _updatePost(Post updatedPost) {
    setState(() {
      final index = _posts.indexWhere((p) => p.id == updatedPost.id);
      if (index != -1) {
        _posts[index] = updatedPost;
      }
    });
  }

  Future<void> _addNewPost(Post newPost) async {
    try {
      await _postService.savePost(
        _currentUserId ?? newPost.authorId,
        newPost.toMap(),
      );

      if (mounted) {
        setState(() {
          _posts.insert(0, newPost);
          _showNewPostsPill = true;
        });
      }
    } catch (e) {
      print('Error adding new post: $e');
    }
  }

  void _showPostOptions(Post post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.bookmark_outline),
                  title: Text(
                    _bookmarkedPostIds.contains(post.id)
                        ? 'Remove Bookmark'
                        : 'Bookmark',
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _toggleBookmark(post);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share_outlined),
                  title: const Text('Share publication'),
                  onTap: () {
                    Navigator.pop(ctx);
                    SharePlus.instance.share(
                      ShareParams(
                        text: '${post.title}\n\n${post.description}',
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.link),
                  title: const Text('Copy link to post'),
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Link copied to clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                if (post.authorId == _currentUserId)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'Delete post',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _postService.deletePost(post.authorId, post.id);
                      _loadPosts();
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: _buildSideDrawer(context, isDark, primaryColor, themeProvider),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar (X Style)
            _buildTopAppBar(context, isDark, primaryColor, themeProvider),

            // Top Feed Tabs (only on Home tab)
            if (_currentBottomNavIndex == 0)
              _buildFeedTabs(context, isDark, primaryColor),

            Divider(
              height: 1,
              thickness: 0.8,
              color: isDark
                  ? Colors.white12
                  : Colors.black.withValues(alpha: 0.08),
            ),

            // Active Tab Content
            Expanded(
              child: _buildCurrentTabBody(context, isDark, primaryColor),
            ),
          ],
        ),
      ),

      // X-Style Floating Action Button
      floatingActionButton: _buildFloatingActionButton(primaryColor),

      // X-Style Bottom Navigation Bar
      bottomNavigationBar: _buildBottomNavigationBar(
        context,
        isDark,
        primaryColor,
      ),
    );
  }

  // -------------------------------------------------------------
  // TOP APP BAR (X Style)
  // -------------------------------------------------------------
  Widget _buildTopAppBar(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    ThemeProvider themeProvider,
  ) {
    return Container(
      color: Theme.of(context).appBarTheme.backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Left: User Avatar (opens drawer)
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: InitialsAvatar(
              name: _currentUserName,
              size: 34,
              fontSize: 13,
            ),
          ),

          const Spacer(),

          // Center: Stylized Brand Logo (X Style)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'PorTuT',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : const Color(0xFF424242),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Right: Upgrade Button (matching X screenshot)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, size: 14, color: primaryColor),
                const SizedBox(width: 4),
                Text(
                  'Upgrade',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // FEED TABS ("For you" / "Following")
  // -------------------------------------------------------------
  Widget _buildFeedTabs(BuildContext context, bool isDark, Color primaryColor) {
    return Container(
      color: Theme.of(context).appBarTheme.backgroundColor,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_currentFeedTabIndex != 0) {
                  setState(() => _currentFeedTabIndex = 0);
                  _loadPosts();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _currentFeedTabIndex == 0
                          ? primaryColor
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Text(
                  'For you',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: _currentFeedTabIndex == 0
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: _currentFeedTabIndex == 0
                        ? (isDark ? Colors.white : const Color(0xFF424242))
                        : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_currentFeedTabIndex != 1) {
                  setState(() => _currentFeedTabIndex = 1);
                  _loadPosts();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _currentFeedTabIndex == 1
                          ? primaryColor
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Text(
                  'Following',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: _currentFeedTabIndex == 1
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: _currentFeedTabIndex == 1
                        ? (isDark ? Colors.white : const Color(0xFF424242))
                        : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // CURRENT TAB BODY
  // -------------------------------------------------------------
  Widget _buildCurrentTabBody(
    BuildContext context,
    bool isDark,
    Color primaryColor,
  ) {
    switch (_currentBottomNavIndex) {
      case 1:
        // Search View
        return SearchView(
          posts: _posts,
          onPostTap: (post) => _openBlogPost(post),
        );
      case 2:
        // Explore / Discover View
        return _buildExploreView(context, isDark, primaryColor);
      case 3:
        // Notifications View
        return const NotificationsView();
      case 4:
        // Messages View
        return const MessagesView();
      default:
        // Home Feed
        return _buildHomeFeed(context, isDark, primaryColor);
    }
  }

  // -------------------------------------------------------------
  // HOME FEED WITH POSTS (X Tweet Layout)
  // -------------------------------------------------------------
  Widget _buildHomeFeed(BuildContext context, bool isDark, Color primaryColor) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }

    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _currentFeedTabIndex == 0 ? Icons.public : Icons.people_outline,
              size: 56,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            const SizedBox(height: 14),
            Text(
              _currentFeedTabIndex == 0
                  ? 'No posts in feed'
                  : 'No posts from following yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : const Color(0xFF424242),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap the + button to compose a post',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadPosts,
          color: primaryColor,
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: _posts.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              thickness: 0.8,
              color: isDark
                  ? Colors.white12
                  : Colors.black.withValues(alpha: 0.08),
            ),
            itemBuilder: (context, index) {
              return _buildTweetCard(_posts[index], isDark, primaryColor);
            },
          ),
        ),

        // Floating New Posts Pill (matching screenshot)
        if (_showNewPostsPill)
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  setState(() => _showNewPostsPill = false);
                  _loadPosts();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.arrow_upward, size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'New posts',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TWEET POST CARD (X Layout)
  // -------------------------------------------------------------
  Widget _buildTweetCard(Post post, bool isDark, Color primaryColor) {
    final isLiked =
        _currentUserId != null && post.likedUsers.contains(_currentUserId);
    final isReposted =
        _currentUserId != null && post.repostedUsers.contains(_currentUserId);
    final isBookmarked = _bookmarkedPostIds.contains(post.id);

    return InkWell(
      onTap: () => _openBlogPost(post),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Author Avatar
            InitialsAvatar(name: post.authorName, size: 40, fontSize: 15),
            const SizedBox(width: 12),

            // Right: Post content & actions
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row (Name, Verified badge, Handle, Time, More menu)
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          post.authorName,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF424242),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified,
                        size: 14,
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '@${post.authorId}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        ' · ${_formatTimestamp(post.timestamp)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _showPostOptions(post),
                        child: Icon(
                          Icons.more_horiz,
                          size: 18,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                  // Post Title
                  if (post.title.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      post.title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF424242),
                      ),
                    ),
                  ],

                  // Post Description
                  const SizedBox(height: 4),
                  Text(
                    post.description,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: isDark
                          ? Colors.grey[200]
                          : const Color(0xFF222222),
                    ),
                  ),

                  // Media Preview (if post has attachments)
                  if (post.mediaUrls.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildPostMediaPreview(
                      post.mediaUrls,
                      isDark,
                      primaryColor,
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Interaction Row (Replies, Reposts, Likes, Views, Bookmarks, Share)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Reply
                      _buildActionItem(
                        icon: Icons.chat_bubble_outline,
                        count: post.comments,
                        color: isDark ? Colors.grey[400]! : Colors.grey[600]!,
                        onTap: () => _openBlogPost(post),
                      ),

                      // Repost
                      _buildActionItem(
                        icon: Icons.repeat,
                        count: post.reposts,
                        color: isReposted
                            ? Colors.green
                            : (isDark ? Colors.grey[400]! : Colors.grey[600]!),
                        onTap: () => _toggleRepost(post),
                      ),

                      // Like
                      _buildActionItem(
                        icon: isLiked ? Icons.favorite : Icons.favorite_border,
                        count: post.likes,
                        color: isLiked
                            ? Colors.red
                            : (isDark ? Colors.grey[400]! : Colors.grey[600]!),
                        onTap: () => _toggleLike(post),
                      ),

                      // Views
                      _buildActionItem(
                        icon: Icons.bar_chart,
                        count: post.views > 0 ? post.views : 340,
                        color: isDark ? Colors.grey[400]! : Colors.grey[600]!,
                        onTap: null,
                      ),

                      // Bookmark & Share
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => _toggleBookmark(post),
                            child: Icon(
                              isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              size: 18,
                              color: isBookmarked
                                  ? primaryColor
                                  : (isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600]),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => SharePlus.instance.share(
                              ShareParams(
                                text: '${post.title}\n\n${post.description}',
                              ),
                            ),
                            child: Icon(
                              Icons.share_outlined,
                              size: 18,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required int count,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Text(
              count > 999
                  ? '${(count / 1000).toStringAsFixed(1)}K'
                  : count.toString(),
              style: TextStyle(fontSize: 12, color: color),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPostMediaPreview(
    List<String> mediaUrls,
    bool isDark,
    Color primaryColor,
  ) {
    final first = mediaUrls.first;
    final isPdf = first.toLowerCase().endsWith('.pdf');

    if (isPdf) {
      final name = first.split(RegExp(r'[\\/]')).last;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEBE6DC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF424242),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    // Image preview
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEBE6DC),
        ),
        child: first.startsWith('http')
            ? Image.network(
                first,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image, size: 40, color: Colors.grey),
              )
            : File(first).existsSync()
            ? Image.file(
                File(first),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image, size: 40, color: Colors.grey),
              )
            : const Icon(Icons.image, size: 40, color: Colors.grey),
      ),
    );
  }

  // -------------------------------------------------------------
  // EXPLORE / GROK TAB (Index 2)
  // -------------------------------------------------------------
  Widget _buildExploreView(
    BuildContext context,
    bool isDark,
    Color primaryColor,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Explore PorTuT',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF424242),
          ),
        ),
        const SizedBox(height: 14),

        // Featured Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'WHAT\'S HAPPENING',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Explore the latest developer tutorials, ideas, and stories',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        Text(
          'Popular Categories',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF424242),
          ),
        ),
        const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              [
                '📱 Flutter',
                '⚛️ React',
                '🚀 Startups',
                '🎨 UI/UX',
                '🤖 AI & ML',
                '☁️ Cloud',
                '💼 Careers',
              ].map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2C2C2C)
                        : const Color(0xFFEBE6DC),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF424242),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // FLOATING ACTION BUTTON
  // -------------------------------------------------------------
  Widget _buildFloatingActionButton(Color primaryColor) {
    return FloatingActionButton(
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreatePostScreen()),
        );
        if (result != null && result is Post) {
          setState(() {
            _currentBottomNavIndex = 0;
            _currentFeedTabIndex = 0;
          });
          await _addNewPost(result);
          await _loadPosts();
        }
      },
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: const CircleBorder(),
      child: const Icon(Icons.add, size: 28),
    );
  }

  // -------------------------------------------------------------
  // BOTTOM NAVIGATION BAR (5 Tabs matching X)
  // -------------------------------------------------------------
  Widget _buildBottomNavigationBar(
    BuildContext context,
    bool isDark,
    Color primaryColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white12
                : Colors.black.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 54,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 0: Home
              _buildBottomNavItem(
                index: 0,
                icon: Icons.home_filled,
                inactiveIcon: Icons.home_outlined,
                primaryColor: primaryColor,
                isDark: isDark,
              ),

              // 1: Search
              _buildBottomNavItem(
                index: 1,
                icon: Icons.search,
                inactiveIcon: Icons.search,
                primaryColor: primaryColor,
                isDark: isDark,
              ),

              // 2: Grok / Explore
              _buildBottomNavItem(
                index: 2,
                icon: Icons.explore,
                inactiveIcon: Icons.explore_outlined,
                primaryColor: primaryColor,
                isDark: isDark,
              ),

              // 3: Notifications (with unread badge)
              _buildBottomNavItem(
                index: 3,
                icon: Icons.notifications,
                inactiveIcon: Icons.notifications_none,
                primaryColor: primaryColor,
                isDark: isDark,
                badgeCount: 1,
              ),

              // 4: Messages (with unread badge)
              _buildBottomNavItem(
                index: 4,
                icon: Icons.mail,
                inactiveIcon: Icons.mail_outline,
                primaryColor: primaryColor,
                isDark: isDark,
                badgeCount: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required int index,
    required IconData icon,
    required IconData inactiveIcon,
    required Color primaryColor,
    required bool isDark,
    int? badgeCount,
  }) {
    final isSelected = _currentBottomNavIndex == index;
    final iconColor = isSelected
        ? primaryColor
        : (isDark ? Colors.grey[400] : const Color(0xFF666666));

    return InkWell(
      onTap: () {
        setState(() {
          _currentBottomNavIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Icon(
              isSelected ? icon : inactiveIcon,
              size: 26,
              color: iconColor,
            ),
          ),
          if (badgeCount != null && badgeCount > 0)
            Positioned(
              right: 12,
              top: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // SIDE DRAWER (X Style)
  // -------------------------------------------------------------
  Widget _buildSideDrawer(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    ThemeProvider themeProvider,
  ) {
    return Drawer(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InitialsAvatar(
                        name: _currentUserName,
                        size: 48,
                        fontSize: 18,
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF536471), width: 1.2),
                        ),
                        child: const Icon(
                          Icons.more_vert,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _currentUserName,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${_currentUserId ?? "b_bertilla24"}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF71767B),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: const [
                      Text(
                        '82 ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Following',
                        style: TextStyle(
                          color: Color(0xFF71767B),
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 14),
                      Text(
                        '11 ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Followers',
                        style: TextStyle(
                          color: Color(0xFF71767B),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(
              height: 16,
              thickness: 0.5,
              color: Color(0xFF2F3336),
            ),

            // Navigation Links
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.person_outline,
                    title: 'Profile',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.verified_outlined,
                    title: 'Premium',
                    trailingBadge: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D9BF0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '50% off',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onTap: () {},
                  ),
                  _buildDrawerItem(
                    icon: Icons.people_outline,
                    title: 'Communities',
                    onTap: () {},
                  ),
                  _buildDrawerItem(
                    icon: Icons.bookmark_border,
                    title: 'Bookmarks',
                    onTap: () async {
                      Navigator.pop(context);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BookmarksScreen(),
                        ),
                      );
                      _loadBookmarks();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.list_alt,
                    title: 'Lists',
                    onTap: () {},
                  ),
                  _buildDrawerItem(
                    icon: Icons.graphic_eq,
                    title: 'Spaces',
                    onTap: () {},
                  ),
                  _buildDrawerItem(
                    icon: Icons.rocket_launch_outlined,
                    title: 'Creator Studio',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            // Bottom Accounts Section (matching screenshot)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFF2F3336), width: 0.5),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF536471),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Accounts',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      InitialsAvatar(
                        name: _currentUserName,
                        size: 38,
                        fontSize: 14,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentUserName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '@${_currentUserId ?? "b_bertilla24"}',
                              style: const TextStyle(
                                color: Color(0xFF71767B),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF00BA7C),
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/signup');
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF536471)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'Create a new account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/login');
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF536471)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'Add an existing account',
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
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    Widget? trailingBadge,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: 0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      leading: Icon(icon, color: Colors.white, size: 24),
      title: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (trailingBadge != null) ...[
            const SizedBox(width: 8),
            trailingBadge,
          ],
        ],
      ),
      onTap: onTap,
    );
  }

  void _openBlogPost(Post post) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BlogPostScreen(post: post)),
    );
    if (result != null && result is Post) {
      _updatePost(result);
    }
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
    } catch (e) {
      return timestamp;
    }
  }
}
