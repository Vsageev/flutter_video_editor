import 'package:flutter/material.dart';
import 'theme.dart';
import 'editor_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Editor',
      debugShowCheckedModeBanner: false,
      theme: editorTheme(),
      home: const EditorScreen(),
    );
  }
}
