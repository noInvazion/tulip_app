import 'package:flutter/material.dart';
import 'theme/theme.dart';
import 'widgets/desktop_shell.dart';

void main() {
  runApp(const TulipApp());
}

class TulipApp extends StatelessWidget {
  const TulipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TULIP',
      theme: tulipTheme,
      debugShowCheckedModeBanner: false,
      home: const DesktopShell(),
    );
  }
}
