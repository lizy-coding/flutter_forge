# file_picker_bridge

Platform file picker bridge API for adapting macOS and Windows file manager integrations.

Host applications register platform implementations through the `file_picker_bridge/file_picker` MethodChannel. This package owns the Dart API and mock-friendly channel client used to bridge Flutter code with native macOS and Windows file selection behavior.

## Roadmap

- Add and maintain macOS and Windows host file picking support while keeping the Dart API stable.
- Normalize returned file metadata across macOS and Windows.
- Keep MethodChannel tests mock-friendly so platform behavior can be verified without native UI.
