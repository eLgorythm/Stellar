import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stellar/widgets/main_drawer.dart';

class VisionPage extends StatefulWidget {
  final String storageDir;
  const VisionPage({super.key, required this.storageDir});

  @override
  State<VisionPage> createState() => _VisionPageState();
}

class _VisionPageState extends State<VisionPage> {
  int _currentQuestionIndex = 0;
  bool _isLoading = true;
  List<dynamic> _questions = [];
  Map<String, dynamic> _resultData = {};
  
  // Map untuk menyimpan skor setiap elemen (menggunakan lowercase sesuai JSON)
  final Map<String, int> _scores = {
    'anemo': 0,
    'geo': 0,
    'electro': 0,
    'dendro': 0,
    'hydro': 0,
    'pyro': 0,
    'cryo': 0,
  };

  final Map<String, Color> _elementColors = {
    'anemo': const Color(0xFFAEEA00),
    'geo': const Color(0xFFFFD54F),
    'electro': const Color(0xFFB388FF),
    'dendro': const Color(0xFF81C784),
    'hydro': const Color(0xFF4FC3F7),
    'pyro': const Color(0xFFFF8A65),
    'cryo': const Color(0xFF80DEEA),
  };

  @override
  void initState() {
    super.initState();
    _loadQuizData();
  }

  Future<void> _loadQuizData() async {
    try {
      final String qContent = await rootBundle.loadString('assets/vision/questions.json');
      final String rContent = await rootBundle.loadString('assets/vision/visions.json');
      
      setState(() {
        _questions = json.decode(qContent);
        _resultData = json.decode(rContent);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading quiz data: $e");
    }
  }

  void _onOptionSelected(Map<String, dynamic> optionScores) {
    setState(() {
      // Update skor berdasarkan bobot di JSON
      optionScores.forEach((element, value) {
        _scores[element] = (_scores[element] ?? 0) + (value as int);
      });

      if (_currentQuestionIndex < _questions.length - 1) {
        _currentQuestionIndex++;
      } else {
        _currentQuestionIndex = _questions.length;
      }
    });
  }

  String _getHighestElement() {
    var sortedEntries = _scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.first.key;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Loading...")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final bool isQuizFinished = _currentQuestionIndex >= _questions.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("What's your Vision?", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      drawer: MainDrawer(storageDir: widget.storageDir),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: isQuizFinished 
            ? _buildResult()
            : _buildQuiz(),
        ),
      ),
    );
  }

  Widget _buildQuiz() {
    final question = _questions[_currentQuestionIndex];
    return Column(
      key: ValueKey(_currentQuestionIndex),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "PERTANYAAN ${_currentQuestionIndex + 1}",
          style: const TextStyle(fontFamily: 'VT323', fontSize: 24, color: Color(0xFFD1C4E9)),
        ),
        const SizedBox(height: 24),
        Text(
          question['question'],
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 48),
        ...List.generate(question['options'].length, (index) {
          final opt = question['options'][index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // Mengirimkan map scores dari JSON
                onPressed: () => _onOptionSelected(opt['scores']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                  padding: const EdgeInsets.all(20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: const BorderSide(color: Colors.white10),
                ),
                child: Text(opt['text'], style: const TextStyle(fontSize: 15)),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildResult() {
    final String element = _getHighestElement();
    final data = _resultData[element]!;
    final Color elementColor = _elementColors[element] ?? Colors.white;

    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, size: 64, color: Color(0xFFD1C4E9)),
            const SizedBox(height: 24),
            Text(
              "Vision Kamu adalah ${data['title']}",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: elementColor),
            ),
            const SizedBox(height: 4),
            Text(
              "(${data['subtitle']})",
              style: const TextStyle(fontSize: 16, color: Colors.white54),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: elementColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    data['quote']!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, height: 1.4, fontStyle: FontStyle.italic, color: Colors.white70),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: Colors.white10),
                  ),
                  Text(
                    data['description']!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            TextButton.icon(
              onPressed: () => setState(() {
                _currentQuestionIndex = 0;
                _scores.updateAll((key, value) => 0);
              }),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("ULANGI TES"),
            ),
          ],
        ),
      ),
    );
  }
}
