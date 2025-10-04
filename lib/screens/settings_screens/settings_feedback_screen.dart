import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void showFeedbackDialog(BuildContext context) {
  final TextEditingController feedbackController = TextEditingController();

  showDialog(
    context: context,
    barrierDismissible: false, // Prevent closing by tapping outside
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: const Text(
                "Send us some feedback!",
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: "Alata",
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Content
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: feedbackController,
                    maxLines: 8,
                    style: const TextStyle(fontFamily: "Alata"),
                    decoration: InputDecoration(
                      hintText: "Input your feedback here...",
                      filled: true,
                      fillColor: const Color.fromARGB(255, 222, 221, 221),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: "Alata",
                            color: Colors.purple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          String feedback = feedbackController.text.trim();

                          if (feedback.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Feedback cannot be empty!",
                                  style: TextStyle(
                                    fontFamily: "Alata",
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          try {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null)
                              throw Exception("User not logged in");

                            // Fetch the formatted_uid safely
                            final userQuery = await FirebaseFirestore.instance
                                .collection('users')
                                .where('uid', isEqualTo: user.uid)
                                .limit(1)
                                .get();

                            String? formattedUid;
                            if (userQuery.docs.isNotEmpty) {
                              final doc = userQuery.docs.first;
                              if (doc.data().containsKey('formatted_uid')) {
                                final uidValue = doc.get('formatted_uid');
                                formattedUid = uidValue?.toString();
                              }
                            }

                            // Add the feedback document
                            await FirebaseFirestore.instance
                                .collection('user feedback')
                                .add({
                                  'message': feedback,
                                  'timestamp': FieldValue.serverTimestamp(),
                                  'uid': user.uid,
                                  'email': user.email,
                                  'formatted_uid': formattedUid,
                                });

                            feedbackController.clear();
                            Navigator.pop(context);

                            // Show success dialog
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) {
                                Future.delayed(const Duration(seconds: 2), () {
                                  Navigator.of(context).pop(true);
                                });
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  content: const Text(
                                    "Your feedback has been sent successfully!",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: "Alata",
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple,
                                    ),
                                  ),
                                );
                              },
                            );
                          } catch (e, stack) {
                            print("Feedback error: $e\n$stack");

                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) {
                                Future.delayed(const Duration(seconds: 2), () {
                                  Navigator.of(context).pop(true);
                                });
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  content: const Text(
                                    "Something went wrong. Please try again later.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: "Alata",
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                );
                              },
                            );
                          }
                        },
                        child: const Text(
                          "Submit",
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: "Alata",
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
