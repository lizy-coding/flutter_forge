# Android 演示项目现状与维护建议

2026-11-07 修订。用户明确：这是演示项目，不是做题或课程项目。此前“三个短实验打样”“核对提示/完成规则”等演进任务来自过度推导，现已撤回，不作为后续开发清单。

## 定位与证据范围

项目展示 Flutter 功能、平台能力及实现效果。现有学习目标、代码说明和示例操作是演示内容，不据此推导出课程、练习判定、进度或掌握程度等需求，也不安排跨模块教学改造。

本轮仅重新核对当前源码、4010候选包报告及已存在问题，未修改功能代码、未新增需求或重新执行测试。此前离线配置19项定向测试和完整门禁通过的证据仍按其运行范围解释；4010新包实际安装验收仍未完成，不借此扩大平台结论。

## 当前已具备

首页搜索前置、分类与最近访问；关于页版本信息复制；框架/目录双语与中文演示内容边界；35个模块的注册与稳定路由。已有功能应先验收收尾，不重复安排开发。

## 有现状依据的建议

| 顺序 | 建议 | 现有依据 | 边界 |
| --- | --- | --- | --- |
| 先交付 | 完成4010真机覆盖安装、搜索、返回、语言切换和版本复制核对 | .release/search-version-20261106/result.json的actual_device仍未连接 | 是已实现功能验收，不是新功能 |
| 修正明确问题 | 本地持久化演示检查写入/删除返回值，提供失败反馈；“清除全部本地数据”改为准确的本演示范围 | persistence_demo_controller.dart忽略bool，clearAll仅删除3个模块键；module_root.dart仍显示“全部本地数据” | 只修已有功能，不改造成练习流程 |
| 整理离线展示（可选） | 将仅有的3类固定回放以示例选择为主，避免自由提问外观造成能力误解 | module_discovery_replay.dart仅接受3类示例，其他输入报不支持；离线版不能连接模型 | 保留回放展示，不增加推荐算法或AI服务 |
| 收紧打包校验 | 明确build-number参数与最终APK versionCode的区别，按实际APK值核对递增 | build_vivo_offline.py前置比较输入值，后续读取实际值但未再次核对；本次2010得到4010 | 不改变发行格式或签名流程；当前尚未改动 |
| 完成材料核对 | 核对公开隐私链接、新图标截图、版本说明与最终APK一致性 | 4010 manifest公开URL未登记，device_acceptance为pending | 不推断商店已通过/被拒 |

源码入口：
- apps/flutter_forge/lib/app/learning_home_page.dart
- apps/flutter_forge/lib/app/app_version_panel.dart
- apps/flutter_forge/lib/modules/state/local_persistence/state/persistence_demo_controller.dart
- apps/flutter_forge/lib/modules/state/local_persistence/module_root.dart
- apps/flutter_forge/lib/app/module_discovery_replay.dart
- tool/build_vivo_offline.py

## 版本演进建议

近期版本以现有演示可正常打开、操作、退出，反馈真实且包来源清楚为完成标准。没有证据要求马上增加收藏、筛选、课程或批量重排模块。

后续只有在实际展示中出现明确问题时再决定增强，例如固定回放容易被误认为自由问答时调整入口；已有演示展示不清楚时定点优化该页面。新增模块需要实际展示诉求，不预设数量、周期或学习验证目标。

具体收敛计划见 [Android演示与版本号收敛计划](ANDROID_DEMO_VERSION_CONVERGENCE.md)。该计划尚未实施。
