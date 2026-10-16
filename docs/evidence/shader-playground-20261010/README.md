# Shader 学习模块首期验证

日期：2026-10-10。基线：`dev / b90d5971a8af6de4a6eaedf979344a9e53ef0cac` 加本次未提交工作区；本记录不代表已发布版本。

## 实现范围

新增 UI 分类学习模块 `/shader-playground`，首期为「UV 坐标与双色渐变」。提供 UV 可视化、横纵方向、渐变偏移、交换颜色、复位、加载错误重试与教学内容。UV 模式禁用不参与输出的渐变控件。

页面管理加载与释放；`shader_preview.dart` 集中绑定 uniform 和绘制；`.frag` 包含 `.glsl` 核心源文件。教学代码直接读取同一 `.glsl`，不维护另一份摘录。资源位于模块自己的 `shaders/`，现有证据指纹扫描覆盖 Shader 源码变化。

无新增依赖、通用 Shader 框架或持续动画。页面按参数变化重绘，退出释放资源，退出后迟到的加载结果也会释放。预览随可用宽度变化，最大高度为 240dp。

模块注册、稳定路由、平台能力和机器契约来自生成器。`fragment_shader_canvas` 对应 Flutter SDK 的 Canvas 片元绘制路径；目标平台入口开放与实际验证状态独立。

## 自动验证

| 范围 | 结果 | 依据 |
| --- | --- | --- |
| Shader 模块定向测试 | PASS，9 项，无跳过 | `node tool/module_availability.js check --module shader_playground --kind logic --platform any` |
| 完整质量门禁 | PASS | [最终日志](quality-gate.log)，生成物、格式、bare analyze、workspace/工具测试、28 个模块测试存在性全部通过 |
| macOS 完整应用 Debug 构建 | PASS | `node tool/module_availability.js check --kind compile --platform macOS` |
| Web 完整应用 Release 构建 | PASS | `node tool/module_availability.js check --kind compile --platform web`，保留项目 CanvasKit 发布路径 |

定向测试使用编译后的真实 FragmentShader，检查横纵渐变、偏移、UV 和预乘 alpha 的像素输出；另覆盖页面参数更新、复位、UV 控件禁用、加载失败重试、退出后成功/失败回调、360×800dp 与 1.6 倍文字缩放、路由注册。测试运行器的离屏像素证据不替代各平台真实宿主渲染。

## macOS 实际执行冒烟

环境：macOS 26.7.1、arm64、Flutter 3.47.2、Debug；启动日志显示 Impeller MetalSDF。下列截图为真实应用窗口，1600×1264 像素。

通过 `flutter run -d macos --no-pub` 启动，使用 UI 与动效目录进入新模块；布局调整后执行热重启并重新进入。

| 操作 | 实际观察 | 截图 |
| --- | --- | --- |
| 初次进入 | 横向蓝橙渐变可见，无持续加载或黑屏 | [默认渐变](macos-gradient.png) |
| 切换纵向 | 上蓝下橙，方向与说明一致 | [纵向](macos-vertical.png) |
| 拖动偏移至 0.20 | 显示 V + 0.20，混合位置变化、底部提前达到橙色 | [偏移](macos-offset.png) |
| 交换颜色 | 同一方向和偏移下颜色顺序交换 | [颜色交换](macos-swapped.png) |
| 显示 UV | 左上黑、右上红、左下绿、右下黄；渐变控件禁用 | [UV](macos-uv.png) |
| 复位 | 关闭 UV，恢复横向、偏移 0.00、蓝橙顺序 | [复位](macos-reset.png) |
| 返回目录再进入 | 新 Shader 正常显示，参数恢复默认 | UI 操作观察；运行时错误检查为空 |

实际执行冒烟 PASS。完整人工 UI 验收仍为 PENDING：本次没有完成真实窗口的紧凑尺寸、大字体、连续缩放和所有生成用例；相应布局已有 widget 测试。浏览器执行、Android/Windows/iOS 构建与执行、桌面分类多窗口及持续性能验收均不在本次通过范围内。iOS 当前没有项目宿主。

平台证据统一通过 `tool/module_availability.js` 登记，矩阵由生成器维护；本报告不另建平台准入名单。

## 后续扩展

1. 在当前模块加入指针波纹：时间 uniform、暂停、复位、减少动态效果与后台停止刷新。
2. 加入内置图片灰度和像素化：纹理采样、比例处理与原图对比。
3. 有第二个独立消费者后再考虑共享封装；ImageFilter 自定义 Shader 单独声明其后端能力与验收范围。

以上是扩展顺序，本次仅实现基础示例。
