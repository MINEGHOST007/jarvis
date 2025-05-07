import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_components/livekit_components.dart'
  show RoomContext, TranscriptionBuilder;
import 'package:provider/provider.dart';
import 'package:voice_assistant/screens/list_recordings.dart';
import 'package:voice_assistant/services/token_service.dart';
import 'package:voice_assistant/widgets/agent_status.dart';
import 'package:voice_assistant/widgets/control_bar.dart';
import 'package:voice_assistant/widgets/transcription_widget.dart';

class VoiceAssistant extends StatefulWidget {
  const VoiceAssistant({super.key});
  @override
  State<VoiceAssistant> createState() => _VoiceAssistantState();
}

class _VoiceAssistantState extends State<VoiceAssistant>
  with SingleTickerProviderStateMixin {
  late Room room;
  VideoParameters? selectedVideoParams = VideoParametersPresets.h360_169;
  bool isConnected = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
  super.initState();
  _initializeRoom();
  _animationController = AnimationController(
    duration: const Duration(milliseconds: 700),
    vsync: this,
  );
  _animation = CurvedAnimation(
    parent: _animationController,
    curve: Curves.easeOutCubic,
  );
  }

  @override
  void dispose() {
  _animationController.dispose();
  super.dispose();
  }

  void _initializeRoom() {
  room = Room(
    roomOptions: RoomOptions(
    enableVisualizer: true,
    dynacast: true,
    defaultScreenShareCaptureOptions: ScreenShareCaptureOptions(
      captureScreenAudio: true,
      useiOSBroadcastExtension: true,
      preferCurrentTab: true,
      params: selectedVideoParams!,
    ),
    ),
  );
  }

  List<DropdownMenuItem<VideoParameters>> _buildVideoQualityOptions() {
  return [
    const DropdownMenuItem(
    value: VideoParametersPresets.h1080_169,
    child: Text('Full HD (1080p)'),
    ),
    const DropdownMenuItem(
    value: VideoParametersPresets.h720_169,
    child: Text('HD (720p)'),
    ),
    const DropdownMenuItem(
    value: VideoParametersPresets.h540_169,
    child: Text('Medium Quality (540p)'),
    ),
    const DropdownMenuItem(
    value: VideoParametersPresets.h360_169,
    child: Text('Low Quality (360p)'),
    ),
    const DropdownMenuItem(
    value: VideoParametersPresets.h180_169,
    child: Text('Very Low Quality (180p)'),
    ),
    const DropdownMenuItem(
    value: VideoParametersPresets.h720_43,
    child: Text('Portrait HD (720p 4:3)'),
    ),
    const DropdownMenuItem(
    value: VideoParametersPresets.h540_43,
    child: Text('Portrait Medium (540p 4:3)'),
    ),
    const DropdownMenuItem(
    value: VideoParametersPresets.h360_43,
    child: Text('Portrait Low (360p 4:3)'),
    ),
    const DropdownMenuItem(
    value: VideoParametersPresets.h180_43,
    child: Text('Portrait Very Low (180p 4:3)'),
    ),
  ];
  }

  void _connect() {
  setState(() {
    isConnected = true;
  });
  _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  final size = MediaQuery.of(context).size;

  return MultiProvider(
    providers: [
    ChangeNotifierProvider(create: (context) => TokenService()),
    ChangeNotifierProvider(create: (context) => RoomContext(room: room)),
    ],
    child: Scaffold(
    appBar: AppBar(
      elevation: 0,
      centerTitle: false,
      backgroundColor: colorScheme.surface.withOpacity(0.9),
      title: Text(
      'Friday',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 24,
        color: colorScheme.primary,
      ),
      ),
      actions: [
      if (isConnected)
        Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
          Icon(
            Icons.fiber_manual_record,
            color: Colors.redAccent,
            size: 12,
          ),
          const SizedBox(width: 6),
          Text(
            'LIVE',
            style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
            ),
          ),
          ],
        ),
        ),
      IconButton(
        icon: Icon(Icons.history, color: colorScheme.primary),
        tooltip: 'View Recordings',
        onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
          builder: (context) => const RecordingsListScreen(),
          ),
        );
        },
      ),
      const SizedBox(width: 8),
      isConnected
        ? IconButton(
          onPressed: () {
            setState(() {
            isConnected = false;
            _animationController.reverse();
            });
          },
          icon: Icon(Icons.settings, color: colorScheme.primary))
        : const SizedBox(),
      const SizedBox(width: 8),
      ],
    ),
    body: SafeArea(
      child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: isConnected
        ? _buildConnectedView(colorScheme, size)
        : _buildSetupView(colorScheme),
      ),
    ),
    ),
  );
  }

  Widget _buildSetupView(ColorScheme colorScheme) {
  return Container(
    key: const ValueKey('setup'),
    decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
      colorScheme.surfaceVariant.withOpacity(0.9),
      colorScheme.surface,
      ],
    ),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    child: Center(
    child: SingleChildScrollView(
      child: Card(
      elevation: 4,
      shadowColor: colorScheme.primary.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
        color: colorScheme.primary.withOpacity(0.2),
        width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mic_rounded,
            size: 64,
            color: colorScheme.primary,
          ),
          ),
          const SizedBox(height: 24),
          Text(
          'Configure Your Session',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
          'Choose your preferred video quality settings',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Text(
          'Video Quality',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
          decoration: BoxDecoration(
            border: Border.all(
            color: colorScheme.outline.withOpacity(0.6),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: DropdownButton<VideoParameters>(
            value: selectedVideoParams,
            isExpanded: true,
            underline: const SizedBox(),
            borderRadius: BorderRadius.circular(16),
            icon: Icon(
            Icons.arrow_drop_down_rounded,
            color: colorScheme.primary,
            size: 32,
            ),
            items: _buildVideoQualityOptions(),
            onChanged: (value) {
            setState(() {
              selectedVideoParams = value;
              _initializeRoom();
            });
            },
          ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
          onPressed: _connect,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(
              horizontal: 36, vertical: 16),
            minimumSize: const Size(240, 56),
            shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            ),
            elevation: 2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
            Text(
              'Start Session',
              style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.arrow_forward_rounded),
            ],
          ),
          ),
        ],
        ),
      ),
      ),
    ),
    ),
  );
  }

  Widget _buildConnectedView(ColorScheme colorScheme, Size size) {
  final isLargeScreen = size.height > 700;

  return Container(
    key: const ValueKey('connected'),
    decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
      colorScheme.surfaceVariant.withOpacity(0.8),
      colorScheme.surface,
      ],
    ),
    ),
    padding: EdgeInsets.symmetric(
      horizontal: 20, vertical: isLargeScreen ? 20 : 12),
    child: Column(
    children: [
      Expanded(
      flex: isLargeScreen ? 6 : 5,
      child: FadeTransition(
        opacity: _animation,
        child: Card(
        elevation: 4,
        shadowColor: colorScheme.primary.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
          color: colorScheme.primary.withOpacity(0.15),
          width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: TranscriptionBuilder(
          builder: (context, roomCtx, transcriptions) {
            return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 4, right: 4, bottom: 12),
                child: Row(
                children: [
                  Icon(
                  Icons.chat_rounded,
                  color: colorScheme.primary,
                  size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                  'Conversation',
                  style:
                    Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                  ),
                ],
                ),
              ),
              Expanded(
                child: TranscriptionWidget(
                textColor: colorScheme.onSurface,
                backgroundColor: colorScheme.surface,
                transcriptions: transcriptions,
                ),
              ),
              ],
            ),
            );
          },
          ),
        ),
        ),
      ),
      ),
      SizedBox(height: isLargeScreen ? 16 : 12),
      Expanded(
      flex: isLargeScreen ? 3 : 4,
      child: FadeTransition(
        opacity: _animation,
        child: Card(
        elevation: 3,
        shadowColor: colorScheme.primary.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
          color: colorScheme.primary.withOpacity(0.15),
          width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
            padding: const EdgeInsets.only(
              left: 4, right: 4, bottom: 8),
            child: Row(
              children: [
              Icon(
                Icons.assistant_rounded,
                color: colorScheme.tertiary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Agent Status',
                style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.tertiary,
                  ),
              ),
              ],
            ),
            ),
            const Expanded(child: AgentStatusWidget()),
          ],
          ),
        ),
        ),
      ),
      ),
      SizedBox(height: isLargeScreen ? 16 : 12),
      Expanded(
      flex: 2,
      child: SlideTransition(
        position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
        ).animate(_animation),
        child: const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: ControlBar(),
        ),
      ),
      ),
    ],
    ),
  );
  }
}
