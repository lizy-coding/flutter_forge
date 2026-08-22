# file_picker_bridge Ownership Contract

## Package

`file_picker_bridge`

## Public Contract

`file_picker_bridge` owns the mock-friendly Dart API and MethodChannel client boundary for adapting host file picker implementations into a stable Flutter-facing file selection service.

It must not own native application UI, business-specific file parsing, G-code loading behavior, app routing, platform bootstrap policy, or any caller-specific file management workflow.

## Maintenance Owners

- Flutter Forge package maintainers
- Platform bridge maintainers
