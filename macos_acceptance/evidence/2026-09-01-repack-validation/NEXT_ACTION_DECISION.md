# macOS UI 验收结果分析与下一步决策

依据：

```text
macos_acceptance/evidence/2026-09-01-repack-validation/MACOS_UI_ACCEPTANCE_REPORT.json
macos_acceptance/evidence/2026-09-01-repack-validation/notes.md
```

## 结论

```json
{
  "macos_gate": "HOLD",
  "windows_ready": false,
  "next_action": "继续 macOS 多窗口 Engine 根因修复与真实交互验收",
  "windows_full_self_test": "NOT_READY",
  "responsive_status": "artifact_identity_pass_but_interaction_blocked",
  "remote_push": "FORBIDDEN"
}
```

## 证据摘要

```text
fresh_artifact: PASS
artifact_identity: PASS
source_head: ce814fbc249bd3c36ca5ab41151bb29fe70cc980
executable_mtime: 2026-08-31T14:34:21+08:00
executable_sha256: e435751b987860f134ed7c903cf1ea2aebfcf15181fa64f2e3b44114b2ecb50e
quality_gate: PASS_6_OF_6
targeted_test: PASS_3_OF_3
```

## 阻断项

| id | condition | verdict | classification | action |
|---|---|---|---|---|
| B-001 | Invalid engine handle on both fresh-candidate startups | FAIL | macOS shared Engine/native lifecycle candidate | continue FIX; do not suppress logs |
| B-002 | Failed to send message to Flutter engine on both fresh-candidate startups | FAIL | desktop_multi_window startup broadcast candidate | continue FIX; reproduce by stage |
| B-003 | Codex Computer Use click pipe closed | BLOCKED | acceptance-tool/environment limitation | use functional desktop session or manual-assisted run |
| B-004 | Navigation/multi-window/file picker not actually operated | BLOCKED | missing interaction evidence | do not infer PASS |
| B-005 | Responsive artifact identity | PASS | artifact provenance | R2-R10 still require real interaction |

## macOS 是否需要继续优化

```json
{
  "code_optimization": "REQUIRED",
  "responsive_code_optimization": "NOT_BLOCKING_FROM_THIS_REPORT",
  "acceptance_process_optimization": "REQUIRED",
  "release_artifact_optimization": "NOT_REQUIRED_FOR_CURRENT_BLOCKER"
}
```

### 必须继续维护的代码方向

```text
1. desktop_multi_window 启动阶段注册广播时机
2. 失效 Engine 是否被 desktop_multi_window 通知
3. 主/子 Engine 的 plugin/channel 注册顺序
4. stale window registry 与 native controller 列表一致性
5. create/show/close/reopen 异步竞态
```

当前 Dart 侧 stale controller 修复已获得：

```text
- targeted_test: 3/3 PASS
- quality_gate: 6/6 PASS
```

但它不能解释启动前已出现的 Engine message 错误。因此该修复只能标记为局部正确，不能关闭 macOS 门禁。

## 是否启动 Windows 自测

```json
{
  "windows_preflight": "ALLOW",
  "windows_full_self_test": "HOLD",
  "windows_final_acceptance": "HOLD"
}
```

### 允许提前做的 Windows 工作

```text
1. 检查 Windows 测试机器、权限、Event Viewer 和 UI 自动化能力
2. 准备 setup.exe 及 SHA256
3. 确认 Windows 产物对应当前源码候选
4. 准备 windows_acceptance/evidence/<date>/ 目录
5. 预置安装、卸载、崩溃日志和截图采集流程
6. 确认 integration_test -d windows 的执行条件
```

### 当前禁止宣布或执行的 Windows 结论

```text
1. 不得宣布 Windows PASS
2. 不得宣布 Windows ready
3. 不得用 v1.2.2 旧产物验收当前响应式提交
4. 不得用 Windows 结果替代 macOS 多窗口证据
5. 不得在 macOS_GATE=HOLD 时执行 Windows 完整放行验收
```

## macOS 放行门槛

只有下列条件全部满足，才允许将 `windows_ready` 改为 `true`：

```text
M-01 fresh macOS artifact identity = PASS
M-02 startup x2 without Invalid engine handle = PASS
M-03 startup x2 without Failed to send message to Flutter engine = PASS
M-04 basic/state/platform three category windows = PASS
M-05 child file picker open + cancel/selection = PASS
M-06 same-category reuse = PASS
M-07 close + reopen >= 3 cycles = PASS
M-08 main window survives = PASS
M-09 responsive debounce_throttle 360/600/1024 = PASS
M-10 raw logs + screenshots complete = PASS
```

## 下一阶段执行顺序

```text
STEP-1 继续 macOS Engine 错误 FIX
STEP-2 本地 targeted test + quality_gate
STEP-3 重新构建最新 macOS Release
STEP-4 真实桌面会话执行 macOS 多窗口与 file_picker
STEP-5 真实桌面会话执行 debounce_throttle 响应式验收
STEP-6 生成 MACOS_GATE=PASS/HOLD
STEP-7 仅当 PASS 时准备并启动 Windows 完整自测
```

## 不应做的优化

```text
- 不要为了通过验收过滤 Engine 错误日志
- 不要把无 crash report 当成 Engine 安全证明
- 不要继续修改已通过的 debounce_throttle 响应式代码，除非真实视口测试发现新缺陷
- 不要重做 LearningScaffold 全局响应式封装
- 不要修改 NavigationPolicy 600dp 语义
- 不要恢复 Windows USB
- 不要提前实施无障碍第二阶段
- 不要推送远端
```

## 最终决策

```text
macOS 产物：PASS
macOS 自动化可用性：BLOCKED
macOS Engine 日志：FAIL
macOS 多窗口功能：未完成验证
macOS 响应式功能：产物已包含当前代码，但真实交互未完成
MACOS_GATE：HOLD
Windows preflight：可以准备
Windows full self-test：暂缓
Windows ready：false
下一步：继续 macOS Engine 修复 + 获取可用真实桌面交互通道
```
