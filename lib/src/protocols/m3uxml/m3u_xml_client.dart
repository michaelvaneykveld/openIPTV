import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'm3u_source_descriptor.dart';
import 'm3u_xml_portal_configuration.dart';
import 'playlist_fetch_envelope.dart';
import 'xmltv_source_descriptor.dart';

/// Fetches M3U playlists and XMLTV guides from remote or local sources.
///
/// The client is intentionally lightweight: it only knows how to retrieve
/// bytes and report HTTP metadata. Parsing, caching, and higher-level logic
/// live in dedicated modules so we can swap out implementations easily.
class M3uXmlClient {
  final Dio _dio;

  M3uXmlClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(minutes: 2),
                sendTimeout: const Duration(seconds: 30),
                responseType: ResponseType.bytes,
              ),
            );

  /// Downloads the playlist described by [source]. Local files are read via
  /// `dart:io`, while remote URLs go through `Dio`. The configuration allows
  /// us to apply shared headers such as the default user-agent.
  Future<PlaylistFetchEnvelope> fetchPlaylist(
    M3uXmlPortalConfiguration configuration,
  ) async {
    final source = configuration.m3uSource;
    if (source is M3uUrlSource) {
      return _fetchRemotePlaylist(configuration, source);
    }
    if (source is M3uFileSource) {
      return _fetchLocalFile(source.filePath);
    }
    throw const UnsupportedError('Unknown M3U source descriptor.');
  }

  /// Downloads the XMLTV feed when available. Returns null when the portal
  /// configuration does not provide an EPG source.
  Future<PlaylistFetchEnvelope?> fetchXmltv(
    M3uXmlPortalConfiguration configuration,
  ) async {
    final source = configuration.xmltvSource;
    if (source == null) {
      return null;
    }
    if (source is XmltvUrlSource) {
      return _fetchRemoteXmltv(configuration, source);
    }
    if (source is XmltvFileSource) {
      return _fetchLocalFile(source.filePath);
    }
    throw const UnsupportedError('Unknown XMLTV source descriptor.');
  }

  /// Handles remote playlist downloads with proper headers and metadata.
  Future<PlaylistFetchEnvelope> _fetchRemotePlaylist(
    M3uXmlPortalConfiguration configuration,
    M3uUrlSource source,
  ) async {
    final uri = source.playlistUri;

    final response = await _dio.getUri(
      uri,
      queryParameters: source.extraQuery.isEmpty ? null : source.extraQuery,
      options: Options(
        headers: {
          'User-Agent': configuration.defaultUserAgent,
          ...source.headers,
        },
        responseType: ResponseType.bytes,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    return PlaylistFetchEnvelope(
      bytes: Uint8List.fromList(response.data is Uint8List
          ? (response.data as Uint8List)
          : Uint8List.fromList(response.data)),
      contentType: response.headers.value('content-type'),
      contentEncoding: response.headers.value('content-encoding'),
      etag: response.headers.value('etag'),
      lastModified: _parseHttpDate(response.headers.value('last-modified')),
      statusCode: response.statusCode ?? 0,
    );
  }

  /// Handles remote XMLTV downloads.
  Future<PlaylistFetchEnvelope> _fetchRemoteXmltv(
    M3uXmlPortalConfiguration configuration,
    XmltvUrlSource source,
  ) async {
    final response = await _dio.getUri(
      source.epgUri,
      options: Options(
        headers: {
          'User-Agent': configuration.defaultUserAgent,
          ...source.headers,
        },
        responseType: ResponseType.bytes,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    return PlaylistFetchEnvelope(
      bytes: Uint8List.fromList(response.data is Uint8List
          ? (response.data as Uint8List)
          : Uint8List.fromList(response.data)),
      contentType: response.headers.value('content-type'),
      contentEncoding: response.headers.value('content-encoding'),
      etag: response.headers.value('etag'),
      lastModified: _parseHttpDate(response.headers.value('last-modified')),
      statusCode: response.statusCode ?? 0,
    );
  }

  /// Reads a file from disk and wraps it into a fetch envelope.
  Future<PlaylistFetchEnvelope> _fetchLocalFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw FileSystemException('Playlist/EPG file not found.', path);
    }
    final bytes = await file.readAsBytes();
    return PlaylistFetchEnvelope(bytes: Uint8List.fromList(bytes));
  }

  /// Parses HTTP date strings (RFC1123) into `DateTime`.
  DateTime? _parseHttpDate(String? value) {
    if (value == null) {
      return null;
    }
    try {
      return HttpDate.parse(value);
    } on FormatException {
      return null;
    }
  }
}

