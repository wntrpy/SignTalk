import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signtalk/app_constants.dart';
import 'package:signtalk/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:signtalk/widgets/buttons/custom_button.dart';
import 'package:signtalk/widgets/buttons/custom_text_button.dart';
import 'package:signtalk/widgets/textfields/custom_textfield_auth.dart';

class TwoFactorScreen extends StatefulWidget {
  const TwoFactorScreen({super.key});

  @override
  State<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends State<TwoFactorScreen> {
  final TextEditingController _codeController = TextEditingController();
  String _error = '';
  bool _isLoading = false;
  bool _resendDisabled = false;

  void _verifyCode(AuthProvider authProvider) async {
    setState(() => _isLoading = true);
    final isValid = await authProvider.verify2FACode(
      _codeController.text.trim(),
    );
    setState(() => _isLoading = false);

    if (isValid) {
      final email = authProvider.tempEmail;
      final password = authProvider.tempPassword;

      if (email != null && password != null) {
        try {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          context.go('/home_screen');
        } catch (e) {
          setState(() => _error = 'Failed to sign in after 2FA.');
        }
      } else {
        setState(() => _error = 'Missing credentials. Please try again.');
      } 
    } else {
        setState(() => _error = 'Invalid verification code.');
      } 
  }

  void _resendCode(AuthProvider authProvider) async {
    if (_resendDisabled) return;
    setState(() {
      _resendDisabled = true;
      _error = '';
    });

    try {
      await authProvider.resend2FACode();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Verification code resent')));
    } catch (e) {
      setState(() => _error = 'Failed to resend code');
    }

    await Future.delayed(const Duration(seconds: 30)); // prevent spamming
    setState(() => _resendDisabled = false);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppConstants.signtalk_bg),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Enter the 6-digit code sent to your email',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "Didn't get the code? Check your spam folder.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              CustomTextfieldAuth(
                labelText: 'Verification Code',
                controller: _codeController,
                errorText: _error.isNotEmpty ? _error : null,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                CustomButton(
                  buttonText: "Verify",
                  colorCode: AppConstants.orange,
                  buttonWidth: 150,
                  buttonHeight: 50,
                  onPressed: () => _verifyCode(authProvider),
                  textSize: 12,
                ),
              CustomTextButton(
                buttonText: 'Resend Code',
                onPressed: _resendDisabled ? () {} : () => _resendCode(authProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
