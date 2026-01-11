// lib/screens/template_list_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kouchuhyo_app/screens/template_files_screen.dart';

class TemplateListScreen extends StatefulWidget {
  const TemplateListScreen({super.key});

  @override
  State<TemplateListScreen> createState() => _TemplateListScreenState();
}

class _TemplateListScreenState extends State<TemplateListScreen> {
  bool _isLoading = true; // 👈 読み込み状態を管理
  List<Directory> _allFolders = []; // 👈 全てのフォルダを保持
  List<Directory> _filteredFolders = []; // 👈 検索で絞り込んだフォルダを保持
  final TextEditingController _searchController = TextEditingController(); // 👈 検索コントローラー

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterFolders); // 👈 検索テキストの変更を監視
    _loadProductFolders();
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterFolders);
    _searchController.dispose();
    super.dispose();
  }

  // 👈 フォルダを読み込んでStateを更新するメソッド
  Future<void> _loadProductFolders() async {
    setState(() {
      _isLoading = true;
    });
    final directory = await getApplicationDocumentsDirectory();
    final List<Directory> folders = [];
    
    if (await directory.exists()) {
      final entities = directory.listSync();
      for (var entity in entities) {
        if (entity is Directory && !entity.path.endsWith('/history')) { // historyフォルダを除外
          folders.add(entity);
        }
      }
      folders.sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
    }

    setState(() {
      _allFolders = folders;
      _filteredFolders = folders; // 最初は全て表示
      _isLoading = false;
    });
  }

  // 👈 フォルダを検索クエリでフィルタリングするメソッド
  void _filterFolders() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredFolders = _allFolders;
      } else {
        _filteredFolders = _allFolders.where((folder) {
          final folderName = _getFolderName(folder).toLowerCase();
          return folderName.contains(query);
        }).toList();
      }
    });
  }

  // フォルダを削除する処理
  Future<void> _deleteFolder(Directory folder) async {
    final folderName = _getFolderName(folder);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('フォルダの削除'),
        content: Text('「$folderName」フォルダを削除しますか？\nフォルダ内のすべてのテンプレートも削除されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await folder.delete(recursive: true);
        await _loadProductFolders(); // 👈 削除後にリストを再読み込み
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('「$folderName」フォルダを削除しました。'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('フォルダの削除に失敗しました: $e')),
          );
        }
      }
    }
  }

  String _getFolderName(Directory folder) {
    return folder.path.split(Platform.pathSeparator).last;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('製品を選択'),
      ),
      body: Column(
        children: [
          // 👈 検索バーUI
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: '製品フォルダを検索',
                hintText: '製品名を入力...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
          // 👈 リスト表示部分
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _allFolders.isEmpty
                    ? const Center(
                        child: Text(
                          '保存された製品フォルダがありません。\n入力画面からテンプレートを保存してください。',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : _filteredFolders.isEmpty
                        ? const Center(
                            child: Text(
                              '該当する製品フォルダが見つかりません。',
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredFolders.length,
                            itemBuilder: (context, index) {
                              final folder = _filteredFolders[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: ListTile(
                                  leading: const Icon(Icons.folder),
                                  title: Text(_getFolderName(folder)),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => TemplateFilesScreen(folderPath: folder.path),
                                      ),
                                    ).then((_) {
                                      _loadProductFolders();
                                    });
                                  },
                                  onLongPress: () {
                                    _deleteFolder(folder);
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}