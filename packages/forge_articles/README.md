# 文章教学能力

独立于 Flutter 页面和 Agent Hub 的 Dart 能力包。`ArticleApi` 复用 Dio 文章请求；`ArticleTeachingAdapter` 提供可取消、可失败的合成数据；`ArticleWorkflowRunner` 执行 `articles.explore` v1 的请求和整理步骤，返回表格数据。

执行入口需要冻结的流程定义、已校验输入、`CancelToken` 和异步事件回调。事件回调成功后才进入下一步，执行结果由调用方交给 Hub 接受。包内不保存运行、不访问模型、不执行任意节点或 shell。

从本目录运行 `flutter test`。测试使用 Flutter workspace 的测试工具，库本身仅依赖 Dio，无 Widget 依赖。原 Dio 拦截器模块继续使用自己的网络配置，通过 `ArticleApi` 共用请求能力。
