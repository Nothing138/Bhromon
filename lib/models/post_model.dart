// models/post_model.dart
import '../models/event_model.dart';

class Post {
  final String id;
  final String userId;
  final String agencyId; // If posted by agency
  final String? userName;
  final String? userFullName;
  final String? userAvatar;
  final String content;
  final String? imageUrl;
  final String? location;
  final int likesCount;
  final int commentsCount;
  final bool isLikedByCurrentUser;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String postType; // 'text', 'image', 'event_promo'

  Post({
    required this.id,
    required this.userId,
    required this.agencyId,
    this.userName,
    this.userFullName,
    this.userAvatar,
    required this.content,
    this.imageUrl,
    this.location,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLikedByCurrentUser = false,
    required this.createdAt,
    required this.updatedAt,
    this.postType = 'text',
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      agencyId: json['agency_id'] as String? ?? '',
      userName: json['user_name'] as String?,
      userFullName: json['user_full_name'] as String?,
      userAvatar: json['user_avatar'] as String?,
      content: json['content'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      location: json['location'] as String?,
      likesCount: (json['likes_count'] as int?) ?? 0,
      commentsCount: (json['comments_count'] as int?) ?? 0,
      isLikedByCurrentUser:
          (json['is_liked_by_current_user'] as bool?) ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      postType: json['post_type'] as String? ?? 'text',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'agency_id': agencyId,
        'user_name': userName,
        'user_full_name': userFullName,
        'user_avatar': userAvatar,
        'content': content,
        'image_url': imageUrl,
        'location': location,
        'likes_count': likesCount,
        'comments_count': commentsCount,
        'is_liked_by_current_user': isLikedByCurrentUser,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'post_type': postType,
      };

  Post copyWith({
    String? id,
    String? userId,
    String? agencyId,
    String? userName,
    String? userFullName,
    String? userAvatar,
    String? content,
    String? imageUrl,
    String? location,
    int? likesCount,
    int? commentsCount,
    bool? isLikedByCurrentUser,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? postType,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      agencyId: agencyId ?? this.agencyId,
      userName: userName ?? this.userName,
      userFullName: userFullName ?? this.userFullName,
      userAvatar: userAvatar ?? this.userAvatar,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      postType: postType ?? this.postType,
    );
  }
}

// Combined feed item - can be either Event or Post
class FeedItem {
  final String id;
  final String type; // 'event' or 'post'
  final dynamic data; // AgencyEvent or Post

  FeedItem({
    required this.id,
    required this.type,
    required this.data,
  });

  DateTime get timestamp {
    if (type == 'event' && data is AgencyEvent) {
      return (data as AgencyEvent).createdAt;
    } else if (type == 'post' && data is Post) {
      return (data as Post).createdAt;
    }
    return DateTime.now();
  }
}
