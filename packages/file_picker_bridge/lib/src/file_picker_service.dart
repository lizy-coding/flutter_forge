class PickedFile {
  const PickedFile({
    required this.path,
    this.name,
  });

  final String path;
  final String? name;
}

abstract class FilePickerService {
  Future<PickedFile?> pickFile({
    List<String> allowedExtensions = const [],
    String? title,
    String? message,
  });
}
