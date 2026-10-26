import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_biometric/flutter_biometric.dart';
import 'package:flutter_forge_app/shared/learning/learning_scaffold.dart';

import 'biometric_session.dart';

/// 生物特征与本地认证：能力查询、认证提示与类型化结果观察。
class BiometricAuthEntry extends StatefulWidget {
  const BiometricAuthEntry({super.key, this.biometric});

  final FlutterBiometric? biometric;

  @override
  State<BiometricAuthEntry> createState() => _BiometricAuthEntryState();
}

class _BiometricAuthEntryState extends State<BiometricAuthEntry> {
  late final BiometricSession session;

  @override
  void initState() {
    super.initState();
    session = BiometricSession(widget.biometric ?? FlutterBiometric());
    unawaited(session.initialize());
  }

  @override
  void dispose() {
    session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) => LearningScaffold(
        title: '生物特征与本地认证',
        interactiveDemo: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(session.capabilityText),
            const SizedBox(height: 12),
            Text(session.outcomeText),
            if (session.loading) const LinearProgressIndicator(),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: 230,
                  child: FilledButton.icon(
                    onPressed:
                        (session.capabilities?.strongAvailable ?? false) &&
                            !session.loading
                        ? () => session.authenticate(BiometricStrength.strong)
                        : null,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('强生物识别'),
                  ),
                ),
                SizedBox(
                  width: 230,
                  child: FilledButton.icon(
                    onPressed:
                        (session.capabilities?.weakAvailable ?? false) &&
                            !session.loading
                        ? () => session.authenticate(BiometricStrength.weak)
                        : null,
                    icon: const Icon(Icons.face),
                    label: const Text('弱或更强生物识别'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: session.hasCredentialFallback && !session.loading
                  ? () => session.authenticate(
                      BiometricStrength.strongWithCredential,
                    )
                  : null,
              icon: const Icon(Icons.password),
              label: const Text('凭据回退认证'),
            ),
            const SizedBox(height: 12),
            StateLogView(logs: session.logs),
          ],
        ),
        sections: const [
          LearningObjectives(
            objectives: [
              '理解入口开放（静态矩阵）与运行时能力（已录入、已授权）是两层不同的判定',
              '观察能力查询结果如何驱动界面降级：无传感器、未录入、无凭据回退',
              '读懂认证结果的稳定原因码，区分用户取消、锁定与硬件不可用',
            ],
          ),
          CommonPitfalls(
            pitfalls: [
              '「设备支持」不等于「已录入」：canAuthenticate 的成功同时覆盖硬件与已录入状态',
              'strong/weak 表示强度，不能指定指纹或面容；硬件特征也不能证明某类生物特征已录入',
              '认证过程中不要阻塞平台主线程：BiometricPrompt 的回调与发起调用共用主线程',
              '取消、失败、锁定都不是异常：它们是类型化结果的一部分，不该抛出跨通道异常',
            ],
          ),
          ExerciseCard(
            task: '先记录能力查询结果，再分别触发一次强生物识别与一次取消，对比原因码差异',
            hint: '取消可返回 userCancel/systemCancel；锁定策略和原因码取决于系统，成功也可能不披露认证方式',
          ),
        ],
      ),
    );
  }
}
