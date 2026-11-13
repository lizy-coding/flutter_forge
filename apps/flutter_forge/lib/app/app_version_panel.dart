import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forge_app_info/forge_app_info.dart';

import '../l10n/strings.dart';
import '../shared/platform/build_features.dart';

class AppVersionPanel extends StatefulWidget {
  const AppVersionPanel({super.key});
  @override
  State<AppVersionPanel> createState() => _AppVersionPanelState();
}

class _AppVersionPanelState extends State<AppVersionPanel> {
  Timer? _timer;
  late Future<AppInfoOutcome> _info = _read();
  Future<AppInfoOutcome> _read() {
    _timer?.cancel();
    final result = Completer<AppInfoOutcome>();
    final timer = Timer(const Duration(seconds: 5), () {
      if (!result.isCompleted) {
        result.complete(const AppInfoUnavailable(AppInfoReason.unavailable));
      }
    });
    _timer = timer;
    unawaited(
      AppInfoPlatform.instance.read().then(
        (value) {
          timer.cancel();
          if (!result.isCompleted) result.complete(value);
        },
        onError: (Object error, StackTrace stack) {
          timer.cancel();
          if (!result.isCompleted) {
            result.complete(
              const AppInfoUnavailable(AppInfoReason.unavailable),
            );
          }
        },
      ),
    );
    return result.future;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool _copying = false;

  Future<void> _copy(InstalledAppInfo info) async {
    setState(() => _copying = true);
    try {
      await Clipboard.setData(
        ClipboardData(
          text: [
            'Flutter Forge',
            'Version: ${info.version}',
            'Build: ${info.buildNumber}',
            'Package: ${info.packageName}',
            'Edition: ${offlineEdition ? 'Offline' : 'Full'}',
          ].join('\n'),
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appStrings(context).versionCopied)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appStrings(context).versionCopyFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _copying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = appStrings(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        key: const ValueKey('app-version-panel'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.versionInfo,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          FutureBuilder<AppInfoOutcome>(
            future: _info,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return Text(strings.versionLoading);
              }
              final result = snapshot.data;
              if (result is! AppInfoAvailable) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.versionUnavailable),
                    TextButton(
                      key: const ValueKey('version-retry'),
                      onPressed: () => setState(() {
                        _info = _read();
                      }),
                      child: Text(strings.versionRetry),
                    ),
                  ],
                );
              }
              final info = result.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    strings.installedVersion(info.version, info.buildNumber),
                  ),
                  Text(
                    offlineEdition
                        ? strings.editionOffline
                        : strings.editionFull,
                  ),
                  SelectableText(info.packageName),
                  TextButton.icon(
                    key: const ValueKey('copy-version-info'),
                    onPressed: _copying ? null : () => _copy(info),
                    icon: const Icon(Icons.copy_outlined),
                    label: Text(strings.copyVersion),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
