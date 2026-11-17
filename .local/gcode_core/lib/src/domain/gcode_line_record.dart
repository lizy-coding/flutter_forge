class GcodeLineRecord {
  const GcodeLineRecord({
    required this.lineNumber,
    required this.rawLine,
    required this.byteOffset,
  });

  final int lineNumber;
  final String rawLine;
  final int byteOffset;
}
