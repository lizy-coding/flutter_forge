# USB 网络桥接

Windows/macOS 的最小 CDC-NCM 网卡枚举与绑定 TCP 能力。无驱动安装、扫描设备、自动重连、协议、UI、视频或全局连接状态。

- `createUsbNetworkAdapter().listInterfaces()`：返回当前可用 NCM IPv4 接口；枚举失败抛出错误，成功但没有接口返回空集合。
- `connect(interface, host: ..., port: ...)`：只接受字面 IPv4 与有效端口；打开前由原生层重新核对接口、索引与源地址。调用方持有连接，监听 `received` 并等待 `close()`。
- `received` 是原始 TCP 字节流，块不是消息。`send` 发送原始字节，不执行 WebSocket、TLS 或设备协议。
- Windows 使用 SetupAPI、Winsock `IP_UNICAST_IF`；macOS 使用 IOKit、`IP_BOUND_IF`。本机带随机令牌的 TCP relay 将原生 Socket 接入 Dart。
- 枚举是短同步 FFI 调用，没有可中断超时承诺。TCP 建立有等待上限；关闭中继等待原生工作线程退出。
- macOS 宿主沙箱需要 network.client 和 network.server entitlement（本机 relay）。系统需要已有 NCM 驱动与 IPv4；包不设置 IP、不安装驱动。

## 来源与许可

原生枚举及 relay 从 `xstudio_framework` 提交 `5871fa4` 适配，符号独立为 ForgeUsb 前缀；未引入其业务、证书、密钥、算法 SDK 或商业二进制。迁入的权属和分发授权仍遵从源项目约定，见 [LICENSE](LICENSE)。依赖 `ffi` 的 BSD-3-Clause 原始声明位于 [第三方许可](THIRD_PARTY_NOTICES.txt)。

## 验证边界

Dart 参数与会话测试、原生编译、应用构建和真机 NCM 收发是独立证据。真实设备的接口识别、重叠网段、收发及拔插仍需在各平台验收；不以空列表或构建通过代替。
