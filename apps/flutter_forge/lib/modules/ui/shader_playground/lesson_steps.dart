import 'package:flutter/material.dart';

import 'shader_preview.dart';

const shaderSteps = [
  (
    title: '先输出一种颜色',
    prediction: '画布上不同位置会有不同颜色吗？',
    answer: '不会。混合比例始终为 0，每个位置都输出起始色。Shader 的规则会用于绘制区域中的片元，不需要在 Dart 中逐像素循环。',
    dart: 'final progress = 0.0;\nfinal color = startColor;',
    lines: ['progress = 0.0;', 'vec4 gradient ='],
    parameters: ShaderParameters(effect: ShaderEffect.solid),
  ),
  (
    title: '把左半蓝规则搬进 GLSL',
    prediction: '点在 U = 0.25、0.75 和正中间时，各是什么颜色？',
    answer: '左侧为蓝色，右侧和 U = 0.5 为白色。与上一课使用相同判断，区别是颜色规则现在交给真正的片元 Shader 执行。',
    dart:
        'final u = x / width;\nfinal progress = u < 0.5 ? 0.0 : 1.0;\nfinal color = Color.lerp(blue, white, progress);',
    lines: ['vec2 uv =', 'progress = uv.x <', 'vec4 gradient ='],
    parameters: ShaderParameters(
      effect: ShaderEffect.split,
      endColor: Colors.white,
    ),
  ),
  (
    title: '从分界变成横向渐变',
    prediction: '把非黑即白的判断换成 U，中间位置会怎样？',
    answer:
        '混合比例连续变化：左侧接近蓝色，中间各占一半，右侧接近橙色。mix(a, b, t) 表示从 a 向 b 混合，t = 0 取 a，t = 1 取 b。',
    dart:
        'final axis = u;\nfinal progress = axis.clamp(0.0, 1.0);\nfinal color = Color.lerp(startColor, endColor, progress);',
    lines: ['float axis =', 'float progress =', 'vec4 gradient ='],
    parameters: ShaderParameters(),
  ),
  (
    title: '只把 U 换成 V',
    prediction: '纵向渐变时，同一行左右两个点的颜色会不同吗？',
    answer:
        '不会，它们的 V 相同。uVertical 为 0 时选 U，为 1 时选 V；Flutter 控件通过 uniform 把这个选择传进 Shader。',
    dart:
        'final axis = vertical ? v : u;\n// 控件更新后，绘制时传入 0 或 1\nshader.setFloat(2, vertical ? 1 : 0);',
    lines: ['uniform float uVertical;', 'float axis =', 'vec4 gradient ='],
    parameters: ShaderParameters(vertical: true),
  ),
  (
    title: '加偏移，观察颜色比例',
    prediction: '偏移设为 +0.5 后，U = 0.75 的混合比例会大于 1 吗？',
    answer: '相加得到 1.25，但 clamp 把结果限制为 1，所以输出结束色。正偏移会增加结束色覆盖范围；这不是移动画布。',
    dart:
        'final progress = (u + offset).clamp(0.0, 1.0);\nshader.setFloat(4, offset);',
    lines: ['uniform float uOffset;', 'float progress =', 'vec4 gradient ='],
    parameters: ShaderParameters(),
  ),
  (
    title: '把亮带变成卡片扫光',
    prediction: '暂停时移动亮带位置，与播放时让位置随时间变化，有什么联系？',
    answer:
        '它们使用同一条颜色规则。先求当前点到亮带中心的距离，再用 smoothstep 让边缘平滑过渡；播放只是逐帧更新位置参数。降低速度会减慢移动，不代表每帧的计算更少。',
    dart:
        'final center = -width + (1 + 2 * width) * phase;\nfinal distance = (u - center).abs();\n// Flutter 动画更新 phase，绘制时传入\nshader.setFloat(14, phase);',
    lines: [
      'float center =',
      'float distance =',
      'progress = 1.0 - smoothstep',
      'vec4 gradient =',
    ],
    parameters: ShaderParameters(
      effect: ShaderEffect.sweep,
      endColor: Colors.white,
    ),
  ),
];
