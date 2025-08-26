import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/presentation/screens/home/home_screen.dart';

void main() {
  runApp(
    // To enable Riverpod for the entire project, we wrap the entire
    // application in a "ProviderScope" widget. This is essential.
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'openIPTV',
      // Let's use a dark theme for a media player app.
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
    );
  }
}
