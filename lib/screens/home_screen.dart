// lib/screens/home_screen.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kouchuhyo_app/screens/order_form_screen.dart';
import 'package:kouchuhyo_app/screens/template_list_screen.dart';
// ▼▼▼ 設定画面のインポート ▼▼▼
import 'package:kouchuhyo_app/screens/settings_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kouchuhyo_app/models/kochuhyo_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<KochuhyoData> _historyList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final directory = await getApplicationDocumentsDirectory();
      final historyDir = Directory('${directory.path}/history');

      if (!await historyDir.exists()) {
        await historyDir.create(recursive: true);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final files = historyDir.listSync()
        ..sort((a, b) => b.path.compareTo(a.path));

      final List<KochuhyoData> loadedHistory = [];
      for (var fileEntity in files) {
        if (fileEntity is File && fileEntity.path.endsWith('.json')) {
          final jsonString = await fileEntity.readAsString();
          final data = KochuhyoData.fromJson(jsonDecode(jsonString));
          loadedHistory.add(data);
        }
      }

      setState(() {
        _historyList = loadedHistory;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('履歴の読み込みに失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _resetHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('履歴の削除'),
        content: const Text('本当にすべての作成履歴を削除しますか？\nこの操作は元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除する', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final historyDir = Directory('${directory.path}/history');
        if (await historyDir.exists()) {
          await historyDir.delete(recursive: true);
        }
        setState(() {
          _historyList.clear();
        });
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('作成履歴をリセットしました。'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('履歴のリセットに失敗しました: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }


  void _navigateToNewFormWithHistory(KochuhyoData data) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OrderFormScreen(templateData: data),
      ),
    );
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
            tooltip: '履歴を再読み込み',
          ),
          // ▼▼▼ 追加: 設定ボタン ▼▼▼
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            tooltip: '設定',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('新規工注票を作成'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const OrderFormScreen()),
                );
                _loadHistory();
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.folder_open_outlined),
              label: const Text('テンプレートから作成'),
               style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
                backgroundColor: Colors.teal,
              ),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const TemplateListScreen()),
                );
                _loadHistory();
              },
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '最近作成した工注票',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                TextButton.icon(
                  icon: const Icon(Icons.delete_sweep, size: 20),
                  label: const Text('履歴をリセット'),
                  onPressed: _resetHistory,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    textStyle: const TextStyle(fontSize: 12)
                  ),
                ),
              ],
            ),
            const Divider(),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _historyList.isEmpty
                      ? Center(
                          child: Text(
                            '作成履歴はありません。\n新規作成すると、ここに履歴が表示されます。',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _historyList.length,
                          itemBuilder: (context, index) {
                            final historyData = _historyList[index];
                            final productSize = (historyData.productLength.isNotEmpty || historyData.productWidth.isNotEmpty || historyData.productHeight.isNotEmpty)
                                ? '製品サイズ: ${historyData.productLength}×${historyData.productWidth}×${historyData.productHeight}'
                                : '製品サイズ: 未入力';

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '工番: ${historyData.kobango.isNotEmpty ? historyData.kobango : '未入力'}',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          Text('品名: ${historyData.hinmei.isNotEmpty ? historyData.hinmei : "未入力"}'),
                                          Text(productSize),
                                          Text('仕向先: ${historyData.shihomeisaki.isNotEmpty ? historyData.shihomeisaki : "未入力"}'),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => _navigateToNewFormWithHistory(historyData),
                                      child: const Text('この内容で作成'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}