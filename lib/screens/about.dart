import 'package:flutter/material.dart';
import 'package:stellar/widgets/main_drawer.dart';

class AboutPage extends StatelessWidget {
  final String storageDir;
  const AboutPage({super.key, required this.storageDir});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("About Stellar")),
      drawer: MainDrawer(storageDir: storageDir),
      body: const Center(
        child: Text("Stellar v1.0.0\nADB Utility for Gacha Games", textAlign: TextAlign.center),
      ),
    );
  }
}