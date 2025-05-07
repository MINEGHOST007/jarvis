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
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
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
          elevation: 2,
          title: const Text('Friday',
              style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
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
                    icon: const Icon(Icons.settings))
                : const SizedBox()
          ],
        ),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
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
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.surface,
            colorScheme.surfaceVariant,
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Center(
        child: SingleChildScrollView(
          child: Card(
            elevation: 8,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: const EdgeInsets.symmetric(vertical: 16),
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.settings, size: 64, color: colorScheme.primary),
                  const SizedBox(height: 20),
                  Text(
                    'Configure Your Session',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Select Video Quality',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outline),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: DropdownButton<VideoParameters>(
                      value: selectedVideoParams,
                      isExpanded: true,
                      underline: const SizedBox(),
                      borderRadius: BorderRadius.circular(12),
                      icon: Icon(Icons.arrow_drop_down,
                          color: colorScheme.primary),
                      items: _buildVideoQualityOptions(),
                      onChanged: (value) {
                        setState(() {
                          selectedVideoParams = value;
                          _initializeRoom();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 36),
                  ElevatedButton(
                    onPressed: _connect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 36, vertical: 16),
                      minimumSize: const Size(220, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 3,
                    ),
                    child: const Text('Start Session',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w500)),
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
    // Adjust proportions based on device size
    final isLargeScreen = size.height > 700;

    return Container(
      key: const ValueKey('connected'),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: TranscriptionBuilder(
                    builder: (context, roomCtx, transcriptions) {
                      debugPrint("Transcriptions: $transcriptions");
                      return Container(
                        padding: const EdgeInsets.all(10),
                        child: TranscriptionWidget(
                          textColor: colorScheme.onSurface,
                          backgroundColor: colorScheme.surface,
                          transcriptions: transcriptions,
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: AgentStatusWidget(),
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
