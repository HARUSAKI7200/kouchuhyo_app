// lib/screens/template_files_screen.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:kouchuhyo_app/screens/order_form_screen.dart';
import 'package:intl/intl.dart';
// ▼▼▼ 追加: モデルクラスのインポート ▼▼▼
import 'package:kouchuhyo_app/models/kochuhyo_data.dart';

class TemplateInfo {
  final File file;
  final KochuhyoData data;
  TemplateInfo({required this.file, required this.data});
}

class TemplateFilesScreen extends StatefulWidget {
  final String folderPath;

  const TemplateFilesScreen({super.key, required this.folderPath});

  @override
  State<TemplateFilesScreen> createState() => _TemplateFilesScreenState();
}

class _TemplateFilesScreenState extends State<TemplateFilesScreen> {
  bool _isLoading = true;
  List<TemplateInfo> _allTemplates = [];
  List<TemplateInfo> _filteredTemplates = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterTemplates);
    _loadTemplateFiles();
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterTemplates);
    _searchController.dispose();
    super.dispose();
  }

  String get _folderName {
    return widget.folderPath.split(Platform.pathSeparator).last;
  }

  Future<void> _loadTemplateFiles() async {
    setState(() => _isLoading = true);
    final directory = Directory(widget.folderPath);
    final List<TemplateInfo> templates = [];
    
    if (await directory.exists()) {
      final entities = directory.listSync();
      for (var entity in entities) {
        if (entity is File && entity.path.endsWith('.json')) {
          try {
            final jsonString = await entity.readAsString();
            final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
            final kochuhyoData = KochuhyoData.fromJson(jsonData);
            templates.add(TemplateInfo(file: entity, data: kochuhyoData));
          } catch (e) {
            debugPrint("Failed to load template ${entity.path}: $e");
          }
        }
      }
      templates.sort((a, b) => b.file.lastModifiedSync().compareTo(a.file.lastModifiedSync()));
    }
    
    setState(() {
      _allTemplates = templates;
      _filteredTemplates = templates;
      _isLoading = false;
    });
  }

  void _filterTemplates() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredTemplates = _allTemplates;
      } else {
        _filteredTemplates = _allTemplates.where((templateInfo) {
          final fileName = _getFileName(templateInfo.file).toLowerCase();
          final data = templateInfo.data;
          return fileName.contains(query) ||
                 data.kobango.toLowerCase().contains(query) ||
                 data.hinmei.toLowerCase().contains(query) ||
                 data.shihomeisaki.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadTemplateAndNavigate(File file) async {
    try {
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final kochuhyoData = KochuhyoData.fromJson(jsonData);

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OrderFormScreen(
            templateData: kochuhyoData,
            templatePath: file.path,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('テンプレートの読み込みに失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _deleteTemplate(File file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除の確認'),
        content: Text('「${_getFileName(file)}」を本当に削除しますか？'),
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
        await file.delete();
        await _loadTemplateFiles();
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('テンプレートを削除しました。'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('削除に失敗しました: $e')),
          );
        }
      }
    }
  }

  String _getFileName(File file) {
    return file.path.split(Platform.pathSeparator).last.replaceAll('.json', '');
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('yyyy/MM/dd HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$_folderName のテンプレート'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'テンプレートを検索',
                hintText: 'ファイル名, 工番, 品名, 仕向先で検索...',
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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _allTemplates.isEmpty
                    ? const Center(child: Text('この製品のテンプレートはありません。'))
                    : _filteredTemplates.isEmpty
                        ? const Center(child: Text('該当するテンプレートが見つかりません。'))
                        : ListView.builder(
                            itemCount: _filteredTemplates.length,
                            itemBuilder: (context, index) {
                              final templateInfo = _filteredTemplates[index];
                              final file = templateInfo.file;
                              final data = templateInfo.data;
                              final productSize = (data.productLength.isNotEmpty || data.productWidth.isNotEmpty || data.productHeight.isNotEmpty)
                                  ? '${data.productLength}×${data.productWidth}×${data.productHeight}'
                                  : '未入力';

                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: ListTile(
                                  leading: const Icon(Icons.description_outlined),
                                  title: Text(_getFileName(file), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('工番: ${data.kobango.isNotEmpty ? data.kobango : "未入力"}'),
                                        // ▼▼▼【削除】「品名」の表示を削除 ▼▼▼
                                        Text('製品サイズ: $productSize'),
                                        Text('仕向先: ${data.shihomeisaki.isNotEmpty ? data.shihomeisaki : "未入力"}'),
                                        const SizedBox(height: 2),
                                        Text('更新日時: ${_formatDateTime(file.lastModifiedSync())}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  onTap: () => _loadTemplateAndNavigate(file),
                                  onLongPress: () => _deleteTemplate(file),
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