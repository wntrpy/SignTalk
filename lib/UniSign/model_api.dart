import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';

class ModelApiService {
  final Dio _dio = Dio();

  static final ModelApiService _instance = ModelApiService._internal();
  factory ModelApiService() => _instance;
  
  ModelApiService._internal(){
    _dio.options.connectTimeout = Duration(minutes: 3);
    _dio.options.receiveTimeout = Duration(minutes: 3);
  }


  String baseUrl = '';

  StreamSubscription<DocumentSnapshot>? _urlSubscription;

  // Call this once when app starts
  Future<void> initialize() async {
    // Get initial URL
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('BaseUrl')
          .doc('serverApi')
          .get();
      
      if (doc.exists) {
        baseUrl = doc['URL'] ?? '';
        print('API URL loaded: $baseUrl');
      }
    } catch (e) {
      print('Error loading URL: $e');
    }

    // Listen for real-time updates
    _urlSubscription = FirebaseFirestore.instance
        .collection('BaseUrl')
        .doc('serverApi')
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        String newUrl = doc['URL'] ?? '';
        if (newUrl != baseUrl) {
          baseUrl = newUrl;
          print('API URL updated to: $baseUrl');
        }
      }
    });
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
