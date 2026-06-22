import 'package:flutter/material.dart';import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import '../models/ocr_document.dart';
import '../services/document_service.dart';

class DocumentScreen extends StatefulWidget {
  const DocumentScreen({super.key});

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  final DocumentService _documentService = DocumentService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  OcrDocumentModel? _selectedDoc;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state.playing);
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playPodcast(String url) async {
    try {
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi phát âm thanh: $e')),
        );
      }
    }
  }

  Future<void> _generatePodcast(OcrDocumentModel doc) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔊 Đang sử dụng Google AI để tạo Podcast...'),
        backgroundColor: Colors.blue,
      ),
    );
    await _documentService.processPodcastGeneration(doc);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Kho Tài liệu & Podcast', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1565C0),
        elevation: 0,
        actions: [
          if (_selectedDoc != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _audioPlayer.stop();
                setState(() => _selectedDoc = null);
              },
            )
        ],
      ),
      body: _selectedDoc == null ? _buildListView() : _buildDetailAndPlayerView(),
    );
  }

  Widget _buildListView() {
    return StreamBuilder<List<OcrDocumentModel>>(
      stream: _documentService.getDocumentsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi kết nối: ${snapshot.error}'));
        }
        final docs = snapshot.data ?? [];
        if (docs.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final hasAudio = doc.audioUrl != null && doc.audioUrl!.isNotEmpty;

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: hasAudio ? Colors.orange[50] : Colors.blue[50],
                      borderRadius: BorderRadius.circular(12)
                  ),
                  child: Icon(
                      hasAudio ? Icons.headset : Icons.description_outlined,
                      color: hasAudio ? Colors.orange[800] : const Color(0xFF1565C0)
                  ),
                ),
                title: Text(doc.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Đã lưu: ${doc.createdAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(doc.createdAt!) : "---"}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => setState(() => _selectedDoc = doc),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailAndPlayerView() {
    return StreamBuilder<List<OcrDocumentModel>>(
      stream: _documentService.getDocumentsStream(),
      builder: (context, snapshot) {
        OcrDocumentModel currentDoc = _selectedDoc!;
        if (snapshot.hasData) {
          try {
            currentDoc = snapshot.data!.firstWhere((d) => d.documentId == _selectedDoc!.documentId);
            _selectedDoc = currentDoc; // Cập nhật để đồng bộ khi tắt app bar
          } catch (_) {}
        }

        return Stack(
          children: [
            _buildDetailContent(currentDoc),
            _buildAudioPlayer(currentDoc),
          ],
        );
      },
    );
  }

  Widget _buildDetailContent(OcrDocumentModel doc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 280),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(doc.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _contentSection('Nội dung tài liệu', doc.extractedText, Colors.blue[50]!),
          if (doc.translatedText != null && doc.translatedText!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _contentSection('Bản dịch tiếng Việt', doc.translatedText!, Colors.orange[50]!),
            ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayer(OcrDocumentModel doc) {
    final status = doc.audioStatus ?? 'none';
    final url = doc.audioUrl;
    final hasAudio = url != null && url.isNotEmpty;

    return Positioned(
      bottom: 16, left: 16, right: 16,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status == 'generating')
              const _GeneratingState()
            else if (status == 'ready' && hasAudio)
              _PlayerControls(
                isPlaying: _isPlaying,
                onPlayToggle: () => _isPlaying ? _audioPlayer.pause() : _playPodcast(url),
                audioPlayer: _audioPlayer,
                formatDuration: _formatDuration,
              )
            else
              _GenerateButton(
                onPressed: () => _generatePodcast(doc),
                isError: status == 'error',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Kho tài liệu trống', style: TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _contentSection(String title, String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(fontSize: 15, height: 1.5)),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _GeneratingState extends StatelessWidget {
  const _GeneratingState();
  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        SizedBox(width: 16),
        Text('Google AI đang chuyển đổi văn bản...', style: TextStyle(fontStyle: FontStyle.italic)),
      ],
    );
  }
}

class _PlayerControls extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlayToggle;
  final AudioPlayer audioPlayer;
  final String Function(Duration) formatDuration;

  const _PlayerControls({required this.isPlaying, required this.onPlayToggle, required this.audioPlayer, required this.formatDuration});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(icon: const Icon(Icons.replay_10), onPressed: () => audioPlayer.seek(audioPlayer.position - const Duration(seconds: 10))),
            const SizedBox(width: 20),
            CircleAvatar(
              radius: 30, backgroundColor: const Color(0xFF1565C0),
              child: IconButton(icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white), iconSize: 32, onPressed: onPlayToggle),
            ),
            const SizedBox(width: 20),
            IconButton(icon: const Icon(Icons.forward_10), onPressed: () => audioPlayer.seek(audioPlayer.position + const Duration(seconds: 10))),
          ],
        ),
        const SizedBox(height: 10),
        StreamBuilder<Duration>(
          stream: audioPlayer.positionStream,
          builder: (context, snapshot) {
            final pos = snapshot.data ?? Duration.zero;
            final dur = audioPlayer.duration ?? Duration.zero;
            return Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(trackHeight: 4, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6)),
                  child: Slider(
                    value: pos.inMilliseconds.toDouble().clamp(0, dur.inMilliseconds.toDouble() > 0 ? dur.inMilliseconds.toDouble() : 1),
                    max: dur.inMilliseconds.toDouble() > 0 ? dur.inMilliseconds.toDouble() : 1,
                    onChanged: (v) => audioPlayer.seek(Duration(milliseconds: v.toInt())),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(formatDuration(pos), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(formatDuration(dur), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                )
              ],
            );
          },
        )
      ],
    );
  }
}

class _GenerateButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isError;
  const _GenerateButton({required this.onPressed, this.isError = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(isError ? Icons.refresh : Icons.auto_awesome),
        label: Text(isError ? 'THỬ TẠO LẠI PODCAST' : 'TẠO PODCAST AI'),
        style: ElevatedButton.styleFrom(
          backgroundColor: isError ? Colors.red[700] : Colors.orange[800],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}