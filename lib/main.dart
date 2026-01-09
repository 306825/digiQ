//import 'package:digiQ/core/api/api_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  runApp(ProviderScope(child: MyApp()));
}

// void main() {
//   runApp(
//     ProviderScope(
//       overrides: [],
//       child: const _BootstrapApp(),
//     ),
//   );
// }

// class _BootstrapApp extends ConsumerWidget {
//   const _BootstrapApp({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     // 🔥 FORCE ApiClient creation
//     ref.read(apiClientProvider);

//     return const MyApp();
//   }
// }
