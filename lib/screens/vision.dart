import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stellar/widgets/main_drawer.dart';
import 'package:stellar/l10n/app_localizations.dart';

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
    'anemo': const Color(0xFF72E2C2), // Teal/Mint khas Anemo
    'geo': const Color(0xFFFFB13F),   // Amber khas Geo
    'electro': const Color(0xFFD9B1FF), // Soft Purple khas Electro
    'dendro': const Color(0xFFA5C83B),  // Grass Green khas Dendro
    'hydro': const Color(0xFF02C0FF),   // Azure Blue khas Hydro
    'pyro': const Color(0xFFFF9C33),    // Fiery Orange khas Pyro
    'cryo': const Color(0xFFA0E9FB),    // Icy Light Blue khas Cryo
  };

  String _getLangCode() {
    final locale = Localizations.localeOf(context);
    final code = locale.languageCode;
    if (['id', 'zh', 'ja'].contains(code)) {
      if (code == 'zh') return 'cn';
      if (code == 'ja') return 'jp';
      return code;
    }
    return 'en'; // Default
  }

  @override
  void initState() {
    super.initState();
    _loadQuizData();
  }

  Future<void> _loadQuizData() async {
    try {
      final String lang = _getLangCode();
      // Memuat file berdasarkan bahasa sistem
      final String qContent = await rootBundle.loadString('assets/vision/questions_$lang.json');
      final String rContent = await rootBundle.loadString('assets/vision/visions_$lang.json');
      
      setState(() {
        _questions = json.decode(qContent);
        _questions.shuffle(); // Mengacak pertanyaan saat pertama kali dimuat
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
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.loading)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final bool isQuizFinished = _currentQuestionIndex >= _questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.visionTest, style: const TextStyle(fontWeight: FontWeight.bold)),
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
    final l10n = AppLocalizations.of(context)!;
    return Column(
      key: ValueKey(_currentQuestionIndex),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "${l10n.question} ${_currentQuestionIndex + 1} / ${_questions.length}",
          style: const TextStyle(fontFamily: 'VT323', fontSize: 24, color: Color(0xFFD1C4E9)),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            backgroundColor: Colors.white10,
            color: const Color(0xFFD1C4E9),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 36),
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
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/$element.webp',
              height: 120,
              width: 120,
              // Fallback jika file gambar tidak ditemukan
              errorBuilder: (context, error, stackTrace) => 
                  Icon(Icons.auto_awesome, size: 80, color: elementColor),
            ),
            const SizedBox(height: 24),
            Text(
              "${l10n.resultVision} ${data['title']}",
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
                _questions.shuffle(); // Mengacak kembali saat mengulangi tes
              }),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.retryTest),
            ),
          ],
        ),
      ),
    );
  }
}
