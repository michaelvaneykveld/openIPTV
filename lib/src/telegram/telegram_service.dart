import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:openiptv/src/telegram/io_socket.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:t/t.dart' as t;
import 'package:tg/tg.dart' as tg;

class TelegramService {
  TelegramService._();
  static final TelegramService instance = TelegramService._();

  // Public test keys (or replace with your own)
  final int apiId = 611335;
  final String apiHash = 'd524b414d21f4d37f08684c1df41ac9c';

  tg.Client? _client;
  tg.Client? get client => _client;

  final _logController = StreamController<String>.broadcast();
  Stream<String> get logs => _logController.stream;

  void log(String text) {
    _logController.add(text);
    // ignore: avoid_print
    print('[Telegram] $text');
  }

  // Default DC (Data Center) configuration
  // DC 2 is often default for Europe/Test
  // Changed to DC 4 as default since many users seem to be there and DC 2 is timing out
  t.DcOption _dc = const t.DcOption(
    ipv6: false,
    mediaOnly: false,
    tcpoOnly: false,
    cdn: false,
    static: false,
    thisPortOnly: false,
    id: 4,
    ipAddress: '149.154.167.91',
    port: 443,
  );

  t.Config? _config;

  Future<tg.Client> connect() async {
    if (_client != null) return _client!;

    // Load saved DC if available
    final prefs = await SharedPreferences.getInstance();
    final savedDcId = prefs.getInt('tg_dc_id');
    if (savedDcId != null && savedDcId != _dc.id) {
      final ip = _getDcIp(savedDcId);
      if (ip != null) {
        _dc = t.DcOption(
          ipv6: false,
          mediaOnly: false,
          tcpoOnly: false,
          cdn: false,
          static: false,
          thisPortOnly: false,
          id: savedDcId,
          ipAddress: ip,
          port: 443,
        );
      }
    }

    log('Connecting to DC ${_dc.id} (${_dc.ipAddress}:${_dc.port})...');

    final socket = await Socket.connect(_dc.ipAddress, _dc.port);
    final ioSocket = IoSocket(socket);

    log('Socket connected.');

    final obfuscation = tg.Obfuscation.random(false, _dc.id);
    final idGenerator = tg.MessageIdGenerator();

    await ioSocket.send(obfuscation.preamble);

    final authKey =
        await _loadSession() ??
        await tg.Client.authorize(ioSocket, obfuscation, idGenerator);

    await _saveSession(authKey);

    final client = tg.Client(
      socket: ioSocket,
      obfuscation: obfuscation,
      authorizationKey: authKey,
      idGenerator: idGenerator,
    );

    client.stream.listen((event) {
      // log('Event: $event');
    });

    // Initialize connection
    try {
      final res = await client
          .initConnection<t.Config>(
            apiId: apiId,
            deviceModel: 'Flutter Desktop',
            systemVersion: Platform.operatingSystemVersion,
            appVersion: '1.0.0',
            systemLangCode: Platform.localeName,
            langPack: '',
            langCode: 'en',
            query: const t.HelpGetConfig(),
          )
          .timeout(const Duration(seconds: 30));

      if (res.result is t.Config) {
        _config = res.result as t.Config;
      }
      log('Connected and initialized.');
    } catch (e) {
      log('Error initializing connection: $e');
      // If auth key is invalid, we might need to clear it and retry
      if (e is TimeoutException) {
        log('Connection timed out. Clearing session and retrying...');
        await logout();
        // Recursive retry? Or just let the user try again?
        // Let's just return the client, but it might not be fully working.
        // Better to throw so the UI knows.
        rethrow;
      }
    }

    _client = client;
    return client;
  }

  Future<void> switchDc(int dcId) async {
    log('Switching to DC $dcId...');

    // Find DC option
    t.DcOption? newDc;

    if (_config != null) {
      // Try to find in config
      try {
        final dcBase = _config!.dcOptions.firstWhere((dc) {
          if (dc is t.DcOption) {
            return dc.id == dcId &&
                !dc.ipv6 &&
                !dc.mediaOnly &&
                !dc.cdn &&
                !dc.tcpoOnly;
          }
          return false;
        });
        if (dcBase is t.DcOption) {
          newDc = dcBase;
        }
      } catch (_) {}
    }

    if (newDc == null) {
      // Fallback
      final ip = _getDcIp(dcId);
      if (ip != null) {
        newDc = t.DcOption(
          ipv6: false,
          mediaOnly: false,
          tcpoOnly: false,
          cdn: false,
          static: false,
          thisPortOnly: false,
          id: dcId,
          ipAddress: ip,
          port: 443,
        );
      }
    }

    if (newDc == null) {
      throw Exception('Could not find IP for DC $dcId');
    }

    _dc = newDc;
    _client = null; // Force reconnect

    // Clear session because we are switching DC and need new auth key
    await logout();

    await connect();
  }

  String? _getDcIp(int dcId) {
    switch (dcId) {
      case 1:
        return '149.154.175.50';
      case 2:
        return '149.154.167.50';
      case 3:
        return '149.154.175.100';
      case 4:
        return '149.154.167.91';
      case 5:
        return '91.108.56.130';
      default:
        return null;
    }
  }

  Future<tg.AuthorizationKey?> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final keyBytes = prefs.getString('tg_auth_key');
    final keyId = prefs.getInt('tg_auth_id');
    final salt = prefs.getInt('tg_auth_salt');

    if (keyBytes != null && keyId != null && salt != null) {
      log('Session loaded.');
      return tg.AuthorizationKey(keyId, base64Decode(keyBytes), salt);
    }
    return null;
  }

  Future<void> _saveSession(tg.AuthorizationKey key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tg_auth_key', base64Encode(key.key));
    await prefs.setInt('tg_auth_id', key.id);
    await prefs.setInt('tg_auth_salt', key.salt);
    await prefs.setInt('tg_dc_id', _dc.id);
    log('Session saved (DC ${_dc.id}).');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tg_auth_key');
    await prefs.remove('tg_auth_id');
    await prefs.remove('tg_auth_salt');
    await prefs.remove('tg_dc_id');
    _client = null;
    log('Logged out.');
  }
}
