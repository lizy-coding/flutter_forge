import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../shared/platform/build_features.dart';
import 'privacy_policy_data.dart';

/// Records explicit acknowledgement of the policy shipped in this edition.
class AndroidPrivacyConsent {
  AndroidPrivacyConsent(this.preferences);

  final SharedPreferences preferences;
  static const preferenceKey = 'flutter_forge.android.accepted_privacy_policy';
  static String get policyVersion =>
      offlineEdition ? offlinePrivacyVersion : fullPrivacyVersion;
  static String get policy =>
      offlineEdition ? offlinePrivacyPolicy : fullPrivacyPolicy;

  bool get accepted => preferences.getString(preferenceKey) == policyVersion;

  Future<bool> accept() => preferences.setString(preferenceKey, policyVersion);
}

/// Shown before application history, routing, or module initialization starts.
class AndroidPrivacyConsentApp extends StatefulWidget {
  const AndroidPrivacyConsentApp({
    super.key,
    required this.saveConsent,
    required this.onAccepted,
    this.onDeclined,
  });

  final Future<bool> Function() saveConsent;
  final Future<void> Function() onAccepted;
  final Future<void> Function()? onDeclined;

  @override
  State<AndroidPrivacyConsentApp> createState() =>
      _AndroidPrivacyConsentAppState();
}

class _AndroidPrivacyConsentAppState extends State<AndroidPrivacyConsentApp> {
  bool _busy = false;
  bool _saveFailed = false;
  bool _startupFailed = false;

  Future<void> _accept() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _saveFailed = false;
      _startupFailed = false;
    });
    try {
      if (!await widget.saveConsent()) throw StateError('Consent not saved');
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _saveFailed = true;
        });
      }
      return;
    }
    try {
      await widget.onAccepted();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _startupFailed = true;
        });
      }
    }
  }

  Future<void> _decline() async {
    if (_busy) return;
    await (widget.onDeclined ?? SystemNavigator.pop)();
  }

  Future<void> _showPolicy(BuildContext context) async {
    final strings = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            leading: const CloseButton(),
            title: Text(strings.privacyUsage),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.policyChinese),
                const SizedBox(height: 12),
                SelectableText(AndroidPrivacyConsent.policy),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Flutter Forge',
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    localeListResolutionCallback: (locales, supported) {
      for (final locale in locales ?? const <Locale>[]) {
        for (final candidate in supported) {
          if (locale.languageCode == candidate.languageCode) return candidate;
        }
      }
      return const Locale('zh');
    },
    home: Builder(
      builder: (context) {
        final strings = AppLocalizations.of(context);
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (!didPop) await _decline();
          },
          child: Scaffold(
            body: Center(
              child: AlertDialog(
                key: const ValueKey('startup-privacy-notice'),
                scrollable: true,
                title: Text(strings.startupPrivacyTitle),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.startupPrivacyIntro),
                    const SizedBox(height: 12),
                    Text(
                      offlineEdition
                          ? strings.startupPrivacyOffline
                          : strings.startupPrivacyFull,
                    ),
                    const SizedBox(height: 12),
                    Text(strings.startupPrivacyPermissions),
                    TextButton(
                      key: const ValueKey('startup-privacy-policy'),
                      onPressed: () async => _showPolicy(context),
                      child: Text(strings.startupPrivacyReadPolicy),
                    ),
                    Text(
                      strings.policyVersion(
                        AndroidPrivacyConsent.policyVersion,
                      ),
                    ),
                    if (_saveFailed || _startupFailed)
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _saveFailed
                              ? strings.startupPrivacySaveFailed
                              : strings.startupPrivacyLaunchFailed,
                        ),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: _busy ? null : _decline,
                    child: Text(strings.startupPrivacyDecline),
                  ),
                  FilledButton(
                    onPressed: _busy ? null : _accept,
                    child: Text(
                      _busy
                          ? strings.startupPrivacySaving
                          : strings.startupPrivacyAccept,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
