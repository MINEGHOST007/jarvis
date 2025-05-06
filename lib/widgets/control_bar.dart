import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as livekit
    show ConnectionState;
import 'package:provider/provider.dart';
import 'package:voice_assistant/services/server_service.dart';
import '../services/token_service.dart';
import 'package:livekit_components/livekit_components.dart';

enum Configuration { disconnected, connected, transitioning }

class ControlBar extends StatefulWidget {
  const ControlBar({super.key});

  @override
  State<ControlBar> createState() => _ControlBarState();
}

class _ControlBarState extends State<ControlBar> {
  bool isConnecting = false;
  bool isDisconnecting = false;
  bool isEgressActive = false;
  ServerService serverService = ServerService();
  Configuration get currentConfiguration {
    if (isConnecting || isDisconnecting) {
      return Configuration.transitioning;
    }

    final roomContext = context.read<RoomContext>();
    if (roomContext.room.connectionState ==
        livekit.ConnectionState.disconnected) {
      return Configuration.disconnected;
    } else {
      return Configuration.connected;
    }
  }

  Future<void> connect() async {
    final roomContext = context.read<RoomContext>();
    final tokenService = context.read<TokenService>();

    setState(() {
      isConnecting = true;
    });

    try {
      final roomName =
          'room-${(1000 + DateTime.now().millisecondsSinceEpoch % 9000)}';
      final participantName =
          'user-${(1000 + DateTime.now().millisecondsSinceEpoch % 9000)}';

      final connectionDetails = await tokenService.fetchConnectionDetails(
        roomName: roomName,
        participantName: participantName,
      );

      if (connectionDetails == null) {
        throw Exception('Failed to get connection details');
      }

      await roomContext.connect(
        url: connectionDetails.serverUrl,
        token: connectionDetails.participantToken,
      );

      await roomContext.localParticipant?.setMicrophoneEnabled(true);
    } catch (error) {
      debugPrint('Connection error: $error');
    } finally {
      setState(() {
        isConnecting = false;
      });
    }
  }

  Future<void> disconnect() async {
    final roomContext = context.read<RoomContext>();

    setState(() {
      isDisconnecting = true;
    });

    await roomContext.disconnect();

    setState(() {
      isDisconnecting = false;
    });
  }

  String egressId = '';

  Future<void> startEgress() async {
    final roomContext = context.read<RoomContext>();
    String? roomName = roomContext.room.name;
    if (roomName == null) {
      debugPrint('Room name is null');
      return;
    }
    var metadata = await serverService.startEgress(roomName);
    setState(() {
      egressId = metadata['info']['egress_id'];
      isEgressActive = true;
    });
  }

  Future<void> stopEgress() async {
    final roomContext = context.read<RoomContext>();
    String? roomName = roomContext.room.name;
    if (roomName == null) {
      debugPrint('Room name is null');
      return;
    }
    await serverService.stopEgress(egressId);
    setState(() {
      egressId = '';
      isEgressActive = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Builder(builder: (context) {
          switch (currentConfiguration) {
            case Configuration.disconnected:
              return ConnectButton(onPressed: connect);

            case Configuration.connected:
              return Row(

                children: [
                  const AudioControls(),
                  DisconnectButton(onPressed: disconnect),
                  IconButton(
                    onPressed: isEgressActive ? stopEgress : startEgress,
                    icon: Icon(isEgressActive ? Icons.stop : Icons.mic),
                    tooltip:
                        isEgressActive ? 'Stop Recording' : 'Start Recording',
                  ),
                ],
              );

            case Configuration.transitioning:
              return TransitionButton(isConnecting: isConnecting);
          }
        }),
      ],
    );
  }
}

class ConnectButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ConnectButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        foregroundColor: Theme.of(context).colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        'Start a Conversation'.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class DisconnectButton extends StatelessWidget {
  final VoidCallback onPressed;

  const DisconnectButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(Icons.close),
      style: IconButton.styleFrom(
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class TransitionButton extends StatelessWidget {
  final bool isConnecting;

  const TransitionButton({super.key, required this.isConnecting});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: null,
      style: TextButton.styleFrom(
        backgroundColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        foregroundColor: Theme.of(context).colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        (isConnecting ? 'Connecting…' : 'Disconnecting…').toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class AudioControls extends StatelessWidget {
  const AudioControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RoomContext>(
      builder: (context, roomContext, _) => MediaDeviceContextBuilder(
        builder: (context, roomCtx, mediaDeviceCtx) {
          return SizedBox(
            height: 42,
            child: Row(
              children: [
                MicrophoneSelectButton(
                  selectedColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  selectedOverlayColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  iconColor: Theme.of(context).colorScheme.primary,
                  titleWidget: ParticipantSelector(
                    filter: (identifier) =>
                        identifier.isAudio && identifier.isLocal,
                    builder: (context, identifier) {
                      return AudioVisualizerWidget(
                        options: AudioVisualizerWidgetOptions(
                          width: 3,
                          spacing: 3,
                          minHeight: 3,
                          maxHeight: 32,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
