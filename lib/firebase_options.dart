// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDEAMlmP3QTsSKXLTmTI8nZAGw3R4izjEs',
    appId: '1:1618713415:web:498c03c8109129897c0a62',
    messagingSenderId: '1618713415',
    projectId: 'signtalk-cb7eb',
    authDomain: 'signtalk-cb7eb.firebaseapp.com',
    storageBucket: 'signtalk-cb7eb.firebasestorage.app',
    measurementId: 'G-X2DH1HBG7P',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBCr4QZ45MdiDdN3I5WQnS0TVPcNi1sTdo',
    appId: '1:1618713415:android:2fad8f1565b5e19a7c0a62',
    messagingSenderId: '1618713415',
    projectId: 'signtalk-cb7eb',
    storageBucket: 'signtalk-cb7eb.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBLP9SLgbUh6s9zrb9rN8hK2iJCg66SUvk',
    appId: '1:1618713415:ios:ce000c065bac6a1f7c0a62',
    messagingSenderId: '1618713415',
    projectId: 'signtalk-cb7eb',
    storageBucket: 'signtalk-cb7eb.firebasestorage.app',
    iosBundleId: 'com.example.signtalk',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBLP9SLgbUh6s9zrb9rN8hK2iJCg66SUvk',
    appId: '1:1618713415:ios:ce000c065bac6a1f7c0a62',
    messagingSenderId: '1618713415',
    projectId: 'signtalk-cb7eb',
    storageBucket: 'signtalk-cb7eb.firebasestorage.app',
    iosBundleId: 'com.example.signtalk',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDEAMlmP3QTsSKXLTmTI8nZAGw3R4izjEs',
    appId: '1:1618713415:web:85b4ade8999058697c0a62',
    messagingSenderId: '1618713415',
    projectId: 'signtalk-cb7eb',
    authDomain: 'signtalk-cb7eb.firebaseapp.com',
    storageBucket: 'signtalk-cb7eb.firebasestorage.app',
    measurementId: 'G-80CYX0RP99',
  );
}
