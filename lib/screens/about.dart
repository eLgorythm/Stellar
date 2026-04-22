import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stellar/widgets/main_drawer.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  final String storageDir;
  const AboutPage({super.key, required this.storageDir});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  Map<String, dynamic>? _aboutData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAboutData();
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

  Future<void> _loadAboutData() async {
    try {
      final lang = _getLangCode();
      String jsonString;
      try {
        jsonString = await rootBundle.loadString('assets/about/about_$lang.json');
      } catch (_) {
        jsonString = await rootBundle.loadString('assets/about/about_en.json');
      }
      
      setState(() {
        _aboutData = json.decode(jsonString);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading about data: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _aboutData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final data = _aboutData!;
    final desc = data['description'];
    final privacy = data['privacy_policy'];
    final tech = data['technical_details'];

    return Scaffold(
      appBar: AppBar(
        title: Text(data['app_name'], style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
      ),
      drawer: MainDrawer(storageDir: widget.storageDir),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header Section
            Center(
              child: Column(
                children: [
                  Text(
                    data['app_name'],
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'Audiowide'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['tagline'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Description Section
            _buildSectionCard(
              context,
              children: [
                _buildDescriptionText(desc['summary']),
                const Divider(height: 32, color: Colors.white10),
                _buildDescriptionText(desc['core_function']),
                const SizedBox(height: 16),
                _buildDescriptionText(desc['experience']),
                const SizedBox(height: 16),
                _buildDescriptionText(desc['philosophy'] ?? '', isItalic: true),
              ],
            ),
            const SizedBox(height: 24),

            // Privacy Section
            _buildSectionCard(
              context,
              title: "Privacy Policy",
              icon: Icons.security_rounded,
              children: [
                _buildInfoRow("Storage", privacy['storage'] ?? ''),
                _buildInfoRow("Data Collection", privacy['data_collection'] ?? ''),
                const SizedBox(height: 12),
                Text(
                  privacy['statement'],
                  style: const TextStyle(fontSize: 13, color: Colors.orangeAccent),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Technical Details Section
            _buildSectionCard(
              context,
              title: "Technical Details",
              icon: Icons.code_rounded,
              children: [
                _buildInfoRow("Version", tech['version'] ?? ''),
                _buildInfoRow("Developer", tech['credits']['developer'] ?? ''),
                _buildInfoRow("Frameworks", (tech['credits']['frameworks'] as List).join(", ")),
                _buildInfoRow("License", tech['license']['type'] ?? ''),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final String? url = tech['repository'];
                    try {
                      if (url != null && url.isNotEmpty) {
                        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      }
                    } catch (e) {
                      debugPrint("Could not launch repository URL: $e");
                    }
                  },
                  icon: const Icon(Icons.link_rounded, size: 18),
                  label: const Text("View Repository"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD1C4E9),
                    side: const BorderSide(color: Color(0xFFD1C4E9)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, {String? title, IconData? icon, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD1C4E9).withOpacity(0.3)), // Glowing outline
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD1C4E9).withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFFD1C4E9)),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD1C4E9))),
              ],
            ),
            const SizedBox(height: 20),
          ],
          ...children,
        ],
      ),
    );
  }

  Widget _buildDescriptionText(String text, {bool isItalic = false}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        height: 1.6,
        color: Colors.white.withOpacity(0.85),
        fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.54), fontSize: 14)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}