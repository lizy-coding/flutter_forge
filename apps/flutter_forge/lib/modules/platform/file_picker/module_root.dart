import 'package:file_picker_bridge/file_picker_bridge.dart';
import 'package:flutter/material.dart';

import 'pages/file_picker_page.dart';
import 'state/file_picker_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.filePicker});

  final FilePickerService? filePicker;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final FilePickerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FilePickerController(filePicker: widget.filePicker);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FilePickerPage(controller: _controller);
  }
}
