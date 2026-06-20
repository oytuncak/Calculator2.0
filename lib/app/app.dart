import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/canvas/canvas_screen.dart';
import '../state/settings_controller.dart';
import 'theme.dart';

class Calculator2App extends ConsumerWidget {
  const Calculator2App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(settingsControllerProvider);
    return MaterialApp(
      title: 'Calculator 2.0',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const CanvasScreen(),
    );
  }
}
