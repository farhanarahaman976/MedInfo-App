const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const logger = require("firebase-functions/logger");

initializeApp();
const db = getFirestore();

exports.updateMedicineRating = onDocumentWritten(
  "medicines/{medicineId}/reviews/{reviewId}",
  async (event) => {
    const medicineId = event.params.medicineId;
    const medicineRef = db.collection("medicines").doc(medicineId);

    const reviewsSnap = await medicineRef.collection("reviews").get();
    const reviews = reviewsSnap.docs;

    if (reviews.length === 0) {
      await medicineRef.update({
        averageRating: 0.0,
        reviewCount: 0,
      });
      logger.info(`Medicine ${medicineId}: no reviews left, reset to 0.`);
      return;
    }

    const total = reviews.reduce((sum, doc) => {
      const stars = doc.data().stars;
      return sum + (typeof stars === "number" ? stars : 0);
    }, 0);

    const average = Number((total / reviews.length).toFixed(1));

    await medicineRef.update({
      averageRating: average,
      reviewCount: reviews.length,
    });

    logger.info(`Updated medicine ${medicineId}: avg=${average}, count=${reviews.length}`);
  }
);