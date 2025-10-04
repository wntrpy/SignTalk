import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
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

  // Login attempt tracking (in-memory cache)
  final Map<String, int> _loginAttempts = {};
  final Map<String, DateTime> _lockoutUntil = {};

  // Constructor - load lockout data when provider is created
  AuthProvider() {
    _initializeLockoutData();
  }

  // Initialize and load lockout data
  Future<void> _initializeLockoutData() async {
    await loadLockoutData();
  }

  // Load lockout data from Firestore
  Future<void> loadLockoutData() async {
    try {
      final snapshot = await _firestore.collection('login_lockouts').get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final email = doc.id;
        final lockoutUntil = (data['lockoutUntil'] as Timestamp?)?.toDate();
        final attempts = data['attempts'] as int?;

        if (lockoutUntil != null && attempts != null) {
          // Only restore if lockout hasn't expired
          if (DateTime.now().isBefore(lockoutUntil)) {
            _lockoutUntil[email] = lockoutUntil;
            _loginAttempts[email] = attempts;
          } else {
            // Clean up expired lockout
            await _firestore.collection('login_lockouts').doc(email).delete();
          }
        }
      }

      notifyListeners();
    } catch (e) {
      print('Error loading lockout data: $e');
    }
  }

  // Save lockout data to Firestore
  Future<void> _saveLockoutData(String email) async {
    try {
      final emailKey = email.toLowerCase();
      final lockoutTime = _lockoutUntil[emailKey];
      final attempts = _loginAttempts[emailKey];

      if (lockoutTime != null && attempts != null) {
        await _firestore.collection('login_lockouts').doc(emailKey).set({
          'email': emailKey,
          'lockoutUntil': Timestamp.fromDate(lockoutTime),
          'attempts': attempts,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error saving lockout data: $e');
    }
  }

  // Clear lockout data from Firestore
  Future<void> _clearLockoutData(String email) async {
    try {
      await _firestore
          .collection('login_lockouts')
          .doc(email.toLowerCase())
          .delete();
    } catch (e) {
      print('Error clearing lockout data: $e');
    }
  }

  // Get any currently locked out email (for UI restoration)
  String? getAnyLockedOutEmail() {
    for (var email in _lockoutUntil.keys) {
      if (isLockedOut(email)) {
        return email;
      }
    }
    return null;
  }

  // Check if email is locked out
  bool isLockedOut(String email) {
    final lockoutTime = _lockoutUntil[email.toLowerCase()];
    if (lockoutTime == null) return false;

    if (DateTime.now().isBefore(lockoutTime)) {
      return true;
    } else {
      // Lockout expired, reset
      _lockoutUntil.remove(email.toLowerCase());
      _loginAttempts.remove(email.toLowerCase());
      _clearLockoutData(email.toLowerCase());
      notifyListeners();
      return false;
    }
  }

  // Get remaining lockout time in seconds
  int getRemainingLockoutTime(String email) {
    final lockoutTime = _lockoutUntil[email.toLowerCase()];
    if (lockoutTime == null) return 0;

    final remaining = lockoutTime.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  // Get current attempt count
  int getAttemptCount(String email) {
    return _loginAttempts[email.toLowerCase()] ?? 0;
  }

  // Reset login attempts (called on successful login)
  Future<void> _resetLoginAttempts(String email) async {
    _loginAttempts.remove(email.toLowerCase());
    _lockoutUntil.remove(email.toLowerCase());
    await _clearLockoutData(email.toLowerCase());
    notifyListeners();
  }

  // Increment failed login attempts
  Future<void> _incrementFailedAttempt(String email) async {
    final emailKey = email.toLowerCase();
    _loginAttempts[emailKey] = (_loginAttempts[emailKey] ?? 0) + 1;

    if (_loginAttempts[emailKey]! >= 3) {
      _lockoutUntil[emailKey] = DateTime.now().add(Duration(minutes: 5));
      await _saveLockoutData(email);
    }

    notifyListeners();
  }

  Future<void> register(
    String email,
    String password,
    String name,
    int age,
    String userTypes,
  ) async {
    print('=== REGISTER START ===');

    try {
      // CHECK FIRESTORE FIRST
      print('Checking Firestore for existing email...');
      final emailQuery = await _firestore
          .collection('users')
          .where('email_lowercase', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      if (emailQuery.docs.isNotEmpty) {
        print('Email already exists in Firestore - throwing exception');
        throw Exception('This email is already registered');
      }

      print('Email not found in Firestore, proceeding with auth...');

      // Create auth account
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      print('Auth account created successfully');

      final authUid = userCredential.user?.uid;
      if (authUid == null) {
        throw Exception("Failed to get Firebase Auth UID");
      }

      // Get latest formatted_uid
      print('Fetching latest formatted_uid...');
      final snapshot = await _firestore
          .collection('users')
          .orderBy('formatted_uid', descending: true)
          .limit(1)
          .get();

      print('Query returned ${snapshot.docs.length} documents');

      int newFormattedUid = 1000; // Default starting value
      if (snapshot.docs.isNotEmpty) {
        final latestDoc = snapshot.docs.first.data();
        print('Latest document data: $latestDoc');

        final latestFormattedUidField = latestDoc['formatted_uid'];
        print(
          'Latest formatted_uid field value: $latestFormattedUidField (type: ${latestFormattedUidField.runtimeType})',
        );

        if (latestFormattedUidField is int) {
          newFormattedUid = latestFormattedUidField + 1;
          print('Calculated new formatted_uid (from int): $newFormattedUid');
        } else if (latestFormattedUidField is String) {
          // Extract numeric part from string like "ADMIN_004" or just parse the number
          String numericPart = latestFormattedUidField.replaceAll(
            RegExp(r'[^0-9]'),
            '',
          );
          if (numericPart.isNotEmpty) {
            newFormattedUid = int.parse(numericPart);
          }

          // If it's an admin formatted UID, keep the format
          if (latestFormattedUidField.startsWith('ADMIN_')) {
            // Skip admin formatted UIDs and find the next numeric one
            final numericSnapshot = await _firestore
                .collection('users')
                .where('formatted_uid', isGreaterThanOrEqualTo: 1000)
                .orderBy('formatted_uid', descending: true)
                .limit(1)
                .get();

            if (numericSnapshot.docs.isNotEmpty) {
              final numericDoc = numericSnapshot.docs.first.data();
              final numericUid = numericDoc['formatted_uid'];
              if (numericUid is int) {
                newFormattedUid = numericUid + 1;
              }
            }
          } else {
            // For numeric formatted_uid strings
            newFormattedUid =
                (int.tryParse(latestFormattedUidField) ?? 999) + 1;
          }
          print('Calculated new formatted_uid (from string): $newFormattedUid');
        }
      }

      print('Final formatted_uid to be assigned: $newFormattedUid');

      // Save user in Firestore
      await _firestore.collection('users').doc(authUid).set({
        'uid': authUid,
        'formatted_uid':
            newFormattedUid, // This will now be a proper incremented number
        'name': name,
        'name_lowercase': name.toLowerCase(),
        'age': age,
        'userType': userTypes,
        'isOnline': false,
        'email': email,
        'email_lowercase': email.toLowerCase(),
        'firebase_uid': authUid,
        'createdAt': FieldValue.serverTimestamp(),
        'photoUrl': '',
      });

      print(
        'User saved to Firestore successfully with formatted_uid: $newFormattedUid',
      );
      print('=== REGISTER SUCCESS ===');
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException caught: ${e.code}');

      if (e.code == 'email-already-in-use') {
        throw Exception('This email is already registered');
      } else if (e.code == 'weak-password') {
        throw Exception('Password is too weak');
      } else if (e.code == 'invalid-email') {
        throw Exception('Invalid email format');
      } else {
        throw Exception(e.message ?? 'Registration failed');
      }
    } catch (e) {
      print('General exception caught: $e');
      print('=== REGISTER FAILED ===');

      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  //Directly send email using SendGrid API
  Future<void> sendEmailDirectlyViaSendGrid(String email, String code) async {
    final String? sendGridApiKey = dotenv.env['SENDGRID_API_KEY'];
    const String senderEmail = 'signtalk625@icloud.com';

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
      // Check if account is locked out
      if (isLockedOut(email)) {
        final remainingTime = getRemainingLockoutTime(email);
        final minutes = (remainingTime / 60).ceil();
        return "Too many failed attempts. Please try again in $minutes minute${minutes > 1 ? 's' : ''}.";
      }

      // Sign in to validate (then sign out)
      final userCred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = userCred.user?.uid;
      await _auth.signOut(); // Sign out immediately to prevent session

      if (uid == null) throw Exception("User ID is null");

      // Reset attempts on successful login
      await _resetLoginAttempts(email);

      _tempEmail = email;
      _tempPassword = password;

      // Generate code and store in Firestore
      final code = (100000 + DateTime.now().millisecondsSinceEpoch % 900000)
          .toString();
      _userIdFor2FA = uid;

      await _firestore.collection('verification').doc(uid).set({
        'code': code,
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(Duration(minutes: 5)),
        ),
      });

      await sendEmailDirectlyViaSendGrid(email, code);
      return null; // No error, proceed to 2FA screen
    } on FirebaseAuthException {
      // Increment failed attempts
      await _incrementFailedAttempt(email);

      final attempts = getAttemptCount(email);
      if (attempts >= 3) {
        return "Too many failed attempts. Your account has been locked for 5 minutes.";
      } else {
        final remaining = 3 - attempts;
        return "Email or password is incorrect. $remaining attempt${remaining > 1 ? 's' : ''} remaining.";
      }
    } catch (e) {
      // Increment failed attempts for general errors too
      await _incrementFailedAttempt(email);

      final attempts = getAttemptCount(email);
      if (attempts >= 3) {
        return "Too many failed attempts. Your account has been locked for 5 minutes.";
      } else {
        return "An error occurred. Please try again.";
      }
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

      // Reset login attempts on successful 2FA verification
      if (_tempEmail != null) {
        await _resetLoginAttempts(_tempEmail!);
      }

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

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      final user = userCredential.user;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          // Get latest formatted_uid for Google sign-in users too
          final snapshot = await _firestore
              .collection('users')
              .orderBy('formatted_uid', descending: true)
              .limit(1)
              .get();

          int newFormattedUid = 1000;
          if (snapshot.docs.isNotEmpty) {
            final latestDoc = snapshot.docs.first.data();
            final latestFormattedUidField = latestDoc['formatted_uid'];

            if (latestFormattedUidField is int) {
              newFormattedUid = latestFormattedUidField + 1;
            } else if (latestFormattedUidField is String) {
              newFormattedUid =
                  (int.tryParse(latestFormattedUidField) ?? 999) + 1;
            }
          }

          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'formatted_uid': newFormattedUid,
            'name': user.displayName ?? '',
            'name_lowercase': (user.displayName ?? '').toLowerCase(),
            'email': user.email,
            'email_lowercase': (user.email ?? '').toLowerCase(),
            'userType': '',
            'age': '',
            'photoUrl': user.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
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
}
