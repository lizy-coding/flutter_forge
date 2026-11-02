# 隐私政策维护

唯一当前文字来源是 `policies.json`：公共身份、设备能力、反馈与变更条款共用，联网版与离线版分别组织完整正文并附平台差异。Android 离线是发行配置，不构成永久离线承诺。policy ID 与应用版本分别管理。

执行 `python3 tool/privacy_policy.py` 生成：

- `apps/flutter_forge/lib/app/privacy_policy_data.dart`，由关于页的“隐私与数据”显示。
- `apps/flutter_forge/web/privacy.html`、`privacy-offline.html` 两个稳定入口。
- `history/<policy-id>.json` 与 `apps/flutter_forge/web/privacy/versions/<policy-id>.html` 的历史快照。
- `index.json`，记录当前与历史版本、正文 hash、HTML hash 和相对路径。

政策正文变化时创建新 ID；已有版本不得覆盖。原有 2026-10-28 离线、2026-10-29 完整版文本已按源码原文归档，不据此宣称旧安装包一定包含它们。生成器在同 ID 内容变化或历史 HTML 被改写时失败。输出禁止手改。

`export_privacy.py` 和 `export_offline_privacy.py` 保留为兼容入口，均同步/检查两版产物，支持 `--check`。检查确认本地内容一致，不代表页面已经公开可访问。

公开托管复用现有 Web 站点：稳定页面用于展示当前版本，历史 URL 用于冻结每次渠道提交的政策。部署后检查 HTTPS、无需登录、移动端可读和正文/版本匹配，再把实际 URL 与核对时间登记到分发台账。未验证的 URL 留空，不猜测线上部署结果；旧安装包提交不得自动指向新的政策正文。

关于页提供最近访问清除、系统权限撤销和各端数据清理说明；仅清除该模块入口偏好，不改变主题、实验数据或第三方数据。清除失败不展示成功。模型/Hub 发送前的能力提示保留。

本次属于政策组织与数据控制入口调整，没有新增数据处理目的，不统一增加启动同意弹窗。若渠道审核或后续能力要求确认，再按具体场景实现选择及政策版本记录；明确同意、拒绝与撤回的实际行为后才能登记验收，不能把点击阅读视为同意。
