// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get language => '语言 / Language';

  @override
  String get systemLanguage => 'System default';

  @override
  String get chinese => '简体中文';

  @override
  String get english => 'English';

  @override
  String get saveLanguageFailed =>
      'Language preference was not saved. Please try again.';

  @override
  String get chineseLessons => 'Lesson content is in Chinese';

  @override
  String get about => 'About Flutter Forge';

  @override
  String get explore => 'Explore and learn';

  @override
  String get searchHint => 'Search modules, concepts or categories';

  @override
  String get categories => 'Categories';

  @override
  String get recent => 'Recently opened';

  @override
  String get homeIntro =>
      'Start with a question or concept and find an example to run.';

  @override
  String get recentEmpty => 'Open a module to find it here later.';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get back => 'Back';

  @override
  String get noResults => 'No matching modules. Clear search';

  @override
  String get searchModules => 'Search modules';

  @override
  String get unsupported => 'This module is unavailable on this platform';

  @override
  String get backCatalog => 'Back to catalog';

  @override
  String get workbench => 'Learning workbench';

  @override
  String get continueExploring => 'Continue exploring';

  @override
  String get quickOpenModule => 'Open a module';

  @override
  String get quickOpen => 'Quick open';

  @override
  String get noHistory =>
      'No history yet. Start from a category below or the sidebar.';

  @override
  String get collapseSidebar => 'Collapse sidebar';

  @override
  String get expandSidebar => 'Expand sidebar';

  @override
  String get previousPage => 'Previous page';

  @override
  String get homeWorkbench => 'Back to workbench';

  @override
  String get homeCategory => 'Back to category';

  @override
  String get enterFullscreen => 'Enter full screen';

  @override
  String get exitFullscreen => 'Exit full screen';

  @override
  String get modules => 'Modules';

  @override
  String get collapseCategory => 'Collapse category';

  @override
  String get expandCategory => 'Expand category';

  @override
  String get platformUnavailable => 'Unavailable on this platform';

  @override
  String get newWindow => 'Open in new window';

  @override
  String get opening => 'Opening…';

  @override
  String get focusCategory => 'Focus on this category in a separate window';

  @override
  String get newTab => 'Open in new tab';

  @override
  String get openWindowFailed =>
      'Could not open the category window. Please retry.';

  @override
  String get aboutIntro => 'A Flutter workshop to run, explore and verify.';

  @override
  String moduleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count modules',
      one: '1 module',
      zero: 'No modules',
    );
    return '$_temp0';
  }

  @override
  String minutes(int count) {
    return '$count min';
  }

  @override
  String get moduleGraphicsBackgroundTitle =>
      'Graphics: GPU, textures and shaders';

  @override
  String get moduleGraphicsBackgroundSubtitle =>
      'Explore pixels, GPU, textures, UV and shaders by displaying an image.';

  @override
  String get modulePixelShaderIntroTitle => 'Drawing: shapes to colors';

  @override
  String get modulePixelShaderIntroSubtitle =>
      'Compare drawing and color rules with a step-by-step UV experiment.';

  @override
  String get moduleConstraintLayoutTitle =>
      'Constraints and declarative layout';

  @override
  String get moduleConstraintLayoutSubtitle =>
      'Adjust parent constraints and observe Row, Column and Wrap layouts.';

  @override
  String get moduleTreeStateTitle => 'Three trees and lifecycle';

  @override
  String get moduleTreeStateSubtitle =>
      'Understand Widget, Element and RenderObject relationships and rebuilds.';

  @override
  String get moduleMicrotaskTitle => 'Event loop and microtasks';

  @override
  String get moduleMicrotaskSubtitle =>
      'Observe microtask and event queue execution order.';

  @override
  String get moduleDebounceThrottleTitle => 'Debounce and throttle';

  @override
  String get moduleDebounceThrottleSubtitle =>
      'Compare debounce and throttle timing and use cases.';

  @override
  String get moduleStreamSubscriptionTitle => 'Stream subscriptions';

  @override
  String get moduleStreamSubscriptionSubtitle =>
      'Compare single-subscription and broadcast streams.';

  @override
  String get moduleIsolateBasicTitle => 'Isolate concurrency';

  @override
  String get moduleIsolateBasicSubtitle =>
      'Compare costly computation on the main thread and in an Isolate.';

  @override
  String get moduleIsolateTaskManagerTitle => 'Multi-task Isolate manager';

  @override
  String get moduleIsolateTaskManagerSubtitle =>
      'Process concurrent tasks and report progress through streams.';

  @override
  String get moduleStatusManagementTitle => 'State management evolution';

  @override
  String get moduleStatusManagementSubtitle =>
      'Compare setState, Provider, Riverpod and Bloc.';

  @override
  String get moduleFlutterIocTitle => 'Flutter IoC container';

  @override
  String get moduleFlutterIocSubtitle =>
      'Explore singleton, transient and scoped lifetimes.';

  @override
  String get moduleLocalPersistenceTitle => 'Local persistence';

  @override
  String get moduleLocalPersistenceSubtitle =>
      'Persist preferences and counters and restore asynchronous state.';

  @override
  String get moduleGcodeVisualizerTitle => 'G-code paths and animation';

  @override
  String get moduleGcodeVisualizerSubtitle =>
      'Parse G-code, render toolpaths and animate execution.';

  @override
  String get moduleAdsorptionLineTitle => 'Alignment snapping canvas';

  @override
  String get moduleAdsorptionLineSubtitle =>
      'Explore alignment snapping, custom painting and gestures.';

  @override
  String get moduleDownloadAnimationTitle => 'Download animations';

  @override
  String get moduleDownloadAnimationSubtitle =>
      'Compare custom views, CustomPaint and Overlay implementations.';

  @override
  String get moduleFontPickerTitle => 'Font picker';

  @override
  String get moduleFontPickerSubtitle =>
      'Compare font families and weights and load local fonts.';

  @override
  String get moduleGenuiWorkbenchTitle => 'Generative experiment workbench';

  @override
  String get moduleGenuiWorkbenchSubtitle =>
      'Ask technical questions, build experiments and observe results.';

  @override
  String get moduleWorkflowWorkbenchTitle => 'Cross-project workflow lab';

  @override
  String get moduleWorkflowWorkbenchSubtitle =>
      'Run article capabilities with Hub workflows and GenUI results.';

  @override
  String get moduleShaderPlaygroundTitle => 'Shaders and interactive effects';

  @override
  String get moduleShaderPlaygroundSubtitle =>
      'Compare Dart and GLSL color rules, gradients and effects.';

  @override
  String get moduleFlutterScene3dTitle => 'Educational 3D viewer';

  @override
  String get moduleFlutterScene3dSubtitle =>
      'Explore orbit cameras, part selection and focus.';

  @override
  String get modulePopupWidgetsTitle => 'Dialog collection';

  @override
  String get modulePopupWidgetsSubtitle =>
      'Explore dialogs, bottom sheets and menus.';

  @override
  String get modulePopupListInteractionTitle => 'Dialogs and lists';

  @override
  String get modulePopupListInteractionSubtitle =>
      'Combine dialogs and two-dimensional scrolling tables.';

  @override
  String get moduleScrollTableTitle => 'Two-dimensional table';

  @override
  String get moduleScrollTableSubtitle =>
      'Explore fixed headers with two_dimensional_scrollables.';

  @override
  String get moduleOverlayFollowCompareTitle => 'Overlay following comparison';

  @override
  String get moduleOverlayFollowCompareSubtitle =>
      'Compare composited followers with markNeedsBuild.';

  @override
  String get moduleDioInterceptorTitle => 'Dio interceptor pipeline';

  @override
  String get moduleDioInterceptorSubtitle =>
      'Explore authentication, errors, retries and logging with a mock server.';

  @override
  String get moduleUsbNetworkTitle => 'USB networking basics';

  @override
  String get moduleUsbNetworkSubtitle =>
      'Explore CDC-NCM adapters, bound TCP and text transfer.';

  @override
  String get moduleNetworkDiagnosticsTitle => 'Network diagnostics';

  @override
  String get moduleNetworkDiagnosticsSubtitle =>
      'Inspect DNS, TCP, HTTP, latency and intermittent failures.';

  @override
  String get moduleUsbDetectorTitle => 'USB device detection';

  @override
  String get moduleUsbDetectorSubtitle =>
      'Observe Android USB devices and their state.';

  @override
  String get moduleBatteryMonitorTitle => 'Battery state and events';

  @override
  String get moduleBatteryMonitorSubtitle =>
      'Explore system changes, sampling, recovery and capacity diagnostics.';

  @override
  String get moduleBluetoothBleTitle => 'BLE connection lifecycle';

  @override
  String get moduleBluetoothBleSubtitle =>
      'Observe scanning, connection, discovery, reads, subscriptions and disconnects.';

  @override
  String get moduleFilePickerTitle => 'File picker';

  @override
  String get moduleFilePickerSubtitle =>
      'Explore file filtering, cancellation and platform differences.';

  @override
  String get moduleOnlineVideoPlayerTitle => 'Video playback and controls';

  @override
  String get moduleOnlineVideoPlayerSubtitle =>
      'Control playback; the offline edition uses bundled lesson media.';

  @override
  String get moduleBiometricAuthTitle => 'Biometrics and local authentication';

  @override
  String get moduleBiometricAuthSubtitle =>
      'Inspect capabilities and authentication outcomes across devices.';

  @override
  String get moduleSystemNotificationTitle => 'Notifications and permissions';

  @override
  String get moduleSystemNotificationSubtitle =>
      'Inspect authorization, permission requests and local delivery.';

  @override
  String get moduleWebviewTitle => 'Web content and navigation';

  @override
  String get moduleWebviewSubtitle =>
      'Explore Android, macOS and Windows web navigation and lifecycle.';

  @override
  String get basicLabel => 'Fundamentals';

  @override
  String get asyncLabel => 'Async and concurrency';

  @override
  String get stateLabel => 'Architecture and state';

  @override
  String get uiLabel => 'UI and motion';

  @override
  String get popupTableLabel => 'Dialogs and lists';

  @override
  String get platformLabel => 'Network and platform';

  @override
  String get beginnerLabel => 'Beginner';

  @override
  String get intermediateLabel => 'Intermediate';

  @override
  String get advancedLabel => 'Advanced';

  @override
  String get pendingLabel => 'Pending';

  @override
  String get readyLabel => 'Ready';

  @override
  String get recommendedLabel => 'Recommended';

  @override
  String get closeQuickOpen => 'Close quick open';

  @override
  String get quickOpenEmpty => 'No matching modules. Try another keyword.';

  @override
  String get quickOpenKeys => '↑ ↓ Select    Enter Open    Esc Back';

  @override
  String get interactiveWorkshop => 'An interactive Flutter workshop';

  @override
  String get searchConcept => 'Search modules or concepts';

  @override
  String get learningObjectives => '🎯 Learning objectives';

  @override
  String get copied => 'Copied to clipboard';

  @override
  String get copyCode => 'Copy code';

  @override
  String get statusLog => '📊 Status log';

  @override
  String get commonMistakes => '⚠️ Common mistakes';

  @override
  String get exercises => '💪 Exercises';

  @override
  String get chineseExperiment => 'Chinese experiment';

  @override
  String get policyChinese => 'The full policy is in Chinese';

  @override
  String get appearance => 'Appearance';

  @override
  String get solidAppearance => 'Solid appearance';

  @override
  String get systemMaterial => 'System material';

  @override
  String get glassAppearance => 'Glass appearance';

  @override
  String get themeSystem => 'System default';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get privacyData => 'Privacy and data';

  @override
  String get offlineEdition =>
      'Offline edition · Experiments run on this device';

  @override
  String get fullEdition =>
      'Full edition · Network services are used on request';

  @override
  String get privacyPermissions => 'Privacy and permission purposes';

  @override
  String get privacyUsage => 'Privacy and data use';

  @override
  String get manageData => 'Manage local data and permissions';

  @override
  String get recentScope =>
      'Recent visits store module entries only. Clearing them does not affect themes, experiments or existing files.';

  @override
  String get recentCleared => 'Recent visits cleared';

  @override
  String get recentSaveFailed =>
      'Could not save cleared history. Entries may return after reopening.';

  @override
  String get clearRecent => 'Clear recent visits';

  @override
  String get systemPermissions =>
      'System permissions: review or revoke Bluetooth, notifications and other access in system settings. Denying optional access does not affect other modules.';

  @override
  String get copyPrivacyEmail => 'Copy privacy contact email';

  @override
  String get emailCopied => 'Email copied. Send feedback using your mail app.';

  @override
  String get discoveryEyebrow => 'Explore with curiosity';

  @override
  String get changeModel => 'Change model service';

  @override
  String get connectModel => 'Connect a model';

  @override
  String get discoveryHeadline => 'What would you like to understand?';

  @override
  String get discoveryIntro =>
      'Start with a question and find an experiment to try.';

  @override
  String get questionExample =>
      'For example: why can an async task freeze the UI?';

  @override
  String get modelConnected => 'Model connected';

  @override
  String get replayNoModel => 'Fixed replay · No model call';

  @override
  String get cancelGeneration => 'Cancel generation';

  @override
  String get generateEntry => 'Generate exploration';

  @override
  String get layoutTopic => 'Layout and sizing';

  @override
  String get asyncTopic => 'Async and concurrency';

  @override
  String get networkTopic => 'Network and devices';

  @override
  String get preparingDiscovery => 'Preparing exploration suggestions…';

  @override
  String get discoveryResults => 'Explore these starting points';

  @override
  String get fixedReplay => 'Fixed replay';

  @override
  String get clearLocalFilter =>
      'Clear local filter and restore recommendations';

  @override
  String get replayChinese =>
      'Lesson replay content is in Chinese. Model and external content stays in its original language.';

  @override
  String get noOpenPlatforms => 'No target platform is currently available';

  @override
  String estimatedTime(int count, String status) {
    return 'Est. $count min · $status';
  }

  @override
  String policyVersion(String version) {
    return 'Policy version: $version';
  }

  @override
  String currentPlatform(String platform) {
    return 'Current platform: $platform';
  }

  @override
  String openPlatforms(String platforms) {
    return 'Available platforms: $platforms';
  }

  @override
  String localFilter(String label) {
    return 'Local filter: $label';
  }

  @override
  String windowError(String message) {
    return 'Window operation failed: $message';
  }

  @override
  String get otherData =>
      'Other local data: Android app settings can clear app data; browsers can clear site data. Windows reset depends on installation type. Uninstalling on macOS may leave preferences and web data. Check what to keep before clearing.';

  @override
  String get thirdPartyData =>
      'Third-party data: stop generation, disconnect or leave a module to stop further operations. Manage data already sent to a model, website or Hub under that service’s rules. Clearing local data does not delete server data.';

  @override
  String get concept0 => 'Pixels';

  @override
  String get concept1 => 'Textures';

  @override
  String get concept2 => 'Fragment shader';

  @override
  String get concept3 => 'Local coordinates';

  @override
  String get concept4 => 'Color rules';

  @override
  String get concept5 => 'UV ratios';

  @override
  String get concept6 => 'Declarative UI';

  @override
  String get concept7 => 'Widget tree';

  @override
  String get concept8 => 'Element tree';

  @override
  String get concept9 => 'Lifecycle';

  @override
  String get concept10 => 'Single subscription';

  @override
  String get concept11 => 'Broadcast stream';

  @override
  String get concept12 => 'Stream transformation';

  @override
  String get concept13 => 'Performance tuning';

  @override
  String get concept14 => 'Multiple tasks';

  @override
  String get concept15 => 'Progress reporting';

  @override
  String get concept16 => 'Pause / resume';

  @override
  String get concept17 => 'Lifting state';

  @override
  String get concept18 => 'Dependency injection';

  @override
  String get concept19 => 'Scopes';

  @override
  String get concept20 => 'Key-value storage';

  @override
  String get concept21 => 'Async loading';

  @override
  String get concept22 => 'State restoration';

  @override
  String get concept23 => 'Test doubles';

  @override
  String get concept24 => 'Animation control';

  @override
  String get concept25 => 'Gesture detection';

  @override
  String get concept26 => 'Snapping algorithm';

  @override
  String get concept27 => 'State management';

  @override
  String get concept28 => 'Tween animation';

  @override
  String get concept29 => 'Animation configuration';

  @override
  String get concept30 => 'Font weight';

  @override
  String get concept31 => 'Letter spacing';

  @override
  String get concept32 => 'Font fallback';

  @override
  String get concept33 => 'Platform fonts';

  @override
  String get concept34 => 'Shared capability reuse';

  @override
  String get concept35 => 'Interaction events';

  @override
  String get concept36 => 'Workflows';

  @override
  String get concept37 => 'Capability registration';

  @override
  String get concept38 => 'Input schema';

  @override
  String get concept39 => 'Execution leases';

  @override
  String get concept40 => 'Run events';

  @override
  String get concept41 => 'Sweep highlight';

  @override
  String get concept42 => 'Scene selection';

  @override
  String get concept43 => 'Visual tuning';

  @override
  String get concept44 => 'Orbit camera';

  @override
  String get concept45 => 'Part focus';

  @override
  String get concept46 => 'Two-dimensional scrolling';

  @override
  String get concept47 => 'Fixed headers';

  @override
  String get concept48 => 'Interceptors';

  @override
  String get concept49 => 'Token refresh';

  @override
  String get concept50 => 'Retry mechanism';

  @override
  String get concept51 => 'Interface binding';

  @override
  String get concept52 => 'TCP byte stream';

  @override
  String get concept53 => 'Resource cleanup';

  @override
  String get concept54 => 'Timeout and cancellation';

  @override
  String get concept55 => 'Evidence boundaries';

  @override
  String get concept56 => 'Platform interface';

  @override
  String get concept57 => 'Capability query';

  @override
  String get concept58 => 'Typed outcomes';

  @override
  String get concept59 => 'System changes';

  @override
  String get concept60 => 'Periodic sampling';

  @override
  String get concept61 => 'Characteristic properties';

  @override
  String get concept62 => 'Notification subscription';

  @override
  String get concept63 => 'Platform bridge';

  @override
  String get concept64 => 'Extension filtering';

  @override
  String get concept65 => 'Cancellation paths';

  @override
  String get concept66 => 'Platform player';

  @override
  String get concept67 => 'HTTP stream';

  @override
  String get concept68 => 'Playback controls';

  @override
  String get concept69 => 'Playback speed';

  @override
  String get concept70 => 'Controller lifecycle';

  @override
  String get concept71 => 'Authentication reason codes';

  @override
  String get concept72 => 'Credential fallback';

  @override
  String get concept73 => 'Runtime permissions';

  @override
  String get concept74 => 'Authorization status';

  @override
  String get concept75 => 'Notification delivery';

  @override
  String get concept76 => 'Loading progress';

  @override
  String get startupLoading => 'Loading application…';

  @override
  String get startupReload => 'Reload';

  @override
  String get startupTimeout =>
      'Loading timed out. Check your connection and retry.';

  @override
  String get startupFailed => 'Loading failed. Please reload.';

  @override
  String get startupResources => 'Loading Flutter resources…';

  @override
  String get startupEngine => 'Initializing the rendering engine…';

  @override
  String get startupApp => 'Opening the learning catalog…';

  @override
  String get modelServiceTitle => 'Connect a model service';

  @override
  String get modelServiceIntro =>
      'Connect to a separately started local Codex bridge using your CLI login, or a service compatible with streaming Chat Completions. The endpoint and model name are remembered. The temporary token is used only on this page; browser endpoints must allow cross-origin requests.';

  @override
  String get modelDataNotice =>
      'Live generation sends your question, experiment state and necessary context to the selected service. The temporary token authenticates requests. Review the service privacy policy for data handling. Fixed replay does not send model requests. See Privacy in About.';

  @override
  String get endpointLabel => 'Full endpoint URL';

  @override
  String get endpointInvalid =>
      'Enter an HTTPS endpoint or local HTTP endpoint.';

  @override
  String get modelName => 'Model name';

  @override
  String get modelNameRequired => 'Enter a model name.';

  @override
  String get modelToken => 'Temporary token (optional for a local service)';

  @override
  String get cancel => 'Cancel';

  @override
  String get useService => 'Use service';

  @override
  String get discoveryFailed =>
      'Exploration did not complete. Check your input or model service and retry.';

  @override
  String get originalDetails => 'Original details';

  @override
  String get explorationRecords => 'View exploration records';

  @override
  String get loadLanguageFailed =>
      'Could not read the saved language. Using the system language. Select a language to save it again.';

  @override
  String get versionInfo => 'Version information';

  @override
  String get versionLoading => 'Reading installed version…';

  @override
  String get versionUnavailable =>
      'Version information is unavailable. Please retry.';

  @override
  String get versionRetry => 'Retry';

  @override
  String get copyVersion => 'Copy version information';

  @override
  String get versionCopied => 'Version information copied';

  @override
  String get versionCopyFailed => 'Could not copy. Please retry.';

  @override
  String get editionOffline => 'Offline edition';

  @override
  String get editionFull => 'Full edition';

  @override
  String installedVersion(String version, String build) {
    return 'Version $version · Build $build';
  }

  @override
  String get offlineReplayExamples =>
      'Choose a fixed example to view its local replay.';
}
