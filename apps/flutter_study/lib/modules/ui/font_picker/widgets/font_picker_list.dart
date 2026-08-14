import 'package:flutter/material.dart';

import '../models/font_option.dart';

class FontPickerList extends StatelessWidget {
  const FontPickerList({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<FontOption> options;
  final FontOption? selected;
  final ValueChanged<FontOption> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final isSelected = selected?.id == option.id;
        return Card(
          key: Key('font-option-${option.id}'),
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          child: ListTile(
            onTap: () => onSelected(option),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    option.displayName,
                    style: option.textStyle(fontSize: 17),
                  ),
                ),
                Text(option.styleLabel, style: option.textStyle(fontSize: 12)),
                if (option.isCustom) ...[
                  const SizedBox(width: 6),
                  const Chip(
                    label: Text('本地'),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '字体样式预览 AaBb 0123',
                style: option.textStyle(fontSize: 16),
              ),
            ),
            trailing: isSelected ? const Icon(Icons.check_circle) : null,
          ),
        );
      },
    );
  }
}
