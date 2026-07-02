import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);

  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// import 'app.dart';
// import 'providers/auth_provider.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   final container = ProviderContainer();

//   await container.read(authProvider.notifier).initialize();

//   runApp(
//     UncontrolledProviderScope(
//       container: container,
//       child: MyApp(),
//     ),
//   );
// }
