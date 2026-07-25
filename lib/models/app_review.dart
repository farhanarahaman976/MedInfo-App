import 'package:cloud_firestore/cloud_firestore.dart';

/// A general review about the MedInfo BD app/service as a whole —
/// not tied to any specific medicine.
class AppReview {
  final String id;
  final String userId;
  final String userName;
  final int stars; // 1 to 5
  final String comment;
  final DateTime createdAt;

  const AppReview({
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

  factory AppReview.fromMap(Map<String, dynamic> map, String id) {
    final rawTimestamp = map['createdAt'];
    final createdAt = rawTimestamp is Timestamp
        ? rawTimestamp.toDate()
        : DateTime.now();

    return AppReview(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      stars: (map['stars'] as num?)?.toInt() ?? 5,
      comment: map['comment'] ?? '',
      createdAt: createdAt,
    );
  }
}