# Flutter Forge Product Context

记录 Flutter Forge 在新增学习模块前必须保持一致的产品与架构语言。

## Language

**PC 封板**:
完成 macOS/Windows 的导航、窗口、平台能力、测试和构建验收后，才允许无额外限制地扩展 PC 业务。
_Avoid_: 全平台封板、Android 已完成

**Android 兼容轨道**:
面向 Android 的并行建设线，不阻塞当前 PC 封板，但必须保持可构建、单窗口和明确的平台不可用状态。
_Avoid_: Android 封板

**业务模块**:
一个具有学习入口、课程元数据、教学内容和独立测试的可注册学习单元。
_Avoid_: demo、页面示例

**分类窗口**:
桌面大屏上承载一个学习分类的独立窗口；它属于导航基础设施，不属于业务模块。
_Avoid_: 业务窗口、模块窗口

**模块准入**:
新业务模块进入主分支前必须满足模块契约、测试和 Agent Hub 路径治理要求。
_Avoid_: 直接注册、手工接入
