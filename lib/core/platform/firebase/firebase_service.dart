import 'package:app_platform/app_platform.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:injectable/injectable.dart';

import '../../../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

@singleton
class FirebaseService {
  /// Initializes Firebase Core before dependency registration resolves any
  /// Firebase-backed lazy singleton (for example network performance).
  static Future<void> initializeCore() async {
    if (Firebase.apps.isNotEmpty) return;
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  /// Initializes the Firebase app with the platform-specific generated options
  /// and registers the background message handler.
  ///
  /// Crash reporting (the global error-capture handlers) is installed
  /// separately via the `CrashReporter` port once this completes.
  Future<void> init() async {
    await initializeCore();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
}
