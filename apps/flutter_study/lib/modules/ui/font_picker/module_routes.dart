import 'package:go_router/go_router.dart';

import 'pages/weight_compare_page.dart';

class FontPickerRoutes {
  const FontPickerRoutes._();

  static const String weightCompare = '/weight-compare';

  static List<GoRoute> get routes => [
    GoRoute(
      path: 'weight-compare',
      builder: (_, __) => const WeightComparePage(),
    ),
  ];
}
