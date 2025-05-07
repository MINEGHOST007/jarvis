import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:voice_assistant/services/user_id_service.dart';

class ServerService {
  final String _baseUrl;

  ServerService._internal()
      : _baseUrl = (dotenv.env['BACKEND_URL'] ?? 'http://127.0.0.1:8000')
            .replaceAll(RegExp(r'/+$'), '');

  static final ServerService _instance = ServerService._internal();

  factory ServerService() => _instance;

  final UserIdService _userIdService = UserIdService();
  Future<Map<String, dynamic>> startEgress(
      String roomName, bool audio_only) async {
    final userId = await _userIdService.getUserId();
    final uri = Uri.parse(
      '$_baseUrl/egress/start'
      '?room_name=${Uri.encodeComponent(roomName)}'
      '&user_id=${Uri.encodeComponent(userId)}'
      '&audio_only=${Uri.encodeComponent(audio_only.toString())}',
    );
    final resp = await http.post(uri);
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('startEgress failed (${resp.statusCode}): ${resp.body}');
    }
  }

  Future<Map<String, dynamic>> stopEgress(String egressId) async {
    final uri = Uri.parse(
      '$_baseUrl/egress/stop?egress_id=${Uri.encodeComponent(egressId)}',
    );
    final resp = await http.post(uri);
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } else {
      throw Exception('stopEgress failed (${resp.statusCode}): ${resp.body}');
    }
  }

  Future<List<String>> get_list_recordings() async {
    String user_id = await _userIdService.getUserId();
    final uri = Uri.parse(
      '$_baseUrl/list?user_id=${Uri.encodeComponent(user_id)}',
    );
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      Map<String, dynamic> records = jsonDecode(resp.body);
      return List<String>.from(records['recordings'] as List<dynamic>);
    } else {
      throw Exception(
          'get_list_recordings failed (${resp.statusCode}): ${resp.body}');
    }
  }

  // get url
  Future<String> getRecordingUrl(String filepath) async {
    final uri = Uri.parse(
      '$_baseUrl/get_file_url?file_key=${Uri.encodeComponent(filepath)}',
    );
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body)['url'] as String;
    } else {
      throw Exception(
          'getRecordingUrl failed (${resp.statusCode}): ${resp.body}');
    }
  }
}
