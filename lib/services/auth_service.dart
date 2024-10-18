import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

class AuthService with ChangeNotifier {
  var logger = Logger();
  final storage = FlutterSecureStorage();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signUp(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    if (FirebaseAuth.instance.currentUser != null) {
      User currentUser = FirebaseAuth.instance.currentUser!;
      await storage.write(key: 'email', value: currentUser.email);
      await storage.write(key: 'userid', value: currentUser.uid);

      String? email = await storage.read(key: 'email');
      String? userid = await storage.read(key: 'userid');
      logger.i("User's email address: $email");
      logger.i("User's UID: $userid");
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
}
