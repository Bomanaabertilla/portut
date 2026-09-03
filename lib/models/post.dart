class Post {
  final String id;
  final String title;
  final String description;
  final String authorName;
  final String authorAvatar;
  final String timestamp;
  final int likes;
  final int comments;
  final bool isPublic;
  final String authorId;
  final List<String> likedUsers;
  final List<String> commentsList;

  Post({
    required this.id,
    required this.title,
    required this.description,
    required this.authorName,
    required this.authorAvatar,
    required this.timestamp,
    required this.likes,
    required this.comments,
    required this.isPublic,
    required this.authorId,
    this.likedUsers = const [],
    this.commentsList = const [],
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
      isPublic: map['visibility'] == 'Public' ||
          map['visibility'] == 'public' ||
          map['isPublic'] == true,
      authorId: authorId,
      likedUsers: List<String>.from(map['likedUsers'] ?? []),
      commentsList: List<String>.from(map['comments'] ?? []),
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
      'visibility': isPublic ? 'Public' : 'Private',
      'isPublic': isPublic,
      'likedUsers': likedUsers,
      'authorId': authorId,
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
    bool? isPublic,
    String? authorId,
    List<String>? likedUsers,
    List<String>? commentsList,
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
      isPublic: isPublic ?? this.isPublic,
      authorId: authorId ?? this.authorId,
      likedUsers: likedUsers ?? this.likedUsers,
      commentsList: commentsList ?? this.commentsList,
    );
  }
}
