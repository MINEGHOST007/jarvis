import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConnectionDetails {
  final String serverUrl;
  final String roomName;
  final String participantName;
  final String participantToken;

  ConnectionDetails({
    required this.serverUrl,
    required this.roomName,
    required this.participantName,
    required this.participantToken,
  });

  factory ConnectionDetails.fromJson(Map<String, dynamic> json) {
    return ConnectionDetails(
      serverUrl: json['serverUrl'],
      roomName: json['roomName'],
      participantName: json['participantName'],
      participantToken: json['participantToken'],
    );
  }
}

class TokenService extends ChangeNotifier {
  final String? hardcodedServerUrl = null;
  final String? hardcodedToken = null;

  String? get sandboxId {
    final value = dotenv.env['LIVEKIT_SANDBOX_ID'];
    if (value != null) {
      return value.replaceAll('"', '');
    }
    return null;
  }

  final String sandboxUrl =
      'https://cloud-api.livekit.io/api/sandbox/connection-details';


  Future<ConnectionDetails?> fetchConnectionDetails({
    required String roomName,
    required String participantName,
  }) async {
    final hardcodedDetails = fetchHardcodedConnectionDetails(
      roomName: roomName,
      participantName: participantName,
    );

    if (hardcodedDetails != null) {
      return hardcodedDetails;
    }

    return await fetchConnectionDetailsFromSandbox(
      roomName: roomName,
      participantName: participantName,
    );
  }

  Future<ConnectionDetails?> fetchConnectionDetailsFromSandbox({
    required String roomName,
    required String participantName,
  }) async {
    if (sandboxId == null) {
      return null;
    }

    final uri = Uri.parse(sandboxUrl).replace(queryParameters: {
      'roomName': roomName,
      'participantName': participantName,
    });

    try {
      final response = await http.post(
        uri,
        headers: {'X-Sandbox-ID': sandboxId!},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final data = jsonDecode(response.body);
          debugPrint("Details : ${data}");
          return ConnectionDetails.fromJson(data);
        } catch (e) {
          debugPrint(
              'Error parsing connection details from LiveKit Cloud sandbox, response: ${response.body}');
          return null;
        }
      } else {
        debugPrint(
            'Error from LiveKit Cloud sandbox: ${response.statusCode}, response: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Failed to connect to LiveKit Cloud sandbox: $e');
      return null;
    }
  }

  ConnectionDetails? fetchHardcodedConnectionDetails({
    required String roomName,
    required String participantName,
  }) {
    if (hardcodedServerUrl == null || hardcodedToken == null) {
      return null;
    }

    return ConnectionDetails(
      serverUrl: hardcodedServerUrl!,
      roomName: roomName,
      participantName: participantName,
      participantToken: hardcodedToken!,
    );
  }
}