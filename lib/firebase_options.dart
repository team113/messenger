// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
    apiKey: 'AIzaSyBbttYFbYjucn8BY-p5tlWomcd5V9h8zWc',
    appId: '1:985927661367:web:f74cc9e76046c1c55c0cb2',
    messagingSenderId: '985927661367',
    projectId: 'messenger-3872c',
    authDomain: 'messenger-3872c.firebaseapp.com',
    storageBucket: 'messenger-3872c.appspot.com',
    measurementId: 'G-8WK80QEL35',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBkNVpSsgni558eAtkMtmB6NVqJW8zFgJg',
    appId: '1:985927661367:android:2f4015706b53ae9f5c0cb2',
    messagingSenderId: '985927661367',
    projectId: 'messenger-3872c',
    storageBucket: 'messenger-3872c.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBYimRBTaBbC1YjRmgyJC8r00RK-rkWYFg',
    appId: '1:985927661367:ios:7eebd61d36a1318a5c0cb2',
    messagingSenderId: '985927661367',
    projectId: 'messenger-3872c',
    storageBucket: 'messenger-3872c.appspot.com',
    iosClientId: '985927661367-2gl74fsbqrk8d5it06lot1v3dk8k4au3.apps.googleusercontent.com',
    iosBundleId: 'com.team113.messenger',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBYimRBTaBbC1YjRmgyJC8r00RK-rkWYFg',
    appId: '1:985927661367:ios:7eebd61d36a1318a5c0cb2',
    messagingSenderId: '985927661367',
    projectId: 'messenger-3872c',
    storageBucket: 'messenger-3872c.appspot.com',
    iosClientId: '985927661367-2gl74fsbqrk8d5it06lot1v3dk8k4au3.apps.googleusercontent.com',
    iosBundleId: 'com.team113.messenger',
  );
}
