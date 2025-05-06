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
  ServerService serverService = ServerService();
  late Future<List<String>> _recordingsFuture;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _recordingsFuture = serverService.get_list_recordings();
  }

  void _refresh() {
    setState(() {
      _recordingsFuture = serverService.get_list_recordings();
    });
  }

  Future<void> _downloadRecording(String fullPath) async {
    setState(() {
      _downloading = true;
    });
    try {
      final urlString = await serverService.getRecordingUrl(fullPath);
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recordings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh recordings',
            onPressed: _refresh,
          ),
        ],
      ),
      body: Stack(
        children: [
          FutureBuilder<List<String>>(
            future: _recordingsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No recordings found.'));
              } else {
                final recordings = snapshot.data!;
                return ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  itemCount: recordings.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final fullPath = recordings[index];
                    final fileName = p.basename(fullPath);
                    return Card(
                      child: ListTile(
                        title: Text(fileName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                        trailing: IconButton(
                          icon: const Icon(Icons.download),
                          tooltip: 'Download',
                          onPressed: () => _downloadRecording(fullPath),
                        ),
                        onTap: () => _downloadRecording(fullPath),
                      ),
                    );
                  },
                );
              }
            },
          ),
          if (_downloading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
