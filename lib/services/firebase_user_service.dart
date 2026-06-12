import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../models/user.dart';

class FirebaseUserService {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String usersCollection = 'users';

  Future<User> registerUser({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String address,
  }) async {
    print('========== Registration Start ==========');
    print('Name: $name | Phone: $phone | Address: $address');

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final firebaseUser = credential.user;
    if (firebaseUser == null) throw Exception('Auth user is null');

    // FIX 2: সব field explicitly map করে Firestore এ save
    final userData = <String, dynamic>{
      'uid': firebaseUser.uid,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      await _firestore
          .collection(usersCollection)
          .doc(firebaseUser.uid)
          .set(userData);
      print('Firestore save OK: $userData');
    } catch (firestoreError) {
      print('Firestore error: $firestoreError');
      try { await firebaseUser.delete(); } catch (_) {}
      throw Exception('Failed to save user data: $firestoreError');
    }

    print('========== Registration Done ==========');
    return User(
      uid: firebaseUser.uid,
      name: name,
      email: email,
      phone: phone,
      address: address,
    );
  }

  Future<User> loginUser({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final firebaseUser = credential.user!;
    print('Login: ${firebaseUser.uid}');

    // FIX 2: Firestore থেকে সব field পড়া
    try {
      final snapshot = await _firestore
          .collection(usersCollection)
          .doc(firebaseUser.uid)
          .get();

      if (!snapshot.exists || snapshot.data() == null) {
        print('No Firestore doc — returning basic user');
        return User(
          uid: firebaseUser.uid,
          name: firebaseUser.displayName ?? email.split('@')[0],
          email: firebaseUser.email ?? email,
          phone: '',
          address: '',
        );
      }

      final d = snapshot.data()!;
      print('Firestore data loaded: $d');

      return User(
        uid: firebaseUser.uid,
        name: (d['name'] as String?) ?? '',
        email: (d['email'] as String?) ?? firebaseUser.email ?? email,
        phone: (d['phone'] as String?) ?? '',
        address: (d['address'] as String?) ?? '',
      );
    } catch (e) {
      print('Firestore read error: $e');
      return User(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? '',
        email: firebaseUser.email ?? email,
        phone: '',
        address: '',
      );
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

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
      print('loadCurrentUser: $d');

      return User(
        uid: firebaseUser.uid,
        name: (d['name'] as String?) ?? '',
        email: (d['email'] as String?) ?? firebaseUser.email ?? '',
        phone: (d['phone'] as String?) ?? '',
        address: (d['address'] as String?) ?? '',
      );
    } catch (e) {
      print('loadCurrentUser error: $e');
      return null;
    }
  }
}