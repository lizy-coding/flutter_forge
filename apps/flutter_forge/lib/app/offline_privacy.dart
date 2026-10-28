import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const offlineSupportEmail = 'diligent_coding@163.com';

const offlinePrivacyPolicy = '''Flutter Forge 离线版隐私说明
更新及生效日期：2026年10月28日
提供者：Flutter Forge 个人开发者（lizy-coding）

本版本提供本地编程教学和交互实验，没有用户账号、广告、统计服务或云端同步，也不连接模型服务或工作流服务器。Android 离线发行包不声明互联网访问权限。内置视频、网页、文章和生成界面示例均随应用提供或在本机生成。

一、本地保存的数据
主题偏好、最近访问的模块入口保存在应用私有存储中。部分教学实验会保存用户主动输入的演示内容。界面显示的任务、文章和账号是教学模拟数据。导入的文件和字体仅用于本地实验，不上传。

二、按需使用的设备能力
蓝牙实验在用户操作和授权后访问附近设备、连接状态及用户选择的设备数据；旧版 Android 为蓝牙扫描需要定位权限，不用于跟踪位置。USB 实验按用户授权访问所选设备。设备和电池信息用于本地展示。通知实验只发送本机通知。生物识别交由系统验证，应用仅接收验证结果，不读取或保存指纹、人脸模板。拒绝这些可选权限不影响其他学习模块。

三、保存、删除和共享
本版本不向开发者服务器或第三方服务器传送实验内容。操作系统负责文件选择、生物识别和设备权限，按系统规则处理相关数据。可在系统应用设置中撤销权限、清除应用数据或卸载应用；卸载不删除用户原有的导入文件。手机备份是否包含应用数据由系统备份设置决定。

四、未成年人及变更
本应用面向编程学习者，不以儿童为目标群体。不主动要求提供姓名、证件、联系方式等身份信息。后续如增加联网或数据处理功能，将更新说明并在需要时重新征得同意。

五、联系与反馈
如对本说明、权限或本地数据处理有疑问，可通过下方邮箱联系开发者。复制邮箱仅写入系统剪贴板，由你自行决定是否发送邮件。
联系邮箱：diligent_coding@163.com
''';

class OfflinePrivacy extends StatelessWidget {
  const OfflinePrivacy({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('离线学习版 · 所有实验在本机进行'),
      const ExpansionTile(
        title: Text('隐私说明与权限用途'),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: SelectableText(offlinePrivacyPolicy),
          ),
        ],
      ),
      TextButton.icon(
        icon: const Icon(Icons.copy),
        label: const Text('复制反馈邮箱'),
        onPressed: () async {
          await Clipboard.setData(
            const ClipboardData(text: offlineSupportEmail),
          );
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('邮箱已复制，请自行发送反馈')));
          }
        },
      ),
    ],
  );
}
