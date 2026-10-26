# 来源及本地维护

来源：https://github.com/lizy-coding/flutter_biometric ，v0.2.0，精确提交 `84f36aa567384ea83e9148822355dc12db72eeb0`。从当前依赖锁定的缓存副本导入 lib、android、macos、test 和许可证/说明文件；未改写缓存中的插件源码或外部仓库。原 LICENSE 保留。

本包按 ADR 0019 作为 Forge workspace 内部插件维护，不独立发布。未在本仓库发现要求保留外部 Git 依赖的复用契约；对外部其他消费者不作断言。

本地差异：操作 ID、可取消认证、并发及 detach 唯一终态、严格响应解析、认证方式 unknown、Android androidx 命名常量、调用方销毁隔离。认证允许强度和凭据回退策略保持原样。

注意：来源的 LICENSE 文件内容为 `TODO: Add your license here.`，本轮原样保留，不能据此宣称 MIT 或其他授权；后续对外分发前需由维护者明确许可证。本轮未发布任何产物。
