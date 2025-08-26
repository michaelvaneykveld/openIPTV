import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  // Wrapping the app in a ProviderScope makes Riverpod providers available
  // throughout the widget tree.
  runApp(const ProviderScope(child: OpenIPTVApp()));
}

class OpenIPTVApp extends StatelessWidget {
  const OpenIPTVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'openIPTV',
      theme: ThemeData.dark(useMaterial3: true),
      // TODO: Replace with a real home screen from the presentation layer
      home: const Scaffold(body: Center(child: Text('Welcome to openIPTV'))),
    );
  }
}

