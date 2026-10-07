import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'module_entry.dart';

@Preview(name: '约束布局 · 窄屏', size: Size(320, 800))
@Preview(name: '约束布局 · 桌面', size: Size(1000, 900))
Widget constraintLayoutPreview() =>
    const MaterialApp(home: ConstraintLayoutEntry());
