import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:openiptv/src/core/api/iprovider.dart';
import 'package:openiptv/src/core/models/epg_programme.dart';
import 'package:openiptv/src/core/models/models.dart';
import 'package:openiptv/src/data/datasources/secure_storage_interface.dart';
import 'package:openiptv/utils/app_logger.dart';

class StalkerApiProvider implements IProvider {
  StalkerApiProvider(this._dio, this._secureStorage);

  final Dio _dio;
  final SecureStorageInterface _secureStorage;

  static const _sessionKeyPrefix = 'stalker_session';
  static const _userAgent =
      'Mozilla/5.0 (QtEmbedded; U; Linux; C) AppleWebKit/533.3 (KHTML, like Gecko) InfomirBrowser/1.0.0 (KHTML, like Gecko)';
  static const _xUserAgent = 'Model: MAG254; Link: Ethernet';
  static const _defaultTimezone = 'UTC';
  static const _sessionTtl = Duration(minutes: 30);

  final Map<String, _StalkerSession> _sessionCache = {};

  @override
  Future<List<Channel>> fetchLiveChannels(String portalId) {
    return _withSession<List<Channel>>(portalId, (session) async {
      final response = await _dio.get(
        '${session.portalUrl}/portal.php',
        queryParameters: <String, dynamic>{
          'type': 'itv',
          'action': 'get_ordered_list',
          'mac': session.macAddress,
          'JsHttpRequest': '1-xml',
        },
        options: _optionsFor(session),
      );
      final map = _ensureMap(response.data);
      final js = map?['js'];
      final rows = _extractDataList(js ?? map);
      if (rows != null) {
        final channels = <Channel>[];
        for (final row in rows) {
          try {
            channels.add(Channel.fromStalkerJson(row));
          } catch (error, stackTrace) {
            _logConversionError(
              "Live channel (${row['id'] ?? 'unknown'})",
              portalId: portalId,
              payload: row,
              error: error,
              stackTrace: stackTrace,
            );
          }
        }
        appLogger.d(
          'Fetched ${channels.length} live channels for portal $portalId.',
        );
        if (channels.isEmpty) {
          _logEmptyPayload(
            'Live channel list',
            portalId: portalId,
            payload: js is Map<String, dynamic> ? js : map,
          );
        }
        return channels;
      }
      _logUnexpectedPayload(
        'Live channel list',
        portalId: portalId,
        payload: js is Map<String, dynamic> ? js : map,
      );
      throw Exception('Failed to fetch channels for portal $portalId.');
    });
  }

  @override
  Future<List<Genre>> getGenres(String portalId) {
    return _withSession<List<Genre>>(portalId, (session) async {
      final response = await _dio.get(
        '${session.portalUrl}/server/load.php',
        queryParameters: <String, dynamic>{
          'type': 'itv',
          'action': 'get_genres',
          'mac': session.macAddress,
        },
        options: _optionsFor(session),
      );
      final map = _ensureMap(response.data);
      final js = map?['js'];
      final rows = _extractDataList(js ?? map);
      if (rows != null) {
        final genres = rows.map(Genre.fromJson).toList();
        appLogger.d(
          'Fetched ${genres.length} genres for portal $portalId from ${session.portalUrl}.',
        );
        if (genres.isEmpty) {
          _logEmptyPayload(
            'Genre list',
            portalId: portalId,
            payload: js is Map<String, dynamic> ? js : map,
          );
        }
        return genres;
      }
      _logUnexpectedPayload(
        'Genre list',
        portalId: portalId,
        payload: js is Map<String, dynamic> ? js : map,
      );
      throw Exception('Failed to fetch genres for portal $portalId.');
    });
  }

  @override
  Future<List<Channel>> getAllChannels(String portalId, String genreId) {
    return _withSession<List<Channel>>(portalId, (session) async {
      final response = await _dio.get(
        '${session.portalUrl}/server/load.php',
        queryParameters: <String, dynamic>{
          'type': 'itv',
          'action': 'get_all_channels',
          'genre': genreId,
          'mac': session.macAddress,
        },
        options: _optionsFor(session),
      );
      final map = _ensureMap(response.data);
      final js = map?['js'];
      final rows = _extractDataList(js ?? map);
      if (rows != null) {
        final channels = <Channel>[];
        for (final row in rows) {
          try {
            channels.add(Channel.fromStalkerJson(row));
          } catch (error, stackTrace) {
            _logConversionError(
              "Channel (${row['id'] ?? 'unknown'}) in genre $genreId",
              portalId: portalId,
              payload: row,
              error: error,
              stackTrace: stackTrace,
            );
          }
        }
        appLogger.d(
          'Fetched ${channels.length} channels for genre $genreId on portal $portalId.',
        );
        if (channels.isEmpty) {
          _logEmptyPayload(
            'Channel list for genre $genreId',
            portalId: portalId,
            payload: js is Map<String, dynamic> ? js : map,
          );
        }
        return channels;
      }
      _logUnexpectedPayload(
        'Channel list for genre $genreId',
        portalId: portalId,
        payload: js is Map<String, dynamic> ? js : map,
      );
      throw Exception('Failed to fetch channels for genre $genreId.');
    });
  }

  @override
  Future<List<VodCategory>> fetchVodCategories(String portalId) {
    return _withSession<List<VodCategory>>(portalId, (session) async {
      final response = await _dio.get(
        '${session.portalUrl}/server/load.php',
        queryParameters: <String, dynamic>{
          'type': 'vod',
          'action': 'get_categories',
          'mac': session.macAddress,
        },
        options: _optionsFor(session),
      );
      final map = _ensureMap(response.data);
      final js = map?['js'];
      final rows = _extractDataList(js ?? map);
      if (rows != null) {
        final categories = rows.map(VodCategory.fromJson).toList();
        appLogger.d(
          'Fetched ${categories.length} VOD categories for portal $portalId.',
        );
        if (categories.isEmpty) {
          _logEmptyPayload(
            'VOD category list',
            portalId: portalId,
            payload: js is Map<String, dynamic> ? js : map,
          );
        }
        return categories;
      }
      _logUnexpectedPayload(
        'VOD category list',
        portalId: portalId,
        payload: js is Map<String, dynamic> ? js : map,
      );
      throw Exception('Failed to fetch VOD categories.');
    });
  }

  @override
  Future<List<VodContent>> fetchVodContent(String portalId, String categoryId) {
    return _withSession<List<VodContent>>(portalId, (session) async {
      final response = await _dio.get(
        '${session.portalUrl}/server/load.php',
        queryParameters: <String, dynamic>{
          'type': 'vod',
          'action': 'get_content',
          'category_id': categoryId,
          'mac': session.macAddress,
        },
        options: _optionsFor(session),
      );
      final rawData = response.data;
      if (rawData == null ||
          (rawData is String && rawData.trim().isEmpty)) {
        _logEmptyPayload(
          'VOD items for category $categoryId',
          portalId: portalId,
        );
        return const <VodContent>[];
      }
      final map = _ensureMap(rawData);
      final js = map?['js'];
      final rows = _extractDataList(js ?? map);
      if (rows != null) {
        final vodItems = <VodContent>[];
        for (final row in rows) {
          try {
            vodItems.add(VodContent.fromJson(row, categoryId: categoryId));
          } catch (error, stackTrace) {
            _logConversionError(
              "VOD item (${row['id'] ?? 'unknown'}) in category $categoryId",
              portalId: portalId,
              payload: row,
              error: error,
              stackTrace: stackTrace,
            );
          }
        }
        appLogger.d(
          'Fetched ${vodItems.length} VOD items for category $categoryId on portal $portalId.',
        );
        if (vodItems.isEmpty) {
          _logEmptyPayload(
            'VOD items for category $categoryId',
            portalId: portalId,
            payload: js is Map<String, dynamic> ? js : map,
          );
        }
        return vodItems;
      }
      _logUnexpectedPayload(
        'VOD items for category $categoryId',
        portalId: portalId,
        payload: js is Map<String, dynamic> ? js : map,
      );
      return const <VodContent>[];
    });
  }

  @override
  Future<List<Genre>> fetchRadioGenres(String portalId) {
    return _withSession<List<Genre>>(portalId, (session) async {
      final response = await _dio.get(
        '${session.portalUrl}/server/load.php',
        queryParameters: <String, dynamic>{
          'type': 'radio',
          'action': 'get_genres',
          'mac': session.macAddress,
        },
        options: _optionsFor(session),
      );
      final map = _ensureMap(response.data);
      final js = map?['js'];
      final rows = _extractDataList(js ?? map);
      if (rows != null) {
        final genres = rows.map(Genre.fromJson).toList();
        appLogger.d(
          'Fetched ${genres.length} radio genres for portal $portalId.',
        );
        if (genres.isEmpty) {
          _logEmptyPayload(
            'Radio genre list',
            portalId: portalId,
            payload: js is Map<String, dynamic> ? js : map,
          );
        }
        return genres;
      }
      _logUnexpectedPayload(
        'Radio genre list',
        portalId: portalId,
        payload: js is Map<String, dynamic> ? js : map,
      );
      throw Exception('Failed to fetch radio genres.');
    });
  }

  @override
  Future<List<Channel>> fetchRadioChannels(String portalId, String genreId) {
    return _withSession<List<Channel>>(portalId, (session) async {
      final response = await _dio.get(
        '${session.portalUrl}/server/load.php',
        queryParameters: <String, dynamic>{
          'type': 'radio',
          'action': 'get_all_channels',
          'genre': genreId,
          'mac': session.macAddress,
        },
        options: _optionsFor(session),
      );
      final map = _ensureMap(response.data);
      final js = map?['js'];
      final rows = _extractDataList(js ?? map);
      if (rows != null) {
        final channels = <Channel>[];
        for (final row in rows) {
          try {
            channels.add(Channel.fromStalkerJson(row));
          } catch (error, stackTrace) {
            _logConversionError(
              "Radio channel (${row['id'] ?? 'unknown'}) in genre $genreId",
              portalId: portalId,
              payload: row,
              error: error,
              stackTrace: stackTrace,
            );
          }
        }
        appLogger.d(
          'Fetched ${channels.length} radio channels for genre $genreId on portal $portalId.',
        );
        if (channels.isEmpty) {
          _logEmptyPayload(
            'Radio channels for genre $genreId',
            portalId: portalId,
            payload: js is Map<String, dynamic> ? js : map,
          );
        }
        return channels;
      }
      _logUnexpectedPayload(
        'Radio channels for genre $genreId',
        portalId: portalId,
        payload: js is Map<String, dynamic> ? js : map,
      );
      throw Exception('Failed to fetch radio channels for genre $genreId.');
    });
  }

  @override
  Future<List<EpgProgramme>> getEpgInfo({
    required String portalId,
    required String chId,
    required int period,
  }) {
    return _withSession<List<EpgProgramme>>(portalId, (session) async {
      final response = await _dio.get(
        '${session.portalUrl}/server/load.php',
        queryParameters: <String, dynamic>{
          'type': 'epg',
          'action': 'get_epg_info',
          'ch_id': chId,
          'period': period,
          'mac': session.macAddress,
        },
        options: _optionsFor(session),
      );
      final map = _ensureMap(response.data);
      final js = map?['js'];
      final rows = _extractDataList(js ?? map);
      if (rows != null) {
        final programmes = <EpgProgramme>[];
        for (final row in rows) {
          try {
            programmes.add(EpgProgramme.fromStalkerJson(row));
          } catch (error, stackTrace) {
            _logConversionError(
              "EPG programme (${row['id'] ?? 'unknown'}) for channel $chId",
              portalId: portalId,
              payload: row,
              error: error,
              stackTrace: stackTrace,
            );
          }
        }
        appLogger.d(
          'Fetched ${programmes.length} EPG programmes for channel $chId on portal $portalId.',
        );
        if (programmes.isEmpty) {
          _logEmptyPayload(
            'EPG programmes for channel $chId',
            portalId: portalId,
            payload: js is Map<String, dynamic> ? js : map,
          );
        }
        return programmes;
      }
      _logUnexpectedPayload(
        'EPG programmes for channel $chId',
        portalId: portalId,
        payload: js is Map<String, dynamic> ? js : map,
      );
      throw Exception('Failed to fetch EPG for channel $chId.');
    });
  }

  Future<bool> login(StalkerCredentials credentials) async {
    final sanitized = StalkerCredentials(
      baseUrl: _normalizePortalUrl(credentials.baseUrl),
      macAddress: credentials.macAddress.toUpperCase(),
    );

    try {
      final session = await _bootstrapSession(
        sanitized,
        portalIdOverride: sanitized.id,
      );
      await _secureStorage.saveCredentials(sanitized);
      _sessionCache[session.portalId] = session;
      await _persistSession(session);
      return true;
    } catch (error, stackTrace) {
      appLogger.e(
        'Stalker login failed for ${sanitized.baseUrl}',
        error: error,
        stackTrace: stackTrace,
      );
      await _invalidateSession(sanitized.id);
      return false;
    }
  }

  Future<void> logout({
    String? portalId,
    bool clearStoredCredentials = false,
  }) async {
    if (portalId != null) {
      await _invalidateSession(portalId);
      await _secureStorage.deleteCredentialById(portalId);
      appLogger.d(
        'Logged out portal $portalId and retained other credentials.',
      );
      return;
    }

    final credentials = await _secureStorage.getCredentialsList();
    for (final credential in credentials.whereType<StalkerCredentials>()) {
      await _invalidateSession(credential.id);
    }

    if (clearStoredCredentials) {
      await _secureStorage.clearAllCredentials();
      appLogger.d('Logged out of all portals and cleared stored credentials.');
    } else {
      appLogger.d('Logged out of all portals but retained stored credentials.');
    }
  }

  Future<_StalkerSession> _withFreshSession(
    String portalId, {
    StalkerCredentials? credentialOverride,
  }) async {
    final cached = _sessionCache[portalId];
    if (cached != null && !cached.isExpired(_sessionTtl)) {
      if (DateTime.now().difference(cached.createdAt) >
          const Duration(minutes: 10)) {
        await _ping(cached);
      }
      return cached;
    }

    final persisted = await _loadPersistedSession(portalId);
    if (persisted != null && !persisted.isExpired(_sessionTtl)) {
      _sessionCache[portalId] = persisted;
      if (DateTime.now().difference(persisted.createdAt) >
          const Duration(minutes: 10)) {
        await _ping(persisted);
      }
      return persisted;
    }

    final credential =
        credentialOverride ??
        await _requireStalkerCredential(portalId: portalId);
    return _bootstrapSession(credential, portalIdOverride: portalId);
  }

  Future<T> _withSession<T>(
    String portalId,
    Future<T> Function(_StalkerSession session) action,
  ) async {
    _StalkerSession session = await _withFreshSession(portalId);
    try {
      return await action(session);
    } on DioException catch (error) {
      if (_isAuthError(error)) {
        appLogger.w(
          'Session for $portalId appears invalid. Re-authenticating...',
        );
        await _invalidateSession(portalId);
        session = await _withFreshSession(portalId);
        return await action(session);
      }
      rethrow;
    }
  }

  Future<_StalkerSession> _bootstrapSession(
    StalkerCredentials credential, {
    String? portalIdOverride,
  }) async {
    final mac = credential.macAddress.toUpperCase();
    final portalId = portalIdOverride ?? credential.id;

    final handshake = await _resolveHandshake(
      portalId: portalId,
      rawPortalUrl: credential.baseUrl,
      macAddress: mac,
    );

    await _doAuth(handshake);
    final profile = await _getProfile(handshake);

    final timezone =
        profile?['default_timezone']?.toString() ??
        profile?['timezone']?.toString() ??
        handshake.timezone ??
        _defaultTimezone;

    final session = _StalkerSession(
      portalId: portalId,
      portalUrl: handshake.portalUrl,
      macAddress: mac,
      token: handshake.token,
      random: handshake.random,
      sessionId: handshake.sessionId,
      timezone: timezone,
      profile: profile,
      createdAt: DateTime.now().toUtc(),
    );

    _sessionCache[portalId] = session;
    await _persistSession(session);
    return session;
  }

  Future<_HandshakePayload> _resolveHandshake({
    required String portalId,
    required String rawPortalUrl,
    required String macAddress,
  }) async {
    final candidates = _buildPortalCandidates(rawPortalUrl);
    if (candidates.isEmpty) {
      throw ArgumentError('Invalid portal URL: $rawPortalUrl');
    }

    Exception? lastError;
    for (final candidate in candidates) {
      try {
        appLogger.d('Attempting handshake at ${candidate.baseUrl}');
        final handshake = await _performHandshake(
          portalId: portalId,
          portalUrl: candidate.baseUrl,
          macAddress: macAddress,
        );
        return handshake;
      } on Exception catch (error, stackTrace) {
        lastError = error;
        appLogger.w(
          'Handshake attempt failed for ${candidate.baseUrl}: $error',
          stackTrace: stackTrace,
        );
      }
    }

    throw lastError ??
        Exception(
          'Unable to establish handshake for $portalId using $rawPortalUrl',
        );
  }

  Future<_HandshakePayload> _performHandshake({
    required String portalId,
    required String portalUrl,
    required String macAddress,
  }) async {
    appLogger.d('Stalker handshake for portal: $portalUrl, mac: $macAddress');
    final response = await _dio.get(
      '$portalUrl/server/load.php',
      queryParameters: <String, dynamic>{
        'type': 'stb',
        'action': 'handshake',
        'token': '',
        'mac': macAddress,
        'JsHttpRequest': '1-xml',
      },
      options: Options(
        headers: <String, String>{
          'User-Agent': _userAgent,
          'X-User-Agent': _xUserAgent,
          'Referer': '$portalUrl/c/',
          'Accept': 'application/json',
        },
      ),
    );

    final map = _ensureMap(response.data);
    final js = map?['js'];
    if (js is! Map<String, dynamic>) {
      throw Exception('Handshake failed: unexpected response payload.');
    }
    final token = js['token']?.toString();
    if (token == null || token.isEmpty) {
      throw Exception('Handshake failed: missing token.');
    }

    final resolvedPortalUrl = _extractPortalUrl(js, portalUrl) ?? portalUrl;
    appLogger.d('Handshake resolved portal URL: $resolvedPortalUrl');

    return _HandshakePayload(
      portalId: portalId,
      portalUrl: resolvedPortalUrl,
      macAddress: macAddress,
      token: token,
      random: js['random']?.toString(),
      sessionId: js['sid']?.toString(),
      timezone: js['timezone']?.toString(),
      raw: js,
    );
  }

  Future<void> _doAuth(_HandshakePayload handshake) async {
    final headers = _baseHeaders(
      portalUrl: handshake.portalUrl,
      macAddress: handshake.macAddress,
      token: handshake.token,
      timezone: handshake.timezone ?? _defaultTimezone,
      sessionId: handshake.sessionId,
      extraHeaders: const <String, String>{'Accept': 'application/json'},
    );

    final response = await _dio.get(
      '${handshake.portalUrl}/portal.php',
      queryParameters: <String, dynamic>{
        'type': 'stb',
        'action': 'do_auth',
        'token': handshake.token,
        'mac': handshake.macAddress,
        'random': handshake.random ?? '',
        'device_id': handshake.macAddress,
        'device_id2': handshake.macAddress,
        'signature': _generateSignature(
          handshake.token,
          handshake.macAddress,
          handshake.random,
        ),
        'JsHttpRequest': '1-xml',
      },
      options: Options(headers: headers),
    );

    final map = _ensureMap(response.data);
    final js = map?['js'];
    if (js is Map<String, dynamic>) {
      final status = js['status']?.toString().toLowerCase();
      final authenticated = js['authenticated']?.toString().toLowerCase();
      if (status == 'ok' || authenticated == '1' || authenticated == 'true') {
        return;
      }
    }

    appLogger.w('Unexpected authentication response: $js');
  }

  Future<Map<String, dynamic>?> _getProfile(_HandshakePayload handshake) async {
    final headers = _baseHeaders(
      portalUrl: handshake.portalUrl,
      macAddress: handshake.macAddress,
      token: handshake.token,
      timezone: handshake.timezone ?? _defaultTimezone,
      sessionId: handshake.sessionId,
    );

    final response = await _dio.get(
      '${handshake.portalUrl}/portal.php',
      queryParameters: <String, dynamic>{
        'type': 'stb',
        'action': 'get_profile',
        'token': handshake.token,
        'mac': handshake.macAddress,
        'JsHttpRequest': '1-xml',
      },
      options: Options(headers: headers),
    );

    final map = _ensureMap(response.data);
    final js = map?['js'];
    return js is Map<String, dynamic> ? js : null;
  }

  Future<void> _ping(_StalkerSession session) async {
    try {
      await _dio.get(
        '${session.portalUrl}/portal.php',
        queryParameters: <String, dynamic>{
          'type': 'stb',
          'action': 'ping',
          'token': session.token,
          'mac': session.macAddress,
          'JsHttpRequest': '1-xml',
        },
        options: _optionsFor(session),
      );
    } on DioException catch (error) {
      if (_isAuthError(error)) {
        await _invalidateSession(session.portalId);
      }
    } catch (error, stackTrace) {
      appLogger.w(
        'Ping failed for ${session.portalId}: $error',
        stackTrace: stackTrace,
      );
    }
  }

  Future<StalkerCredentials> _requireStalkerCredential({
    String? portalId,
  }) async {
    final savedCredentials = await _secureStorage.getCredentialsList();
    final stalkerCredentials = savedCredentials
        .whereType<StalkerCredentials>()
        .toList();
    if (stalkerCredentials.isEmpty) {
      throw Exception('No Stalker credentials found. Please log in.');
    }

    if (portalId == null) {
      return stalkerCredentials.first;
    }

    try {
      return stalkerCredentials.firstWhere(
        (credential) => credential.id == portalId,
      );
    } catch (_) {
      throw Exception('No Stalker credentials found for portal $portalId.');
    }
  }

  Options _optionsFor(
    _StalkerSession session, {
    Map<String, String>? extraHeaders,
    Map<String, String>? extraCookies,
  }) {
    return Options(
      headers: _baseHeaders(
        portalUrl: session.portalUrl,
        macAddress: session.macAddress,
        token: session.token,
        timezone: session.timezone ?? _defaultTimezone,
        sessionId: session.sessionId,
        extraHeaders: extraHeaders,
        extraCookies: extraCookies,
      ),
    );
  }

  Map<String, String> _baseHeaders({
    required String portalUrl,
    required String macAddress,
    required String token,
    String? timezone,
    String? sessionId,
    Map<String, String>? extraHeaders,
    Map<String, String>? extraCookies,
  }) {
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'User-Agent': _userAgent,
      'X-User-Agent': _xUserAgent,
      'Referer': '$portalUrl/c/',
      'Accept': 'application/json',
      'Accept-Language': 'en-US',
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache',
    };
    final cookies = <String, String>{
      'mac': macAddress,
      'stb_lang': 'en',
      if (timezone != null && timezone.isNotEmpty) 'timezone': timezone,
      if (sessionId != null && sessionId.isNotEmpty) 'sid': sessionId,
    };
    if (extraCookies != null) {
      cookies.addAll(extraCookies);
    }
    headers['Cookie'] = _formatCookies(cookies);
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  String _formatCookies(Map<String, String> cookies) {
    return cookies.entries
        .where((entry) => entry.value.isNotEmpty)
        .map((entry) => '${entry.key}=${entry.value}')
        .join('; ');
  }

  Map<String, dynamic>? _ensureMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          return decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      } catch (error, stackTrace) {
        appLogger.w(
          'Failed to decode JSON response: $error',
          stackTrace: stackTrace,
        );
      }
    }
    return null;
  }

  bool _isAuthError(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode ?? 0;
      if (statusCode == 401 || statusCode == 403) {
        return true;
      }
      final payload = _ensureMap(error.response?.data);
      final status = payload?['js'];
      if (status is Map) {
        final statusText = status['status']?.toString().toLowerCase() ?? '';
        if (statusText.contains('auth') || statusText.contains('token')) {
          return true;
        }
      }
    }
    return false;
  }

  Future<_StalkerSession?> _loadPersistedSession(String portalId) async {
    final key = _sessionStorageKey(portalId);
    final stored = await _secureStorage.read(key: key);
    if (stored == null || stored.isEmpty) {
      return null;
    }
    try {
      final Map<String, dynamic> map =
          jsonDecode(stored) as Map<String, dynamic>;
      return _StalkerSession.fromJson(map);
    } catch (error, stackTrace) {
      appLogger.w(
        'Failed to restore persisted session for $portalId: $error',
        stackTrace: stackTrace,
      );
      await _secureStorage.delete(key: key);
      return null;
    }
  }

  Future<void> _persistSession(_StalkerSession session) async {
    if (kIsWeb) {
      return;
    }
    final key = _sessionStorageKey(session.portalId);
    try {
      await _secureStorage.write(key: key, value: jsonEncode(session.toJson()));
    } catch (error, stackTrace) {
      appLogger.w(
        'Failed to persist session for ${session.portalId}: $error',
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _invalidateSession(String portalId) async {
    _sessionCache.remove(portalId);
    await _secureStorage.delete(key: _sessionStorageKey(portalId));
  }

  String _sessionStorageKey(String portalId) =>
      '${_sessionKeyPrefix}_$portalId';

  List<_PortalCandidate> _buildPortalCandidates(String rawPortalUrl) {
    final trimmed = rawPortalUrl.trim();
    if (trimmed.isEmpty) {
      return const <_PortalCandidate>[];
    }

    Uri? baseUri;
    var working = trimmed;
    if (working.contains('://')) {
      baseUri = Uri.tryParse(working);
    } else {
      // Try https first, then http if parsing fails.
      baseUri = Uri.tryParse('https://$working');
      if (baseUri == null || baseUri.host.isEmpty) {
        baseUri = Uri.tryParse('http://$working');
      }
    }

    if (baseUri == null || baseUri.host.isEmpty) {
      return const <_PortalCandidate>[];
    }

    final host = baseUri.host;
    final port = baseUri.hasPort ? baseUri.port : null;
    final originalScheme = baseUri.scheme.isNotEmpty
        ? baseUri.scheme.toLowerCase()
        : null;
    final originalPathSegments = baseUri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList();
    final originalPath = originalPathSegments.isEmpty
        ? ''
        : '/${originalPathSegments.join('/')}';

    final basePaths = <String>{
      if (originalPath.isNotEmpty) originalPath,
      '',
      '/stalker_portal',
      '/portal',
      '/mag',
    };

    final schemeOrder = <String>[];
    if (originalScheme != null && originalScheme.isNotEmpty) {
      schemeOrder.add(originalScheme);
      final fallback = originalScheme == 'https' ? 'http' : 'https';
      schemeOrder.add(fallback);
    } else if (port == 443) {
      schemeOrder.addAll(['https', 'http']);
    } else if (port == 80) {
      schemeOrder.addAll(['http', 'https']);
    } else {
      schemeOrder.addAll(['https', 'http']);
    }

    final schemes = <String>{
      ...schemeOrder.map((scheme) => scheme.toLowerCase()),
    };
    if (schemes.isEmpty) {
      schemes.addAll(['https', 'http']);
    }

    final seen = <String>{};
    final candidates = <_PortalCandidate>[];

    void addCandidate(String url) {
      final normalized = _sanitizePortalUrl(url);
      if (seen.add(normalized)) {
        candidates.add(_PortalCandidate(normalized));
      }
    }

    for (final scheme in schemes) {
      for (final path in basePaths) {
        final segments = path.isEmpty
            ? const <String>[]
            : path.split('/').where((s) => s.isNotEmpty).toList();
        final uri = Uri(
          scheme: scheme,
          host: host,
          port: port ?? 0,
          pathSegments: segments,
        );
        addCandidate(uri.toString());
      }
    }

    return candidates;
  }

  String _normalizePortalUrl(String portalUrl) {
    return portalUrl.replaceAll(RegExp(r'/+$'), '');
  }

  String _sanitizePortalUrl(String value) {
    var normalized = _normalizePortalUrl(value.trim());
    const suffixes = ['/server/load.php', '/portal.php', '/c', '/c/'];
    for (final suffix in suffixes) {
      if (normalized.toLowerCase().endsWith(suffix)) {
        normalized = _normalizePortalUrl(
          normalized.substring(0, normalized.length - suffix.length),
        );
      }
    }
    return normalized;
  }

  String? _extractPortalUrl(Map<String, dynamic> js, String fallback) {
    final candidates = [
      js['portal_url'],
      js['portal'],
      js['server_url'],
      js['internal_portal_url'],
      js['external_portal_url'],
      js['store_url'],
      js['log_url'],
    ];
    for (final candidate in candidates) {
      final value = candidate?.toString();
      if (value != null && value.isNotEmpty) {
        return _sanitizePortalUrl(value);
      }
    }
    return _sanitizePortalUrl(fallback);
  }

  void _logEmptyPayload(
    String context, {
    required String portalId,
    Map<String, dynamic>? payload,
  }) {
    try {
      final encoded = payload != null ? jsonEncode(payload) : 'null';
      appLogger.w(
        '$context returned an empty data array for portal $portalId. Raw payload: $encoded',
      );
    } catch (error, stackTrace) {
      appLogger.w(
        '$context returned an empty data array for portal $portalId. Raw payload could not be encoded.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  List<Map<String, dynamic>>? _extractDataList(dynamic payload) {
    if (payload is List) {
      return payload.whereType<Map<String, dynamic>>().toList();
    }
    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().toList();
      }
    }
    return null;
  }

  void _logConversionError(
    String context, {
    required String portalId,
    Map<String, dynamic>? payload,
    Object? error,
    StackTrace? stackTrace,
  }) {
    try {
      final encoded = payload != null ? jsonEncode(payload) : 'null';
      appLogger.e(
        '$context conversion failed for portal $portalId. Payload: $encoded',
        error: error,
        stackTrace: stackTrace,
      );
    } catch (encodeError, encodeStackTrace) {
      appLogger.e(
        '$context conversion failed for portal $portalId and JSON encoding failed.',
        error: encodeError,
        stackTrace: encodeStackTrace,
      );
    }
  }

  void _logUnexpectedPayload(
    String context, {
    required String portalId,
    Map<String, dynamic>? payload,
  }) {
    try {
      final encoded = payload != null ? jsonEncode(payload) : 'null';
      appLogger.w(
        '$context returned an unexpected payload for portal $portalId. Raw payload: $encoded',
      );
    } catch (error, stackTrace) {
      appLogger.w(
        '$context returned an unexpected payload for portal $portalId and JSON encoding failed.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  String _generateSignature(String token, String macAddress, [String? random]) {
    final buffer = StringBuffer(macAddress.toLowerCase())..write(token);
    if (random != null && random.isNotEmpty) {
      buffer.write(random);
    }
    final bytes = utf8.encode(buffer.toString());
    return crypto.md5.convert(bytes).toString();
  }
}

class _PortalCandidate {
  const _PortalCandidate(this.baseUrl);

  final String baseUrl;
}

class _HandshakePayload {
  const _HandshakePayload({
    required this.portalId,
    required this.portalUrl,
    required this.macAddress,
    required this.token,
    this.random,
    this.sessionId,
    this.timezone,
    this.raw,
  });

  final String portalId;
  final String portalUrl;
  final String macAddress;
  final String token;
  final String? random;
  final String? sessionId;
  final String? timezone;
  final Map<String, dynamic>? raw;
}

class _StalkerSession {
  _StalkerSession({
    required this.portalId,
    required this.portalUrl,
    required this.macAddress,
    required this.token,
    this.random,
    this.sessionId,
    this.timezone,
    required DateTime createdAt,
    this.profile,
  }) : createdAt = createdAt.toUtc();

  final String portalId;
  final String portalUrl;
  final String macAddress;
  final String token;
  final String? random;
  final String? sessionId;
  final String? timezone;
  final DateTime createdAt;
  final Map<String, dynamic>? profile;

  bool isExpired(Duration ttl) =>
      DateTime.now().toUtc().difference(createdAt) > ttl;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'portalId': portalId,
      'portalUrl': portalUrl,
      'macAddress': macAddress,
      'token': token,
      'random': random,
      'sessionId': sessionId,
      'timezone': timezone,
      'createdAt': createdAt.toIso8601String(),
      'profile': profile,
    };
  }

  factory _StalkerSession.fromJson(Map<String, dynamic> json) {
    return _StalkerSession(
      portalId: json['portalId'] as String,
      portalUrl: json['portalUrl'] as String,
      macAddress: json['macAddress'] as String,
      token: json['token'] as String,
      random: json['random'] as String?,
      sessionId: json['sessionId'] as String?,
      timezone: json['timezone'] as String?,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now().toUtc(),
      profile: (json['profile'] as Map?)?.cast<String, dynamic>(),
    );
  }
}
