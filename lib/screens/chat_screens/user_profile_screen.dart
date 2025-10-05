import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signtalk/app_colors.dart';
import 'package:signtalk/widgets/buttons/custom_button.dart';
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
  final List<String> userTypes = ['Hearing', 'Non-Hearing'];
  UserModel? _userModel;
  bool _isEditingName = false;
  bool _isEditingAge = false;
  String? selectedUserType;

  @override
  void initState() {
    super.initState();
    print('Current User: ${FirebaseAuth.instance.currentUser?.uid}');
    print('Is Authenticated: ${FirebaseAuth.instance.currentUser != null}');
  }

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

        // -------------------- Profile Picture -------------------- \\
        Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.of(context).surface,
              backgroundImage:
                  (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                  ? NetworkImage(user.photoUrl!)
                  : null,
              child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                  ? Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : "?",
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.darkViolet,
                      ),
                    )
                  : null,
            ),
            // Edit icon button overlay (only in edit mode)
            if (isEditMode)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () async {
                    await uploadProfilePicture(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.orange,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.of(context).surface,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: AppColors.of(context).surface,
                      size: 20,
                    ),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 7),
        Text(
          user.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.of(context).surface,
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
          onPressed: () {
            _toggleEditMode();
          },
          textSize: AppConstants.fontSizeMedium,
          textColor: isEditMode
              ? AppColors.of(context).surface
              : AppConstants.darkViolet,
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
              colorCode: _isEditingName
                  ? AppConstants.orange
                  : Theme.of(context).colorScheme.surface,
              textColor: _isEditingName
                  ? AppColors.of(context).surface
                  : AppConstants.darkViolet,
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
              colorCode: _isEditingAge
                  ? AppConstants.orange
                  : Theme.of(context).colorScheme.surface,
              textColor: _isEditingAge
                  ? AppColors.of(context).surface
                  : AppConstants.darkViolet,
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

        // --- USER TYPE LABEL + DROPDOWN FIELD WITH SAVE BUTTON ONLY IF NULL ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Text(
                  'User Type',
                  style: TextStyle(
                    fontSize: AppConstants.fontSizeSmall,
                    color: AppConstants.darkViolet,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: DropdownButtonFormField<String>(
                        value: selectedUserType,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.only(bottom: 8.0),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(color: Colors.black),
                        dropdownColor: AppColors.of(context).background,
                        items: userTypes
                            .map(
                              (String item) => DropdownMenuItem<String>(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged:
                            (_userModel?.userType == null ||
                                _userModel!.userType.isEmpty)
                            ? (value) =>
                                  setState(() => selectedUserType = value)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if ((_userModel?.userType == null ||
                          _userModel!.userType.isEmpty) &&
                      selectedUserType != null)
                    CustomButton(
                      buttonText: "Save",
                      colorCode: AppConstants.orange,
                      textColor: AppColors.of(context).surface,
                      buttonWidth: 70,
                      buttonHeight: 38,
                      textSize: 14,
                      onPressed: () async {
                        await _saveField("userType", selectedUserType!);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("User type saved.")),
                          );
                        }
                      },
                    ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Divider(thickness: 1, color: Colors.black, height: 1),
              ),
            ],
          ),
        ),

        CustomLineTextfield(
          defaultValue: user.email,
          label: 'Email',
          enabled: false,
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
        resizeToAvoidBottomInset: true,
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text("User data not found."));
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final user = UserModel.fromMap(data);

            if (_userModel == null ||
                _userModel!.uid != user.uid ||
                !isEditMode) {
              _nameController.text = user.name;
              _ageController.text = user.age;
              selectedUserType = user.userType.isNotEmpty
                  ? user.userType
                  : selectedUserType;
              _userModel = user;
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.40,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            AppConstants.signtalk_bg,
                            fit: BoxFit.cover,
                          ),
                          _buildProfileHeader(user, context),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(top: 12),
                    color: AppColors.of(context).surface,
                    child: _buildProfileForm(user, isEditMode),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
