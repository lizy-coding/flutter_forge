import 'package:package_info_plus/package_info_plus.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class InstalledAppInfo {
  const InstalledAppInfo({
    required this.version,
    required this.buildNumber,
    required this.packageName,
  });
  final String version;
  final String buildNumber;
  final String packageName;
}

enum AppInfoReason { unavailable, invalidData }

sealed class AppInfoOutcome {
  const AppInfoOutcome();
}

class AppInfoAvailable extends AppInfoOutcome {
  const AppInfoAvailable(this.value);
  final InstalledAppInfo value;
}

class AppInfoUnavailable extends AppInfoOutcome {
  const AppInfoUnavailable(this.reason);
  final AppInfoReason reason;
}

abstract class AppInfoPlatform extends PlatformInterface {
  AppInfoPlatform() : super(token: _token);
  static final Object _token = Object();
  static AppInfoPlatform _instance = PackageAppInfoPlatform();
  static AppInfoPlatform get instance => _instance;
  static set instance(AppInfoPlatform value) {
    PlatformInterface.verifyToken(value, _token);
    _instance = value;
  }

  Future<AppInfoOutcome> read();
  Future<bool> queryCapabilities() async {
    try {
      return await read().timeout(const Duration(seconds: 5))
          is AppInfoAvailable;
    } catch (_) {
      return false;
    }
  }
}

class PackageAppInfoPlatform extends AppInfoPlatform {
  PackageAppInfoPlatform({Future<PackageInfo> Function()? loader})
    : _loader = loader ?? PackageInfo.fromPlatform;
  final Future<PackageInfo> Function() _loader;
  @override
  Future<AppInfoOutcome> read() async {
    try {
      final info = await _loader();
      if ([
        info.version,
        info.buildNumber,
        info.packageName,
      ].any((value) => value.trim().isEmpty)) {
        return const AppInfoUnavailable(AppInfoReason.invalidData);
      }
      return AppInfoAvailable(
        InstalledAppInfo(
          version: info.version,
          buildNumber: info.buildNumber,
          packageName: info.packageName,
        ),
      );
    } catch (_) {
      return const AppInfoUnavailable(AppInfoReason.unavailable);
    }
  }
}
