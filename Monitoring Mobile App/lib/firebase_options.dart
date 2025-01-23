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
    apiKey: 'AIzaSyDQXg6iOefWHgDYsooVM2GsbwASoHr_l-Y',
    appId: '1:484243703973:web:6414123f4ad9c1a3c5654c',
    messagingSenderId: '484243703973',
    projectId: 'automated-egg-incubator-2675c',
    authDomain: 'automated-egg-incubator-2675c.firebaseapp.com',
    databaseURL: 'https://automated-egg-incubator-2675c-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'automated-egg-incubator-2675c.appspot.com',
    measurementId: 'G-P7BG7PCV40',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDEuRznKPl-DdfJadmn1gaUpm0VbALfOuM',
    appId: '1:484243703973:android:b25b985da3aa170fc5654c',
    messagingSenderId: '484243703973',
    projectId: 'automated-egg-incubator-2675c',
    databaseURL: 'https://automated-egg-incubator-2675c-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'automated-egg-incubator-2675c.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA6jIi1sPTU9r68dM4OgzsicSCr9qpaqD8',
    appId: '1:484243703973:ios:50001595dd69e07ec5654c',
    messagingSenderId: '484243703973',
    projectId: 'automated-egg-incubator-2675c',
    databaseURL: 'https://automated-egg-incubator-2675c-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'automated-egg-incubator-2675c.appspot.com',
    iosBundleId: 'com.example.incubatorApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA6jIi1sPTU9r68dM4OgzsicSCr9qpaqD8',
    appId: '1:484243703973:ios:50001595dd69e07ec5654c',
    messagingSenderId: '484243703973',
    projectId: 'automated-egg-incubator-2675c',
    databaseURL: 'https://automated-egg-incubator-2675c-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'automated-egg-incubator-2675c.appspot.com',
    iosBundleId: 'com.example.incubatorApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDQXg6iOefWHgDYsooVM2GsbwASoHr_l-Y',
    appId: '1:484243703973:web:83cac65ef0009af8c5654c',
    messagingSenderId: '484243703973',
    projectId: 'automated-egg-incubator-2675c',
    authDomain: 'automated-egg-incubator-2675c.firebaseapp.com',
    databaseURL: 'https://automated-egg-incubator-2675c-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'automated-egg-incubator-2675c.appspot.com',
    measurementId: 'G-DM9R88C9X6',
  );
}