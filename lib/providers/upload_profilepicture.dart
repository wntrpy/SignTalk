import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;


Future<void> uploadProfilePicture(BuildContext context) async {
  final picker = ImagePicker();
  final uid = FirebaseAuth.instance.currentUser?.uid;
  
  if (uid == null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User not signed in")));
    return;
  }

  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
  if (pickedFile == null) return;

  final file = File(pickedFile.path);
   final extension = path.extension(pickedFile.path); // e.g. .jpg, .png

  try {
    // Upload to Firebase Storage
    final ref = FirebaseStorage.instance.ref().child('profile_pictures/$uid$extension');
    final uploadTask = await ref.putFile(file);
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    // Update Firestore with new profile URL
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'photoUrl': downloadUrl,
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Profile picture updated!")));
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
  }
}
