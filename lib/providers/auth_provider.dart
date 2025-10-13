import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  Future<int> _getNextFormattedUid() async {
    try {
      // Query Firestore to get the user with the highest formatted_uid
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(
            'formatted_uid',
            isNotEqualTo: 'ADMIN_018',
          ) // Exclude admin UIDs (if stored as string)
          .orderBy('formatted_uid', descending: true)
          .limit(1)
          .get();

      int nextUid = 1000; // Starting UID

      if (querySnapshot.docs.isNotEmpty) {
        var latestUid = querySnapshot.docs.first.get('formatted_uid');

        // If formatted_uid is stored as int
        if (latestUid is int) {
          nextUid = latestUid + 1;
        }
        // If formatted_uid is stored as String (like "1000")
        else if (latestUid is String) {
          int? parsed = int.tryParse(latestUid);
          if (parsed != null) {
            nextUid = parsed + 1;
          }
        }
      }

      return nextUid;
    } catch (e) {
      print('Error getting next formatted UID: $e');
      return 1000; // Fallback to starting UID
    }
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

      // Query only numeric formatted_uid values (ignore admin UIDs)
      final numericSnapshot = await _firestore
          .collection('users')
          .where('formatted_uid', isGreaterThanOrEqualTo: 1000)
          .where('formatted_uid', isLessThan: 1000000) // Reasonable upper limit
          .orderBy('formatted_uid', descending: true)
          .limit(1)
          .get();

      int newFormattedUid = 1000; // Default starting value

      if (numericSnapshot.docs.isNotEmpty) {
        final latestDoc = numericSnapshot.docs.first.data();
        final latestFormattedUid = latestDoc['formatted_uid'];

        print('Latest numeric formatted_uid: $latestFormattedUid');

        if (latestFormattedUid is int) {
          newFormattedUid = latestFormattedUid + 1;
          print('Calculated new formatted_uid: $newFormattedUid');
        }
      } else {
        print('No numeric formatted_uid found, starting at 1000');
      }

      print('Final formatted_uid to be assigned: $newFormattedUid');

      await _firestore.collection('users').doc(authUid).set({
        'uid': authUid,
        'formatted_uid': newFormattedUid,
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
        'registeredViaEmail': true,
        'googleLinkPromptShown': false,
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

  // Add this method at the end of AuthProvider class
  Future<void> markGoogleLinkPromptShown() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'googleLinkPromptShown': true,
        });
        notifyListeners();
      }
    } catch (e) {
      print('Error marking Google link prompt as shown: $e');
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

  Future<void> signInWithGoogle() async {
    print('=== GOOGLE SIGN-IN START ===');

    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        print('Google Sign-In cancelled by user');
        // IMPORTANT: Throw exception so caller knows it was cancelled
        throw Exception('CANCELLED');
      }

      print('Google user selected: ${googleUser.email}');

      // Check if user with this email already exists in Firestore
      final existingUserQuery = await _firestore
          .collection('users')
          .where('email_lowercase', isEqualTo: googleUser.email.toLowerCase())
          .limit(1)
          .get();

      if (existingUserQuery.docs.isNotEmpty) {
        // User exists in Firestore
        print('Found existing user with email: ${googleUser.email}');

        final existingUserDoc = existingUserQuery.docs.first;
        final existingUserData = existingUserDoc.data();

        print(
          'Existing user data: name=${existingUserData['name']}, formatted_uid=${existingUserData['formatted_uid']}',
        );

        // Check if Google is linked by looking at a flag in Firestore
        final bool isGoogleLinked = existingUserData['googleLinked'] ?? false;

        print('Google linked status: $isGoogleLinked');

        if (!isGoogleLinked) {
          // Google is NOT linked - block sign-in
          print('Google is NOT linked. Blocking sign-in.');

          // Sign out from Google immediately
          await GoogleSignIn().signOut();

          throw Exception(
            'This email is already registered with a password. '
            'To use Google Sign-In, you must link your Google account first:\n\n'
            '1. Sign in with your email and password\n'
            '2. Go to Settings\n'
            '3. Click "Link Google Account"\n\n'
            'This ensures your account data is preserved.',
          );
        }

        // Google IS linked - proceed with sign-in
        print('Google is linked. Proceeding with sign-in...');
      }

      // Safe to sign in with Google now
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      print('Signed in with Google. Firebase UID: ${userCredential.user?.uid}');

      // Check if user exists in Firestore (update or create)
      final userDocQuery = await _firestore
          .collection('users')
          .where('email_lowercase', isEqualTo: googleUser.email.toLowerCase())
          .limit(1)
          .get();

      if (userDocQuery.docs.isNotEmpty) {
        // Existing user - update online status
        final userDoc = userDocQuery.docs.first;

        await _firestore.collection('users').doc(userDoc.id).update({
          'isOnline': true,
        });

        print('Logged in with existing account data');
        print(
          'User data: name=${userDoc.data()['name']}, formatted_uid=${userDoc.data()['formatted_uid']}',
        );
        print('=== GOOGLE SIGN-IN SUCCESS (EXISTING USER) ===');
        notifyListeners();
        return;
      }

      // No existing user - create new account
      print('No existing user found. Creating new account...');

      // Get latest formatted_uid
      print('Fetching latest formatted_uid...');

      // Query only numeric formatted_uid values (ignore admin UIDs)
      final numericSnapshot = await _firestore
          .collection('users')
          .where('formatted_uid', isGreaterThanOrEqualTo: 1000)
          .where('formatted_uid', isLessThan: 1000000) // Reasonable upper limit
          .orderBy('formatted_uid', descending: true)
          .limit(1)
          .get();

      int newFormattedUid = 1000; // Default starting value

      if (numericSnapshot.docs.isNotEmpty) {
        final latestDoc = numericSnapshot.docs.first.data();
        final latestFormattedUid = latestDoc['formatted_uid'];

        print('Latest numeric formatted_uid: $latestFormattedUid');

        if (latestFormattedUid is int) {
          newFormattedUid = latestFormattedUid + 1;
          print('Calculated new formatted_uid: $newFormattedUid');
        }
      } else {
        print('No numeric formatted_uid found, starting at 1000');
      }

      print('Final formatted_uid to be assigned: $newFormattedUid');

      // Create new user document
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'uid': userCredential.user?.uid,
        'formatted_uid': newFormattedUid,
        'name': googleUser.displayName ?? 'User',
        'name_lowercase': (googleUser.displayName ?? 'User').toLowerCase(),
        'age': '',
        'userType': '',
        'isOnline': true,
        'email': googleUser.email,
        'email_lowercase': googleUser.email.toLowerCase(),
        'firebase_uid': userCredential.user?.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'photoUrl': googleUser.photoUrl ?? '',
        'googleLinked': true,
      });

      print(
        'New Google user saved to Firestore with formatted_uid: $newFormattedUid',
      );
      print('=== GOOGLE SIGN-IN SUCCESS (NEW USER) ===');
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during Google Sign-In: ${e.code}');

      if (e.code == 'account-exists-with-different-credential') {
        throw Exception('An account with this email already exists');
      } else if (e.code == 'invalid-credential') {
        throw Exception('Invalid Google credentials');
      } else if (e.code == 'user-disabled') {
        throw Exception('This account has been disabled');
      } else {
        throw Exception(e.message ?? 'Google Sign-In failed');
      }
    } catch (e) {
      print('General exception during Google Sign-In: $e');
      print('=== GOOGLE SIGN-IN FAILED ===');

      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Google Sign-In failed: ${e.toString()}');
    }
  }

  // Link Google to existing email/password account
  Future<void> linkGoogleAccount() async {
    print('=== LINKING GOOGLE ACCOUNT START ===');

    try {
      User? currentUser = _auth.currentUser;

      if (currentUser == null) {
        throw Exception('You must be signed in to link a Google account');
      }

      print('Current user UID: ${currentUser.uid}');

      // Check if Google is already linked in Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final bool isGoogleLinked = userData?['googleLinked'] ?? false;

        if (isGoogleLinked) {
          throw Exception('Google account is already linked');
        }
      }

      // Trigger Google Sign-In
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        print('Google Sign-In cancelled');
        return;
      }

      // Verify the email matches
      if (googleUser.email.toLowerCase() != currentUser.email?.toLowerCase()) {
        await GoogleSignIn().signOut();
        throw Exception(
          'Please use the same email (${currentUser.email}) for linking',
        );
      }

      // Get auth credentials
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Link the credential to current user
      await currentUser.linkWithCredential(credential);

      // Update Firestore to mark Google as linked
      await _firestore.collection('users').doc(currentUser.uid).update({
        'googleLinked': true,
      });

      print('Google account linked successfully!');
      print('User can now sign in with both email/password and Google');
      print('=== LINKING GOOGLE ACCOUNT SUCCESS ===');

      notifyListeners();
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during linking: ${e.code}');

      if (e.code == 'provider-already-linked') {
        throw Exception('Google account is already linked');
      } else if (e.code == 'credential-already-in-use') {
        throw Exception(
          'This Google account is already used by another account',
        );
      } else if (e.code == 'email-already-in-use') {
        throw Exception('This email is already in use');
      } else {
        throw Exception(e.message ?? 'Failed to link Google account');
      }
    } catch (e) {
      print('General exception during linking: $e');
      print('=== LINKING GOOGLE ACCOUNT FAILED ===');

      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to link Google account: ${e.toString()}');
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_login_email');
    await prefs.remove('is_locked_out');
    await prefs.remove('lockout_end_time');

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
