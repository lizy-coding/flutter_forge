import 'dart:convert';
import 'dart:io';

import '../../domain/gcode_line_record.dart';
import 'gcode_line_reader.dart';

class FileGcodeLineReader implements GcodeLineReader {
  const FileGcodeLineReader(this.path);

  final String path;

  static String normalizePath(String value) {
    var normalized = value.trim();
    if (normalized.length >= 2) {
      final first = normalized[0];
      final last = normalized[normalized.length - 1];
      if ((first == '"' && last == '"') || (first == "'" && last == "'")) {
        normalized = normalized.substring(1, normalized.length - 1).trim();
      }
    }

    if (normalized.startsWith('file://')) {
      normalized =
          Uri.parse(normalized).toFilePath(windows: Platform.isWindows);
    }

    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        '';
    if (home.isNotEmpty && normalized == '~') {
      normalized = home;
    } else if (home.isNotEmpty && normalized.startsWith('~/')) {
      normalized = '$home/${normalized.substring(2)}';
    }

    normalized = normalized.replaceAllMapped(
      RegExp(r'\\([ ()\[\]&;])'),
      (match) => match.group(1)!,
    );

    return normalized;
  }

  @override
  Stream<GcodeLineRecord> readLines() async* {
    final normalizedPath = normalizePath(path);
    final type = await FileSystemEntity.type(normalizedPath);
    if (type == FileSystemEntityType.notFound) {
      throw FileSystemException('文件不存在', normalizedPath);
    }
    if (type == FileSystemEntityType.directory) {
      throw FileSystemException('路径是目录，不是 G-code 文件', normalizedPath);
    }

    final file = File(normalizedPath);
    var lineNumber = 0;
    var byteOffset = 0;

    await for (final line in file
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      lineNumber++;
      yield GcodeLineRecord(
        lineNumber: lineNumber,
        rawLine: line,
        byteOffset: byteOffset,
      );
      byteOffset += utf8.encode(line).length + 1;
    }
  }
}
