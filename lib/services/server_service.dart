import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ServerService {
  final String _baseUrl;

  ServerService._internal()
      : _baseUrl = (dotenv.env['BACKEND_URL'] ?? 'http://127.0.0.1:8000')
            .replaceAll(RegExp(r'/+$'), '');

  static final ServerService _instance = ServerService._internal();

  factory ServerService() => _instance;

  String get _sessionId => dotenv.env['SESSION_ID']?.trim().isNotEmpty == true
      ? dotenv.env['SESSION_ID']!
      : 'default_session_id';

  Future<Map<String, dynamic>> startEgress(String roomName) async {
    final uri = Uri.parse(
      '$_baseUrl/egress/start'
      '?session_id=${Uri.encodeComponent(_sessionId)}'
      '&room_name=${Uri.encodeComponent(roomName)}',
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

  Future<List<Map<String, dynamic>>> listEgresses() async {
    final uri = Uri.parse('$_baseUrl/egress/list');
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      final list = jsonDecode(resp.body) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } else {
      throw Exception('listEgresses failed (${resp.statusCode}): ${resp.body}');
    }
  }

  Future<List<String>> getRecordings() async {
    final uri = Uri.parse('$_baseUrl/recordings');
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return List<String>.from(data['recordings'] ?? []);
    } else {
      throw Exception(
          'getRecordings failed (${resp.statusCode}): ${resp.body}');
    }
  }

  String getRecordingUrl(String recordingId) {
    final encoded = Uri.encodeComponent(recordingId);
    return '$_baseUrl/recordings/$encoded';
  }
}
