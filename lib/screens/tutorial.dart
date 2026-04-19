import 'package:flutter/material.dart';
import 'package:stellar/widgets/main_drawer.dart';

class TutorialStep {
  final String title;
  final String description;
  final IconData icon;
  const TutorialStep({required this.title, required this.description, required this.icon});
}

class TutorialPage extends StatelessWidget {
  final String storageDir;
  const TutorialPage({super.key, required this.storageDir});

  static const List<TutorialStep> _steps = [
    TutorialStep(
      title: "Persiapan Sistem",
      description: "Aktifkan Opsi Developer di pengaturan Android Anda (Ketuk 'Build Number' 7x). Kemudian aktifkan 'Wireless Debugging' di Opsi Developer.",
      icon: Icons.settings_applications_rounded,
    ),
    TutorialStep(
      title: "Proses Pairing",
      description: "Buka menu Wireless Debugging > Pair device with pairing code. Masukkan 6-digit kode yang muncul ke dalam notifikasi Stellar yang muncul.",
      icon: Icons.vibration_rounded,
    ),
    TutorialStep(
      title: "Scanning Link Gacha",
      description: "Setelah status 'Paired', klik CONNECT, lalu tekan SCAN di jendela yang muncul. Buka riwayat gacha di dalam game (Genshin/HSR/ZZZ), lalu kembali ke Stellar.",
      icon: Icons.manage_search_rounded,
    ),
    TutorialStep(
      title: "Import Data",
      description: "Salin link hasil scan, buka menu Wish Counter, pilih game yang sesuai, tempel link tersebut dan tekan IMPORT DATA.",
      icon: Icons.auto_awesome_rounded,
    ),
    TutorialStep(
    title: "Import From Local File",
    description: "Kamu dapat upload file lokal untuk memasukkan data lama yang sudah tidak terdeteksi oleh API (lebih dari 6 bulan), lalu digabungkan dengan data baru.",
    icon: Icons.upload_file_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tutorial", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      drawer: MainDrawer(storageDir: storageDir),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeader(),
          const SizedBox(height: 8),
          ..._steps.asMap().entries.map((entry) {
            int idx = entry.key;
            TutorialStep step = entry.value;
            return _buildStep(
              context,
              (idx + 1).toString(),
              step.title,
              step.description,
              step.icon,
            );
          }),
          const SizedBox(height: 32),
          _buildNote(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
        const Text(
          "Cara Menggunakan Stellar",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const Text(
          "Ikuti langkah-langkah di bawah ini",
          style: TextStyle(color: Colors.white54),
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

  Widget _buildNote(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orangeAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.orangeAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Penting: Pastikan HP berada di jaringan Wi-Fi yang sama agar Wireless Debugging bekerja.",
              style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}