import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../models/user.dart';

class FirebaseUserService {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String usersCollection = 'users';

  // ── Register ────────────────────────────────────────────────────────────────

  Future<User> registerUser({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String address,
    // New medical params
    String bloodGroup = '',
    double? weight,
    double? height,
    bool hasDiabetes = false,
    bool hasHypertension = false,
    bool hasThyroid = false,
    bool hasHeartDisease = false,
    bool hasAsthma = false,
    String emergencyContactName = '',
    String emergencyContactPhone = '',
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final firebaseUser = credential.user;
    if (firebaseUser == null) throw Exception('Auth user is null');

    final userData = <String, dynamic>{
      'uid': firebaseUser.uid,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'createdAt': FieldValue.serverTimestamp(),
      // Medical fields
      'bloodGroup': bloodGroup,
      'weight': weight,
      'height': height,
      'hasDiabetes': hasDiabetes,
      'hasHypertension': hasHypertension,
      'hasThyroid': hasThyroid,
      'hasHeartDisease': hasHeartDisease,
      'hasAsthma': hasAsthma,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
    };

    try {
      await _firestore
          .collection(usersCollection)
          .doc(firebaseUser.uid)
          .set(userData);
    } catch (firestoreError) {
      try {
        await firebaseUser.delete();
      } catch (_) {}
      throw Exception('Failed to save user data: $firestoreError');
    }

    return User(
      uid: firebaseUser.uid,
      name: name,
      email: email,
      phone: phone,
      address: address,
      bloodGroup: bloodGroup,
      weight: weight,
      height: height,
      hasDiabetes: hasDiabetes,
      hasHypertension: hasHypertension,
      hasThyroid: hasThyroid,
      hasHeartDisease: hasHeartDisease,
      hasAsthma: hasAsthma,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
    );
  }

  // ── Login ───────────────────────────────────────────────────────────────────

  Future<User> loginUser({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final firebaseUser = credential.user!;

    try {
      final snapshot = await _firestore
          .collection(usersCollection)
          .doc(firebaseUser.uid)
          .get();

      if (!snapshot.exists || snapshot.data() == null) {
        return User(
          uid: firebaseUser.uid,
          name: firebaseUser.displayName ?? email.split('@')[0],
          email: firebaseUser.email ?? email,
          phone: '',
          address: '',
        );
      }

      final d = snapshot.data()!;
      return _userFromDoc(firebaseUser.uid, d, fallbackEmail: email);
    } catch (e) {
      return User(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? '',
        email: firebaseUser.email ?? email,
        phone: '',
        address: '',
      );
    }
  }

  // ── Sign out ────────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── Load current user ───────────────────────────────────────────────────────

  Future<User?> loadCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    try {
      final snapshot = await _firestore
          .collection(usersCollection)
          .doc(firebaseUser.uid)
          .get();

      if (!snapshot.exists || snapshot.data() == null) return null;

      final d = snapshot.data()!;
      return _userFromDoc(
        firebaseUser.uid,
        d,
        fallbackEmail: firebaseUser.email ?? '',
      );
    } catch (e) {
      return null;
    }
  }

  // ── Update user (profile edit) ──────────────────────────────────────────────

  Future<void> updateUser(User user) async {
    final data = <String, dynamic>{
      'name': user.name,
      'phone': user.phone,
      'address': user.address,
      'bloodGroup': user.bloodGroup,
      'weight': user.weight,
      'height': user.height,
      'hasDiabetes': user.hasDiabetes,
      'hasHypertension': user.hasHypertension,
      'hasThyroid': user.hasThyroid,
      'hasHeartDisease': user.hasHeartDisease,
      'hasAsthma': user.hasAsthma,
      'emergencyContactName': user.emergencyContactName,
      'emergencyContactPhone': user.emergencyContactPhone,
    };
    await _firestore.collection(usersCollection).doc(user.uid).update(data);
  }

  // ── Helper: build User from Firestore map ───────────────────────────────────

  User _userFromDoc(
    String uid,
    Map<String, dynamic> d, {
    String fallbackEmail = '',
  }) {
    return User(
      uid: uid,
      name: (d['name'] as String?) ?? '',
      email: (d['email'] as String?) ?? fallbackEmail,
      phone: (d['phone'] as String?) ?? '',
      address: (d['address'] as String?) ?? '',
      bloodGroup: (d['bloodGroup'] as String?) ?? '',
      weight: (d['weight'] as num?)?.toDouble(),
      height: (d['height'] as num?)?.toDouble(),
      hasDiabetes: (d['hasDiabetes'] as bool?) ?? false,
      hasHypertension: (d['hasHypertension'] as bool?) ?? false,
      hasThyroid: (d['hasThyroid'] as bool?) ?? false,
      hasHeartDisease: (d['hasHeartDisease'] as bool?) ?? false,
      hasAsthma: (d['hasAsthma'] as bool?) ?? false,
      emergencyContactName: (d['emergencyContactName'] as String?) ?? '',
      emergencyContactPhone: (d['emergencyContactPhone'] as String?) ?? '',
    );
  }
}
