# forge_notification_bridge

独立通知能力域：queryCapabilities、queryPermissionState、requestPermission、post、cancel，经 token 平台接口与类型化 Outcome 接入。available 的 post 结果仅表示系统受理通知请求，不证明可见展示；cancel=true 表示系统接受撤回请求，不证明此前一定展示过。返回 false 不得当成功撤回。

通道响应先校验顶层、状态、原因及各方法成功负载；畸形值返回 invalidData。普通传输错误返回 unavailable，缺适配返回 unsupported，能力查询降级为 none。权限状态必须从系统重新读取，拒绝后不承诺一定再次弹框。macOS UNErrorDomain.notificationsNotAllowed明确归为permissionDenied/notifications_not_allowed；session请求失败后再做非交互权限重查，保留请求失败日志与最新权限事实。

Android 配置重建时移除旧监听器、保留有期限的授权等待，重新绑定后继续接收；永久 detach/engine detach 明确结束 pending，迟到旧请求代码不能完成新请求。用户授权等待120秒后返回 unresolved/timeout 语义；系统权限提示无法由插件强制关闭，后续结果不再回写旧会话，用户应重新查询权限状态。Android UUID tag+ID=0 避免时间戳/哈希冲突导致撤回其他通知。

macOS 每插件实例拥有异步回调与期限：普通操作10秒、权限请求120秒。窗口关闭结束本实例的等待并丢弃迟到回调；对象释放取消期限。UNUserNotificationCenter 没有程序化撤销已显示权限询问的接口，超时/退出不等于系统拒绝或系统操作已回滚。通知中心是应用范围的系统服务，用户显式按 ID 撤回仍具有应用范围语义；实例清理不批量撤回其他窗口通知。

Forge session 在初始化、查询、请求、投递、撤回的每个 await 检查所有权，dispose 立即完成 session 等待并隔离迟到结果。重复操作被拒绝，异常通过 finally 清除 loading，编程错误继续暴露。

Dart 通道测试与调用方测试由现有 workspace 门禁遍历；原生 Swift 无提示生命周期测试见 test/native/main.swift 及本轮实施报告。真实权限、投递、撤回和多窗口操作仍需人工验收。
