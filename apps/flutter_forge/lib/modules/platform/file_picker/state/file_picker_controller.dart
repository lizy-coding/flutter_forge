import 'package:file_picker_bridge/file_picker_bridge.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum FilePickerState {
  idle,
  loading,
  picked,
  cancelled,
  platformUnsupported,
  error,
}

class FilePickerController extends ChangeNotifier {
  FilePickerController({FilePickerService? filePicker})
    : _filePicker = filePicker ?? createFilePickerService();

  static const Map<String, List<String>> _extensionsByMode = {
    'gcode': ['.gcode', '.nc', '.tap'],
    'text': ['.txt', '.md', '.log'],
  };

  final FilePickerService _filePicker;

  FilePickerState _state = FilePickerState.idle;
  PickedFile? _pickedFile;
  String? _errorMessage;
  String _filterMode = 'gcode';
  bool _disposed = false;

  FilePickerState get state => _state;
  PickedFile? get pickedFile => _pickedFile;
  String? get errorMessage => _errorMessage;
  String get filterMode => _filterMode;
  List<String> get allowedExtensions => _extensionsByMode[_filterMode]!;

  void setFilterMode(String mode) {
    if (_disposed) return;
    if (!_extensionsByMode.containsKey(mode) || mode == _filterMode) return;
    _filterMode = mode;
    notifyListeners();
  }

  Future<void> pickFile() async {
    if (_disposed || _state == FilePickerState.loading) return;
    _state = FilePickerState.loading;
    _pickedFile = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final file = await _filePicker.pickFile(
        allowedExtensions: allowedExtensions,
        title: '选择文件',
      );
      if (_disposed) return;
      if (file == null) {
        _state = FilePickerState.cancelled;
      } else {
        _pickedFile = file;
        _state = FilePickerState.picked;
      }
    } on MissingPluginException {
      if (_disposed) return;
      _state = FilePickerState.platformUnsupported;
      _errorMessage = '当前平台暂未实现原生文件选择桥接';
    } catch (error) {
      if (_disposed) return;
      _state = FilePickerState.error;
      _errorMessage = '文件选择失败：$error';
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
