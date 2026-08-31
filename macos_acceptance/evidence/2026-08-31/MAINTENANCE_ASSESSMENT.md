# macOS 验收后续维护评估

日期：2026-08-31 记录复核
依据：`macos_acceptance/evidence/2026-08-31/notes.md`

## 结论

需要进一步维护代码，但当前应先创建独立的多窗口稳定性修复/复现任务，不应把问题归入响应式布局改造。

### 需要维护的原因

记录中两次启动均出现：

```text
Invalid engine handle
Failed to send message to Flutter engine on channel 'mixin.one/desktop_multi_window'
```

这属于桌面多窗口 Engine 生命周期或消息发送路径的真实代码维护候选。主窗口仍存活、没有 `.crash` 文件，不能抵消该错误。

### 暂不判定为响应式代码缺陷的原因

当前 Release bundle 的修改时间为：

```text
2026-08-27 17:57:14 CST
```

响应式提交 `ce814fbc249bd3c36ca5ab41151bb29fe70cc980` 的提交时间为：

```text
2026-08-31 12:57:13 +08:00
```

因此响应式模块验收结果应保持：

```text
R1-R10：NOT_IN_ARTIFACT
H1-H10：NOT_IN_ARTIFACT 或 BLOCKED
```

不能用旧 Release 的界面结果判断 `debounce_throttle` 新代码。

## 问题分类

| 现象 | 分类 | 是否需要代码维护 | 当前处理 |
|---|---|---:|---|
| 主窗口可启动并显示首屏 | 通过事实 | 否 | 保留 PASS |
| Computer Use 点击管道关闭 | 验收环境/工具限制 | 否，不能据此改源码 | 更新清单为 BLOCKED |
| 旧产物不含响应式提交 | 产物一致性问题 | 否 | R/H 标记 NOT_IN_ARTIFACT |
| Invalid engine handle | 多窗口 Engine 生命周期候选 | 是 | 创建独立 FIX 任务 |
| Failed to send message to Flutter engine | 多窗口通道/失效 Engine 候选 | 是 | 创建独立 FIX 任务 |
| 没有 macOS crash report | 非充分通过证据 | 否 | 不能覆盖 M13/M14 FAIL |
| Range probe HTTP 403 | 外部网络/资源条件 | 暂不 | 不据此判视频代码失败 |

## 建议的代码维护范围

独立任务应只围绕以下路径和行为展开：

```text
apps/flutter_forge/macos/Runner/AppDelegate.swift
apps/flutter_forge/macos/Runner/MainFlutterWindow.swift
apps/flutter_forge/lib/shared/multi_window/multi_window_manager.dart
apps/flutter_forge/lib/app/app_bootstrap.dart
```

重点核查：

```text
1. 主 Engine 和每个子 Engine 是否都完成 GeneratedPlugin 注册
2. 主 Engine 和每个子 Engine 是否都注册 file_picker_bridge 通道
3. onWindowsChanged 是否可能向已销毁 Engine 发送消息
4. 关闭窗口后 Dart 注册表是否及时移除 stale window
5. createCategoryWindow 前后的 WindowController 列表与本地注册表是否一致
6. show、关闭、重开之间是否存在异步消息竞态
7. 三个不同分类窗口并存时是否触发失效 Engine 广播
```

## 推荐复现矩阵

必须使用三个不同分类：

```text
基础机制
状态管理
网络与平台
```

执行阶段应分开采集日志：

```text
A. 仅启动主窗口
B. 打开第一个分类窗口
C. 打开第二个分类窗口
D. 打开第三个分类窗口
E. 重复打开已存在分类
F. 关闭一个分类窗口
G. 关闭全部分类窗口
H. 重新打开已关闭分类
I. 子窗口打开并取消 file_picker
```

每阶段记录：

```text
时间
主进程 PID
窗口 ID
分类
Console 原始日志
截图
是否出现 Invalid engine handle
是否出现 Failed to send message to Flutter engine
```

## 修复验收门槛

修复任务不能只依赖单次启动成功，必须满足：

```text
- 主窗口启动无目标引擎错误
- 三个不同分类窗口均可首帧显示
- 子窗口 file_picker 可打开并取消返回
- 同分类重复打开复用既有窗口
- 关闭后重开成功
- 连续打开/关闭/重开至少 3 轮
- 无 Invalid engine handle
- 无 Failed to send message to Flutter engine
- 无 EXC_BAD_ACCESS / SIGABRT
- 主窗口始终存活
```

## 自测清单已更新的内容

`macos_acceptance/MACOS_SELF_TEST_CHECKLIST.md` 已增加：

```text
1. 启动日志专项判定
2. 引擎错误与普通实验性日志的区分
3. M13/M14 失败时的代码维护判定
4. WindowController 与本地注册表一致性记录
5. 响应式产物 mtime、SHA256、HEAD 时间一致性校验
6. 自动化点击未生效时的 BLOCKED 规则
7. 本次 notes.md 对应的后续维护触发条件
```

## 最终状态

```text
多窗口代码维护：需要，待独立复现/FIX 任务
响应式代码维护：debounce_throttle 已有本地改动；本次 macOS 旧产物无法验收
自测清单：已更新
无障碍：仍为第二阶段，不因本次问题提前展开
远端推送：未执行，继续禁止
```
