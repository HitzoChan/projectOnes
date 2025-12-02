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
    apiKey: 'AIzaSyD2JzL5uSIhR0_fmDyCOAkbKGab861KRcQ',
    appId: '1:694824180500:web:4fb66793d770c9b1b2c001',
    messagingSenderId: '694824180500',
    projectId: 'projectone-b6cde',
    authDomain: 'projectone-b6cde.firebaseapp.com',
    storageBucket: 'projectone-b6cde.firebasestorage.app',
    measurementId: 'G-XP66T7BW6Y',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCZzYuiIOqK06xv52K_9VEaoeThpKVaIAM',
    appId: '1:694824180500:android:3c2403ff4f369ab0b2c001',
    messagingSenderId: '694824180500',
    projectId: 'projectone-b6cde',
    storageBucket: 'projectone-b6cde.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyARVwhelFmoCEWwpt1AJmB8ADEpSvOHqro',
    appId: '1:694824180500:ios:3ab3c78833f880ecb2c001',
    messagingSenderId: '694824180500',
    projectId: 'projectone-b6cde',
    storageBucket: 'projectone-b6cde.firebasestorage.app',
    iosBundleId: 'com.example.projectOne',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyARVwhelFmoCEWwpt1AJmB8ADEpSvOHqro',
    appId: '1:694824180500:ios:3ab3c78833f880ecb2c001',
    messagingSenderId: '694824180500',
    projectId: 'projectone-b6cde',
    storageBucket: 'projectone-b6cde.firebasestorage.app',
    iosBundleId: 'com.example.projectOne',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD2JzL5uSIhR0_fmDyCOAkbKGab861KRcQ',
    appId: '1:694824180500:web:1e7c8f248ef7d369b2c001',
    messagingSenderId: '694824180500',
    projectId: 'projectone-b6cde',
    authDomain: 'projectone-b6cde.firebaseapp.com',
    storageBucket: 'projectone-b6cde.firebasestorage.app',
    measurementId: 'G-XYH5VQTZ3V',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyAgUhHU8wSJgO5MVNy95tMT07NEjzMOfz0',
    appId: '1:448618578101:linux:0b650370bb29e29cac3efc',
    messagingSenderId: '448618578101',
    projectId: 'attendance-monitoring-system',
    storageBucket: 'attendance-monitoring-system.appspot.com',
  );
}