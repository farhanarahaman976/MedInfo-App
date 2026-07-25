import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String userId;
  final String userName;
  final int stars; // 1 to 5
  final String comment;
  final DateTime createdAt;

  const Review({
    this.id = '',
    required this.userId,
    required this.userName,
    required this.stars,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'stars': stars,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Review.fromMap(Map<String, dynamic> map, String id) {
    final rawTimestamp = map['createdAt'];
    final createdAt = rawTimestamp is Timestamp
        ? rawTimestamp.toDate()
        : DateTime.now();

    return Review(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      stars: (map['stars'] as num?)?.toInt() ?? 5,
      comment: map['comment'] ?? '',
      createdAt: createdAt,
    );
  }
}