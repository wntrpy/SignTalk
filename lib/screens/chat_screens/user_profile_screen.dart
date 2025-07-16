import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signtalk/providers/auth_provider.dart'as authprovider; 
import 'package:signtalk/widgets/buttons/custom_button.dart';
import 'package:signtalk/widgets/buttons/custom_circle_pfp_button.dart';
import 'package:signtalk/widgets/custom_app_bar.dart';
import 'package:signtalk/widgets/textfields/custom_line_textfield.dart';
import 'package:signtalk/app_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:signtalk/providers/edit_mode_provider.dart';
import 'package:signtalk/providers/user_model.dart';
import 'package:signtalk/providers/upload_profilepicture.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  UserModel? _userModel; //Keeps last loaded user data
  bool _isEditingName = false;
  bool _isEditingAge = false;
  

//controller allocates memory, use .dispose() to free up memory after use
  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _saveField(String field, String value) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  await FirebaseFirestore.instance.collection('users').doc(uid).update({
    field: value,
  });
}

bool _toggleEditMode() {
  final current = ref.read(isEditModeProvider);
  ref.read(isEditModeProvider.notifier).state = !current;
  return !current;
}
  Widget _buildProfileHeader(UserModel user, BuildContext context) {
    final isEditMode = ref.watch(isEditModeProvider);

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const CustomAppBar(appBarText: "Profile"),
        CustomCirclePfpButton(
          borderColor: AppConstants.white,
          userImage: user.photoUrl ?? AppConstants.default_user_pfp,
          width: 120,
          height: 120,
       
        ),
        const SizedBox(height: 7),
        Text(
          user.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppConstants.white,
            fontSize: AppConstants.fontSizeExtraLarge,
          ),
        ),
        const SizedBox(height: 15),
        CustomButton(
          buttonText: isEditMode ? "Save" : "Edit Profile",
          colorCode: isEditMode
              ? AppConstants.orange
              : Theme.of(context).colorScheme.surface,
          buttonWidth: 150,
          buttonHeight: 45,
           onPressed: () async {
          if (_toggleEditMode()) {
            await uploadProfilePicture(context);
           }
          },
          textSize: AppConstants.fontSizeMedium,
          textColor: isEditMode ? AppConstants.white : AppConstants.darkViolet,
        ),
      ],
    );
  }

  Widget _buildProfileForm(UserModel user, bool isEditMode) {
    return Column(
      children: [
          // --- NAME FIELD WITH EDIT/SAVE BUTTON ---
        Row(
      children: [
        Expanded(
          child: CustomLineTextfield(
            defaultValue: _nameController.text,
            label: 'Name',
            enabled: _isEditingName,
            controller: _nameController,
          ),
        ),
        const SizedBox(width: 8),
        CustomButton(
          buttonText: _isEditingName ? "Save" : "Edit",
          colorCode: _isEditingName ? AppConstants.orange : Theme.of(context).colorScheme.surface,
          textColor: _isEditingName ? AppConstants.white : AppConstants.darkViolet,
          buttonWidth: 70,
          buttonHeight: 38,
          textSize: 14,
          onPressed: () async {
            if (_isEditingName) {
              await _saveField("name", _nameController.text);
            }
            setState(() {
              _isEditingName = !_isEditingName;
            });
          },
        ),
      ],
    ),

        // --- AGE FIELD WITH EDIT/SAVE BUTTON ---
       Row(
          children: [
            Expanded(
              child: CustomLineTextfield(
                defaultValue: _ageController.text,
                label: 'Age',
                enabled: _isEditingAge,
                controller: _ageController,
              ),
            ),
            const SizedBox(width: 8),
            CustomButton(
              buttonText: _isEditingAge ? "Save" : "Edit",
              colorCode: _isEditingAge ? AppConstants.orange : Theme.of(context).colorScheme.surface,
              textColor: _isEditingAge ? AppConstants.white : AppConstants.darkViolet,
              buttonWidth: 70,
              buttonHeight: 38,
              textSize: 14,
              onPressed: () async {
                if (_isEditingAge) {
                  await _saveField("age", _ageController.text);
                }
                setState(() {
                  _isEditingAge = !_isEditingAge;
                });
              },
            ),
          ],
        ),
        
        CustomLineTextfield(
          defaultValue: user.userType,
          label: 'User Type',
          enabled: false,
        ),
        CustomLineTextfield(
          defaultValue: user.email,
          label: 'Email',
          enabled: false,
        ),
        const SizedBox(height: 30),
        CustomButton(
          buttonText: 'Log out',
          colorCode: AppConstants.orange,
          textColor: AppConstants.white,
          buttonWidth: 150,
          buttonHeight: 45,
          textSize: AppConstants.fontSizeMedium,
          borderRadiusValue: 10,
          onPressed: () async {
            await ref.read(authprovider.authProvider).signOut();
            context.go('/login_screen');
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = ref.watch(isEditModeProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return const Center(child: Text('User not logged in'));

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) => !didPop ? context.pop() : null,
      child: Scaffold(
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text("User data not found."));
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final user = UserModel.fromMap(data);

            // Only update controllers if user changed (avoid reset on every rebuild)
            if (_userModel == null || _userModel!.uid != user.uid || !isEditMode) {
              _nameController.text = user.name;
              _ageController.text = user.age;
              _userModel = user;
            }

            return Column(
              children: [
                Expanded(
                  flex: 2,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(AppConstants.signtalk_bg, fit: BoxFit.cover),
                        _buildProfileHeader(user, context),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.only(top: 12),
                    color: AppConstants.white,
                    child: _buildProfileForm(user, isEditMode),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
