# CI/CD 门禁修整与人工验收清单

日期：2026-10-10。范围：用户批准的 packaging_change。当前基线为 dev 的 HEAD `75a57d1cdab644d3499f77eade3f1c668acbec83` 加当前未提交工作区；电池与 USB 的原有改动继续保留。本报告不代表 tag、远端工作流或真实设备验收。

## 实施结果

FlutterGuard 不再属于依赖解析、提交、CI、打包或发布的强制要求。应用依赖、锁文件、pre-commit、旧扫描配置、生成器的强制工具 pin 和当前规则声明均已移除；历史报告中的 FlutterGuard 证据保持原样。

基础门禁由 `tool/quality_gate.sh` 统一执行五阶段：

1. 生成器只读 `--check` 与契约校验，覆盖全部生成输出及 workspace 包契约。
2. Dart 只读格式检查，格式不合规失败，不要求工作区已提交。
3. bare `flutter analyze`，所有 issue 阻断。
4. 从 workspace 成员执行全部 Flutter 测试，再执行 Node 工具测试和 Dart scaffold 验收脚本；缺失测试或空测试文件不记为 PASS。
5. 测试布局与模块准入校验。允许同一模块目录内组织多个行为测试；当前 27 个模块均有测试，无存量豁免。

各包继承官方 lint 基础配置，并新增 unawaited_futures、discarded_futures、cancel_subscriptions、close_sinks。后台操作用 unawaited 显式表达原有调度意图；教学时序和静态分析无法追踪的所有权转移使用有说明的局部例外。新 lint 不代表生命周期竞态、原生句柄或设备功能已经验收。

模块间依赖、模块到 app 的依赖、shared 到 app/modules 的依赖由项目生成器检查；有临时 fixture 反向测试。多窗口包原有空 main 测试已补成原生通道行为测试。

## CI/CD 行为

- CI 保留 `quality-gate` 检查名和 dev/master 的 push、PR 触发条件。
- Pages、Cloudflare 和两条安装包工作流依赖同一次运行中的可复用质量门禁。Cloudflare 的原部署开关保留。
- 可复用门禁输出实际验证的 SHA；安装包 job 显式 checkout 该 SHA。
- release_metadata 校验应用版本、tag、SHA、干净源码，以及 tag 提交属于 origin/master；无 tag 的手动构建只形成候选产物。
- 四个平台上传版本化产物，以及平台独立的 RELEASE_MANIFEST 和 SHA256SUMS；包含源码 SHA、run ID、模式、签名声明、大小及哈希。文件名避免多平台下载合并时覆盖。
- macOS x64 显式使用 macos-15-intel，并检查应用二进制包含 x86_64；Windows 检查 runner 的 PE x64 标识及安装器版本；Android 检查 ARM64 native 库并统一为 debug APK。
- GitHub Release 正式发布仍归 Agent Hub 所有；业务仓库工作流只有 contents:read，不含 Release 发布步骤。

## 本地验证

- 完整五阶段门禁：PASS。
- bare Flutter analyze：无 issue。
- workspace Flutter 测试：主应用 236、文件选择 8、IoC 22、多窗口 3、电池 95、USB 3，共 367 个通过。
- Node 工具与发布身份测试：22 个通过；Dart scaffold 验收：PASS。
- 模块测试布局：27/27。
- Web release 构建及现有启动壳、本地 CanvasKit、可控媒体产物验证：PASS。
- actionlint 1.7.12：所有六个工作流通过；Shell 语法与 git diff --check：PASS。
- offline pub get --enforce-lockfile：PASS，移除工具无需升级保留依赖。
- 发布身份反向 fixture：版本不匹配、SHA 不匹配、dirty 源码、tag 位于稳定分支外、空产物与错误格式均阻断。

## 人工与远端验收：PENDING

本轮没有提交、推送、部署或发布。后续必须在对应提交上记录：

1. 推送 dev 后 CI 和 Pages 都成功，Pages 的 build/deploy 不早于其 quality job 成功。
2. 用受控失败提交确认质量失败时部署和打包不执行；手动触发不能绕过同样规则。
3. tag/版本错误被阻断，四平台构建成功，下载的产物与 manifest 哈希一致。
4. DMG 打开、Windows 安装器启动、Android debug 安装与 Web 浏览器冒烟按平台分别验收。
5. Agent Hub 接收版本化产物后冻结最终发布 manifest；构建成功不替代真实主机/设备验收。

macOS 本机 Xcode license 尚未接受；本轮未取得本机原生构建证据。Windows、Android 的实际打包和签名检查由对应远端 runner 验证。

## 官方依据

- [Dart 只读格式检查](https://dart.dev/tools/dart-format)
- [Flutter 测试分层](https://docs.flutter.dev/testing/overview)
- [Future 等待意图](https://dart.dev/tools/linter-rules/unawaited_futures)
- [同步函数中的 Future](https://dart.dev/tools/linter-rules/discarded_futures)
- [订阅取消及局限](https://dart.dev/tools/linter-rules/cancel_subscriptions)
- [Sink 关闭及局限](https://dart.dev/tools/linter-rules/close_sinks)
- [GitHub 可复用工作流](https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows)
- [GitHub runner 架构](https://github.com/actions/runner-images)
