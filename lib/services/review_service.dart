import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review.dart';

/// Reviews live in medicines/{medicineId}/reviews/{reviewId}.
/// averageRating + reviewCount on the parent medicine document are kept
/// in sync by the updateMedicineRating Cloud Function, NOT by the client —
/// Firestore rules only let the client write reviews, not those fields.
class ReviewService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _reviewsRef(String medicineId) {
    return _db.collection('medicines').doc(medicineId).collection('reviews');
  }

  /// Live stream of reviews for a medicine, newest first.
  Stream<List<Review>> getReviews(String medicineId) {
    return _reviewsRef(medicineId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Review.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Submits one review per user per medicine — if the same user reviews
  /// again, it overwrites their previous review instead of adding a duplicate.
  Future<void> submitReview({
    required String medicineId,
    required String userId,
    required String userName,
    required int stars,
    required String comment,
  }) async {
    final review = Review(
      userId: userId,
      userName: userName,
      stars: stars,
      comment: comment,
      createdAt: DateTime.now(),
    );

    await _reviewsRef(medicineId).doc(userId).set(review.toMap());
    // averageRating/reviewCount are recalculated server-side by the
    // updateMedicineRating Cloud Function — no client-side update here,
    // since Firestore rules don't allow the client to touch those fields.
  }

  Future<void> deleteReview(String medicineId, String userId) async {
    await _reviewsRef(medicineId).doc(userId).delete();
    // Same as above: the Cloud Function handles the aggregate recalculation.
  }
}