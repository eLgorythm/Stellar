import 'package:flutter/material.dart';
import 'package:stellar/screens/home.dart';
import 'package:stellar/screens/wish_counter.dart';
import 'package:stellar/screens/vision.dart';
import 'package:stellar/screens/import_data.dart';
import 'package:stellar/screens/about.dart';
import 'package:stellar/screens/tutorial.dart';

class MainDrawer extends StatelessWidget {
  final String storageDir;
  const MainDrawer({super.key, required this.storageDir});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Container(
            // Menambahkan padding top sistem agar gambar benar-benar penuh melewati status bar
            height: 220 + MediaQuery.of(context).padding.top,
            width: double.infinity,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              image: const DecorationImage(
                image: AssetImage('assets/images/drawer_bg.webp'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.adb_rounded),
            title: const Text('Home'),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage(storageDir: storageDir)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome_rounded),
            title: const Text('Wish Counter'),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => WishCounterPage(storageDir: storageDir)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.upload_file_rounded),
            title: const Text('Import/Export'),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ImportDataPage(storageDir: storageDir)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.remove_red_eye_rounded),
            title: const Text("What's your Vision?"),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => VisionPage(storageDir: storageDir)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.lightbulb_outline_rounded),
            title: const Text('Tutorial'),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => TutorialPage(storageDir: storageDir)),
            ),
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('About'),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AboutPage(storageDir: storageDir)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}