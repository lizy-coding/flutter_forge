import 'package:file_selector/file_selector.dart';

import 'file_picker_service.dart';

XTypeGroup? fileSelectorTypeGroupForExtensions(
  List<String> allowedExtensions,
) {
  if (allowedExtensions.isEmpty) return null;
  return XTypeGroup(extensions: allowedExtensions);
}

class FileSelectorFilePicker implements FilePickerService {
  const FileSelectorFilePicker();

  @override
  Future<PickedFile?> pickFile({
    List<String> allowedExtensions = const [],
    String? title,
    String? message,
  }) async {
    final file = await openFile(
      acceptedTypeGroups: [
        if (fileSelectorTypeGroupForExtensions(allowedExtensions)
            case final typeGroup?)
          typeGroup,
      ],
      confirmButtonText: title,
    );
    if (file == null) return null;

    return PickedFile(path: file.path, name: file.name);
  }
}
