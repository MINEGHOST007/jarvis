import 'package:chat_bubbles/chat_bubbles.dart' show BubbleNormal;
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' show LocalParticipant;
import 'package:livekit_components/livekit_components.dart';

class TranscriptionWidget extends StatefulWidget {
  const TranscriptionWidget({
    super.key,
    required this.transcriptions,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.white,
  });
  final Color backgroundColor;
  final Color textColor;
  final List<TranscriptionForParticipant> transcriptions;
  @override
  State<TranscriptionWidget> createState() => _TranscriptionWidgetState();
}

class _TranscriptionWidgetState extends State<TranscriptionWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  List<Widget> _buildMessages(
      context, List<TranscriptionForParticipant> transcriptions) {
    List<Widget> msgWidgets = [];
    var sortedTranscriptions = transcriptions
      ..sort((a, b) =>
          a.segment.firstReceivedTime.compareTo(b.segment.firstReceivedTime));
    for (var transcription in sortedTranscriptions) {
      var participant = transcription.participant;
      var segment = transcription.segment;

      if (participant is LocalParticipant) {
        msgWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: BubbleNormal(
              text: segment.text + (segment.isFinal ? '' : '...'),
              textStyle: TextStyle(
                color: widget.textColor,
                fontSize: 18,
              ),
              color: widget.backgroundColor,
              tail: true,
              isSender: true,
            ),
          ),
        );
      } else {
        msgWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  segment.text + (segment.isFinal ? '' : '...'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
    return msgWidgets;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            reverse: true,
            child: Column(
              children: _buildMessages(context, widget.transcriptions),
            ),
          ),
        ),
      ],
    );
  }
}
