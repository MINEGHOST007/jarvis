import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_components/livekit_components.dart'
    show RoomContext, TranscriptionBuilder;
import 'package:provider/provider.dart';
import 'package:voice_assistant/services/token_service.dart';
import 'package:voice_assistant/widgets/agent_status.dart';
import 'package:voice_assistant/widgets/control_bar.dart';
import 'package:voice_assistant/widgets/transcription_widget.dart';

/// The main voice assistant screen that manages the LiveKit room connection
/// and displays the status visualizer and control bar
class VoiceAssistant extends StatefulWidget {
  const VoiceAssistant({super.key});
  @override
  State<VoiceAssistant> createState() => _VoiceAssistantState();
}

class _VoiceAssistantState extends State<VoiceAssistant> {
  // Create a LiveKit Room instance with audio visualization enabled
  // This is the main object that manages the connection to LiveKit
  final room = Room(roomOptions: const RoomOptions(enableVisualizer: true,));

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Provide the TokenService and RoomContext to descendant widgets
      // TokenService handles LiveKit authentication
      // RoomContext provides LiveKit room state and operations
      providers: [
        ChangeNotifierProvider(create: (context) => TokenService()),
        ChangeNotifierProvider(create: (context) => RoomContext(room: room)),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Voice Assistant'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 6,
                  child: TranscriptionBuilder(
                    builder: (context, roomCtx, transcriptions) {
                      print("Transcriptions: ${transcriptions}");
                      return TranscriptionWidget(
                        textColor: Theme.of(context).colorScheme.primary,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                        transcriptions: transcriptions,
                      );
                    },
                  ),
                ),
                // Status widget shows the agent's audio visualization
                const Expanded(
                  flex: 3,
                  child: AgentStatusWidget(),
                ),
                // Control bar handles room connection and audio controls
                const Expanded(
                  flex: 3,
                  child: ControlBar(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
