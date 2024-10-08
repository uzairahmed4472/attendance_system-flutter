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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyD2zQ3VfvBOmpyWMjtMF6Gb8NMOsGnpz2Q',
    appId: '1:14982928532:web:e97a7640e4f5542a043c81',
    messagingSenderId: '14982928532',
    projectId: 'attendance-system-5db2c',
    authDomain: 'attendance-system-5db2c.firebaseapp.com',
    storageBucket: 'attendance-system-5db2c.appspot.com',
    measurementId: 'G-45LZZYJSHM',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDzFMSgzEcBFk-OuVmvqVoNPi83fO1PcIE',
    appId: '1:14982928532:android:8c301b7a8f36f585043c81',
    messagingSenderId: '14982928532',
    projectId: 'attendance-system-5db2c',
    storageBucket: 'attendance-system-5db2c.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB1Wtymtpghmb8-VZWUgD715vnA3GGF2cA',
    appId: '1:14982928532:ios:52a692a71b6d887d043c81',
    messagingSenderId: '14982928532',
    projectId: 'attendance-system-5db2c',
    storageBucket: 'attendance-system-5db2c.appspot.com',
    iosBundleId: 'com.example.attendanceSystem',
  );
}
