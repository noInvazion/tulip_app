import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../models/case_score_response.dart';

class TulipApiService {
  /// Update this to match wherever the FastAPI backend is running.
  final String baseUrl;

  const TulipApiService({this.baseUrl = 'http://localhost:8000'});

  Future<CaseScoreResponse> scoreCase({
    PlatformFile? lCc,
    PlatformFile? lMlo,
    PlatformFile? rCc,
    PlatformFile? rMlo,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/case'));

    void addIfPresent(String field, PlatformFile? file) {
      if (file == null || file.bytes == null) return;
      request.files.add(http.MultipartFile.fromBytes(
        field, file.bytes!, filename: file.name,
      ));
    }

    addIfPresent('l_cc', lCc);
    addIfPresent('l_mlo', lMlo);
    addIfPresent('r_cc', rCc);
    addIfPresent('r_mlo', rMlo);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw TulipApiException(
        statusCode: response.statusCode,
        detail: body['detail']?.toString() ?? 'Unknown error',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return CaseScoreResponse.fromJson(body);
  }

  String imageUrl(String relativePath) => '$baseUrl$relativePath';
}

class TulipApiException implements Exception {
  final int statusCode;
  final String detail;
  TulipApiException({required this.statusCode, required this.detail});

  @override
  String toString() => 'TulipApiException($statusCode): $detail';
}