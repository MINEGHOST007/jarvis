import 'package:flutter/material.dart';
import 'package:voice_assistant/services/server_service.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

class RecordingsListScreen extends StatefulWidget {
  const RecordingsListScreen({super.key});

  @override
  State<RecordingsListScreen> createState() => _RecordingsListScreenState();
}

class _RecordingsListScreenState extends State<RecordingsListScreen> {
  final ServerService _serverService = ServerService();
  late Future<List<String>> _recordingsFuture;
  bool _downloading = false;
  
  @override
  void initState() {
    super.initState();
    _recordingsFuture = _serverService.get_list_recordings();
  }

  void _refresh() {
    setState(() {
      _recordingsFuture = _serverService.get_list_recordings();
    });
  }

  Future<void> _downloadRecording(String fullPath) async {
    setState(() {
      _downloading = true;
    });
    try {
      final urlString = await _serverService.getRecordingUrl(fullPath);
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch download URL')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _downloading = false;
      });
    }
  }

  String _formatFileName(String fullPath) {
    final fileName = p.basename(fullPath);
    // Add any additional formatting logic if needed
    return fileName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Recordings'),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh recordings',
            onPressed: _downloading ? null : _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: Stack(
          children: [
            FutureBuilder<List<String>>(
              future: _recordingsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.red,
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading recordings',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.mic_none_rounded,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No recordings found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your recordings will appear here',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Refresh'),
                        ),
                      ],
                    ),
                  );
                } else {
                  final recordings = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: recordings.length,
                    itemBuilder: (context, index) {
                      final fullPath = recordings[index];
                      final fileName = _formatFileName(fullPath);
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          elevation: 2,
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: _downloading 
                                ? null 
                                : () => _downloadRecording(fullPath),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primaryContainer,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.audio_file_rounded,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          fileName,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tap to download or play',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.download_rounded),
                                    tooltip: 'Download recording',
                                    onPressed: _downloading 
                                        ? null 
                                        : () => _downloadRecording(fullPath),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
            if (_downloading)
              Container(
                color: Colors.black45,
                alignment: Alignment.center,
                child: Card(
                  margin: const EdgeInsets.all(32),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 24),
                        Text(
                          'Preparing download...',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
