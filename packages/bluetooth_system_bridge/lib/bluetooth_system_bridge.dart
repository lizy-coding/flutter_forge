import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher/url_launcher.dart';

enum BluetoothSystemStatus {
  available,
  unsupported,
  unavailable,
  permissionDenied,
  invalidData,
}

class BluetoothSystemOutcome<T> {
  const BluetoothSystemOutcome.available(T this.value)
    : status = BluetoothSystemStatus.available,
      reason = null;
  const BluetoothSystemOutcome._(this.status, this.reason) : value = null;
  factory BluetoothSystemOutcome.state(
    BluetoothSystemStatus status,
    String reason,
  ) {
    if (status == BluetoothSystemStatus.available) {
      throw ArgumentError.value(status);
    }
    return BluetoothSystemOutcome._(
      status,
      reason.trim().isEmpty ? 'unspecified_reason' : reason,
    );
  }
  final BluetoothSystemStatus status;
  final String? reason;
  final T? value;
  bool get isAvailable => status == BluetoothSystemStatus.available;
}

class BluetoothSystemCapabilities {
  const BluetoothSystemCapabilities({
    this.settings = false,
    this.audioDevices = false,
  });
  final bool settings;
  final bool audioDevices;
}

class SystemAudioDevice {
  const SystemAudioDevice({
    required this.id,
    required this.name,
    required this.profiles,
    this.error,
  });
  final String id;
  final String? name;
  final List<String> profiles;
  final String? error;
}

abstract class BluetoothSystemPlatform extends PlatformInterface {
  BluetoothSystemPlatform() : super(token: _token);
  static final _token = Object();
  static BluetoothSystemPlatform _instance = MethodChannelBluetoothSystem();
  static BluetoothSystemPlatform get instance => _instance;
  static set instance(BluetoothSystemPlatform value) {
    PlatformInterface.verifyToken(value, _token);
    _instance = value;
  }

  Future<BluetoothSystemCapabilities> queryCapabilities() async =>
      const BluetoothSystemCapabilities();
  Future<BluetoothSystemOutcome<bool>> openSettings();
  Future<BluetoothSystemOutcome<List<SystemAudioDevice>>>
  connectedAudioDevices();
}

class MethodChannelBluetoothSystem extends BluetoothSystemPlatform {
  static const channel = MethodChannel('flutter_forge/bluetooth_system');
  bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  @override
  Future<BluetoothSystemCapabilities> queryCapabilities() async {
    if (kIsWeb) return const BluetoothSystemCapabilities();
    if (_android) {
      try {
        final value = await channel
            .invokeMethod<Object?>('queryCapabilities')
            .timeout(const Duration(seconds: 6));
        if (value is Map &&
            value['settings'] is bool &&
            value['audioDevices'] is bool) {
          return BluetoothSystemCapabilities(
            settings: value['settings'] == true,
            audioDevices: value['audioDevices'] == true,
          );
        }
      } on PlatformException {
        return const BluetoothSystemCapabilities();
      } on MissingPluginException {
        return const BluetoothSystemCapabilities();
      } on TimeoutException {
        return const BluetoothSystemCapabilities();
      }
      return const BluetoothSystemCapabilities();
    }
    return BluetoothSystemCapabilities(
      settings:
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows,
    );
  }

  @override
  Future<BluetoothSystemOutcome<bool>> openSettings() async {
    try {
      if (_android) {
        final result = await channel
            .invokeMethod<Object?>('openSettings')
            .timeout(const Duration(seconds: 6));
        if (result == null) return const BluetoothSystemOutcome.available(true);
        return BluetoothSystemOutcome.state(
          BluetoothSystemStatus.invalidData,
          'invalid_settings_response',
        );
      }
      final uri = kIsWeb
          ? null
          : switch (defaultTargetPlatform) {
              TargetPlatform.macOS => Uri.parse(
                'x-apple.systempreferences:com.apple.BluetoothSettings',
              ),
              TargetPlatform.windows => Uri.parse('ms-settings:bluetooth'),
              _ => null,
            };
      if (uri == null) {
        return BluetoothSystemOutcome.state(
          BluetoothSystemStatus.unsupported,
          'platform_unsupported',
        );
      }
      final accepted = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      ).timeout(const Duration(seconds: 6));
      return accepted
          ? const BluetoothSystemOutcome.available(true)
          : BluetoothSystemOutcome.state(
              BluetoothSystemStatus.unavailable,
              'settings_unavailable',
            );
    } on PlatformException catch (e) {
      return BluetoothSystemOutcome.state(
        BluetoothSystemStatus.unavailable,
        e.code,
      );
    } on MissingPluginException {
      return BluetoothSystemOutcome.state(
        BluetoothSystemStatus.unsupported,
        'missing_plugin',
      );
    } on TimeoutException {
      return BluetoothSystemOutcome.state(
        BluetoothSystemStatus.unavailable,
        'settings_unresolved',
      );
    }
  }

  @override
  Future<BluetoothSystemOutcome<List<SystemAudioDevice>>>
  connectedAudioDevices() async {
    if (!_android) {
      return BluetoothSystemOutcome.state(
        BluetoothSystemStatus.unsupported,
        'platform_unsupported',
      );
    }
    try {
      final result = await channel
          .invokeMethod<Object?>('connectedAudioDevices')
          .timeout(const Duration(seconds: 6));
      if (result is! List) {
        return BluetoothSystemOutcome.state(
          BluetoothSystemStatus.invalidData,
          'invalid_device_list',
        );
      }
      final devices = <SystemAudioDevice>[];
      for (var index = 0; index < result.length; index++) {
        final raw = result[index];
        if (raw is! Map ||
            raw['id'] is! String ||
            (raw['id'] as String).isEmpty ||
            (raw['name'] != null && raw['name'] is! String) ||
            raw['profiles'] is! List ||
            !(raw['profiles'] as List).every((e) => e is String)) {
          devices.add(
            SystemAudioDevice(
              id: 'invalid/$index',
              name: '系统音频记录无效',
              profiles: const [],
              error: 'invalid_device_entry',
            ),
          );
        } else {
          devices.add(
            SystemAudioDevice(
              id: raw['id'] as String,
              name: raw['name'] as String?,
              profiles: List<String>.from(raw['profiles'] as List),
            ),
          );
        }
      }
      return BluetoothSystemOutcome.available(List.unmodifiable(devices));
    } on PlatformException catch (e) {
      return BluetoothSystemOutcome.state(
        e.code == 'permission_denied'
            ? BluetoothSystemStatus.permissionDenied
            : BluetoothSystemStatus.unavailable,
        e.code,
      );
    } on MissingPluginException {
      return BluetoothSystemOutcome.state(
        BluetoothSystemStatus.unsupported,
        'missing_plugin',
      );
    } on TimeoutException {
      return BluetoothSystemOutcome.state(
        BluetoothSystemStatus.unavailable,
        'profile_query_unresolved',
      );
    }
  }
}
