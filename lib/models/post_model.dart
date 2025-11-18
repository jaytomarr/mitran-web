import 'package:cloud_firestore/cloud_firestore.dart';

class PostAuthor {
  final String userId;
  final String username;
  final String profilePictureUrl;

  const PostAuthor({
    required this.userId,
    required this.username,
    required this.profilePictureUrl,
  });

  factory PostAuthor.fromMap(Map<String, dynamic> map) {
    return PostAuthor(
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      profilePictureUrl: map['profilePictureUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'profilePictureUrl': profilePictureUrl,
    };
  }
}

class PostModel {
  final String postId;
  final String content;
  final PostAuthor author;
  final DateTime timestamp;
  final DateTime createdAt;

  const PostModel({
    required this.postId,
    required this.content,
    required this.author,
    required this.timestamp,
    required this.createdAt,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PostModel(
      postId: doc.id,
      content: data['content'] ?? '',
      author: PostAuthor.fromMap(data['author'] ?? {}),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'author': author.toMap(),
      'timestamp': Timestamp.fromDate(timestamp),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}