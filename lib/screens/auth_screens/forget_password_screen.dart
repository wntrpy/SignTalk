import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:signtalk/providers/auth_provider.dart' as authentication;
import 'package:signtalk/widgets/textfields/custom_textfield_auth.dart';
import 'package:signtalk/widgets/buttons/custom_button.dart';
import 'package:signtalk/widgets/custom_signtalk_logo.dart';
import 'package:signtalk/app_constants.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

     @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  String? _emailerror; 
  bool _isLoading = false;

  Future<void> _submit() async {
    setState(() {
      _emailerror = null;
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final provider = Provider.of<authentication.AuthProvider>(context, listen: false);

    try {
      final exists = await provider.resetPasswordIfExists(email);
      if (!mounted) return;

      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reset link sent to $email')),
        );
        context.push('/login_screen'); // Navigate to login screen after successful submission
      } else {
        setState(() {
          _emailerror = 'Email not found';
        });
      }
    } catch (e) {

      if (!mounted) return;
      setState(() {
        _emailerror = 'Something went wrong. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        context.pop(); // goto previos page ion the stack
        return false; // block system back button's default exit
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(AppConstants.signtalk_bg, fit: BoxFit.cover),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 80),

              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomSigntalkLogo(width: 150, height: 150),
                  SizedBox(height: 50),

                  //------------------------------------EMAIL/USERNAME-------------------------------------------------//
                  CustomTextfieldAuth(
                    labelText: "Enter your email address",
                    controller: _emailController,
                    errorText: _emailerror,
                  ),

                  SizedBox(height: 40),

                  //------------------------------------SUBMIT-------------------------------------------------//
                  CustomButton(
                    buttonText:"SUBMIT",
                    colorCode: AppConstants.orange,
                    buttonWidth: 250,
                    buttonHeight: 70,
                    onPressed: _isLoading ? () {} : () { _submit(); }, //TODO: FIX LATER
                    textSize: 18,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
