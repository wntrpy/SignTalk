import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:signtalk/providers/auth_provider.dart';
import 'package:signtalk/widgets/textfields/custom_textfield_auth.dart';
import 'package:signtalk/widgets/buttons/custom_button.dart';
import 'package:signtalk/widgets/textfields/custom_password_textfield.dart';
import 'package:signtalk/widgets/custom_signtalk_logo.dart';
import 'package:signtalk/widgets/buttons/custom_text_button.dart';
import 'package:signtalk/app_constants.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:signtalk/core/loginscreen_validator.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Add these keys
  static const String KEY_EMAIL = 'last_login_email';
  static const String KEY_IS_LOCKED = 'is_locked_out';
  static const String KEY_LOCKOUT_END = 'lockout_end_time';

  final emailcontroller = TextEditingController();
  final passcontroller = TextEditingController();
  String? _loginError;
  bool _isLockedOut = false;
  int _remainingSeconds = 0;
  Timer? _countdownTimer;

  final GlobalKey<FormState> _formKey1 = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      if (mounted) {
        setState(() {});
      }
    });
    _googleSignIn.signInSilently();

    // Load saved state when screen initializes
    _loadSavedState();
  }

  // Add this method to load saved state
  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();

    // Load saved email
    final savedEmail = prefs.getString(KEY_EMAIL);
    if (savedEmail != null) {
      emailcontroller.text = savedEmail;
    }

    // Load lockout state
    final isLocked = prefs.getBool(KEY_IS_LOCKED) ?? false;
    if (isLocked) {
      final lockoutEndTime = DateTime.fromMillisecondsSinceEpoch(
        prefs.getInt(KEY_LOCKOUT_END) ?? 0,
      );

      if (DateTime.now().isBefore(lockoutEndTime)) {
        final remaining = lockoutEndTime.difference(DateTime.now()).inSeconds;
        if (remaining > 0) {
          _startCountdown(remaining);
        }
      } else {
        // Clear expired lockout
        await _clearSavedLockoutState();
      }
    }

    // Load lockout data from provider
    await _loadLockoutData();
  }

  // Add method to save lockout state
  Future<void> _saveLockoutState(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutEnd = DateTime.now().add(Duration(seconds: seconds));

    await prefs.setString(KEY_EMAIL, emailcontroller.text);
    await prefs.setBool(KEY_IS_LOCKED, true);
    await prefs.setInt(KEY_LOCKOUT_END, lockoutEnd.millisecondsSinceEpoch);
  }

  // Add method to clear lockout state
  Future<void> _clearSavedLockoutState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(KEY_IS_LOCKED);
    await prefs.remove(KEY_LOCKOUT_END);
  }

  // Load lockout data when screen initializes
  Future<void> _loadLockoutData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.loadLockoutData();

    // Check if current email is locked out after loading data
    final email = emailcontroller.text.trim();
    if (email.isNotEmpty && authProvider.isLockedOut(email)) {
      final remaining = authProvider.getRemainingLockoutTime(email);
      if (remaining > 0) {
        _startCountdown(remaining);
      }
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    // Don't clear controllers here since we want to persist the values
    super.dispose();
  }

  void _startCountdown(int seconds) {
    setState(() {
      _isLockedOut = true;
      _remainingSeconds = seconds;
      _loginError = "locked_out";
    });

    // Save lockout state
    _saveLockoutState(seconds);

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          _isLockedOut = false;
          _loginError = null;
          timer.cancel();
          _clearSavedLockoutState(); // Clear saved state when lockout expires
          if (_formKey1.currentState != null) {
            _formKey1.currentState!.validate();
          }
        } else {
          if (_formKey1.currentState != null) {
            _formKey1.currentState!.validate();
          }
        }
      });
    });
  }

  Future<void> _handlelogin() async {
    final email = emailcontroller.text.trim();
    final password = passcontroller.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _loginError = "Please enter both email and password";
      });
      _formKey1.currentState!.validate();
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // check if locked out before attempting login
    if (authProvider.isLockedOut(email)) {
      final remaining = authProvider.getRemainingLockoutTime(email);
      _startCountdown(remaining);
      _formKey1.currentState!.validate();
      return;
    }

    setState(() {
      _loginError = null;
    });

    final error = await authProvider.signInWith2FA(email, password);

    if (!mounted) return;

    if (error == null) {
      // Success - proceed to 2FA
      context.push('/2FA_screen');
    } else {
      // Check if now locked out after this attempt
      if (authProvider.isLockedOut(email)) {
        final remaining = authProvider.getRemainingLockoutTime(email);
        _startCountdown(remaining);
      } else {
        setState(() {
          _loginError = error;
        });
      }
      _formKey1.currentState!.validate();
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String? _getEmailError(String? value) {
    // priority 1: Show lockout message if locked out
    if (_isLockedOut && _loginError == "locked_out") {
      return "Too many failed attempts. Please try again in ${_formatTime(_remainingSeconds)}";
    }

    // priority 2: Show other login errors (wrong password, etc)
    if (_loginError != null && _loginError != "locked_out") {
      return LoginscreenValidator.emailValidator(
        value,
        loginError: _loginError,
      );
    }

    // priority 3: Show validation errors
    return LoginscreenValidator.emailValidator(value, loginError: null);
  }

  String? _getPasswordError(String? value) {
    // Only show error state when locked out, don't duplicate message
    if (_isLockedOut && _loginError == "locked_out") {
      return " "; // Empty space to show error state without duplicate message
    }

    // Show other password-related errors
    if (_loginError != null && _loginError != "locked_out") {
      return LoginscreenValidator.passwordValidator(
        value,
        loginError: _loginError,
      );
    }

    return LoginscreenValidator.passwordValidator(value, loginError: null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(AppConstants.signtalk_bg, fit: BoxFit.cover),

          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 56.0, vertical: 80),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                CustomSigntalkLogo(width: 120, height: 120),

                SizedBox(height: 20),

                // Error/Info banner at the top
                if (_isLockedOut)
                  Container(
                    margin: EdgeInsets.only(bottom: 20),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade400, width: 2),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade700,
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Account Locked",
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Too many failed attempts.\nPlease come back after ${_formatTime(_remainingSeconds)}",
                                style: TextStyle(
                                  color: Colors.red.shade900,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                Form(
                  key: _formKey1,
                  child: Column(
                    children: [
                      CustomTextfieldAuth(
                        labelText: "Email",
                        controller: emailcontroller,
                        errorText: null,
                        enabled: !_isLockedOut,
                        validator: _getEmailError,
                      ),
                      SizedBox(height: 20),

                      CustomPasswordField(
                        controller: passcontroller,
                        labelText: "Password",
                        enabled: !_isLockedOut,
                        validator: _getPasswordError,
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                ),

                Align(
                  alignment: Alignment.centerLeft,
                  child: CustomTextButton(
                    buttonText: "Forgot Password?",
                    onPressed: _isLockedOut
                        ? null
                        : () => context.push('/forget_password_screen'),
                  ),
                ),

                SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 150,
                    child: CustomButton(
                      buttonText: "Login",
                      colorCode: _isLockedOut
                          ? Colors.grey
                          : AppConstants.orange,
                      buttonWidth: 110,
                      buttonHeight: 45,
                      onPressed: _isLockedOut ? null : _handlelogin,
                      textColor: AppConstants.white,
                      textSize: AppConstants.fontSizeLarge,
                    ),
                  ),
                ),

                SizedBox(height: 40),

                Column(
                  children: [
                    CustomButton(
                      buttonText: 'Sign Up',
                      colorCode: AppConstants.white,
                      buttonWidth: 120,
                      buttonHeight: 40,
                      onPressed: () => context.push('/registration_screen'),
                      textColor: AppConstants.black,
                      textSize: AppConstants.fontSizeMedium,
                    ),

                    Padding(
                      padding: EdgeInsets.only(top: 12, bottom: 12),
                      child: Text(
                        "OR",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: AppConstants.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    CustomButton(
                      buttonText: 'Log in with Google',
                      colorCode: AppConstants.white,
                      buttonWidth: 200,
                      buttonHeight: 45,
                      onPressed: () async {
                        final authProvider = Provider.of<AuthProvider>(
                          context,
                          listen: false,
                        );
                        final result = await authProvider.signInWithGoogle();
                        if (result == "success") {
                          context.push('/home_screen');
                        } else if (result == "error") {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Google sign-in failed. Please try again.",
                              ),
                            ),
                          );
                        }
                      },
                      textColor: AppConstants.black,
                      icon: Image.asset(AppConstants.google_logo),
                      textSize: AppConstants.fontSizeMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
