import 'package:flutter/services.dart';

import 'file_picker_service.dart';

class MethodChannelFilePicker implements FilePickerService {
  const MethodChannelFilePicker({
    MethodChannel channel = _defaultChannel,
  }) : _channel = channel;

  static const MethodChannel _defaultChannel = MethodChannel(
    'flutter_study/file_picker',
  );

  final MethodChannel _channel;

  @override
  Future<PickedFile?> pickFile({
    List<String> allowedExtensions = const [],
    String? title,
    String? message,
  }) async {
    final result = await _channel.invokeMapMethod<String, Object?>(
      'pickFile',
      <String, Object?>{
        'allowedExtensions': allowedExtensions,
        'title': title,
        'message': message,
      },
    );

    final path = result?['path'] as String?;
    if (path == null || path.isEmpty) {
      return null;
    }

    return PickedFile(
      path: path,
      name: result?['name'] as String?,
    );
  }
}
