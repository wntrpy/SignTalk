import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final systemStatusProvider = FutureProvider<bool>((ref) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('system status')
      .limit(1)
      .get();

  if (snapshot.docs.isNotEmpty) {
    return snapshot.docs.first.data()['isActive'] ?? false;
  }
  return false;
});
