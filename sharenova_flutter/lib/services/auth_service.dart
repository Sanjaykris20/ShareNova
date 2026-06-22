// ignore_for_file: unused_import
// ignore_for_file: avoid_print
// ignore_for_file: use_build_context_synchronously
// ignore_for_file: undefined_method, undefined_getter, new_with_undefined_constructor_default, await_only_futures
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart' as google_sign_in;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Anonymous Auth
  Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  // Email / Password
  Future<UserCredential> signInEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUpEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  // Google Sign‑In
  Future<UserCredential> signInWithGoogle() async {
    final google_sign_in.GoogleSignInAccount? googleUser = await google_sign_in.GoogleSignIn().signIn();
    if (googleUser == null) throw Exception('Google sign‑in cancelled');
    final google_sign_in.GoogleSignInAuthentication googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return await _auth.signInWithCredential(credential);
  }

  // Phone Auth – caller must handle code verification UI
  Future<void> verifyPhone({
    required String phoneNumber,
    required void Function(String verificationId) codeSent,
    required void Function(FirebaseAuthException e) verificationFailed,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: verificationFailed,
      codeSent: (String verificationId, int? _) => codeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
}
