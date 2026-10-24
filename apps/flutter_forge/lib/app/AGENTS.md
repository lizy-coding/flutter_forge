# App shell Agent guide

## 入口与归属

按根 AGENTS 与本目录 AI_ANALYSIS 阅读当前契约。bootstrap 解析进程平台与窗口参数；App 与 CategoryWindowApp 组合路由、主题和壳。模块入口与排除平台由 module_registry 声明，稳定路径通过 app_route_table 组装。

## 当前工作边界

- `theme/` 统一 AppTheme、ThemeExtension tokens、主题选择和持久化。主窗口与分类窗口使用同一主题来源；窗口参数和 method handler 的主题同步属于应用基础设施。
- 桌面主框架遵循 ADR 0016：macOS/Windows 共用 Flutter 渲染、约 48dp单行沉浸式标题栏、平台原生窗口按钮和两层分类／模块侧栏；平台宿主提供原生窗口按钮、窗口操作与等价系统命令，不再保留独立 AppKit导航工具栏。
- 交互以 ADR 0018 为准：桌面基础导航页面默认系统材质、跟随系统明暗；教学正文、实验与侧栏实色，标题栏最低强度。页面职责不能按 URL 段数推断。DesktopWindowHost 按所属窗口提供 macOS 系统模糊、Windows 公开 Mica 接口与实色降级；Mica 不宣传为窗口后透视。用户实色偏好与系统关闭透明／高对比度优先，材质变化不得重建路由。
- 候选 flutter_acrylic 的 macOS 依赖存在进程级主窗口绑定，本轮采用现有每引擎宿主的窄材质适配，不新增依赖。后续引入插件须先验证主窗口、分类窗口和每引擎绑定；DesktopWindowHost 继续拥有窗口控制。liquid_glass_easy 只提供应用内部玻璃，原生浮层必须保持文字可读。
- macOS 原生材质放入 contentView 内、位于 Flutter 视图下方，装饰视图的 hitTest 必须返回 nil，窗口保留实体输入背景。按钮验收必须包含真实坐标鼠标操作与页面／状态变化，辅助功能触发和 WidgetTester.tap 不能替代原生输入验收。
- macOS 新窗口先配置启动背景、注册插件／宿主与窗口定义，再显示并设为 key；Dart configure 握手前不主动向子引擎发消息。不可对 FlutterAppDelegate 未实现的可选生命周期方法调用 super；原生异常须查系统日志，不能仅凭 Dart 无错误认定正常。
- 工作台与 Web／移动首页记录最近访问的模块入口，四端搜索统一匹配标题、简介、分类与概念；同会话返回保留检索词、分类与滚动位置。记录不代表学习进度或任务恢复，单个当前模块经稳定路由切换，不建立多标签保活。
- Web／移动首页按搜索、分类、最近访问组织，作者资料进入关于；移动以快速查阅为主，不新增底部标签栏。Web 保留稳定 URL、前进后退和显式新标签页操作。本期修改入口、导航、表面和阅读容器，教学内容复用、模块内部重排另行推进；基本阅读和操作溢出纳入本期。
- DesktopWindowHost 对接每引擎窗口命令与状态；主窗口关闭退出应用，分类窗口关闭仅影响自身。macOS 在左侧预留原生红黄绿按钮，Windows 在右侧预留原生窗口按钮并交还系统命中与 Snap；桌面窗口保留系统缩放边界，标题栏空白区支持拖拽，双击遵循系统习惯，独立全屏入口切换真实全屏／窗口模式；主页按钮进入当前窗口根路由，交互控件不得成为拖动热区。
- 分类窗口的 router/controller/listener 绑定到窗口生命周期。关闭、重开、复用与主题同步必须释放旧对象，并区分单窗口移动/Web 与桌面分类窗口。
- Shell 只编排导航、搜索与平台说明，不接管 BLE 会话、扫描或设备权限。
- `shared/popup` 持有浮层归属与释放，`shared/table` 提供业务无关表格；页面通过现有边界复用，禁止复制底层生命周期实现。
- 当前未提交主题或 BLE 改动只表示工作区实现；读根 Git 差异与对应定向测试，不能推定它们已进入 tag 或已有真实设备闭环。

## 取证与验证

本期收尾记录见 `docs/desktop_workbench_phase1_20261017.md`：用户确认 macOS 手工验收通过，Windows 构建和主机操作单独待验收；该记录仅对应当时未提交工作区，不代表发布版本或读屏专项通过。

ADR 0018 本轮实现及当前 Mac 的集成／Release 窗口验收见 `docs/reports/PLATFORM_INTERACTION_MACOS_ACCEPTANCE-20261021.md`。Windows、Android 与 Safari 的未执行项目按该记录范围解释，不引用 macOS 结果替代。

先读取变更命中的入口及主题/窗口依赖，使用明确文件列表调用 Hub 两张分析图。文档维护不触发全库扫描。实现变更优先运行 category_window_lifecycle、multi_window_manager、app_theme、desktop_workbench 和模块路由相关定向测试；完整质量门禁按根规则执行。
