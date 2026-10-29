# Windows MSIX 首次远端构建与仅本地修复

本轮遵从用户最后授权：只读查看 GitHub；有本次安装包则下载并测试，没有则仅本地修复；不提交、不推送、不触发重跑。
所有本轮修复均为未提交工作区修改，远端源码仍为 `226839a481737f276a3b462c527555a62cd76029`。

## 本次构建事实

- [Windows Store candidate / run 40673499706](https://github.com/lizy-coding/flutter_forge/actions/runs/40673499706)，应用版本 `1.2.10+5`。
- 首次延后轮询看到 CI 与 reusable quality 均成功、Windows package job 仍运行；后续十分钟轮询确认 package job 失败。
- [package job](https://github.com/lizy-coding/flutter_forge/actions/runs/40673499706/job/122769413156) 的原始日志：北京时间 18:54:04，`flutter build windows --release` 完成，生成 `build/windows/x64/runner/Release/flutter_forge.exe`，耗时 397.1s。
- 随后打包预检报错 `Not a Windows PE binary: .../data/app.so`，未执行 MakeAppx、签名或产物上传。
- GitHub artifacts API 实际返回 `total_count: 0`。本次没有可下载的 MSIX，也未用历史 EXE 替代本次安装验证。
- 虚拟机安装、启动、核心交互、卸载以及 WACK 均 **NOT_RUN**。Windows 编译通过不能代表这些行为通过。

本地原始证据：

- `/private/tmp/forge-windows-run-40673499706-status.json`
- `/private/tmp/forge-windows-run-40673499706-failed.log`

## 根因与本地修改

`tool/windows_store.py` 之前把 `.exe/.dll/.so` 全部按 PE 检查；原测试也错误地把 `data/app.so` 伪造成 PE，因此没有覆盖真实 AOT 快照格式。
当前安装的 Flutter 源码 `packages/flutter_tools/lib/src/build_system/targets/windows.dart` 将 WindowsAotBundle 委托给 AotElfRelease；
`lib/src/base/build.dart` 使用 `--snapshot_kind=app-aot-elf --elf=.../app.so`。
[Dart ELF 头写入实现](https://github.com/dart-lang/sdk/blob/3.11.5/runtime/vm/elf.cc) 也明确区分 ELF64、小端、ET_DYN 与 EM_X86_64。

仅在本地修改：

1. EXE/DLL 和 VC runtime 继续使用 x64 PE 检查；只对固定路径 `data/app.so` 使用 64 位小端 x64 AOT ELF 头检查，并保持原字节复制。
2. 替换错误的 PE 快照 fixture，新增拒绝 ARM64、32 位、错误端序、PE 冒充快照及截断 ELF 的回归测试。
3. 修复先前本机全量门禁发现的 Dio 租约测试偶发模拟 500：通过已有 `createServer` 注入零随机失败、零教学延迟的测试服务器，移除 blanket retry。生产教学 MockServer 的默认随机失败率和行为不变。
4. 同步 MSIX README 的格式检查说明。

## 验证范围

- 修复前，使用 ELF 的 payload 回归实际复现相同的 PE 校验错误，日志 `/private/tmp/forge-msix-elf-regression-before.log`。
- 修复后，10 项 Python 打包测试通过，日志 `/private/tmp/forge-msix-elf-regression-after.log`。这是格式与 staging fixture 验证，不执行 Windows SDK。
- Dio 会话定向测试 3 项通过，日志 `/private/tmp/forge-dio-session-deterministic-20261028.log`。
- 完整质量门禁通过：生成物无漂移、只读格式、bare Flutter analyze、workspace/tool 全量测试与模块测试存在性全部 PASS，命令退出码 0。日志 `/private/tmp/forge-msix-local-only-quality-20261028.log`。
- 最终 `git diff --cached --quiet` 返回 0，本轮修复未暂存；本地 HEAD 与只读查询到的远端 dev 均为 `226839a481737f276a3b462c527555a62cd76029`，没有新增提交或推送。

未推送修复，所以远端仍会在原校验处失败；本地测试通过不等于新的 Windows MSIX 已构建或安装通过。
后续只有获得新的远端写入授权后，才能推送修复并重新验证 MakeAppx、签名、产物下载与虚拟机测试；本轮不执行这些动作。
