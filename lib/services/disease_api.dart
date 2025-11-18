import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class DiseaseApi {
  final String baseUrl;

  DiseaseApi({
    this.baseUrl = 'https://mitran-disease-detection.onrender.com',
  });

  Future<bool> checkHealth() async {
    try {
      final uri = Uri.parse('$baseUrl/health');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final status = data['status'];
        if (status is String) {
          return status.toLowerCase() == 'ok';
        }
        return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<List<String>> getLabels() async {
    try {
      final uri = Uri.parse('$baseUrl/labels');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        throw Exception('Failed to load labels');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['labels'] as List).cast<String>();
    } catch (e) {
      throw Exception('Get labels error: $e');
    }
  }

  Future<Map<String, dynamic>> predict({
    required Uint8List imageBytes,
    required String filename,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/predict');
      final request = http.MultipartRequest('POST', uri);
      final ext = filename.toLowerCase().split('.').last;
      final subtype = ext == 'png' ? 'png' : 'jpeg';
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: filename,
          contentType: MediaType('image', subtype),
        ),
      );
      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 400) {
        throw Exception('Unsupported file type. Use PNG or JPEG.');
      }
      if (response.statusCode == 503) {
        throw Exception('AI model is not ready. Please wait and try again.');
      }
      if (response.statusCode != 200) {
        throw Exception('Prediction failed: ${response.statusCode}');
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Predict error: $e');
    }
  }
}