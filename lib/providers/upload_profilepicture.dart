import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

/// Shows a bottom sheet to let user choose between camera or gallery
Future<void> uploadProfilePicture(BuildContext context) async {
  final ImageSource? source = await showModalBottomSheet<ImageSource>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Choose Profile Picture',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Colors.blue),
            title: const Text('Take Photo'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: Colors.green),
            title: const Text('Choose from Gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.cancel, color: Colors.red),
            title: const Text('Cancel'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    ),
  );

  if (source != null) {
    await _pickAndUploadImage(context, source);
  }
}

/// Picks image and uploads to Firebase Storage
Future<void> _pickAndUploadImage(
  BuildContext context,
  ImageSource source,
) async {
  final picker = ImagePicker();
  final uid = FirebaseAuth.instance.currentUser?.uid;

  if (uid == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User not signed in")));
    }
    return;
  }

  try {
    // Pick image
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    if (context.mounted) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    final file = File(pickedFile.path);
    final extension = path.extension(pickedFile.path);

    // Delete old profile picture if it exists
    try {
      // Try to list and delete all profile pictures for this user
      final listResult = await FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .listAll();

      for (var item in listResult.items) {
        if (item.name.startsWith(uid)) {
          await item.delete();
          debugPrint('Deleted old profile picture: ${item.name}');
        }
      }
    } catch (e) {
      // Old file might not exist, ignore error
      debugPrint('Old profile picture not found or already deleted: $e');
    }

    // Upload new profile picture with timestamp to ensure uniqueness
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '$uid-$timestamp$extension';
    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_pictures')
        .child(fileName);

    final uploadTask = ref.putFile(file);

    // Optional: Monitor upload progress
    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      final progress = snapshot.bytesTransferred / snapshot.totalBytes;
      debugPrint('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
    });

    await uploadTask;
    final downloadUrl = await ref.getDownloadURL();

    // Update Firestore
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'photoUrl': downloadUrl,
    });

    if (context.mounted) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile picture updated!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.pop(context); // Close loading dialog if open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error uploading image: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
    debugPrint('Error uploading profile picture: $e');
  }
}

/// Call this when user first registers to initialize with empty photoUrl
Future<void> initializeUserProfile({
  required String uid,
  required String name,
  required String email,
  String age = '',
  String userType = '',
}) async {
  try {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'age': age,
      'userType': userType,
      'photoUrl': '', // Empty string means use initial letter
      'createdAt': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    debugPrint('Error initializing user profile: $e');
    rethrow;
  }
}
