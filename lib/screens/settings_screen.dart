// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:kouchuhyo_app/screens/changelog_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('アプリ変更履歴'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ChangelogScreen()),
              );
            },
          ),
          const Divider(),
          // 今後項目が増えたらここに追加
        ],
      ),
    );
  }
}