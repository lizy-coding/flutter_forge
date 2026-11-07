# forge_localization

Workspace-local Flutter package for locale resolution and observable preference
changes. Consumers supply supported locales, a fallback, system locales and an
optional asynchronous persistence callback. It contains no Forge messages,
routes, storage plugin or native channel.

`LocaleController` resolves the first supported system language, maps regional
variants by language code, and falls back when no candidate is supported.
Explicit preferences override system changes. Writes run in selection order;
`saveError` reports a failed latest write and selecting again retries it.
`applyRemotePreference` does not save or rebroadcast.

Hosts forward system locale events and coordinate cross-engine messages. Wrap
consumers in `LocaleScope`, then pass `effectiveLocale` to `MaterialApp` along
with the application's official gen_l10n delegates. Keep the router and task
controllers alive across locale changes.

Validation: `flutter test test/locale_controller_test.dart`.
