import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_ioc_core/flutter_ioc_core.dart' as ioc;
import 'module_root.dart' as flutter_ioc;
import 'model/counter_model.dart';

class FlutterIocEntry extends StatefulWidget {
  const FlutterIocEntry({super.key});

  @override
  State<FlutterIocEntry> createState() => _FlutterIocEntryState();
}

class _FlutterIocEntryState extends State<FlutterIocEntry> {
  late final ioc.Container _container;

  @override
  void initState() {
    super.initState();
    _container = ioc.Container(environment: {'appName': 'Counter'});
    _container.registerSingleton<CounterModel>(
      (_) => CounterModel(name: 'Default', count: 0),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Provider<ioc.IoCContainer>.value(
      value: _container,
      child: ChangeNotifierProvider<CounterModel>(
        create: (_) => _container.resolve<CounterModel>(),
        child: const flutter_ioc.CounterScreen(),
      ),
    );
  }
}
