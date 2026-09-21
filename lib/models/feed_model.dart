class FeedTopic {
  final String id;
  final String title;
  final String description;
  final String createdByName;
  final bool isFollowing;
  final DateTime createdAt;

  const FeedTopic({
    required this.id,
    required this.title,
    required this.description,
    required this.createdByName,
    required this.isFollowing,
    required this.createdAt,
  });

  factory FeedTopic.fromJson(Map<String, dynamic> json) => FeedTopic(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        createdByName: json['createdByName']?.toString() ?? '',
        isFollowing: json['isFollowing'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      );

  FeedTopic copyWith({bool? isFollowing}) => FeedTopic(
        id: id,
        title: title,
        description: description,
        createdByName: createdByName,
        isFollowing: isFollowing ?? this.isFollowing,
        createdAt: createdAt,
      );
}

class FeedPost {
  final String id;
  final String topicId;
  final String authorName;
  final String authorRole;
  final String title;
  final String body;
  final DateTime createdAt;

  const FeedPost({
    required this.id,
    required this.topicId,
    required this.authorName,
    required this.authorRole,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  factory FeedPost.fromJson(Map<String, dynamic> json) => FeedPost(
        id: json['id']?.toString() ?? '',
        topicId: json['topicId']?.toString() ?? '',
        authorName: json['authorName']?.toString() ?? '',
        authorRole: json['authorRole']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      );
}
