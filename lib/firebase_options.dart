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
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'dummy-api-key-for-web-testing',
    appId: '1:123456789:web:dummy-app-id',
    messagingSenderId: '123456789',
    projectId: 'finflow-demo',
    authDomain: 'finflow-demo.firebaseapp.com',
    storageBucket: 'finflow-demo.appspot.com',
    measurementId: 'G-XXXXXXXXXX',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDd_W6i9nyvUuO-XU6RSdXJl_2qw8t2_Uo',
    appId: '1:1066730590986:android:0433644050b5cb484be0f3',
    messagingSenderId: '1066730590986',
    projectId: 'finflow-a7bc8',
    storageBucket: 'finflow-a7bc8.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'dummy-api-key-for-ios-testing',
    appId: '1:123456789:ios:dummy-app-id',
    messagingSenderId: '123456789',
    projectId: 'finflow-demo',
    storageBucket: 'finflow-demo.appspot.com',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'dummy-api-key-for-macos-testing',
    appId: '1:123456789:macos:dummy-app-id',
    messagingSenderId: '123456789',
    projectId: 'finflow-demo',
    storageBucket: 'finflow-demo.appspot.com',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'dummy-api-key-for-windows-testing',
    appId: '1:123456789:windows:dummy-app-id',
    messagingSenderId: '123456789',
    projectId: 'finflow-demo',
    storageBucket: 'finflow-demo.appspot.com',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'dummy-api-key-for-linux-testing',
    appId: '1:123456789:linux:dummy-app-id',
    messagingSenderId: '123456789',
    projectId: 'finflow-demo',
    storageBucket: 'finflow-demo.appspot.com',
  );
}
