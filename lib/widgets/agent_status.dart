import 'package:flutter/material.dart';
import 'package:livekit_components/livekit_components.dart';


class AgentStatusWidget extends StatefulWidget {
  const AgentStatusWidget({
    super.key,
  });

  @override
  State<AgentStatusWidget> createState() => _AgentStatusWidgetState();
}

class _AgentStatusWidgetState extends State<AgentStatusWidget> {
  @override
  Widget build(BuildContext context) {
    return ParticipantSelector(
      filter: (identifier) =>
          identifier.isAudio && !identifier.isLocal,
      builder: (context, identifier) {
        return SizedBox(
          height: 320,
          child: AudioVisualizerWidget(
            noTrackWidget: const SizedBox.shrink(),
            options: AudioVisualizerWidgetOptions(
              width: 32,
              minHeight: 32,
              maxHeight: 320,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      },
    );
  }
}


enum AgentState {
  initializing,
  speaking,
  thinking,
  listening; 

  static AgentState fromString(String value) {
    return AgentState.values.firstWhere(
      (state) => state.name == value,
      orElse: () => AgentState.initializing,
    );
  }
}
