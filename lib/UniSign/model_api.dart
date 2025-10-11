import 'package:dio/dio.dart';

class ModelApiService {
  final Dio _dio = Dio();

  String baseUrl =
      'https://animation-notebooks-wichita-download.trycloudflare.com';

  ModelApiService() {
    _dio.options.connectTimeout = Duration(minutes: 3);
    _dio.options.receiveTimeout = Duration(minutes: 3);
  }

  void updateBaseUrl(String newUrl) {
    baseUrl = newUrl.endsWith('/')
        ? newUrl.substring(0, newUrl.length - 1)
        : newUrl;
    print('API URL updated: $baseUrl');
  }

  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get('$baseUrl/health');
      if (response.statusCode == 200) {
        print('Server healthy: ${response.data}');
        return true;
      }
      return false;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> recognizeVideo({
    required String videoUrl,
    required String userId,
    String? chatId,
  }) async {
    try {
      print('Sending video to API...');
      print('Video URL: $videoUrl');

      final response = await _dio.post(
        '$baseUrl/recognize',
        data: {'video_url': videoUrl, 'userId': userId, 'chatId': chatId},
      );

      if (response.statusCode == 200) {
        print('Recognition successful: ${response.data}');
        return response.data;
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('Network error: ${e.message}');

      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Connection timeout.');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Processing took too long');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }
}
