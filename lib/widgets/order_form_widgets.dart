// lib/widgets/order_form_widgets.dart

import 'package:flutter/material.dart';
import 'dart:typed_data';

/// ラベル付きテキスト入力フィールド
class LabeledTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool readOnly;
  final bool enabled;
  final String? hintText;
  final String? unit;
  final bool showLabel;
  final FocusNode? focusNode;
  final VoidCallback? onSubmitted;

  const LabeledTextField({
    super.key,
    this.label = '',
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.enabled = true,
    this.hintText,
    this.unit,
    this.showLabel = true,
    this.focusNode,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showLabel) SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 14))),
          if (showLabel) const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              readOnly: readOnly,
              enabled: enabled,
              focusNode: focusNode,
              onSubmitted: onSubmitted != null ? (_) => onSubmitted!() : null,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: hintText,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                isDense: true,
                filled: true,
                fillColor: readOnly ? Colors.grey[200] : Colors.transparent,
              ),
            ),
          ),
          if (unit != null) ...[
            const SizedBox(width: 8),
            Text(unit, style: TextStyle(color: Colors.grey[700])),
          ]
        ],
      ),
    );
  }
}

/// ラベル付き日付入力フィールド
class LabeledDateInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback onTap;

  const LabeledDateInput({
    super.key,
    required this.label,
    required this.controller,
    this.focusNode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label)),
          const SizedBox(width: 8),
          Expanded(child: GestureDetector(
            onTap: onTap,
            child: AbsorbPointer(
              child: TextField(
                controller: controller,
                readOnly: true,
                focusNode: focusNode,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'yyyy/MM/dd',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  isDense: true,
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
}

/// ラベル付きドロップダウン
class LabeledDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String hint;
  final FocusNode? focusNode;

  const LabeledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.hint,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 80, child: Text(label)),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<T>(
              focusNode: focusNode,
              value: value,
              isDense: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                isDense: true,
              ),
              hint: Text(hint),
              items: items,
              onChanged: onChanged,
            )
          ),
        ],
      ),
    );
  }
}

/// 寸法選択用ドロップダウン
class DimensionDropdown extends StatelessWidget {
  final String? selectedValue;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final String hintText;

  const DimensionDropdown({
    super.key,
    required this.selectedValue,
    required this.options,
    required this.onChanged,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.only(top: 4.0),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        hint: Text(hintText, style: const TextStyle(fontSize: 14)),
        isExpanded: true,
        items: options.map((size) {
          return DropdownMenuItem<String>(
            value: size,
            child: Text(size, style: const TextStyle(fontSize: 14)),
          );
        }).toList(),
        onChanged: onChanged,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
      ),
    );
  }
}

/// ラジオボタングループ
class RadioGroup extends StatelessWidget {
  final String? title;
  final String? groupValue;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final FocusNode? focusNode;

  const RadioGroup({
    super.key,
    this.title,
    required this.groupValue,
    required this.options,
    required this.onChanged,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    Widget radioList = Row(
      children: options.map((option) => Expanded(
        child: Row(
          children: [
            Radio<String>(
              value: option,
              groupValue: groupValue,
              onChanged: onChanged,
              visualDensity: VisualDensity.compact,
              focusNode: focusNode,
            ),
            Flexible(child: Text(option, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis)),
          ],
        ),
      )).toList(),
    );
    if (title == null) return radioList;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title!, style: const TextStyle(fontWeight: FontWeight.bold)),
        radioList,
      ],
    );
  }
}

/// 垂直配置の入力グループ（タイトル付き）
class VerticalInputGroup extends StatelessWidget {
  final String title;
  final Widget child;

  const VerticalInputGroup(this.title, this.child, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

/// 図面プレビューウィジェット
class DrawingPreview extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final Uint8List? imageBytes;
  final String placeholder;

  const DrawingPreview({
    super.key,
    required this.title,
    required this.onTap,
    required this.imageBytes,
    required this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    const double previewHeight = 250.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            height: previewHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8.0),
              color: Colors.grey.shade100,
            ),
            child: imageBytes == null
                ? Center(child: Text(placeholder, style: TextStyle(color: Colors.grey.shade700)))
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.memory(
                      imageBytes,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(child: Text('画像表示エラー')),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}