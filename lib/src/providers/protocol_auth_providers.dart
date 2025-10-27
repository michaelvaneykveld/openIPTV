import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:openiptv/src/protocols/m3uxml/m3u_source_descriptor.dart';
import 'package:openiptv/src/protocols/m3uxml/m3u_xml_authenticator.dart';
import 'package:openiptv/src/protocols/m3uxml/m3u_xml_client.dart';
import 'package:openiptv/src/protocols/m3uxml/m3u_xml_portal_configuration.dart';
import 'package:openiptv/src/protocols/m3uxml/m3u_xml_session.dart';
import 'package:openiptv/src/protocols/m3uxml/xmltv_source_descriptor.dart';
import 'package:openiptv/src/protocols/stalker/stalker_authenticator.dart';
import 'package:openiptv/src/protocols/stalker/stalker_portal_configuration.dart';
import 'package:openiptv/src/protocols/stalker/stalker_session.dart';
import 'package:openiptv/src/protocols/xtream/xtream_authenticator.dart';
import 'package:openiptv/src/protocols/xtream/xtream_portal_configuration.dart';
import 'package:openiptv/src/protocols/xtream/xtream_session.dart';

/// Provides shared access to the Stalker/Ministra authenticator.
final stalkerAuthenticatorProvider = Provider<StalkerAuthenticator>((ref) {
  return DefaultStalkerAuthenticator();
});

/// Executes the MAC+token handshake for a given Stalker configuration.
final stalkerSessionProvider =
    FutureProvider.family<StalkerSession, StalkerPortalConfiguration>((
      ref,
      configuration,
    ) async {
      final authenticator = ref.watch(stalkerAuthenticatorProvider);
      return authenticator.authenticate(configuration);
    });

/// Provides shared access to the Xtream authenticator.
final xtreamAuthenticatorProvider = Provider<XtreamAuthenticator>((ref) {
  return DefaultXtreamAuthenticator();
});

/// Runs the Xtream login flow for a given configuration.
final xtreamSessionProvider =
    FutureProvider.family<XtreamSession, XtreamPortalConfiguration>((
      ref,
      configuration,
    ) async {
      final authenticator = ref.watch(xtreamAuthenticatorProvider);
      return authenticator.authenticate(configuration);
    });

/// Provides shared access to the M3U/XMLTV authenticator.
final m3uXmlAuthenticatorProvider = Provider<M3uXmlAuthenticator>((ref) {
  return DefaultM3uXmlAuthenticator(client: M3uXmlClient());
});

/// Fetches and validates the playlist/EPG pair for a configuration.
final m3uXmlSessionProvider =
    FutureProvider.family<M3uXmlSession, M3uXmlPortalConfiguration>((
      ref,
      configuration,
    ) async {
      final authenticator = ref.watch(m3uXmlAuthenticatorProvider);
      return authenticator.authenticate(configuration);
    });

/// Helper that builds a basic configuration for the supplied playlist input.
M3uXmlPortalConfiguration buildM3uConfiguration({
  required String portalId,
  required String playlistInput,
  String? displayName,
  String? username,
  String? password,
  String? userAgent,
  Map<String, String>? customHeaders,
  bool allowSelfSignedTls = false,
  bool followRedirects = true,
  String? xmltvInput,
  Map<String, String>? xmltvHeaders,
}) {
  final trimmed = playlistInput.trim();
  final isRemote = trimmed.contains('://');
  final query = <String, dynamic>{};
  if (username != null && username.isNotEmpty) {
    query['username'] = username;
  }
  if (password != null && password.isNotEmpty) {
    query['password'] = password;
  }

  final resolvedHeaders = customHeaders ?? const {};
  XmltvSourceDescriptor? xmltvSource;
  if (xmltvInput != null && xmltvInput.trim().isNotEmpty) {
    final trimmedXmltv = xmltvInput.trim();
    if (trimmedXmltv.contains('://')) {
      xmltvSource = XmltvUrlSource(
        epgUri: Uri.parse(trimmedXmltv),
        headers: xmltvHeaders ?? resolvedHeaders,
      );
    } else {
      xmltvSource = XmltvFileSource(
        filePath: trimmedXmltv,
        originalFileName: displayName,
        displayName: displayName,
      );
    }
  }

  return M3uXmlPortalConfiguration(
    portalId: portalId,
    displayName: displayName ?? portalId,
    defaultUserAgent: userAgent,
    allowSelfSignedTls: allowSelfSignedTls,
    defaultHeaders: resolvedHeaders,
    followRedirects: followRedirects,
    xmltvSource: xmltvSource,
    m3uSource: isRemote
        ? M3uUrlSource(
            playlistUri: Uri.parse(trimmed),
            extraQuery: query,
            displayName: displayName,
            headers: customHeaders,
          )
        : M3uFileSource(
            filePath: trimmed,
            originalFileName: displayName,
            displayName: displayName,
          ),
  );
}
