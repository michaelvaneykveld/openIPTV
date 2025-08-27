import 'dart:developer' as developer;
import 'dart:convert'; // Added for jsonDecode
import 'package:dio/dio.dart';
import 'package:openiptv/src/core/api/iprovider.dart';
import 'package:openiptv/src/core/models/channel.dart';
import 'package:openiptv/src/data/datasources/secure_storage_interface.dart'; // Import the new interface
import 'package:openiptv/src/core/models/credential.dart'; // Import Credential model

class StalkerApiProvider implements IProvider {
  final Dio _dio;
  final SecureStorageInterface _secureStorage; // Explicitly typed with new interface

  StalkerApiProvider(this._dio, this._secureStorage);

  static const _tokenKey = 'stalker_token';

  Future<String?> login(String portalUrl, String macAddress) async {
    try {
      final response = await _dio.get(
        '$portalUrl/server/load.php',
        queryParameters: {
          'type': 'stb',
          'action': 'handshake',
          'token': '',
          'mac': macAddress,
          'JsHttpRequest': '1-xml', // Added this line
        },
      );

      final Map<String, dynamic> responseData = jsonDecode(response.data);

      if (response.statusCode == 200 && responseData['js'] != null && responseData['js']['token'] != null) {
        final token = responseData['js']['token'] as String;
        await _secureStorage.write(key: _tokenKey, value: token);
        developer.log('Login successful, token received.', name: 'StalkerApiProvider');
        return token;
      } else {
        developer.log('Login failed. Status code: \${response.statusCode}, data: \${response.data}', name: 'StalkerApiProvider');
        throw Exception('Failed to login');
      }
    } catch (e) {
      developer.log('Error during login: $e', name: 'StalkerApiProvider');
      return null;
    }
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  @override
  Future<List<Channel>> fetchLiveChannels() async {
    final savedCredentials = await _secureStorage.getCredentialsList();
    if (savedCredentials.isEmpty) {
      throw Exception('No saved credentials found. Please log in.');
    }
    // Assuming the first saved credential is the one to use for fetching channels
    final portalUrl = savedCredentials.first.portalUrl.replaceAll(RegExp(r'/$'), '');
    final macAddress = savedCredentials.first.macAddress; // Also get macAddress if needed for future API calls

    // Re-login to get a fresh token with the stored credentials
    final newToken = await login(portalUrl, macAddress);
    if (newToken == null) {
      throw Exception('Failed to re-login with saved credentials.');
    }
    // Update the token for the current fetch operation
    final token = newToken;

    try {
      final response = await _dio.get(
        '$portalUrl/portal.php',
        queryParameters: {
          'type': 'itv',
          'action': 'get_ordered_list',
          'JsHttpRequest': '1-xml', // Added this line
        },
        options: Options( // This Options is from Dio
          headers: {
            'Authorization': 'Bearer $token',
            'User-Agent': 'Mozilla/5.0 (QtEmbedded; U; Linux; C)', // Added User-Agent
            'Cookie': 'mac=$macAddress', // Added Cookie with MAC address
          },
        ),
      );

      // throw Exception('Channel Fetch URL: \${response.requestOptions.uri.toString()}'); // Temporary: to get the URL

      developer.log('Channel Fetch URL: ' + response.requestOptions.uri.toString(), name: 'StalkerApiProvider');

      if (response.data == null || response.data.toString().isEmpty) {
        developer.log('Raw channel response: (empty)', name: 'StalkerApiProvider');
        return [];
      }

      developer.log('Raw channel response: ${response.data}', name: 'StalkerApiProvider');

      // Assuming channel data is also JSON and needs decoding
      final Map<String, dynamic> responseData = jsonDecode(response.data);

      if (response.statusCode == 200 && responseData['js'] != null && responseData['js']['data'] != null) {
        final channelsData = responseData['js']['data'] as List;
        return channelsData.map((channelData) {
          return Channel(
            id: channelData['id'].toString(),
            name: channelData['name'] as String,
            logoUrl: channelData['logo'] as String?,
            streamUrl: channelData['cmd'] as String,
            group: channelData['tv_genre_id'].toString(), // Or another field if available
            epgId: channelData['epg_id'].toString(),
          );
        }).toList();
      } else {
        throw Exception('Failed to fetch channels');
      }
    } catch (e) {
      developer.log(e.toString(), name: 'StalkerApiProvider');
      return [];
    }
  }
}
