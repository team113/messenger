import 'package:firebase_core/firebase_core.dart'
    show Firebase, FirebaseOptions;

import 'util/platform_utils.dart';

/// Default [FirebaseOptions] used to initialize the [Firebase].
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
  /// Key used to get a FCM token on the Web.
  late String vapidKey;

  /// API key used for authenticating requests to Google servers on Android.
  late String androidApiKey;

  /// API key used for authenticating requests to Google servers on iOS and
  /// macOS.
  late String appleApiKey;

  /// API key used for authenticating requests to Google servers on Web.
  late String webApiKey;

  /// Google unique Android App ID.
  late String androidAppId;

  /// Google unique Apple App ID.
  late String appleAppId;

  /// Google unique Web App ID.
  late String webAppId;

  /// Auth domain used to handle redirects from OAuth on Web.
  late String authDomain;

  /// Project measurement ID on Web.
  late String measurementId;

  /// The unique sender ID value used to identify the app.
  late String messagingSenderId;

  /// The Project ID from the Firebase console.
  late String projectId;

  /// The Google Cloud Storage bucket name.
  late String storageBucket;

  /// The iOS client ID.
  late String appleClientId;

  /// The iOS bundle ID.
  late String appleBundleId;

  /// Returns [FirebaseOptions] for the Web platform.
  FirebaseOptions get web => FirebaseOptions(
        apiKey: webApiKey,
        appId: webAppId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        authDomain: authDomain,
        storageBucket: storageBucket,
        measurementId: measurementId,
      );

  /// Returns [FirebaseOptions] for the Android platform.
  FirebaseOptions get android => FirebaseOptions(
        apiKey: androidApiKey,
        appId: androidAppId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        storageBucket: storageBucket,
      );

  /// Returns [FirebaseOptions] for the iOS or macOS platform.
  FirebaseOptions get apple => FirebaseOptions(
        apiKey: appleApiKey,
        appId: appleAppId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        storageBucket: storageBucket,
        iosClientId: appleClientId,
        iosBundleId: appleBundleId,
      );

  /// Returns [FirebaseOptions] for the current platform.
  FirebaseOptions get currentPlatform {
    if (PlatformUtils.isWeb) {
      return web;
    } else if(PlatformUtils.isAndroid) {
      return android;
    } else if(PlatformUtils.isIOS || PlatformUtils.isMacOS) {
      return apple;
    } else {
      throw UnsupportedError(
        'DefaultFirebaseOptions are not supported for this platform.',
      );
    }
  }

  /// Initializes this [DefaultFirebaseOptions] by applying values from the
  /// following sources (in the following order):
  /// - compile-time environment variables;
  /// - provided [configuration];
  /// - default values.
  void init(Map<String, dynamic> configuration) {
    vapidKey = const bool.hasEnvironment('SOCAPP_FCM_VAPID_KEY')
        ? const String.fromEnvironment('SOCAPP_FCM_VAPID_KEY')
        : (configuration['vapidKey'] ?? '');

    androidApiKey = const bool.hasEnvironment('SOCAPP_FCM_ANDROID_API_KEY')
        ? const String.fromEnvironment('SOCAPP_FCM_ANDROID_API_KEY')
        : (configuration['androidApiKey'] ?? '');

    appleApiKey = const bool.hasEnvironment('SOCAPP_FCM_APPLE_API_KEY')
        ? const String.fromEnvironment('SOCAPP_FCM_APPLE_API_KEY')
        : (configuration['appleApiKey'] ?? '');

    webApiKey = const bool.hasEnvironment('SOCAPP_FCM_WEB_API_KEY')
        ? const String.fromEnvironment('SOCAPP_FCM_WEB_API_KEY')
        : (configuration['webApiKey'] ?? '');

    androidAppId = const bool.hasEnvironment('SOCAPP_FCM_ANDROID_APP_ID')
        ? const String.fromEnvironment('SOCAPP_FCM_ANDROID_APP_ID')
        : (configuration['androidAppId'] ?? '');

    appleAppId = const bool.hasEnvironment('SOCAPP_FCM_APPLE_APP_ID')
        ? const String.fromEnvironment('SOCAPP_FCM_APPLE_APP_ID')
        : (configuration['appleAppId'] ?? '');

    webAppId = const bool.hasEnvironment('SOCAPP_FCM_WEB_APP_ID')
        ? const String.fromEnvironment('SOCAPP_FCM_WEB_APP_ID')
        : (configuration['webAppId'] ?? '');

    authDomain = const bool.hasEnvironment('SOCAPP_FCM_AUTH_DOMAIN')
        ? const String.fromEnvironment('SOCAPP_FCM_AUTH_DOMAIN')
        : (configuration['authDomain'] ?? '');

    measurementId = const bool.hasEnvironment('SOCAPP_FCM_MEASUREMENT_ID')
        ? const String.fromEnvironment('SOCAPP_FCM_MEASUREMENT_ID')
        : (configuration['measurementId'] ?? '');

    messagingSenderId =
        const bool.hasEnvironment('SOCAPP_FCM_MESSAGING_SENDER_ID')
            ? const String.fromEnvironment('SOCAPP_FCM_MESSAGING_SENDER_ID')
            : (configuration['messagingSenderId'] ?? '');

    projectId = const bool.hasEnvironment('SOCAPP_FCM_PROJECT_ID')
        ? const String.fromEnvironment('SOCAPP_FCM_PROJECT_ID')
        : (configuration['projectId'] ?? '');

    storageBucket = const bool.hasEnvironment('SOCAPP_FCM_STORAGE_BUCKET')
        ? const String.fromEnvironment('SOCAPP_FCM_STORAGE_BUCKET')
        : (configuration['storageBucket'] ?? '');

    appleClientId = const bool.hasEnvironment('SOCAPP_FCM_APPLE_CLIENT_ID')
        ? const String.fromEnvironment('SOCAPP_FCM_APPLE_CLIENT_ID')
        : (configuration['appleClientId'] ?? '');

    appleBundleId = const bool.hasEnvironment('SOCAPP_FCM_APPLE_BUNDLE_ID')
        ? const String.fromEnvironment('SOCAPP_FCM_APPLE_BUNDLE_ID')
        : (configuration['appleBundleId'] ?? '');
  }
}
