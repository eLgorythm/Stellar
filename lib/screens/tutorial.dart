import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stellar/widgets/main_drawer.dart';

class TutorialPage extends StatefulWidget {
  final String storageDir;
  const TutorialPage({super.key, required this.storageDir});

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  Map<String, dynamic>? _tutorialData;
  bool _isLoading = true;

  // Ikon tetap didefinisikan di Dart karena IconData tidak serializable di JSON
  final List<IconData> _stepIcons = [
    Icons.settings_applications_rounded,
    Icons.vibration_rounded,
    Icons.manage_search_rounded,
    Icons.auto_awesome_rounded,
    Icons.upload_file_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _loadTutorialData();
  }

  String _getLangCode() {
    final code = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    if (['id', 'zh', 'ja'].contains(code)) {
      if (code == 'zh') return 'cn';
      if (code == 'ja') return 'jp';
      return code;
    }
    return 'en';
  }

  Future<void> _loadTutorialData() async {
    try {
      final lang = _getLangCode();
      String jsonString;
      try {
        jsonString = await rootBundle.loadString('assets/tutorial/tutorial_$lang.json');
      } catch (_) {
        jsonString = await rootBundle.loadString('assets/tutorial/tutorial_en.json');
      }
      
      setState(() {
        _tutorialData = json.decode(jsonString);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading tutorial data: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _tutorialData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final data = _tutorialData!;
    final List<dynamic> stepsData = data['steps'];

    return Scaffold(
      appBar: AppBar(
        title: Text(data['app_bar'], style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      drawer: MainDrawer(storageDir: widget.storageDir),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeader(data['header_title'], data['header_subtitle']),
          const SizedBox(height: 8),
          ...stepsData.asMap().entries.map((entry) {
            int idx = entry.key;
            final step = entry.value;
            // Gunakan ikon berdasarkan urutan index
            return _buildStep(
              context,
              (idx + 1).toString(),
              step['title'],
              step['desc'] ?? step['description'] ?? '',
              _stepIcons[idx % _stepIcons.length],
            );
          }),
          const SizedBox(height: 32),
          _buildNote(context, data['note']),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, String subtitle) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFD1C4E9).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.auto_fix_high_rounded, size: 64, color: Color(0xFFD1C4E9)),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.white54),
        ),
      ],
    );
  }

  Widget _buildStep(BuildContext context, String num, String title, String desc, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Theme.of(context).colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF9575CD),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(num, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 18, color: const Color(0xFFD1C4E9)),
                      const SizedBox(width: 8),
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    desc,
                    style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNote(BuildContext context, String note) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.orangeAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              note,
              style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}