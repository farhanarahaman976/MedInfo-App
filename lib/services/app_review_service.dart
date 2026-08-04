import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_review.dart';

class AppReviewService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _reviewsRef =>
      _db.collection('app_reviews');

  /// Live stream of testimonials, newest first.
  Stream<List<AppReview>> getReviews() {
    return _reviewsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppReview.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> submitReview({
    required String userId,
    required String userName,
    required int stars,
    required String comment,
  }) async {
    final review = AppReview(
      userId: userId,
      userName: userName,
      stars: stars,
      comment: comment,
      createdAt: DateTime.now(),
    );
    await _reviewsRef.doc(userId).set(review.toMap());
  }
}