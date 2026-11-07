import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @language.
  ///
  /// In zh, this message translates to:
  /// **'语言 / Language'**
  String get language;

  /// No description provided for @systemLanguage.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get systemLanguage;

  /// No description provided for @chinese.
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get chinese;

  /// No description provided for @english.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @saveLanguageFailed.
  ///
  /// In zh, this message translates to:
  /// **'语言偏好未保存，请重试。'**
  String get saveLanguageFailed;

  /// No description provided for @chineseLessons.
  ///
  /// In zh, this message translates to:
  /// **'教学正文为中文'**
  String get chineseLessons;

  /// No description provided for @about.
  ///
  /// In zh, this message translates to:
  /// **'关于 Flutter Forge'**
  String get about;

  /// No description provided for @explore.
  ///
  /// In zh, this message translates to:
  /// **'探索与查阅'**
  String get explore;

  /// No description provided for @searchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索模块、概念或分类'**
  String get searchHint;

  /// No description provided for @categories.
  ///
  /// In zh, this message translates to:
  /// **'学习分类'**
  String get categories;

  /// No description provided for @recent.
  ///
  /// In zh, this message translates to:
  /// **'最近访问'**
  String get recent;

  /// No description provided for @homeIntro.
  ///
  /// In zh, this message translates to:
  /// **'从一个问题或概念开始，找到可以运行的示例。'**
  String get homeIntro;

  /// No description provided for @recentEmpty.
  ///
  /// In zh, this message translates to:
  /// **'打开模块后，可以在这里快速找到它。'**
  String get recentEmpty;

  /// No description provided for @clearSearch.
  ///
  /// In zh, this message translates to:
  /// **'清空搜索'**
  String get clearSearch;

  /// No description provided for @back.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get back;

  /// No description provided for @noResults.
  ///
  /// In zh, this message translates to:
  /// **'没有匹配模块，清空搜索'**
  String get noResults;

  /// No description provided for @searchModules.
  ///
  /// In zh, this message translates to:
  /// **'搜索模块'**
  String get searchModules;

  /// No description provided for @unsupported.
  ///
  /// In zh, this message translates to:
  /// **'当前平台暂不支持此模块'**
  String get unsupported;

  /// No description provided for @backCatalog.
  ///
  /// In zh, this message translates to:
  /// **'返回模块目录'**
  String get backCatalog;

  /// No description provided for @workbench.
  ///
  /// In zh, this message translates to:
  /// **'学习工作台'**
  String get workbench;

  /// No description provided for @continueExploring.
  ///
  /// In zh, this message translates to:
  /// **'随时继续探索'**
  String get continueExploring;

  /// No description provided for @quickOpenModule.
  ///
  /// In zh, this message translates to:
  /// **'快速打开模块'**
  String get quickOpenModule;

  /// No description provided for @quickOpen.
  ///
  /// In zh, this message translates to:
  /// **'快速打开'**
  String get quickOpen;

  /// No description provided for @noHistory.
  ///
  /// In zh, this message translates to:
  /// **'还没有访问记录，从下方分类或侧栏开始。'**
  String get noHistory;

  /// No description provided for @collapseSidebar.
  ///
  /// In zh, this message translates to:
  /// **'收起侧栏'**
  String get collapseSidebar;

  /// No description provided for @expandSidebar.
  ///
  /// In zh, this message translates to:
  /// **'展开侧栏'**
  String get expandSidebar;

  /// No description provided for @previousPage.
  ///
  /// In zh, this message translates to:
  /// **'返回上一页'**
  String get previousPage;

  /// No description provided for @homeWorkbench.
  ///
  /// In zh, this message translates to:
  /// **'返回工作台'**
  String get homeWorkbench;

  /// No description provided for @homeCategory.
  ///
  /// In zh, this message translates to:
  /// **'返回分类主页'**
  String get homeCategory;

  /// No description provided for @enterFullscreen.
  ///
  /// In zh, this message translates to:
  /// **'进入全屏'**
  String get enterFullscreen;

  /// No description provided for @exitFullscreen.
  ///
  /// In zh, this message translates to:
  /// **'退出全屏'**
  String get exitFullscreen;

  /// No description provided for @modules.
  ///
  /// In zh, this message translates to:
  /// **'学习模块'**
  String get modules;

  /// No description provided for @collapseCategory.
  ///
  /// In zh, this message translates to:
  /// **'收起分类'**
  String get collapseCategory;

  /// No description provided for @expandCategory.
  ///
  /// In zh, this message translates to:
  /// **'展开分类'**
  String get expandCategory;

  /// No description provided for @platformUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'当前平台不可用'**
  String get platformUnavailable;

  /// No description provided for @newWindow.
  ///
  /// In zh, this message translates to:
  /// **'在新窗口打开'**
  String get newWindow;

  /// No description provided for @opening.
  ///
  /// In zh, this message translates to:
  /// **'正在打开…'**
  String get opening;

  /// No description provided for @focusCategory.
  ///
  /// In zh, this message translates to:
  /// **'在独立窗口中专注学习这个分类'**
  String get focusCategory;

  /// No description provided for @newTab.
  ///
  /// In zh, this message translates to:
  /// **'在新标签页打开'**
  String get newTab;

  /// No description provided for @openWindowFailed.
  ///
  /// In zh, this message translates to:
  /// **'打开分类窗口失败，请重试。'**
  String get openWindowFailed;

  /// No description provided for @aboutIntro.
  ///
  /// In zh, this message translates to:
  /// **'可运行、可拆解、可验证的 Flutter 学习工坊。'**
  String get aboutIntro;

  /// No description provided for @moduleCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个学习模块'**
  String moduleCount(int count);

  /// No description provided for @minutes.
  ///
  /// In zh, this message translates to:
  /// **'{count} 分钟'**
  String minutes(int count);

  /// No description provided for @moduleGraphicsBackgroundTitle.
  ///
  /// In zh, this message translates to:
  /// **'图形绘制背景：认识 GPU、纹理与 Shader'**
  String get moduleGraphicsBackgroundTitle;

  /// No description provided for @moduleGraphicsBackgroundSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'从显示一张图片出发，分节认识像素、GPU、纹理、UV 与着色器的职责'**
  String get moduleGraphicsBackgroundSubtitle;

  /// No description provided for @modulePixelShaderIntroTitle.
  ///
  /// In zh, this message translates to:
  /// **'绘制入门：从画形状到算颜色'**
  String get modulePixelShaderIntroTitle;

  /// No description provided for @modulePixelShaderIntroSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'用左半边涂蓝的分步实验，理解直接绘制、颜色规则和 UV 位置比例'**
  String get modulePixelShaderIntroSubtitle;

  /// No description provided for @moduleConstraintLayoutTitle.
  ///
  /// In zh, this message translates to:
  /// **'约束与声明式布局'**
  String get moduleConstraintLayoutTitle;

  /// No description provided for @moduleConstraintLayoutSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'拖动父容器约束，实时观察子组件尺寸与 Row、Column、Wrap 布局变化'**
  String get moduleConstraintLayoutSubtitle;

  /// No description provided for @moduleTreeStateTitle.
  ///
  /// In zh, this message translates to:
  /// **'三棵树与生命周期'**
  String get moduleTreeStateTitle;

  /// No description provided for @moduleTreeStateSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'理解 Widget/Element/RenderObject 的关系与重建机制'**
  String get moduleTreeStateSubtitle;

  /// No description provided for @moduleMicrotaskTitle.
  ///
  /// In zh, this message translates to:
  /// **'事件循环与微任务'**
  String get moduleMicrotaskTitle;

  /// No description provided for @moduleMicrotaskSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'掌握 Dart 事件循环中微任务队列与事件队列的执行顺序'**
  String get moduleMicrotaskSubtitle;

  /// No description provided for @moduleDebounceThrottleTitle.
  ///
  /// In zh, this message translates to:
  /// **'防抖与节流'**
  String get moduleDebounceThrottleTitle;

  /// No description provided for @moduleDebounceThrottleSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'对比防抖和节流的执行时序，理解适用场景'**
  String get moduleDebounceThrottleSubtitle;

  /// No description provided for @moduleStreamSubscriptionTitle.
  ///
  /// In zh, this message translates to:
  /// **'Stream 订阅机制'**
  String get moduleStreamSubscriptionTitle;

  /// No description provided for @moduleStreamSubscriptionSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'学习单订阅流与广播流的区别及使用场景'**
  String get moduleStreamSubscriptionSubtitle;

  /// No description provided for @moduleIsolateBasicTitle.
  ///
  /// In zh, this message translates to:
  /// **'Isolate 并发对比'**
  String get moduleIsolateBasicTitle;

  /// No description provided for @moduleIsolateBasicSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'对比主线程与 Isolate 执行耗时计算对 UI 流畅度的影响'**
  String get moduleIsolateBasicSubtitle;

  /// No description provided for @moduleIsolateTaskManagerTitle.
  ///
  /// In zh, this message translates to:
  /// **'多任务 Isolate 管理器'**
  String get moduleIsolateTaskManagerTitle;

  /// No description provided for @moduleIsolateTaskManagerSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'使用 Isolate 并行处理多任务，通过 Stream 实时上报进度'**
  String get moduleIsolateTaskManagerSubtitle;

  /// No description provided for @moduleStatusManagementTitle.
  ///
  /// In zh, this message translates to:
  /// **'状态管理演进'**
  String get moduleStatusManagementTitle;

  /// No description provided for @moduleStatusManagementSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'串联 setState、Provider、Riverpod、Bloc，对比不同方案'**
  String get moduleStatusManagementSubtitle;

  /// No description provided for @moduleFlutterIocTitle.
  ///
  /// In zh, this message translates to:
  /// **'Flutter IoC 容器'**
  String get moduleFlutterIocTitle;

  /// No description provided for @moduleFlutterIocSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'自研 IoC 容器实现，支持单例/瞬态/作用域生命周期'**
  String get moduleFlutterIocSubtitle;

  /// No description provided for @moduleLocalPersistenceTitle.
  ///
  /// In zh, this message translates to:
  /// **'本地持久化'**
  String get moduleLocalPersistenceTitle;

  /// No description provided for @moduleLocalPersistenceSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'使用 shared_preferences 持久化设置项与计数器，理解异步读取与状态恢复'**
  String get moduleLocalPersistenceSubtitle;

  /// No description provided for @moduleGcodeVisualizerTitle.
  ///
  /// In zh, this message translates to:
  /// **'G-code 解析与轨迹动画'**
  String get moduleGcodeVisualizerTitle;

  /// No description provided for @moduleGcodeVisualizerSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'解析 G-code 指令，绘制刀路轨迹并用动画展示执行过程'**
  String get moduleGcodeVisualizerSubtitle;

  /// No description provided for @moduleAdsorptionLineTitle.
  ///
  /// In zh, this message translates to:
  /// **'智能吸附线画板'**
  String get moduleAdsorptionLineTitle;

  /// No description provided for @moduleAdsorptionLineSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'类似设计工具的对齐吸附功能，学习自定义绘制与手势'**
  String get moduleAdsorptionLineSubtitle;

  /// No description provided for @moduleDownloadAnimationTitle.
  ///
  /// In zh, this message translates to:
  /// **'下载飞入动效'**
  String get moduleDownloadAnimationTitle;

  /// No description provided for @moduleDownloadAnimationSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'三种实现方式对比：Custom View / CustomPaint / Overlay'**
  String get moduleDownloadAnimationSubtitle;

  /// No description provided for @moduleFontPickerTitle.
  ///
  /// In zh, this message translates to:
  /// **'字体选择器'**
  String get moduleFontPickerTitle;

  /// No description provided for @moduleFontPickerSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'命名列表中直观对比不同字体族与字重样式，并通过文件选择器加载本地字体'**
  String get moduleFontPickerSubtitle;

  /// No description provided for @moduleGenuiWorkbenchTitle.
  ///
  /// In zh, this message translates to:
  /// **'生成式实验工作区'**
  String get moduleGenuiWorkbenchTitle;

  /// No description provided for @moduleGenuiWorkbenchSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'提出技术问题，用 GenUI 组织可操作实验，观察真实结果并继续探索'**
  String get moduleGenuiWorkbenchSubtitle;

  /// No description provided for @moduleWorkflowWorkbenchTitle.
  ///
  /// In zh, this message translates to:
  /// **'跨项目工作流实验室'**
  String get moduleWorkflowWorkbenchTitle;

  /// No description provided for @moduleWorkflowWorkbenchSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'Hub 保存流程与运行记录，Forge 执行文章能力并通过 GenUI 展示结果'**
  String get moduleWorkflowWorkbenchSubtitle;

  /// No description provided for @moduleShaderPlaygroundTitle.
  ///
  /// In zh, this message translates to:
  /// **'Shader 像素绘制与交互动效'**
  String get moduleShaderPlaygroundTitle;

  /// No description provided for @moduleShaderPlaygroundSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'衔接绘制入门，分步对照 Dart 与 GLSL，从颜色规则走向渐变、卡片扫光和场景调优'**
  String get moduleShaderPlaygroundSubtitle;

  /// No description provided for @moduleFlutterScene3dTitle.
  ///
  /// In zh, this message translates to:
  /// **'教学型 3D 查看器'**
  String get moduleFlutterScene3dTitle;

  /// No description provided for @moduleFlutterScene3dSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'用轨道相机、部件选取与聚焦反馈理解 3D 查看器交互'**
  String get moduleFlutterScene3dSubtitle;

  /// No description provided for @modulePopupWidgetsTitle.
  ///
  /// In zh, this message translates to:
  /// **'弹窗合集'**
  String get modulePopupWidgetsTitle;

  /// No description provided for @modulePopupWidgetsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'全面展示 Flutter 中的对话框、底部抽屉、菜单等弹窗类型'**
  String get modulePopupWidgetsSubtitle;

  /// No description provided for @modulePopupListInteractionTitle.
  ///
  /// In zh, this message translates to:
  /// **'弹窗与列表交互'**
  String get modulePopupListInteractionTitle;

  /// No description provided for @modulePopupListInteractionSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'Flutter 弹窗组件与二维滚动表格的综合演示'**
  String get modulePopupListInteractionSubtitle;

  /// No description provided for @moduleScrollTableTitle.
  ///
  /// In zh, this message translates to:
  /// **'二维滚动表格'**
  String get moduleScrollTableTitle;

  /// No description provided for @moduleScrollTableSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'使用 two_dimensional_scrollables 实现固定表头的表格'**
  String get moduleScrollTableSubtitle;

  /// No description provided for @moduleOverlayFollowCompareTitle.
  ///
  /// In zh, this message translates to:
  /// **'Overlay 跟随方案对照组'**
  String get moduleOverlayFollowCompareTitle;

  /// No description provided for @moduleOverlayFollowCompareSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'对比 CompositedTransformFollower 与 markNeedsBuild 两种浮层跟随方案'**
  String get moduleOverlayFollowCompareSubtitle;

  /// No description provided for @moduleDioInterceptorTitle.
  ///
  /// In zh, this message translates to:
  /// **'Dio 拦截器链路'**
  String get moduleDioInterceptorTitle;

  /// No description provided for @moduleDioInterceptorSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'Auth/Error/Retry/Log 拦截器 + 本地 Mock Server 实战'**
  String get moduleDioInterceptorSubtitle;

  /// No description provided for @moduleUsbNetworkTitle.
  ///
  /// In zh, this message translates to:
  /// **'USB 网络连接基础'**
  String get moduleUsbNetworkTitle;

  /// No description provided for @moduleUsbNetworkSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'CDC-NCM 网卡、绑定 TCP 与文本收发'**
  String get moduleUsbNetworkSubtitle;

  /// No description provided for @moduleNetworkDiagnosticsTitle.
  ///
  /// In zh, this message translates to:
  /// **'网络诊断：从现象到检测证据'**
  String get moduleNetworkDiagnosticsTitle;

  /// No description provided for @moduleNetworkDiagnosticsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'检测 DNS、TCP 与 HTTP 响应，观察延迟和间歇失败，预览并复制诊断报告'**
  String get moduleNetworkDiagnosticsSubtitle;

  /// No description provided for @moduleUsbDetectorTitle.
  ///
  /// In zh, this message translates to:
  /// **'USB 设备检测'**
  String get moduleUsbDetectorTitle;

  /// No description provided for @moduleUsbDetectorSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'Android USB 设备检测与状态监控'**
  String get moduleUsbDetectorSubtitle;

  /// No description provided for @moduleBatteryMonitorTitle.
  ///
  /// In zh, this message translates to:
  /// **'电池状态与事件监听'**
  String get moduleBatteryMonitorTitle;

  /// No description provided for @moduleBatteryMonitorSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'系统变化、定期采样、会话恢复与容量诊断'**
  String get moduleBatteryMonitorSubtitle;

  /// No description provided for @moduleBluetoothBleTitle.
  ///
  /// In zh, this message translates to:
  /// **'BLE 连接生命周期'**
  String get moduleBluetoothBleTitle;

  /// No description provided for @moduleBluetoothBleSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'观察扫描、连接、服务发现、读取与订阅、断开'**
  String get moduleBluetoothBleSubtitle;

  /// No description provided for @moduleFilePickerTitle.
  ///
  /// In zh, this message translates to:
  /// **'文件选择器'**
  String get moduleFilePickerTitle;

  /// No description provided for @moduleFilePickerSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'复用 file_picker_bridge 中台能力，演示扩展过滤、取消分支与平台差异'**
  String get moduleFilePickerSubtitle;

  /// No description provided for @moduleOnlineVideoPlayerTitle.
  ///
  /// In zh, this message translates to:
  /// **'视频播放与控制'**
  String get moduleOnlineVideoPlayerTitle;

  /// No description provided for @moduleOnlineVideoPlayerSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'使用 video_player 打开视频并操控播放参数，离线版使用内置教学素材'**
  String get moduleOnlineVideoPlayerSubtitle;

  /// No description provided for @moduleBiometricAuthTitle.
  ///
  /// In zh, this message translates to:
  /// **'生物特征与本地认证'**
  String get moduleBiometricAuthTitle;

  /// No description provided for @moduleBiometricAuthSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'从能力查询到认证结果，观察指纹与面容的运行时差异'**
  String get moduleBiometricAuthSubtitle;

  /// No description provided for @moduleSystemNotificationTitle.
  ///
  /// In zh, this message translates to:
  /// **'系统通知与授权状态'**
  String get moduleSystemNotificationTitle;

  /// No description provided for @moduleSystemNotificationSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'授权状态、授权请求与本地通知投递的运行时链路'**
  String get moduleSystemNotificationSubtitle;

  /// No description provided for @moduleWebviewTitle.
  ///
  /// In zh, this message translates to:
  /// **'网页容器与跨平台导航'**
  String get moduleWebviewTitle;

  /// No description provided for @moduleWebviewSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'学习 Android、macOS、Windows 网页导航与生命周期'**
  String get moduleWebviewSubtitle;

  /// No description provided for @basicLabel.
  ///
  /// In zh, this message translates to:
  /// **'基础机制'**
  String get basicLabel;

  /// No description provided for @asyncLabel.
  ///
  /// In zh, this message translates to:
  /// **'异步并发'**
  String get asyncLabel;

  /// No description provided for @stateLabel.
  ///
  /// In zh, this message translates to:
  /// **'架构与状态'**
  String get stateLabel;

  /// No description provided for @uiLabel.
  ///
  /// In zh, this message translates to:
  /// **'UI 与动效'**
  String get uiLabel;

  /// No description provided for @popupTableLabel.
  ///
  /// In zh, this message translates to:
  /// **'弹窗与列表'**
  String get popupTableLabel;

  /// No description provided for @platformLabel.
  ///
  /// In zh, this message translates to:
  /// **'网络与平台'**
  String get platformLabel;

  /// No description provided for @beginnerLabel.
  ///
  /// In zh, this message translates to:
  /// **'入门'**
  String get beginnerLabel;

  /// No description provided for @intermediateLabel.
  ///
  /// In zh, this message translates to:
  /// **'进阶'**
  String get intermediateLabel;

  /// No description provided for @advancedLabel.
  ///
  /// In zh, this message translates to:
  /// **'实战'**
  String get advancedLabel;

  /// No description provided for @pendingLabel.
  ///
  /// In zh, this message translates to:
  /// **'待整改'**
  String get pendingLabel;

  /// No description provided for @readyLabel.
  ///
  /// In zh, this message translates to:
  /// **'可学习'**
  String get readyLabel;

  /// No description provided for @recommendedLabel.
  ///
  /// In zh, this message translates to:
  /// **'推荐'**
  String get recommendedLabel;

  /// No description provided for @closeQuickOpen.
  ///
  /// In zh, this message translates to:
  /// **'关闭快速打开'**
  String get closeQuickOpen;

  /// No description provided for @quickOpenEmpty.
  ///
  /// In zh, this message translates to:
  /// **'没有匹配模块，请尝试其他关键词'**
  String get quickOpenEmpty;

  /// No description provided for @quickOpenKeys.
  ///
  /// In zh, this message translates to:
  /// **'↑ ↓ 选择    Enter 打开    Esc 返回'**
  String get quickOpenKeys;

  /// No description provided for @interactiveWorkshop.
  ///
  /// In zh, this message translates to:
  /// **'可交互的 Flutter 学习现场'**
  String get interactiveWorkshop;

  /// No description provided for @searchConcept.
  ///
  /// In zh, this message translates to:
  /// **'搜索模块或概念'**
  String get searchConcept;

  /// No description provided for @learningObjectives.
  ///
  /// In zh, this message translates to:
  /// **'🎯 学习目标'**
  String get learningObjectives;

  /// No description provided for @copied.
  ///
  /// In zh, this message translates to:
  /// **'已复制到剪贴板'**
  String get copied;

  /// No description provided for @copyCode.
  ///
  /// In zh, this message translates to:
  /// **'复制代码'**
  String get copyCode;

  /// No description provided for @statusLog.
  ///
  /// In zh, this message translates to:
  /// **'📊 状态日志'**
  String get statusLog;

  /// No description provided for @commonMistakes.
  ///
  /// In zh, this message translates to:
  /// **'⚠️ 常见误区'**
  String get commonMistakes;

  /// No description provided for @exercises.
  ///
  /// In zh, this message translates to:
  /// **'💪 练习任务'**
  String get exercises;

  /// No description provided for @chineseExperiment.
  ///
  /// In zh, this message translates to:
  /// **'中文实验'**
  String get chineseExperiment;

  /// No description provided for @policyChinese.
  ///
  /// In zh, this message translates to:
  /// **'政策全文为中文'**
  String get policyChinese;

  /// No description provided for @appearance.
  ///
  /// In zh, this message translates to:
  /// **'切换外观'**
  String get appearance;

  /// No description provided for @solidAppearance.
  ///
  /// In zh, this message translates to:
  /// **'实色外观'**
  String get solidAppearance;

  /// No description provided for @systemMaterial.
  ///
  /// In zh, this message translates to:
  /// **'系统材质'**
  String get systemMaterial;

  /// No description provided for @glassAppearance.
  ///
  /// In zh, this message translates to:
  /// **'玻璃外观'**
  String get glassAppearance;

  /// No description provided for @themeSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In zh, this message translates to:
  /// **'白日模式'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In zh, this message translates to:
  /// **'黑暗模式'**
  String get themeDark;

  /// No description provided for @privacyData.
  ///
  /// In zh, this message translates to:
  /// **'隐私与数据'**
  String get privacyData;

  /// No description provided for @offlineEdition.
  ///
  /// In zh, this message translates to:
  /// **'离线学习版 · 所有实验在本机进行'**
  String get offlineEdition;

  /// No description provided for @fullEdition.
  ///
  /// In zh, this message translates to:
  /// **'联网完整版 · 按操作使用网络服务'**
  String get fullEdition;

  /// No description provided for @privacyPermissions.
  ///
  /// In zh, this message translates to:
  /// **'隐私说明与权限用途'**
  String get privacyPermissions;

  /// No description provided for @privacyUsage.
  ///
  /// In zh, this message translates to:
  /// **'隐私说明与数据使用'**
  String get privacyUsage;

  /// No description provided for @manageData.
  ///
  /// In zh, this message translates to:
  /// **'管理本地数据与权限'**
  String get manageData;

  /// No description provided for @recentScope.
  ///
  /// In zh, this message translates to:
  /// **'最近访问只保存模块入口。清除后不影响主题、实验内容或原有文件。'**
  String get recentScope;

  /// No description provided for @recentCleared.
  ///
  /// In zh, this message translates to:
  /// **'最近访问已清除'**
  String get recentCleared;

  /// No description provided for @recentSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'最近访问保存失败，重新打开后可能仍会显示'**
  String get recentSaveFailed;

  /// No description provided for @clearRecent.
  ///
  /// In zh, this message translates to:
  /// **'清除最近访问'**
  String get clearRecent;

  /// No description provided for @systemPermissions.
  ///
  /// In zh, this message translates to:
  /// **'系统权限：在系统设置中查看或撤销蓝牙、通知等授权。拒绝可选权限不影响其他学习模块。'**
  String get systemPermissions;

  /// No description provided for @copyPrivacyEmail.
  ///
  /// In zh, this message translates to:
  /// **'复制隐私反馈邮箱'**
  String get copyPrivacyEmail;

  /// No description provided for @emailCopied.
  ///
  /// In zh, this message translates to:
  /// **'邮箱已复制，请自行发送反馈'**
  String get emailCopied;

  /// No description provided for @discoveryEyebrow.
  ///
  /// In zh, this message translates to:
  /// **'探索，从好奇开始'**
  String get discoveryEyebrow;

  /// No description provided for @changeModel.
  ///
  /// In zh, this message translates to:
  /// **'更换模型服务'**
  String get changeModel;

  /// No description provided for @connectModel.
  ///
  /// In zh, this message translates to:
  /// **'连接真实模型'**
  String get connectModel;

  /// No description provided for @discoveryHeadline.
  ///
  /// In zh, this message translates to:
  /// **'今天，想弄明白什么？'**
  String get discoveryHeadline;

  /// No description provided for @discoveryIntro.
  ///
  /// In zh, this message translates to:
  /// **'从一个问题出发，找到值得动手的实验。'**
  String get discoveryIntro;

  /// No description provided for @questionExample.
  ///
  /// In zh, this message translates to:
  /// **'比如：异步任务为什么会卡住界面？'**
  String get questionExample;

  /// No description provided for @modelConnected.
  ///
  /// In zh, this message translates to:
  /// **'模型已连接'**
  String get modelConnected;

  /// No description provided for @replayNoModel.
  ///
  /// In zh, this message translates to:
  /// **'固定回放 · 未调用模型'**
  String get replayNoModel;

  /// No description provided for @cancelGeneration.
  ///
  /// In zh, this message translates to:
  /// **'取消生成'**
  String get cancelGeneration;

  /// No description provided for @generateEntry.
  ///
  /// In zh, this message translates to:
  /// **'生成探索入口'**
  String get generateEntry;

  /// No description provided for @layoutTopic.
  ///
  /// In zh, this message translates to:
  /// **'布局与尺寸'**
  String get layoutTopic;

  /// No description provided for @asyncTopic.
  ///
  /// In zh, this message translates to:
  /// **'异步与并发'**
  String get asyncTopic;

  /// No description provided for @networkTopic.
  ///
  /// In zh, this message translates to:
  /// **'网络与设备'**
  String get networkTopic;

  /// No description provided for @preparingDiscovery.
  ///
  /// In zh, this message translates to:
  /// **'正在为你整理探索方向…'**
  String get preparingDiscovery;

  /// No description provided for @discoveryResults.
  ///
  /// In zh, this message translates to:
  /// **'为这次好奇，找到入口'**
  String get discoveryResults;

  /// No description provided for @fixedReplay.
  ///
  /// In zh, this message translates to:
  /// **'固定回放'**
  String get fixedReplay;

  /// No description provided for @clearLocalFilter.
  ///
  /// In zh, this message translates to:
  /// **'清除本地过滤，恢复完整推荐'**
  String get clearLocalFilter;

  /// No description provided for @replayChinese.
  ///
  /// In zh, this message translates to:
  /// **'教学回放内容为中文；模型或外部内容保留原文。'**
  String get replayChinese;

  /// No description provided for @noOpenPlatforms.
  ///
  /// In zh, this message translates to:
  /// **'当前没有开放的目标平台'**
  String get noOpenPlatforms;

  /// No description provided for @estimatedTime.
  ///
  /// In zh, this message translates to:
  /// **'预计 {count} 分钟 · {status}'**
  String estimatedTime(int count, String status);

  /// No description provided for @policyVersion.
  ///
  /// In zh, this message translates to:
  /// **'政策版本：{version}'**
  String policyVersion(String version);

  /// No description provided for @currentPlatform.
  ///
  /// In zh, this message translates to:
  /// **'当前平台：{platform}'**
  String currentPlatform(String platform);

  /// No description provided for @openPlatforms.
  ///
  /// In zh, this message translates to:
  /// **'已开放平台：{platforms}'**
  String openPlatforms(String platforms);

  /// No description provided for @localFilter.
  ///
  /// In zh, this message translates to:
  /// **'本地过滤：{label}'**
  String localFilter(String label);

  /// No description provided for @windowError.
  ///
  /// In zh, this message translates to:
  /// **'窗口操作失败：{message}'**
  String windowError(String message);

  /// No description provided for @otherData.
  ///
  /// In zh, this message translates to:
  /// **'其他本地数据：Android 可在系统应用设置清除应用数据；Web 可在浏览器清除站点数据。Windows 的应用重置取决于安装方式；macOS 卸载应用不保证清除全部偏好及网页数据。清理前请确认需要保留的内容。'**
  String get otherData;

  /// No description provided for @thirdPartyData.
  ///
  /// In zh, this message translates to:
  /// **'第三方数据：停止生成、断开连接或离开模块可停止后续操作。已发送给模型、网页或 Hub 的数据需按服务方规则管理，清除本地数据不会删除服务端数据。'**
  String get thirdPartyData;

  /// No description provided for @concept0.
  ///
  /// In zh, this message translates to:
  /// **'像素'**
  String get concept0;

  /// No description provided for @concept1.
  ///
  /// In zh, this message translates to:
  /// **'纹理'**
  String get concept1;

  /// No description provided for @concept2.
  ///
  /// In zh, this message translates to:
  /// **'片元着色器'**
  String get concept2;

  /// No description provided for @concept3.
  ///
  /// In zh, this message translates to:
  /// **'局部坐标'**
  String get concept3;

  /// No description provided for @concept4.
  ///
  /// In zh, this message translates to:
  /// **'颜色规则'**
  String get concept4;

  /// No description provided for @concept5.
  ///
  /// In zh, this message translates to:
  /// **'UV 比例'**
  String get concept5;

  /// No description provided for @concept6.
  ///
  /// In zh, this message translates to:
  /// **'声明式 UI'**
  String get concept6;

  /// No description provided for @concept7.
  ///
  /// In zh, this message translates to:
  /// **'Widget 树'**
  String get concept7;

  /// No description provided for @concept8.
  ///
  /// In zh, this message translates to:
  /// **'Element 树'**
  String get concept8;

  /// No description provided for @concept9.
  ///
  /// In zh, this message translates to:
  /// **'生命周期'**
  String get concept9;

  /// No description provided for @concept10.
  ///
  /// In zh, this message translates to:
  /// **'单订阅'**
  String get concept10;

  /// No description provided for @concept11.
  ///
  /// In zh, this message translates to:
  /// **'广播流'**
  String get concept11;

  /// No description provided for @concept12.
  ///
  /// In zh, this message translates to:
  /// **'Stream 变换'**
  String get concept12;

  /// No description provided for @concept13.
  ///
  /// In zh, this message translates to:
  /// **'性能优化'**
  String get concept13;

  /// No description provided for @concept14.
  ///
  /// In zh, this message translates to:
  /// **'多任务'**
  String get concept14;

  /// No description provided for @concept15.
  ///
  /// In zh, this message translates to:
  /// **'进度上报'**
  String get concept15;

  /// No description provided for @concept16.
  ///
  /// In zh, this message translates to:
  /// **'暂停/恢复'**
  String get concept16;

  /// No description provided for @concept17.
  ///
  /// In zh, this message translates to:
  /// **'状态提升'**
  String get concept17;

  /// No description provided for @concept18.
  ///
  /// In zh, this message translates to:
  /// **'依赖注入'**
  String get concept18;

  /// No description provided for @concept19.
  ///
  /// In zh, this message translates to:
  /// **'作用域'**
  String get concept19;

  /// No description provided for @concept20.
  ///
  /// In zh, this message translates to:
  /// **'键值存储'**
  String get concept20;

  /// No description provided for @concept21.
  ///
  /// In zh, this message translates to:
  /// **'异步读取'**
  String get concept21;

  /// No description provided for @concept22.
  ///
  /// In zh, this message translates to:
  /// **'状态恢复'**
  String get concept22;

  /// No description provided for @concept23.
  ///
  /// In zh, this message translates to:
  /// **'测试替身'**
  String get concept23;

  /// No description provided for @concept24.
  ///
  /// In zh, this message translates to:
  /// **'动画控制'**
  String get concept24;

  /// No description provided for @concept25.
  ///
  /// In zh, this message translates to:
  /// **'手势检测'**
  String get concept25;

  /// No description provided for @concept26.
  ///
  /// In zh, this message translates to:
  /// **'吸附算法'**
  String get concept26;

  /// No description provided for @concept27.
  ///
  /// In zh, this message translates to:
  /// **'状态管理'**
  String get concept27;

  /// No description provided for @concept28.
  ///
  /// In zh, this message translates to:
  /// **'Tween 动画'**
  String get concept28;

  /// No description provided for @concept29.
  ///
  /// In zh, this message translates to:
  /// **'动画配置'**
  String get concept29;

  /// No description provided for @concept30.
  ///
  /// In zh, this message translates to:
  /// **'字重'**
  String get concept30;

  /// No description provided for @concept31.
  ///
  /// In zh, this message translates to:
  /// **'字距'**
  String get concept31;

  /// No description provided for @concept32.
  ///
  /// In zh, this message translates to:
  /// **'字体 fallback'**
  String get concept32;

  /// No description provided for @concept33.
  ///
  /// In zh, this message translates to:
  /// **'平台字体'**
  String get concept33;

  /// No description provided for @concept34.
  ///
  /// In zh, this message translates to:
  /// **'中台复用'**
  String get concept34;

  /// No description provided for @concept35.
  ///
  /// In zh, this message translates to:
  /// **'交互事件'**
  String get concept35;

  /// No description provided for @concept36.
  ///
  /// In zh, this message translates to:
  /// **'工作流'**
  String get concept36;

  /// No description provided for @concept37.
  ///
  /// In zh, this message translates to:
  /// **'能力注册'**
  String get concept37;

  /// No description provided for @concept38.
  ///
  /// In zh, this message translates to:
  /// **'输入 Schema'**
  String get concept38;

  /// No description provided for @concept39.
  ///
  /// In zh, this message translates to:
  /// **'执行租约'**
  String get concept39;

  /// No description provided for @concept40.
  ///
  /// In zh, this message translates to:
  /// **'运行事件'**
  String get concept40;

  /// No description provided for @concept41.
  ///
  /// In zh, this message translates to:
  /// **'扫光'**
  String get concept41;

  /// No description provided for @concept42.
  ///
  /// In zh, this message translates to:
  /// **'场景选择'**
  String get concept42;

  /// No description provided for @concept43.
  ///
  /// In zh, this message translates to:
  /// **'视觉调优'**
  String get concept43;

  /// No description provided for @concept44.
  ///
  /// In zh, this message translates to:
  /// **'轨道相机'**
  String get concept44;

  /// No description provided for @concept45.
  ///
  /// In zh, this message translates to:
  /// **'部件聚焦'**
  String get concept45;

  /// No description provided for @concept46.
  ///
  /// In zh, this message translates to:
  /// **'二维滚动'**
  String get concept46;

  /// No description provided for @concept47.
  ///
  /// In zh, this message translates to:
  /// **'固定表头'**
  String get concept47;

  /// No description provided for @concept48.
  ///
  /// In zh, this message translates to:
  /// **'拦截器'**
  String get concept48;

  /// No description provided for @concept49.
  ///
  /// In zh, this message translates to:
  /// **'Token 刷新'**
  String get concept49;

  /// No description provided for @concept50.
  ///
  /// In zh, this message translates to:
  /// **'重试机制'**
  String get concept50;

  /// No description provided for @concept51.
  ///
  /// In zh, this message translates to:
  /// **'接口绑定'**
  String get concept51;

  /// No description provided for @concept52.
  ///
  /// In zh, this message translates to:
  /// **'TCP 字节流'**
  String get concept52;

  /// No description provided for @concept53.
  ///
  /// In zh, this message translates to:
  /// **'资源释放'**
  String get concept53;

  /// No description provided for @concept54.
  ///
  /// In zh, this message translates to:
  /// **'超时与取消'**
  String get concept54;

  /// No description provided for @concept55.
  ///
  /// In zh, this message translates to:
  /// **'证据边界'**
  String get concept55;

  /// No description provided for @concept56.
  ///
  /// In zh, this message translates to:
  /// **'平台接口'**
  String get concept56;

  /// No description provided for @concept57.
  ///
  /// In zh, this message translates to:
  /// **'能力查询'**
  String get concept57;

  /// No description provided for @concept58.
  ///
  /// In zh, this message translates to:
  /// **'类型化结果'**
  String get concept58;

  /// No description provided for @concept59.
  ///
  /// In zh, this message translates to:
  /// **'系统变化'**
  String get concept59;

  /// No description provided for @concept60.
  ///
  /// In zh, this message translates to:
  /// **'定期采样'**
  String get concept60;

  /// No description provided for @concept61.
  ///
  /// In zh, this message translates to:
  /// **'特征值属性'**
  String get concept61;

  /// No description provided for @concept62.
  ///
  /// In zh, this message translates to:
  /// **'通知订阅'**
  String get concept62;

  /// No description provided for @concept63.
  ///
  /// In zh, this message translates to:
  /// **'平台桥接'**
  String get concept63;

  /// No description provided for @concept64.
  ///
  /// In zh, this message translates to:
  /// **'扩展名过滤'**
  String get concept64;

  /// No description provided for @concept65.
  ///
  /// In zh, this message translates to:
  /// **'取消分支'**
  String get concept65;

  /// No description provided for @concept66.
  ///
  /// In zh, this message translates to:
  /// **'平台播放器'**
  String get concept66;

  /// No description provided for @concept67.
  ///
  /// In zh, this message translates to:
  /// **'HTTP 流'**
  String get concept67;

  /// No description provided for @concept68.
  ///
  /// In zh, this message translates to:
  /// **'播放控制'**
  String get concept68;

  /// No description provided for @concept69.
  ///
  /// In zh, this message translates to:
  /// **'倍速'**
  String get concept69;

  /// No description provided for @concept70.
  ///
  /// In zh, this message translates to:
  /// **'Controller 生命周期'**
  String get concept70;

  /// No description provided for @concept71.
  ///
  /// In zh, this message translates to:
  /// **'认证原因码'**
  String get concept71;

  /// No description provided for @concept72.
  ///
  /// In zh, this message translates to:
  /// **'凭据回退'**
  String get concept72;

  /// No description provided for @concept73.
  ///
  /// In zh, this message translates to:
  /// **'运行时权限'**
  String get concept73;

  /// No description provided for @concept74.
  ///
  /// In zh, this message translates to:
  /// **'授权状态'**
  String get concept74;

  /// No description provided for @concept75.
  ///
  /// In zh, this message translates to:
  /// **'通知投递'**
  String get concept75;

  /// No description provided for @concept76.
  ///
  /// In zh, this message translates to:
  /// **'加载进度'**
  String get concept76;

  /// No description provided for @startupLoading.
  ///
  /// In zh, this message translates to:
  /// **'正在加载应用…'**
  String get startupLoading;

  /// No description provided for @startupReload.
  ///
  /// In zh, this message translates to:
  /// **'重新加载'**
  String get startupReload;

  /// No description provided for @startupTimeout.
  ///
  /// In zh, this message translates to:
  /// **'加载超时，请检查网络后重试。'**
  String get startupTimeout;

  /// No description provided for @startupFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载失败，请重新加载。'**
  String get startupFailed;

  /// No description provided for @startupResources.
  ///
  /// In zh, this message translates to:
  /// **'正在加载 Flutter 资源…'**
  String get startupResources;

  /// No description provided for @startupEngine.
  ///
  /// In zh, this message translates to:
  /// **'正在初始化渲染引擎…'**
  String get startupEngine;

  /// No description provided for @startupApp.
  ///
  /// In zh, this message translates to:
  /// **'正在启动学习目录…'**
  String get startupApp;

  /// No description provided for @modelServiceTitle.
  ///
  /// In zh, this message translates to:
  /// **'连接模型服务'**
  String get modelServiceTitle;

  /// No description provided for @modelServiceIntro.
  ///
  /// In zh, this message translates to:
  /// **'可连接单独启动的本机 Codex 桥接，使用已有 CLI 登录。也可连接兼容 Chat Completions 流式协议的服务。端点与模型名会记住，方便下次连接；临时令牌仅当前页面有效，离开后清除；浏览器端点需允许跨域。'**
  String get modelServiceIntro;

  /// No description provided for @modelDataNotice.
  ///
  /// In zh, this message translates to:
  /// **'真实生成会把你的问题、实验状态和必要上下文发送到所选服务，临时令牌用于请求认证。服务方的数据保留和使用方式请查看其隐私政策；固定回放无需发送模型请求。详见“关于”中的隐私说明。'**
  String get modelDataNotice;

  /// No description provided for @endpointLabel.
  ///
  /// In zh, this message translates to:
  /// **'完整端点 URL'**
  String get endpointLabel;

  /// No description provided for @endpointInvalid.
  ///
  /// In zh, this message translates to:
  /// **'请输入 HTTPS 端点或本机 HTTP 端点。'**
  String get endpointInvalid;

  /// No description provided for @modelName.
  ///
  /// In zh, this message translates to:
  /// **'模型名称'**
  String get modelName;

  /// No description provided for @modelNameRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入模型名称。'**
  String get modelNameRequired;

  /// No description provided for @modelToken.
  ///
  /// In zh, this message translates to:
  /// **'临时访问令牌（本机服务可留空）'**
  String get modelToken;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @useService.
  ///
  /// In zh, this message translates to:
  /// **'使用此服务'**
  String get useService;

  /// No description provided for @discoveryFailed.
  ///
  /// In zh, this message translates to:
  /// **'探索未完成，请检查输入或模型服务后重试。'**
  String get discoveryFailed;

  /// No description provided for @originalDetails.
  ///
  /// In zh, this message translates to:
  /// **'原始详情'**
  String get originalDetails;

  /// No description provided for @explorationRecords.
  ///
  /// In zh, this message translates to:
  /// **'查看探索记录'**
  String get explorationRecords;

  /// No description provided for @loadLanguageFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法读取已保存的语言，当前跟随系统。请选择语言以重新保存。'**
  String get loadLanguageFailed;

  /// No description provided for @versionInfo.
  ///
  /// In zh, this message translates to:
  /// **'版本信息'**
  String get versionInfo;

  /// No description provided for @versionLoading.
  ///
  /// In zh, this message translates to:
  /// **'正在读取安装版本…'**
  String get versionLoading;

  /// No description provided for @versionUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'暂时无法读取版本信息，请重试。'**
  String get versionUnavailable;

  /// No description provided for @versionRetry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get versionRetry;

  /// No description provided for @copyVersion.
  ///
  /// In zh, this message translates to:
  /// **'复制版本信息'**
  String get copyVersion;

  /// No description provided for @versionCopied.
  ///
  /// In zh, this message translates to:
  /// **'版本信息已复制'**
  String get versionCopied;

  /// No description provided for @versionCopyFailed.
  ///
  /// In zh, this message translates to:
  /// **'复制失败，请重试。'**
  String get versionCopyFailed;

  /// No description provided for @editionOffline.
  ///
  /// In zh, this message translates to:
  /// **'离线学习版'**
  String get editionOffline;

  /// No description provided for @editionFull.
  ///
  /// In zh, this message translates to:
  /// **'联网完整版'**
  String get editionFull;

  /// No description provided for @installedVersion.
  ///
  /// In zh, this message translates to:
  /// **'版本 {version} · 构建 {build}'**
  String installedVersion(String version, String build);

  /// No description provided for @offlineReplayExamples.
  ///
  /// In zh, this message translates to:
  /// **'选择一个固定示例，查看本地回放效果。'**
  String get offlineReplayExamples;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
