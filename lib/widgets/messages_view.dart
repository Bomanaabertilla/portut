import 'package:flutter/material.dart';
import 'initials_avatar.dart';

class MessagesView extends StatefulWidget {
  const MessagesView({super.key});

  @override
  State<MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends State<MessagesView> {
  final List<Map<String, dynamic>> _threads = [
    {
      'id': '1',
      'name': 'Sarah Chen',
      'handle': '@sarah_c',
      'lastMessage': 'Hey! Did you see the new update for React Hooks?',
      'time': '10m',
      'unreadCount': 2,
    },
    {
      'id': '2',
      'name': 'Alex Miller',
      'handle': '@alex_m',
      'lastMessage': 'Thanks for the post recommendation. Very useful!',
      'time': '3h',
      'unreadCount': 0,
    },
    {
      'id': '3',
      'name': 'Jessica Taylor',
      'handle': '@jtaylor',
      'lastMessage': 'Let us catch up soon on the project roadmap.',
      'time': '1d',
      'unreadCount': 0,
    },
    {
      'id': '4',
      'name': 'David Kim',
      'handle': '@davidk',
      'lastMessage': 'Could you share the PDF documentation?',
      'time': '3d',
      'unreadCount': 0,
    },
  ];

  void _openChat(Map<String, dynamic> thread) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    final List<Map<String, dynamic>> messages = [
      {'sender': 'other', 'text': thread['lastMessage'], 'time': thread['time']},
    ];
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Chat header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDark
                              ? Colors.white12
                              : Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        InitialsAvatar(name: thread['name'], size: 36, fontSize: 14),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                thread['name'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isDark ? Colors.white : const Color(0xFF424242),
                                ),
                              ),
                              Text(
                                thread['handle'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),

                  // Messages list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, idx) {
                        final msg = messages[idx];
                        final isMe = msg['sender'] == 'me';
                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? primaryColor
                                  : (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEBE6DC)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              msg['text'],
                              style: TextStyle(
                                color: isMe
                                    ? Colors.white
                                    : (isDark ? Colors.white : const Color(0xFF424242)),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Message Input
                  Container(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 8,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: isDark
                              ? Colors.white12
                              : Colors.black.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF424242),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Start a message',
                              hintStyle: TextStyle(
                                color: isDark ? Colors.grey[500] : Colors.grey[600],
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5DC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.send, color: primaryColor),
                          onPressed: () {
                            final text = controller.text.trim();
                            if (text.isEmpty) return;
                            setModalState(() {
                              messages.add({
                                'sender': 'me',
                                'text': text,
                                'time': 'Just now',
                              });
                            });
                            controller.clear();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Column(
      children: [
        // Top Header
        Container(
          color: theme.appBarTheme.backgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                'Messages',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF424242),
                ),
              ),
              const Spacer(),
              Icon(Icons.settings_outlined, color: primaryColor, size: 22),
            ],
          ),
        ),

        // Search Direct Messages
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEBE6DC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF424242),
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Search Direct Messages',
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 18,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),

        Divider(
          height: 1,
          thickness: 0.8,
          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
        ),

        // Conversation List
        Expanded(
          child: ListView.separated(
            itemCount: _threads.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              thickness: 0.8,
              color: isDark
                  ? Colors.white12
                  : Colors.black.withValues(alpha: 0.08),
            ),
            itemBuilder: (context, index) {
              final thread = _threads[index];
              final hasUnread = (thread['unreadCount'] as int) > 0;

              return InkWell(
                onTap: () {
                  setState(() {
                    thread['unreadCount'] = 0;
                  });
                  _openChat(thread);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      InitialsAvatar(
                        name: thread['name'],
                        size: 48,
                        fontSize: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  thread['name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isDark ? Colors.white : const Color(0xFF424242),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  thread['handle'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  thread['time'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    thread['lastMessage'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                                      color: isDark
                                          ? (hasUnread ? Colors.white : Colors.grey[400])
                                          : (hasUnread ? Colors.black87 : Colors.grey[700]),
                                    ),
                                  ),
                                ),
                                if (hasUnread) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      thread['unreadCount'].toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
