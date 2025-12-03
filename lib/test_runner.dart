import 'package:flutter/material.dart';
import 'package:openiptv/src/ui/test/native_http_test.dart';

/// Simple test runner for native HTTP client
/// Run with: flutter run -d windows -t lib/test_runner.dart
void main() {
  runApp(const TestRunnerApp());
}

class TestRunnerApp extends StatelessWidget {
  const TestRunnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Native HTTP Test',
      theme: ThemeData.dark(),
      home: const NativeHttpTest(),
      debugShowCheckedModeBanner: false,
    );
  }
}
