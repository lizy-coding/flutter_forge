import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/drawing_state.dart';
import 'pages/adsorption_line_page.dart';

class AdsorptionLineEntry extends StatelessWidget {
  const AdsorptionLineEntry({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DrawingState(),
      child: const AdsorptionLinePage(),
    );
  }
}
