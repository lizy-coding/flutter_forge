import 'package:flutter/services.dart';

abstract class FontLoaderService {
  Future<void> loadFont({required String familyName, required Uint8List bytes});
}

class FontLoaderFontService implements FontLoaderService {
  const FontLoaderFontService();

  @override
  Future<void> loadFont({
    required String familyName,
    required Uint8List bytes,
  }) async {
    final loader = FontLoader(familyName)
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }
}
