import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:openiptv/src/core/api/iprovider.dart';
import 'package:openiptv/src/core/models/models.dart';
import 'package:openiptv/src/data/datasources/secure_storage_interface.dart';

class StalkerApiProvider implements IProvider {
  final Dio _dio;
  final SecureStorageInterface _secureStorage;

  StalkerApiProvider(this._dio, this._secureStorage);

  static const _tokenKey = 'stalker_token';

  Future<String?> _performHandshake(String portalUrl, String macAddress) async {
    try {
      final response = await _dio.get(
        '$portalUrl/server/load.php',
        queryParameters: {
          'type': 'stb',
          'action': 'handshake',
          'token': '',
          'mac': macAddress,
          'JsHttpRequest': '1-xml',
        },
      );

      final Map<String, dynamic> responseData = response.data;

      if (response.statusCode == 200 &&
          responseData['js'] != null &&
          responseData['js']['token'] != null) {
        final token = responseData['js']['token'] as String;
        await _secureStorage.write(key: _tokenKey, value: token);
        developer.log('Handshake successful, token received.',
            name: 'StalkerApiProvider');
        return token;
      } else {
        developer.log(
            'Handshake failed. Status code: ${response.statusCode}, data: ${response.data}',
            name: 'StalkerApiProvider');
        throw Exception('Failed to perform handshake');
      }
    } catch (e) {
      developer.log('Error during handshake: $e', name: 'StalkerApiProvider');
      return null;
    }
  }

  Future<String?> _getAuthenticatedToken() async {
    final savedCredentials = await _secureStorage.getCredentialsList();
    if (savedCredentials.isEmpty) {
      throw Exception('No saved credentials found. Please log in.');
    }
    // Assuming the first credential is the active one for Stalker
    final StalkerCredentials stalkerCredentials = savedCredentials.first as StalkerCredentials;
    final portalUrl = stalkerCredentials.baseUrl.replaceAll(RegExp(r'/$'), '');
    final macAddress = stalkerCredentials.macAddress;

    String? token = await _secureStorage.read(key: _tokenKey);

    token ??= await _performHandshake(portalUrl, macAddress);

    if (token == null) {
      throw Exception('Failed to obtain authentication token.');
    }
    return token;
  }

  Options _getAuthOptions(String token, String macAddress) {
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
        'User-Agent': 'Mozilla/5.0 (QtEmbedded; U; Linux; C)',
        'Cookie': 'mac=$macAddress',
      },
    );
  }

  @override
  Future<List<Channel>> fetchLiveChannels() async {
    try {
      final savedCredentials = await _secureStorage.getCredentialsList();
      if (savedCredentials.isEmpty) {
        throw Exception('No saved credentials found. Please log in.');
      }
      final StalkerCredentials stalkerCredentials = savedCredentials.first as StalkerCredentials;
      final portalUrl = stalkerCredentials.baseUrl.replaceAll(RegExp(r'/$'), '');
      final macAddress = stalkerCredentials.macAddress;

      final token = await _getAuthenticatedToken();

      final response = await _dio.get(
        '$portalUrl/portal.php',
        queryParameters: {
          'type': 'itv',
          'action': 'get_ordered_list',
          'JsHttpRequest': '1-xml',
        },
        options: _getAuthOptions(token!, macAddress),
      );

      developer.log('Channel Fetch URL: ${response.requestOptions.uri}',
          name: 'StalkerApiProvider');

      if (response.data == null || response.data.toString().isEmpty) {
        developer.log('Raw channel response: (empty)',
            name: 'StalkerApiProvider');
        return [];
      }

      developer.log('Raw channel response: ${response.data}',
          name: 'StalkerApiProvider');

      final Map<String, dynamic> responseData = response.data;

      if (response.statusCode == 200 &&
          responseData['js'] != null &&
          responseData['js']['data'] != null) {
        final channelsData = responseData['js']['data'] as List;
        return channelsData
            .map((channelData) => Channel.fromJson(channelData))
            .toList();
      } else {
        throw Exception('Failed to fetch channels');
      }
    } catch (e) {
      developer.log('Error fetching live channels: $e',
          name: 'StalkerApiProvider');
      return [];
    }
  }

  @override
  Future<List<Genre>> getGenres() async {
    try {
      final savedCredentials = await _secureStorage.getCredentialsList();
      if (savedCredentials.isEmpty) {
        throw Exception('No saved credentials found. Please log in.');
      }
      final StalkerCredentials stalkerCredentials = savedCredentials.first as StalkerCredentials;
      final portalUrl = stalkerCredentials.baseUrl.replaceAll(RegExp(r'/$'), '');
      final macAddress = stalkerCredentials.macAddress;

      final token = await _getAuthenticatedToken();

      final response = await _dio.get(
        '$portalUrl/stalker_portal/server/load.php',
        queryParameters: {
          'type': 'itv',
          'action': 'get_genres',
        },
        options: _getAuthOptions(token!, macAddress),
      );

      final Map<String, dynamic> responseData = response.data;

      if (response.statusCode == 200 &&
          responseData['js'] != null &&
          responseData['js']['data'] != null) {
        final genresData = responseData['js']['data'] as List;
        return genresData.map((genreData) => Genre.fromJson(genreData)).toList();
      } else {
        throw Exception('Failed to fetch genres');
      }
    } catch (e) {
      developer.log('Error fetching genres: $e', name: 'StalkerApiProvider');
      return [];
    }
  }

  @override
  Future<List<VodCategory>> fetchVodCategories() async {
    try {
      final savedCredentials = await _secureStorage.getCredentialsList();
      if (savedCredentials.isEmpty) {
        throw Exception('No saved credentials found. Please log in.');
      }
      final StalkerCredentials stalkerCredentials = savedCredentials.first as StalkerCredentials;
      final portalUrl = stalkerCredentials.baseUrl.replaceAll(RegExp(r'/$'), '');
      final macAddress = stalkerCredentials.macAddress;

      final token = await _getAuthenticatedToken();

      final response = await _dio.get(
        '$portalUrl/stalker_portal/server/load.php',
        queryParameters: {
          'type': 'vod',
          'action': 'get_categories',
        },
        options: _getAuthOptions(token!, macAddress),
      );

      final Map<String, dynamic> responseData = response.data;

      if (response.statusCode == 200 &&
          responseData['js'] != null &&
          responseData['js']['data'] != null) {
        final categoriesData = responseData['js']['data'] as List;
        return categoriesData
            .map((categoryData) => VodCategory.fromJson(categoryData))
            .toList();
      } else {
        throw Exception('Failed to fetch VOD categories');
      }
    } catch (e) {
      developer.log('Error fetching VOD categories: $e',
          name: 'StalkerApiProvider');
      return [];
    }
  }

  @override
  Future<List<VodContent>> fetchVodContent(String categoryId) async {
    try {
      final savedCredentials = await _secureStorage.getCredentialsList();
      if (savedCredentials.isEmpty) {
        throw Exception('No saved credentials found. Please log in.');
      }
      final StalkerCredentials stalkerCredentials = savedCredentials.first as StalkerCredentials;
      final portalUrl = stalkerCredentials.baseUrl.replaceAll(RegExp(r'/$'), '');
      final macAddress = stalkerCredentials.macAddress;

      final token = await _getAuthenticatedToken();

      final response = await _dio.get(
        '$portalUrl/stalker_portal/server/load.php',
        queryParameters: {
          'type': 'vod',
          'action': 'get_content',
          'category_id': categoryId,
        },
        options: _getAuthOptions(token!, macAddress),
      );

      final Map<String, dynamic> responseData = response.data;

      if (response.statusCode == 200 &&
          responseData['js'] != null &&
          responseData['js']['data'] != null) {
        final contentData = responseData['js']['data'] as List;
        return contentData
            .map((content) => VodContent.fromJson(content))
            .toList();
      } else {
        throw Exception('Failed to fetch VOD content');
      }
    } catch (e) {
      developer.log('Error fetching VOD content: $e',
          name: 'StalkerApiProvider');
      return [];
    }
  }

  @override
  Future<List<Genre>> fetchRadioGenres() async {
    try {
      final savedCredentials = await _secureStorage.getCredentialsList();
      if (savedCredentials.isEmpty) {
        throw Exception('No saved credentials found. Please log in.');
      }
      final StalkerCredentials stalkerCredentials = savedCredentials.first as StalkerCredentials;
      final portalUrl = stalkerCredentials.baseUrl.replaceAll(RegExp(r'/$'), '');
      final macAddress = stalkerCredentials.macAddress;

      final token = await _getAuthenticatedToken();

      final response = await _dio.get(
        '$portalUrl/stalker_portal/server/load.php',
        queryParameters: {
          'type': 'radio',
          'action': 'get_genres',
        },
        options: _getAuthOptions(token!, macAddress),
      );

      final Map<String, dynamic> responseData = response.data;

      if (response.statusCode == 200 &&
          responseData['js'] != null &&
          responseData['js']['data'] != null) {
        final genresData = responseData['js']['data'] as List;
        return genresData.map((genreData) => Genre.fromJson(genreData)).toList();
      } else {
        throw Exception('Failed to fetch radio genres');
      }
    } catch (e) {
      developer.log('Error fetching radio genres: $e',
          name: 'StalkerApiProvider');
      return [];
    }
  }

  @override
  Future<List<Channel>> fetchRadioChannels(String genreId) async {
    try {
      final savedCredentials = await _secureStorage.getCredentialsList();
      if (savedCredentials.isEmpty) {
        throw Exception('No saved credentials found. Please log in.');
      }
      final StalkerCredentials stalkerCredentials = savedCredentials.first as StalkerCredentials;
      final portalUrl = stalkerCredentials.baseUrl.replaceAll(RegExp(r'/$'), '');
      final macAddress = stalkerCredentials.macAddress;

      final token = await _getAuthenticatedToken();

      final response = await _dio.get(
        '$portalUrl/stalker_portal/server/load.php',
        queryParameters: {
          'type': 'radio',
          'action': 'get_all_channels',
          'genre': genreId,
        },
        options: _getAuthOptions(token!, macAddress),
      );

      final Map<String, dynamic> responseData = response.data;

      if (response.statusCode == 200 &&
          responseData['js'] != null &&
          responseData['js']['data'] != null) {
        final channelsData = responseData['js']['data'] as List;
        return channelsData
            .map((channelData) => Channel.fromJson(channelData))
            .toList();
      } else {
        throw Exception('Failed to fetch radio channels');
      }
    } catch (e) {
      developer.log('Error fetching radio channels: $e',
          name: 'StalkerApiProvider');
      return [];
    }
  }

  // Implement login and logout methods
  Future<bool> login(String portalUrl, String macAddress) async {
    try {
      final token = await _performHandshake(portalUrl, macAddress);
      if (token != null) {
        // Save credentials after successful login
        await _secureStorage.saveCredentials(
            StalkerCredentials(id: portalUrl, name: 'Stalker Portal', baseUrl: portalUrl, macAddress: macAddress));
        return true;
      }
      return false;
    } catch (e) {
      developer.log('Login failed: $e', name: 'StalkerApiProvider');
      return false;
    }
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.clearAllCredentials();
    developer.log('Logged out and cleared credentials.', name: 'StalkerApiProvider');
  }
}