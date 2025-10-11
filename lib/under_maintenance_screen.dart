import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_constants.dart';

class UnderMaintenanceScreen extends StatefulWidget {
  const UnderMaintenanceScreen({super.key});

  @override
  State<UnderMaintenanceScreen> createState() => _UnderMaintenanceScreenState();
}

class _UnderMaintenanceScreenState extends State<UnderMaintenanceScreen> {
  bool isActive = false; // true = app active, false = under maintenance

  @override
  void initState() {
    super.initState();
    _checkSystemStatus();
  }

  Future<void> _checkSystemStatus() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('system status')
          .doc('04N5OCS28bovQuovDRIS')
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('isActive')) {
          isActive = data['isActive'] == true;
        }
      }

      if (isActive && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/home');
        });
      }
    } catch (e) {
      debugPrint("Error checking maintenance status: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to check maintenance status: $e'),
            backgroundColor: AppConstants.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppConstants.signtalk_bg),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    AppConstants.signtalk_logo,
                    height: 200,
                    width: 200,
                  ),
                  const SizedBox(height: 40),

                  // Content Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppConstants.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppConstants.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.build_circle_rounded,
                          size: 70,
                          color: AppConstants.lightViolet,
                        ),
                        const SizedBox(height: 24),

                        Text(
                          "Under Maintenance",
                          style: TextStyle(
                            fontSize: AppConstants.fontSizeExtraLarge,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.darkViolet,
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          "We're working hard to improve SignTalk for you.\nPlease check back later.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: AppConstants.fontSizeMedium,
                            color: AppConstants.lightViolet,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
