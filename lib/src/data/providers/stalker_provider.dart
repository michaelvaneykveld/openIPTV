import 'package:dio/dio.dart';
import 'dart:convert'; // Belangrijk: import voor JSON conversie

import '../../core/api/iprovider.dart';
import '../../core/models/models.dart';

/// An implementation of [IProvider] for Stalker Portals.
class StalkerProvider implements IProvider {
  final Dio _dio;
  StalkerCredentials? _credentials;

  StalkerProvider({Dio? dio}) : _dio = dio ?? Dio();

  @override
  Future<void> signIn(Credentials credentials) async {
    if (credentials is! StalkerCredentials) {
      throw ArgumentError('Invalid credentials type provided for StalkerProvider.');
    }
    _credentials = credentials;
    // For Stalker, we often need to "handshake" to get a token.
    // For now, we'll just store the credentials.
  }

  @override
  Future<List<Channel>> fetchLiveChannels() async {
    if (_credentials == null) {
      throw StateError('You must sign in before fetching channels.');
    }

    // Construct the Stalker API request URL
    final url = Uri.parse(_credentials!.portalUrl).replace(
      queryParameters: {
        'type': 'itv',
        'action': 'get_all_channels',
        'mac': _credentials!.macAddress,
      },
    ).toString();

    print('Requesting Stalker channels from: $url');

    try {
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            // Stalker portals are often picky about the User-Agent
            'User-Agent': 'Mozilla/5.0 (Qt; U; Linux; en) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36',
            'Accept': 'application/json',
          },
        ),
      );

      // DE FIX: Zet de data expliciet om naar een JSON string voordat we het printen.
      // Dit is de meest robuuste manier om de debugger-fout te voorkomen.
      final responseDataString = jsonEncode(response.data);
      print('RAW STALKER RESPONSE:');
      print(responseDataString);

      // For now, we return an empty list because we haven't written the parser yet.
      return [];
    } catch (e) {
      print('Error fetching Stalker channels: $e');
      // Re-throw the error so the UI can display it.
      rethrow;
    }
  }

  @override
  Future<List<Category>> fetchCategories() async => throw UnimplementedError();
  @override
  Future<List<VodItem>> fetchVod({Category? category}) async => throw UnimplementedError();
  @override
  Future<List<Series>> fetchSeries({Category? category}) async => throw UnimplementedError();
  @override
  Future<List<EpgEvent>> fetchEpg(String channelId, DateTime from, DateTime to) async => throw UnimplementedError();
  @override
  StreamUrlResolver get resolver => throw UnimplementedError();
}
