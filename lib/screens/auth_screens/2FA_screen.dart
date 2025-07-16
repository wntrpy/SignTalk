import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signtalk/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

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
    final isValid = await authProvider.verify2FACode(_codeController.text.trim());
    setState(() => _isLoading = false);

    if (isValid) {
  final email = authProvider.tempEmail;
  final password = authProvider.tempPassword;

  if (email != null && password != null) {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      context.go('/home_screen');
    } catch (e) {
      setState(() => _error = 'Failed to sign in after 2FA.');
    }
  } else {
    setState(() => _error = 'Missing credentials. Please try again.');
    }
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification code resent')));
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
      appBar: AppBar(title: const Text('2FA Verification')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text('Enter the 6-digit code sent to your email'),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Verification Code',
                errorText: _error.isNotEmpty ? _error : null,
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: () => _verifyCode(authProvider),
                child: const Text('Verify'),
              ),
            TextButton(
              onPressed: _resendDisabled ? null : () => _resendCode(authProvider),
              child: const Text('Resend Code'),
            ),
          ],
        ),
      ),
    );
  }
}
