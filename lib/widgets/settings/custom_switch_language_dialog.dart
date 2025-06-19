import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signtalk/app_constants.dart';
import 'package:signtalk/widgets/buttons/custom_button.dart';
import 'package:signtalk/widgets/buttons/custom_text_button.dart';
import 'package:signtalk/widgets/settings/custom_radio_option.dart';

class CustomSwitchLanguageDialog extends StatefulWidget {
  const CustomSwitchLanguageDialog({super.key});

  @override
  State<CustomSwitchLanguageDialog> createState() =>
      _CustomSwitchLanguageDialogState();
}

class _CustomSwitchLanguageDialogState
    extends State<CustomSwitchLanguageDialog> {
  String selectedSignLanguage = 'ASL';
  String selectedInAppLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //------------------------------------TITLE SIGN LANGUAGE-------------------------------------------------//
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Color(0xFF6F22A3), // dark violet
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Select Sign language:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),

            //------------------------------------ASL OPTION-------------------------------------------------//
            CustomRadioOption(
              label: 'American Sign Language (ASL)',
              value: 'ASL',
              groupValue: selectedSignLanguage,
              onChanged: (value) {
                setState(() => selectedSignLanguage = value);
              },
            ),

            //------------------------------------FSL OPTION-------------------------------------------------//
            CustomRadioOption(
              label: 'Filipino Sign Language (FSL)',
              value: 'FSL',
              groupValue: selectedSignLanguage,
              onChanged: (value) {
                setState(() => selectedSignLanguage = value);
              },
            ),

            const SizedBox(height: 16),

            //------------------------------------TITLE IN-APP LANGUAGE------------------------------------------------//
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Color(0xFF6F22A3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Select In-App Language:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),

            //------------------------------------ENGLIUSH------------------------------------------------//
            CustomRadioOption(
              label: 'English',
              value: 'English',
              groupValue: selectedInAppLanguage,
              onChanged: (value) {
                setState(() => selectedInAppLanguage = value);
              },
            ),

            //------------------------------------FILIPINO------------------------------------------------//
            CustomRadioOption(
              label: 'Filipino',
              value: 'Filipino',
              groupValue: selectedInAppLanguage,
              onChanged: (value) {
                setState(() => selectedInAppLanguage = value);
              },
            ),

            const SizedBox(height: 24),

            //------------------------------------BUTTONS------------------------------------------------//
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomTextButton(
                  buttonText: 'Cancel',
                  onPressed: () => context.pop(context),
                  textColor: Colors.black,
                ),

                CustomButton(
                  buttonText: "Confirm",
                  colorCode: AppConstants.orange,
                  buttonWidth: 120,
                  buttonHeight: 50,
                  onPressed: () {
                    //TODO: backend
                    print('Sign Language: $selectedSignLanguage');
                    print('App Language: $selectedInAppLanguage');
                    context.pop(context);
                  },
                  textSize: null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
