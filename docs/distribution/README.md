# 分发与隐私管理

[当前总览](OVERVIEW.md)由 `catalog.json` 生成。日常只维护结构化台账，历史报告与原始 manifest 保留，不继续维护第二份当前状态表。优先 vivo、Microsoft Store；macOS、Web、GitHub 分发维持维护，小米暂缓新增发行。iOS 不登记虚假的就绪渠道。

## 归属与记录

- `profiles`：发行配置，描述平台、edition、网络边界、Dart define 与签名身份。模块入口仍由现有 module_registry/能力规则决定，不在此复制模块白名单。
- `artifacts`：冻结的包记录，关联版本、平台构建号、源 SHA、dirty、包 hash、签名身份及政策版本/hash。ID 一经登记不修改；重打包使用新 ID。产物与私密密钥不放入台账，签名仅记录公开指纹。
- `submissions`：渠道、产物、素材版本、原始材料证据和追加的 `observations`。审核与发布状态只在 observation 中记录，避免多份当前状态。
- observation 示例：`{"at":"2026-10-30T14:00:00+08:00","review":"in_review","publication":"not_published","evidence":["后台截图或报告路径"],"note":"只读核对"}`。新提交按登记顺序追加；渠道总览只展示最后登记提交的观察。真实观察后追加，不把构建或旧记录转换成后台状态。更正错误时追加新观察并说明原因，保留旧记录。
- 审核状态：`needs_verification/not_submitted/submitted/in_review/approved/rejected`；发布状态：`needs_verification/not_published/scheduled/published/withdrawn`。审核通过不等于上架。超过 7 天的后台观察显示待核对；按需核对，不额外建立周期监控。
- 政策链接核对后登记到渠道的 `policy_url`、`policy_url_verified_at`、`policy_url_policy_id`、`policy_url_text_sha256`；确认公开内容与所提交包的历史政策一致。当前源码政策不替代旧安装包政策。

当前整理仅依据本地清单。2026-10-30 Chrome 的 vivo 开发者首页显示未登录，未进入应用后台，2006 的实时审核和发布状态仍待核对。Microsoft Store 的正式身份、宿主验收、WACK、材料和提交分别取证；LocalTest 流水线不代表正式商店包。

## 常用操作

```bash
# 同步并检查两版政策、不可变快照、Dart 常量与公开 HTML
python3 tool/privacy_policy.py
python3 tool/export_privacy.py --check
python3 tool/export_offline_privacy.py --check

# 台账检查与生成总览（均无远程操作）
python3 tool/distribution.py validate
python3 tool/distribution.py generate
python3 tool/distribution.py check

# 对已登记包生成审核材料 JSON 和缺口清单；输出目录必须不存在
python3 tool/distribution.py prepare --channel vivo --artifact-id vivo-1.2.10-2006 --output /tmp/forge-vivo-review

# 新构建完成后，核对实际文件 hash 并导入构建报告，追加冻结记录
python3 tool/distribution.py register --profile android-offline --artifact-id vivo-1.2.11-2007 --manifest .release/vivo/1.2.11/offline-2007/manifest.json --artifact .release/vivo/1.2.11/offline-2007/FlutterForge-1.2.11-2007-arm64-offline-release.apk
```

`prepare`：0 表示材料已整理供复核，2 表示存在明确缺口，1 表示输入/台账错误。`prepared_for_review` 不代表商店验收通过或获得提交授权。商店准备需符合渠道的包格式与身份/签名、真实宿主证据、已核对的公开政策链接和素材版本；完整专项仍按对应商店清单执行。

`register` 支持 vivo 离线构建 manifest、Windows MSIX result 与既有 GitHub release manifest。导入验证文件 hash、配置、版本及政策绑定；它不是第二套 APK/MSIX 验收器，必须保存原构建工具的验证证据。旧 manifest 没有政策绑定时保持未知，不能填入当前版本冒充包内政策。原始本地文件可能不随 clone 分发，缺失时准备工具明确阻塞。

## 构建和发布边界

- vivo 构建继续使用 `tool/build_vivo_offline.py --build-number <新versionCode>`，代码必须大于已登记离线包号，且实际证书匹配配置中登记的指纹。每个构建号写入新输出目录，不覆盖旧包。下一包号至少为 2007，执行前还要核对后台是否已有更高包号。
- Windows Store 工具在新 result 中附带政策绑定。正式身份 MSIX 可由商店在提交过程中签名，不误套侧载签名要求，依据 [Microsoft 官方说明](https://learn.microsoft.com/en-us/windows/msix/package/sign-msix-package-guide)。`preview`、`LocalTest`、正式未签名候选及实际提交分别记录；导入 LocalTest 不使其具备商店就绪资格。
- 通用四端发布仅给新 manifest 增加 `distribution_profile` 和 `policy_binding` 元数据，保留原校验、签名声明和发布授权。历史 manifest 不改写。Windows MSIX 构建号记录实际包版本；同一产品版本重做正式 Store 包时，必须核对商店版本规则后选择递增包版本，不把 Flutter `+build` 当成已自动映射。
- 新渠道提交分配独立 ID；商店文案、截图等变更增加素材版本。重打包增加产物记录，提交记录仍指向当时的产物。
- 仓库 CI 继续只构建暂存产物；GitHub Release 经 Agent Hub `release-plan` / `release-run --execute`。提交审核、发布、撤回均需明确授权；不默认设置审核通过立即发布。已有后台设置必须据实记录，本工具不修改它。
- 本期未改 CI/门禁脚本语义；检查和测试作为显式专项登记。不会因建立管理台账而自动部署政策网页或更新已分发应用。

## 专项验证

```bash
python3 tool/distribution_test.py
python3 tool/windows_store_test.py
python3 tool/automation.py run --platform local --case distribution-tests --output /tmp/forge-distribution-tests
```

Widget/逻辑测试覆盖政策展开、360px 阅读、清除最近访问及并发写入顺序；完整质量门禁仍执行 `bash tool/quality_gate.sh`。真实 Android/Windows 包和商店审核不由这些测试代替。
