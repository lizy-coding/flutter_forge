import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../module_registry/app_platform_snapshot.dart';

final appPlatformProvider = Provider<AppPlatformSnapshot>(
  (ref) => throw StateError('AppPlatformSnapshot was not initialized'),
);
