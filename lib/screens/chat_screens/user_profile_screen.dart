import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signtalk/widgets/buttons/custom_button.dart';
import 'package:signtalk/widgets/buttons/custom_circle_pfp_button.dart';
import 'package:signtalk/widgets/custom_app_bar.dart';
import 'package:signtalk/widgets/textfields/custom_line_textfield.dart';
import 'package:signtalk/app_constants.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isEditMode = false;
  //TODO: basahen mu
  //pag penendot yng button dapat:
  //mabago yung color to orange
  //mabago yung text to save
  //maenable yung pag-iinput ng text sa textfield
  //riverpod state, na nagchecheck if false or true ba yung value
  //if false, yung default button
  //if true, then change to orange and such

  //TODO: manggagaling to sa state, change mo later
  final Map<String, String> _userData = {
    'name': 'Byeon Woo Seok',
    'username': 'RyuSunJae',
    'age': '24',
    'type': 'Hearing',
    'email': 'ByeinWooSeok@gmail.com',
  };

  void _toggleEditMode() {
    setState(() => _isEditMode = !_isEditMode);
  }

  Widget _buildProfileHeader() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const CustomAppBar(appBarText: "Profile"),

        // ------------------------USER PPFP----------------------------
        CustomCirclePfpButton(
          borderColor: AppConstants.white,
          userImage: AppConstants.default_user_pfp,
          width: 100,
          height: 100,
        ),
        const SizedBox(height: 7),

        // ------------------------FULL NAME----------------------------
        Text(
          _userData['name']!,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppConstants.white,
            fontSize: AppConstants.fontSizeExtraLarge,
          ),
        ),
        const SizedBox(height: 15),

        // ------------------------EDIT/SAVE BUTTON----------------------------
        CustomButton(
          buttonText: _isEditMode ? "Save" : "Edit Profile",
          colorCode: _isEditMode
              ? AppConstants.orange
              : Theme.of(context).colorScheme.surface,
          buttonWidth: 150,
          buttonHeight: 45,
          onPressed: _toggleEditMode,
          textSize: AppConstants.fontSizeMedium,
          textColor: _isEditMode ? AppConstants.white : AppConstants.darkViolet,
        ),
      ],
    );
  }

  Widget _buildProfileForm() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // ------------------------FULL NAME FIELD----------------------------
          CustomLineTextfield(defaultValue: _userData['name']!, label: 'Name'),

          // ------------------------USERNAME FIELD----------------------------
          CustomLineTextfield(
            defaultValue: _userData['username']!,
            label: 'Username',
          ),

          // ------------------------AGE FIELD----------------------------
          CustomLineTextfield(defaultValue: _userData['age']!, label: 'Age'),

          // ------------------------USER TYPE FIELD----------------------------
          CustomLineTextfield(
            defaultValue: _userData['type']!,
            label: 'User Type',
          ),

          // ------------------------EMAIL FIELD----------------------------
          CustomLineTextfield(
            defaultValue: _userData['email']!,
            label: 'Email',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) => !didPop ? context.pop() : null,
      child: Scaffold(
        body: Column(
          children: [
            // ------------------------CONTAINER FOR PROFILE HEADER----------------------------
            SizedBox(
              height: 334,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(AppConstants.signtalk_bg, fit: BoxFit.cover),
                    _buildProfileHeader(),
                  ],
                ),
              ),
            ),

            // ------------------------CONTAINER FOR FIELDS----------------------------
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(top: 12),
                color: AppConstants.white,
                child: _buildProfileForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
