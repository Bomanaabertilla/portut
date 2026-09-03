class Post {
  final String id;
  final String title;
  final String description;
  final String authorName;
  final String authorAvatar;
  final String timestamp;
  final int likes;
  final int comments;
  final int reposts;
  final int views;
  final bool isPublic;
  final String authorId;
  final List<String> likedUsers;
  final List<String> repostedUsers;
  final List<String> commentsList;
  final List<String> mediaUrls;

  Post({
    required this.id,
    required this.title,
    required this.description,
    required this.authorName,
    required this.authorAvatar,
    required this.timestamp,
    required this.likes,
    required this.comments,
    this.reposts = 0,
    this.views = 0,
    required this.isPublic,
    required this.authorId,
    this.likedUsers = const [],
    this.repostedUsers = const [],
    this.commentsList = const [],
    this.mediaUrls = const [],
  });

  // Factory constructor to create Post from Map
  factory Post.fromMap(Map<String, dynamic> map, [String? fallbackAuthorId]) {
    final authorId = (map['authorId'] as String?) ?? fallbackAuthorId ?? 'unknown';
    return Post(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      description: map['content'] ?? map['description'] ?? '',
      authorName: map['authorName'] ?? map['author'] ?? 'Unknown',
      authorAvatar: map['authorAvatar'] ??
          'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=50&h=50&fit=crop&crop=face',
      timestamp: map['timestamp'] ?? DateTime.now().toIso8601String(),
      likes: (map['likes'] as num?)?.toInt() ?? 0,
      comments: (map['comments'] as List?)?.length ?? 0,
      reposts: (map['reposts'] as num?)?.toInt() ?? 0,
      views: (map['views'] as num?)?.toInt() ?? 0,
      isPublic: map['visibility'] == 'Public' ||
          map['visibility'] == 'public' ||
          map['isPublic'] == true,
      authorId: authorId,
      likedUsers: List<String>.from(map['likedUsers'] ?? []),
      repostedUsers: List<String>.from(map['repostedUsers'] ?? []),
      commentsList: List<String>.from(map['comments'] ?? []),
      mediaUrls: List<String>.from(map['mediaUrls'] ?? map['media'] ?? []),
    );
  }

  // Convert Post to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': description,
      'description': description,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'timestamp': timestamp,
      'likes': likes,
      'comments': commentsList,
      'reposts': reposts,
      'views': views,
      'visibility': isPublic ? 'Public' : 'Private',
      'isPublic': isPublic,
      'likedUsers': likedUsers,
      'repostedUsers': repostedUsers,
      'authorId': authorId,
      'mediaUrls': mediaUrls,
    };
  }

  // Create a copy with updated properties
  Post copyWith({
    String? id,
    String? title,
    String? description,
    String? authorName,
    String? authorAvatar,
    String? timestamp,
    int? likes,
    int? comments,
    int? reposts,
    int? views,
    bool? isPublic,
    String? authorId,
    List<String>? likedUsers,
    List<String>? repostedUsers,
    List<String>? commentsList,
    List<String>? mediaUrls,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      timestamp: timestamp ?? this.timestamp,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      reposts: reposts ?? this.reposts,
      views: views ?? this.views,
      isPublic: isPublic ?? this.isPublic,
      authorId: authorId ?? this.authorId,
      likedUsers: likedUsers ?? this.likedUsers,
      repostedUsers: repostedUsers ?? this.repostedUsers,
      commentsList: commentsList ?? this.commentsList,
      mediaUrls: mediaUrls ?? this.mediaUrls,
    );
  }
}
