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

final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();

}
class _LoginScreenState extends State<LoginScreen> {

  //TODO: AYUSIN MO LATER
  //TODO: PAKIAYOS YUNG ERROR SA WRONG EMAIL OR PASSWORD 
  //WAG MONG PAGHIWALAYIN YUNG PAGLABAS NG ERROR ang gamitin mo ay(Email or Password is incorrect)
  //sa taas mo na lang na part ilabas yung error message na (Email or Password is incorrect)
  final emailcontroller = TextEditingController();
  final passcontroller = TextEditingController();
  String? _loginError; // Variable to hold login error message
  
  
  final GlobalKey<FormState> _formKey1 = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
      _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
        if(mounted){
          setState(() {});
        }
  });
    _googleSignIn.signInSilently();
  }

Future<void> _handlelogin() async {
  final email = emailcontroller.text.trim();
  final password = passcontroller.text.trim();  
    _loginError = null;

 if (_formKey1.currentState!.validate()) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final error = await authProvider.signInWith2FA(email, password);

    if (!mounted) return;

    if (error == null) {
      context.push('/2FA_screen');
    } else {
      // General login failure
      setState(() {
        _loginError = LoginscreenValidator.bothLoginError;
      });
      _formKey1.currentState!.validate(); // Triggers re-validation
    }
  }
}
                          
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          false, // prevents resize pag enabled yung on-screen keeb
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(AppConstants.signtalk_bg, fit: BoxFit.cover),

          // prevents overflow
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 56.0, vertical: 80),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // SignTalk logo
                CustomSigntalkLogo(width: 120, height: 120),

                SizedBox(height: 20),

                //------------------------------------INPUT-FIELDS-------------------------------------------------//
                Form(
                key: _formKey1,
                child: Column(
                  children: [
                    //------------------------------------USERNAME OR EMAIL-------------------------------------------------//
                    CustomTextfieldAuth(
                      labelText: "Email",
                      controller: emailcontroller,
                      errorText: null, //TODO: add error text validation
                      validator:(value) => LoginscreenValidator.emailValidator(value, loginError: _loginError),
                    ),
                    SizedBox(height: 20),

                    //------------------------------------PASSWORD-------------------------------------------------//
                    CustomPasswordField(
                      controller: passcontroller,
                      labelText: "Password",
                      validator: (value) => LoginscreenValidator.passwordValidator(value, loginError: _loginError),
                    ),
                       SizedBox(height: 10),
                  ],
                ),

             
                ),
                //------------------------------------FORGOT PASSWORD-------------------------------------------------//
                Align(
                  alignment: Alignment.centerLeft,
                  child: CustomTextButton(
                    buttonText: "Forgot Password?",
                    onPressed: () => context.push('/forget_password_screen'),
                  ),
                ),

                SizedBox(height: 10),

                //------------------------------------LOGIN BUTTON-------------------------------------------------//
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 150,
                    child: CustomButton(
                      buttonText: "Login",
                      colorCode: AppConstants.orange,
                      buttonWidth: 110,
                      buttonHeight: 45,
                      onPressed: _handlelogin,                         
              
                      textColor: AppConstants.white,
                      textSize: AppConstants.fontSizeLarge,
                    ),
                  ),
                ),

                SizedBox(height: 40),

                //------------------------------------SIGN UP AND GOOGLE LOGIN-------------------------------------------------//
                Column(
                  children: [
                    //------------------------------------SIGN UP-------------------------------------------------//
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

                    //------------------------------------GOOGLE LOGIN-------------------------------------------------//
                    CustomButton(
                      buttonText: 'Log in with Google',
                      colorCode: AppConstants.white,
                      buttonWidth: 200,
                      buttonHeight: 45,
                      onPressed: () async {
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        final result = await authProvider.signInWithGoogle();
                        if (result == "success") {
                          context.push('/home_screen');
                        } else if (result == "error") {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Google sign-in failed. Please try again."))
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

