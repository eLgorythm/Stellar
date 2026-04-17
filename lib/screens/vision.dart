import 'package:flutter/material.dart';
import 'package:stellar/widgets/main_drawer.dart';

class VisionPage extends StatelessWidget {
  final String storageDir;
  const VisionPage({super.key, required this.storageDir});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("What's your Vision?")),
      drawer: MainDrawer(storageDir: storageDir),
      body: const Center(
        child: Text("Vision Personality Test\nComing Soon", textAlign: TextAlign.center),
      ),
    );
  }
}