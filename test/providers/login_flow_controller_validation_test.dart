import 'package:flutter_test/flutter_test.dart';
import 'package:openiptv/src/providers/login_flow_controller.dart';

void main() {
  group('LoginFlowController URL validation', () {
    test('accepts bare domain for M3U playlists', () {
      final controller = LoginFlowController();
      controller.selectProvider(LoginProviderType.m3u);
      controller.updateM3uPlaylistUrl('open.iptv.me');

      final isValid = controller.validateActiveForm();

      expect(isValid, isTrue);
      expect(controller.state.m3u.playlistUrl.error, isNull);
    });

    test('accepts IPv4 with port for Xtream', () {
      final controller = LoginFlowController();
      controller.selectProvider(LoginProviderType.xtream);
      controller.updateXtreamServerUrl('203.0.113.10:2086');
      controller.updateXtreamUsername('demo');
      controller.updateXtreamPassword('secret');

      final isValid = controller.validateActiveForm();

      expect(isValid, isTrue);
      expect(controller.state.xtream.serverUrl.error, isNull);
    });

    test('accepts bare domain for Stalker portals', () {
      final controller = LoginFlowController();
      controller.selectProvider(LoginProviderType.stalker);
      controller.updateStalkerPortalUrl('open.iptv.me');
      controller.updateStalkerMacAddress('00:11:22:33:44:55');

      final isValid = controller.validateActiveForm();

      expect(isValid, isTrue);
      expect(controller.state.stalker.portalUrl.error, isNull);
    });

    test('rejects filesystem paths in URL fields', () {
      final controller = LoginFlowController();
      controller.selectProvider(LoginProviderType.m3u);
      controller.updateM3uPlaylistUrl(r'C:\iptv\playlist.m3u');

      final isValid = controller.validateActiveForm();

      expect(isValid, isFalse);
      expect(controller.state.m3u.playlistUrl.error, isNotNull);
    });
  });
}
