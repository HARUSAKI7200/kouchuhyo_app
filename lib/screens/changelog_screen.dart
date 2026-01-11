// lib/screens/changelog_screen.dart

import 'package:flutter/material.dart';

class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key});

  // 変更履歴データ
  final List<Map<String, String>> _changes = const [
    {
      'date': '2026/01/06', // 今日の日付を入れています
      'version': 'v1.0.0',
      'content': 
'''・2026/01/06までに実装、開発した内容。
・工注票作成機能の実装（基本情報、寸法、腰下、側・妻、天井、梱包材、追加部材の入力）
・入力画面のタブ切り替えUIの実装
・寸法および容積の自動計算機能
・乾燥剤必要量の自動計算機能
・床板強度計算機能（等分布荷重、中央集中荷重、2点集中荷重[均等/不均等]に対応）
・図面作成機能（ペン、直線、四角形、寸法線、テキスト、消しゴムツール）
・図面作成時のスナップ機能（腰下ベース画像に対して吸着）
・テンプレート保存・読み込み機能（履歴保存、製品ごとのフォルダ管理・別名保存）
・PDF印刷プレビュー・出力機能（A4縦2面付、作成図面の埋め込み対応）
・品名の自動縮小表示（PDF）および時間指定項目の追加
・Kotlinバージョンの更新対応'''
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('アプリ変更履歴'),
      ),
      body: SafeArea(
        child: ListView.builder(
          itemCount: _changes.length,
          itemBuilder: (context, index) {
            final item = _changes[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['date'] ?? '', 
                          style: TextStyle(color: Colors.grey[600], fontSize: 12)
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Text(
                            item['version'] ?? '', 
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[800], fontSize: 12)
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      item['content'] ?? '', 
                      style: const TextStyle(height: 1.6, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}