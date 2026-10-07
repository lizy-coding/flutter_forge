# App shell Agent guide

## 入口与归属

按根 AGENTS 与本目录 AI_ANALYSIS 阅读当前契约。bootstrap 解析进程平台与窗口参数；App 与 CategoryWindowApp 组合路由、主题和壳。模块入口与排除平台由 module_registry 声明，稳定路径通过 app_route_table 组装。

## 当前工作边界

- `theme/` 统一 AppTheme、ThemeExtension tokens、主题选择和持久化。主窗口与分类窗口使用同一主题来源；窗口参数和 method handler 的主题同步属于应用基础设施。
- 分类窗口的 router/controller/listener 绑定到窗口生命周期。关闭、重开、复用与主题同步必须释放旧对象，并区分单窗口移动/Web 与桌面分类窗口。
- Shell 只编排导航、搜索与平台说明，不接管 BLE 会话、扫描或设备权限。
- `shared/popup` 持有浮层归属与释放，`shared/table` 提供业务无关表格；页面通过现有边界复用，禁止复制底层生命周期实现。
- 当前未提交主题或 BLE 改动只表示工作区实现；读根 Git 差异与对应定向测试，不能推定它们已进入 tag 或已有真实设备闭环。

## 取证与验证

先读取变更命中的入口及主题/窗口依赖，使用明确文件列表调用 Hub 两张分析图。文档维护不触发全库扫描。实现变更优先运行 category_window_lifecycle、multi_window_manager、app_theme 和模块路由相关定向测试；完整质量门禁按根规则执行。
