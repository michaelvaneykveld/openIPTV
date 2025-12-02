import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import 'package:openiptv/src/ui/login_screen.dart';
// DEPRECATED: LocalProxyServer is no longer used (RAW TCP mode disabled)
// import 'package:openiptv/src/playback/local_proxy_server.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // DEPRECATED: LocalProxyServer (RAW TCP Socket mode) is disabled by default
  // Direct Stream mode is now used (Cloudflare-compatible normal HTTP)
  // await LocalProxyServer.start();

  runApp(const ProviderScope(child: OpenIptvApp()));
}

class OpenIptvApp extends StatelessWidget {
  const OpenIptvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenIPTV',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
