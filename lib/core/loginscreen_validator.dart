class LoginscreenValidator {
  // General login error message
  static const String bothLoginError = "Email or password is incorrect";

  static String? emailValidator(String? value, {String? loginError}) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (loginError != null) {
      return loginError;
    }
    return null;
  }

  static String? passwordValidator(String? value, {String? loginError}) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (loginError != null) {
      return loginError;
    }
    return null;
  }
}
