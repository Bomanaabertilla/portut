import 'package:flutter/material.dart';
import 'initials_avatar.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  String _selectedTab = 'All';

  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'type': 'like',
      'actorName': 'Emmy',
      'actorHandle': '@ChuksEmma',
      'content': 'liked your post "Complete Guide to React"',
      'time': '2h',
      'read': false,
    },
    {
      'id': '2',
      'type': 'comment',
      'actorName': 'Sarah Chen',
      'actorHandle': '@sarah_c',
      'content': 'replied: "This was really helpful, thanks for sharing!"',
      'time': '5h',
      'read': false,
    },
    {
      'id': '3',
      'type': 'repost',
      'actorName': 'Dev Community',
      'actorHandle': '@dev_comm',
      'content': 'reposted your publication',
      'time': '1d',
      'read': true,
    },
    {
      'id': '4',
      'type': 'welcome',
      'actorName': 'PorTuT Team',
      'actorHandle': '@portut',
      'content': 'Welcome to PorTuT! Start sharing and connecting today.',
      'time': '2d',
      'read': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    final filtered = _selectedTab == 'Mentions'
        ? _notifications.where((n) => n['type'] == 'comment').toList()
        : _notifications;

    return Column(
      children: [
        // Header
        Container(
          color: theme.appBarTheme.backgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF424242),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    for (var n in _notifications) {
                      n['read'] = true;
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All notifications marked as read'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Text(
                  'Mark all read',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Tabs
        Container(
          color: theme.appBarTheme.backgroundColor,
          child: Row(
            children: ['All', 'Verified', 'Mentions'].map((tab) {
              final isSelected = _selectedTab == tab;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = tab),
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
                    child: Text(
                      tab,
                      style: TextStyle(
                        color: isSelected
                            ? (isDark ? Colors.white : const Color(0xFF424242))
                            : Colors.grey,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        Divider(
          height: 1,
          thickness: 0.8,
          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
        ),

        // Notification list
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 56,
                        color: isDark ? Colors.white24 : Colors.black26,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No notifications yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : const Color(0xFF424242),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    thickness: 0.8,
                    color: isDark
                        ? Colors.white12
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final isRead = item['read'] as bool;

                    IconData iconData;
                    Color iconColor;

                    switch (item['type']) {
                      case 'like':
                        iconData = Icons.favorite;
                        iconColor = Colors.redAccent;
                        break;
                      case 'repost':
                        iconData = Icons.repeat;
                        iconColor = Colors.green;
                        break;
                      case 'comment':
                        iconData = Icons.chat_bubble;
                        iconColor = Colors.blueAccent;
                        break;
                      default:
                        iconData = Icons.star;
                        iconColor = primaryColor;
                    }

                    return Container(
                      color: isRead
                          ? Colors.transparent
                          : (isDark
                              ? primaryColor.withValues(alpha: 0.08)
                              : primaryColor.withValues(alpha: 0.04)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(iconData, color: iconColor, size: 24),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InitialsAvatar(
                                  name: item['actorName'],
                                  size: 34,
                                  fontSize: 13,
                                ),
                                const SizedBox(height: 8),
                                RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark ? Colors.white : const Color(0xFF424242),
                                    ),
                                    children: [
                                      TextSpan(
                                        text: item['actorName'] + ' ',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(
                                        text: item['content'],
                                        style: TextStyle(
                                          color: isDark ? Colors.grey[300] : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            item['time'],
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
