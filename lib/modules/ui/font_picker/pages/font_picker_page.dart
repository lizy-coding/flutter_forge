import 'dart:io';

import 'package:file_picker_bridge/file_picker_bridge.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_study_learning/flutter_study_learning.dart';
import 'package:go_router/go_router.dart';

import '../data/font_catalog.dart';
import '../models/font_option.dart';
import '../state/font_loader_service.dart';
import '../widgets/font_picker_list.dart';
import '../widgets/font_preview_panel.dart';

typedef FontBytesReader = Future<Uint8List> Function(String path);

class FontPickerPage extends StatefulWidget {
  const FontPickerPage({
    super.key,
    this.filePicker = const MethodChannelFilePicker(),
    this.loader = const FontLoaderFontService(),
    this.fileReader = _readFontFile,
  });

  final FilePickerService filePicker;
  final FontLoaderService loader;
  final FontBytesReader fileReader;

  static Future<Uint8List> _readFontFile(String path) =>
      File(path).readAsBytes();

  @override
  State<FontPickerPage> createState() => _FontPickerPageState();
}

class _FontPickerPageState extends State<FontPickerPage> {
  late final List<FontOption> _options;
  FontOption? _selected;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _options = [...FontCatalog.fontsFor(defaultTargetPlatform)];
    _selected = _options.firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    return LearningScaffold(
      title: '字体选择器',
      interactiveDemo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FontPreviewPanel(option: _selected),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                key: const Key('load-local-font'),
                onPressed: _isLoading ? null : _pickLocalFont,
                icon: _isLoading
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.font_download_outlined),
                label: const Text('加载本地字体'),
              ),
              const Text('支持 ttf / otf / ttc'),
              TextButton.icon(
                key: const Key('open-weight-compare'),
                onPressed: () => context.push('/font-picker/weight-compare'),
                icon: const Icon(Icons.compare),
                label: const Text('字重与字距对比'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 460,
            child: FontPickerList(
              options: _options,
              selected: _selected,
              onSelected: (option) => setState(() => _selected = option),
            ),
          ),
        ],
      ),
      sections: const [
        LearningObjectives(
          objectives: [
            '对比不同字体族的外观差异',
            '理解 TextStyle 的 fontFamily、字重、斜体与字距',
            '通过中台文件选择能力加载本地字体（FontLoader）',
          ],
        ),
        ConceptChips(
          concepts: [
            'fontFamily',
            'TextStyle',
            '字重',
            '字距',
            'fallback',
            'FontLoader',
            '中台复用',
          ],
        ),
        CodeSnippetCard(
          title: '加载本地字体',
          code:
              "final picked = await filePicker.pickFile(\n"
              "  allowedExtensions: ['ttf', 'otf', 'ttc'],\n"
              ");\n"
              "final loader = FontLoader('customFamily');\n"
              'loader.addFont(Future.value(fontBytes));\n'
              'await loader.load();',
          explanation: '字体选择器复用 file_picker_bridge 中台能力，读取用户所选字体字节后动态注册字体族。',
        ),
        CommonPitfalls(
          pitfalls: [
            '不同平台字体集不同，缺失字体会静默回退',
            'fontFamily 只认系统已安装字体，无法枚举全部系统字体',
            '测试环境无法验证真实字形，需桌面截图验收',
            '加载失败或选择非字体文件时需要明确的错误提示',
          ],
        ),
        ExerciseCard(
          task: '为列表新增一种你系统里的字体',
          hint: '在 FontCatalog 对应平台列表追加 FontOption，family 使用系统真实字体名',
        ),
      ],
    );
  }

  Future<void> _pickLocalFont() async {
    final picked = await widget.filePicker.pickFile(
      allowedExtensions: const ['ttf', 'otf', 'ttc'],
      title: '选择字体文件',
    );
    if (picked == null || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final bytes = await widget.fileReader(picked.path);
      final familyName = 'custom_font_${DateTime.now().microsecondsSinceEpoch}';
      await widget.loader.loadFont(familyName: familyName, bytes: bytes);
      final option = FontOption(
        id: familyName,
        displayName: picked.name ?? _basename(picked.path),
        family: familyName,
        styleLabel: '本地字体',
        isCustom: true,
      );
      if (!mounted) return;
      setState(() {
        _options.insert(0, option);
        _selected = option;
      });
    } on FileSystemException {
      _showError('读取字体文件失败');
    } catch (_) {
      _showError('不是有效的字体文件');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _basename(String path) => File(path).uri.pathSegments.last;
}
