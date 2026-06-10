//import 'package:digiQ/core/api/api_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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
