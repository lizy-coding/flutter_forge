# Windows Microsoft Store 分发准备（2026-10-28）

源码起点：`dev` / `3fc98c422a0b391a82d1d5d3994bc41d34fc2a56`，版本 `1.2.10+5`。
工作区已有大量未提交的平台、Android 离线版及自动化改动；本轮只新增 MSIX 准备工具、配置与说明。
没有提交、推送、注册账号、上传商店或发布。

## 本轮交付

- `tool/windows_store.py`：跨平台 manifest/图标预览，Windows 上从当前源码构建 x64 Release 并用 MakeAppx 打包。
- `tool/windows_store_test.py`：身份、版本、XML 转义、图标尺寸、PE 架构、必要 payload、私有符号排除、失败报告及不覆盖保护。
- `tool/windows_store_requirements.txt`：独立打包工具的 Pillow 依赖，不增加应用依赖。
- `apps/flutter_forge/windows/store/identity.example.json`：空正式身份模板；展示名草案 `Flutter Forge by Forest`，发布者草案 `Forest`。
- 同目录 README：注册、构建、测试签名、安装、基本启动、卸载、真机冒烟、WACK 及提交准备步骤。

现有 Windows 安装源实际为 `windows/installer/setup.iss`（Inno Setup）。
MSIX 为独立候选路径，未修改原有 EXE 工作流、CI、门禁脚本或 Agent Hub 冻结发布 manifest。
不代表 MSIX 已接入正式 release-hosting 流程。

## 实际验证

| 范围 | 结果 | 证据与边界 |
| --- | --- | --- |
| MSIX 准备工具定向测试 | PASS，9 项 | `PYTHONDONTWRITEBYTECODE=1 python3 tool/windows_store_test.py`；含 fixture，不执行 Windows SDK |
| manifest/图标预览 | PASS | `/private/tmp/forge-store-preview-20261028/`，本地测试身份，版本 `1.2.10.0`；图标沿用现有 Windows ICO |
| 完整质量门禁 | PASS | `/private/tmp/forge-store-quality-20261028-authorized.log`；生成物、只读格式、bare analyze、workspace/tool tests、模块测试存在性均通过 |
| Windows 11 ARM 虚拟机 | 已启动并进入 PowerShell | VMware Fusion，用户 `forest`；只做环境检查，不是应用启动证据 |
| Windows Release/MSIX 构建 | BLOCKED | PowerShell 未找到 Flutter/Git；Python 显示 WindowsApps 入口，未确认为可用解释器；常规 Program Files 目录未发现 Visual Studio C++ / Windows SDK |
| MSIX 安装、应用启动、卸载 | NOT_RUN | 未生成本轮 Windows 包，未创建或信任证书，未改变系统签名策略 |
| WACK、真机冒烟、商店审核 | NOT_RUN | 后续分层执行，不能由本机测试或虚拟机环境检查替代 |

首次门禁在受限沙箱内因 Flutter 无法更新仓库外 SDK 缓存而未能启动格式/分析/Flutter 测试；
获得该门禁命令的执行权限后原样重跑通过，没有降低检查标准。
原始失败日志：`/private/tmp/forge-store-quality-20261028.log`。

Agent Hub `agent-context --project flutter-forge` 返回 PARTIAL（无 blocker、11 个证据缺口）；
只用于身份和定点来源定位，不作为构建或发布授权，也不计入平台验收。

## 后续顺序

用户明确本轮虚拟机仅需跑通基本流程，下一步再完善冒烟并使用真机测试。

1. 补齐或连接已有 Flutter 3.47.2、Git、Python、Visual Studio C++ 和 Windows SDK 的 Windows 环境。
2. 用独立本地测试身份构建；如需创建测试证书及信任，单独确认测试环境设置。
3. 在虚拟机完成安装 → 开始菜单启动 → 首页/确定性模块 → 关闭 → 再启动 → 卸载，记录包哈希与客户机架构。
4. 复用现有 automation fixture/adapter 完善真机冒烟；安装包激活专项统一登记 catalog。
5. x64 真机验证、WACK、实际 Windows 隐私政策及商店截图/描述准备。
6. 注册后以 Partner Center 真实身份重新构建验证，再准备提交；测试包不上传。

Windows ARM 虚拟机中的 x64 仿真结果不扩大为 x64 真机、GPU、BLE 或外设验收。

## 后续调整：GitHub 构建、本地验证

用户提出用 GitHub 虚拟环境打包、本地仅验证，因此新增独立的 `windows-store.yml` 草案，
复用原有质量门禁，通过后在 `windows-2022` 构建同一 SHA 的 x64 MSIX。
导出 unsigned 原包、单独自签名的本地测试包、公开 CER 及对应哈希/签名信息；私钥不导出、不上传。
不改原 EXE 发布、不创建 Release、不提交 Store，也不要求在本地虚拟机安装开发工具链。

这一调整替代上方后续顺序第 1 项的“在本地补工具链”建议。实际 GitHub run 尚未执行，
需要先明确提交范围并获得提交/推送授权。工作流本地检查不等于 GitHub 构建通过。
下载到虚拟机后仍需确认测试证书信任、安装与运行；这些动作尚未执行。

新增 workflow 已通过 YAML 解析及 actionlint 1.7.7 检查（工具压缩包与官方 release SHA-256 一致），
打包工具的 9 项定向测试复跑通过；加入该 workflow 后再次执行完整质量门禁通过，
日志为 `/private/tmp/forge-store-github-quality-20261028.log`。`.github/workflows/ci.yml`、`quality.yml`、`release.yml`
及 `tool/quality_gate.sh` 未修改。
当前已提交应用版本为 `1.2.10+4`，本地脏树版本为 `1.2.10+5`；只提交本轮打包文件时，
GitHub 首轮构建会使用前者，不会自动包含尚未提交的业务修改。最终以 run 中记录的源码 SHA 与版本为准。
