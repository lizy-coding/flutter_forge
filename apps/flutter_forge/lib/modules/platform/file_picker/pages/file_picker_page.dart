import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_forge_app/shared/learning/learning_scaffold.dart';

import '../state/file_picker_controller.dart';

class FilePickerPage extends StatelessWidget {
  const FilePickerPage({super.key, required this.controller});

  final FilePickerController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) => LearningScaffold(
        title: '文件选择器',
        interactiveDemo: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'gcode', label: Text('G-code')),
                ButtonSegment(value: 'text', label: Text('文本')),
              ],
              selected: {controller.filterMode},
              onSelectionChanged: (selection) {
                controller.setFilterMode(selection.first);
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              key: const Key('pick-file-button'),
              onPressed: controller.state == FilePickerState.loading
                  ? null
                  : controller.pickFile,
              icon: const Icon(Icons.file_open),
              label: const Text('选择文件'),
            ),
            const SizedBox(height: 16),
            Card(
              key: const Key('pick-result'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildResult(context),
              ),
            ),
          ],
        ),
        sections: const [
          LearningObjectives(
            objectives: [
              '理解 MethodChannel 原生桥接原理',
              '复用中台 FilePickerService 能力',
              '掌握扩展名过滤与取消分支处理',
            ],
          ),
          ConceptChips(
            concepts: [
              'FilePickerService',
              'MethodChannel',
              '扩展过滤',
              '取消分支',
              '平台差异',
            ],
          ),
          CodeSnippetCard(
            title: '中台能力调用',
            code:
                'FilePickerController({\n'
                '  FilePickerService filePicker =\n'
                '      const MethodChannelFilePicker(),\n'
                '});\n\n'
                'await filePicker.pickFile(\n'
                "  allowedExtensions: ['.gcode', '.nc', '.tap'],\n"
                "  title: '选择文件',\n"
                ');',
            explanation: '模块只依赖抽象接口，原生实现由 file_picker_bridge 包提供。',
          ),
          CommonPitfalls(
            pitfalls: [
              'Windows 平台暂未注册原生 handler，调用抛 MissingPluginException',
              '扩展过滤只是对话框提示，不校验文件内容',
              '沙箱下只能读用户所选文件（files.user-selected.read-only）',
            ],
          ),
          ExerciseCard(
            task: '为文本模式增加 .json 过滤',
            hint: '在 filterMode 映射追加扩展名数组',
          ),
        ],
      ),
    );
  }

  Widget _buildResult(BuildContext context) {
    switch (controller.state) {
      case FilePickerState.idle:
        return const Text('选择过滤类型，然后打开原生文件对话框。');
      case FilePickerState.loading:
        return const Center(child: CircularProgressIndicator());
      case FilePickerState.picked:
        final file = controller.pickedFile!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(file.name ?? _fileName(file.path)),
            const SizedBox(height: 8),
            SelectableText(file.path),
            const SizedBox(height: 8),
            Text('大小：${_fileSize(file.path)}'),
          ],
        );
      case FilePickerState.cancelled:
        return const Text('未选择文件，对话框已取消');
      case FilePickerState.platformUnsupported:
        return Row(
          children: [
            Icon(
              Icons.desktop_access_disabled,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(controller.errorMessage!)),
          ],
        );
      case FilePickerState.error:
        return Text(controller.errorMessage ?? '文件选择失败');
    }
  }

  String _fileName(String path) => File(path).uri.pathSegments.last;

  String _fileSize(String path) {
    try {
      return '${File(path).statSync().size} 字节';
    } on FileSystemException {
      return '无法读取';
    }
  }
}
