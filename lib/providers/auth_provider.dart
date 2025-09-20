import 'dart:async';
import 'dart:convert'; // Importing dart:convert for JSON encoding of the email payload
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart'
    as http; // Importing http package for making HTTP requests
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:signtalk/providers/presence_service.dart';

//getter for current user ID
final currentUserIdProvider = StateProvider<String>((ref) => '');

final authProviderProvider = Provider<AuthProvider>((ref) {
  return AuthProvider();
});

final authProvider = ChangeNotifierProvider<AuthProvider>((ref) {
  return AuthProvider();
});

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  bool get isSignedin => _auth.currentUser != null;

  String? _userIdFor2FA;

  String? get userIdFor2FA => _userIdFor2FA;

  String? _tempEmail;
  String? _tempPassword;

  String? get tempEmail => _tempEmail;
  String? get tempPassword => _tempPassword;

  Future<void> register(
    String email,
    String password,
    String name,
    int age,
    String userTypes,
  ) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'uid': userCredential.user?.uid,
        'name': name,
        'name_lowercase': name.toLowerCase(), // need to for search feature
        'age': age,
        'userType': userTypes,
        'email': email,
        'email_lowercase': email.toLowerCase(),
      });

      notifyListeners();
    } catch (e) {
      rethrow; // Handle error appropriately
    }
  }

  //Directly send email using SendGrid API ---direct call from flutter to SendGrid w/o using intermediary Firebase Function
  Future<void> sendEmailDirectlyViaSendGrid(String email, String code) async {
    final String? sendGridApiKey =
        dotenv.env['SENDGRID_API_KEY']; //Shouldn't be hardcoded -- NOT SECURE
    const String senderEmail = '<signtalk625@icloud.com>';
    if (sendGridApiKey == null) {
      throw Exception('SendGrid API key not found in environment variables');
    }

    final url = Uri.parse('https://api.sendgrid.com/v3/mail/send');
    final emailPayload = {
      "personalizations": [
        {
          "to": [
            {"email": email},
          ],
          "subject": "Your 2FA Code",
        },
      ],
      "from": {"email": senderEmail, "name": "SignTalk"},
      "content": [
        {
          "type": "text/plain",
          "value":
              "Your verification code is: $code. It will expire in 5 minutes.",
        },
      ],
    };

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $sendGridApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(emailPayload),
    );

    if (response.statusCode == 202) {
      print("Email sent successfully to $email");
    } else {
      print("SendGrid Error: ${response.statusCode} - ${response.body}");
      throw Exception('Failed to send email');
    }
  }

  Future<String?> signInWith2FA(String email, String password) async {
    try {
      // Sign in to validate (then sign out)
      final userCred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = userCred.user?.uid;
      await _auth.signOut(); // Sign out immediately to prevent session

      if (uid == null) throw Exception("User ID is null");

      _tempEmail = email;
      _tempPassword = password;

      // Generate code and store in Firestore
      final code = (100000 + DateTime.now().millisecondsSinceEpoch % 900000)
          .toString();
      //_generatedCode = code;
      _userIdFor2FA = uid;

      await _firestore.collection('verification').doc(uid).set({
        'code': code,
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(Duration(minutes: 5)),
        ),
      });

      await sendEmailDirectlyViaSendGrid(email, code);
      return null; // No error, proceed to 2FA screen
    } catch (_) {
      return "An error occured. Please try again.";
    }
  }

  Future<bool> verify2FACode(String inputCode) async {
    if (_userIdFor2FA == null) return false;

    final doc = await _firestore
        .collection('verification')
        .doc(_userIdFor2FA)
        .get();
    if (!doc.exists) return false;

    final data = doc.data();
    final savedCode = data?['code'];
    final expiresAt = (data?['expiresAt'] as Timestamp).toDate();

    if (DateTime.now().isAfter(expiresAt)) return false;

    if (inputCode == savedCode) {
      await _firestore.collection('verification').doc(_userIdFor2FA!).delete();

      //set user as online
      final presence = PresenceService();
      await presence.setUserOnline(true);

      return true;
    } else {
      return false;
    }
  }

  Future<void> resend2FACode() async {
    if (_tempEmail == null || _userIdFor2FA == null) {
      throw Exception("Missing data to resend code.");
    }

    try {
      final code = (100000 + DateTime.now().millisecondsSinceEpoch % 900000)
          .toString();

      await _firestore.collection('verification').doc(_userIdFor2FA!).set({
        'code': code,
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(Duration(minutes: 5)),
        ),
      });

      await sendEmailDirectlyViaSendGrid(_tempEmail!, code);
    } catch (e) {
      throw Exception("Failed to resend 2FA code");
    }
  }

  //Sign in using Google
  Future<String> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null)
        return "cancelled"; // User closed the sign-in dialog

      final googleAuth = await googleUser
          .authentication; // Get the authentication details from the Google sign-in process

      final credential = GoogleAuthProvider.credential(
        // Create a credential using the Google authentication details
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final userCredential = await _auth.signInWithCredential(
        credential,
      ); // Sign in to Firebase using the Google credential

      final user = userCredential.user; // Check if the user is not null
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          // If the user document does not exist, create it
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'name': user.displayName ?? '',
            'email': user.email,
            'userType': '',
            'age': '',
            'photoUrl': user.photoURL, //move this to storage firebase
          });
        }

        //mark online sa chat
        final presence = PresenceService();
        await presence.setUserOnline(true);
        notifyListeners();
        return "success";
      }
      return "error";
    } catch (e) {
      print("Google Sign-In Error: $e");
      return "error";
    }
  }

  Future<void> signOut() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'isOnline': false, 'lastSeen': FieldValue.serverTimestamp()},
      );
    }

    await _auth.signOut();
    await _googleSignIn.signOut();

    notifyListeners();
  }

  Future<bool> resetPasswordIfExists(String email) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return false;

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  //   Future<void> signInWith2FA(String email, String password) async {
  //   try {
  //     final userCred = await _auth.signInWithEmailAndPassword(email: email, password: password);
  //     final uid = userCred.user?.uid;
  //     if (uid == null) throw Exception("User ID is null");

  //     // Generate 6-digit code
  //     final code = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
  //     _generatedCode = code;
  //     _userIdFor2FA = uid;

  //     // Store in Firestore temporarily
  //     await _firestore.collection('verification').doc(uid).set({
  //       'code': code,
  //       'expiresAt': Timestamp.fromDate(DateTime.now().add(Duration(minutes: 5))),
  //     });

  //     // Call Firebase Function to send email
  //     await sendEmailCode(email, code);
  //   } catch (e) {
  //     rethrow;
  //   }

  // }

  // Future<void> sendEmailCode(String email, String code) async {
  //   final callable = FirebaseFunctions.instance.httpsCallable('send2FACode');
  //   await callable.call({'email': email, 'code': code});
  // }

  // Future<bool> verify2FACode(String inputCode) async {
  //   if (_userIdFor2FA == null) return false;

  //   final doc = await _firestore.collection('verification').doc(_userIdFor2FA).get();
  //   if (!doc.exists) return false;

  //   final data = doc.data();
  //   final savedCode = data?['code'];
  //   final expiresAt = (data?['expiresAt'] as Timestamp).toDate();

  //   if (DateTime.now().isAfter(expiresAt)) return false;

  //   if (inputCode == savedCode) {
  //     await _firestore.collection('verification').doc(_userIdFor2FA!).delete();
  //     return true;
  //   } else {
  //     return false;
  //   }
  // }
}
