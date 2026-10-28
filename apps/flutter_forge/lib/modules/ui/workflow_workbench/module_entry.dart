import 'package:flutter/material.dart';

import 'workflow_page.dart';
import 'offline_workflow_page.dart';
import '../../../shared/platform/build_features.dart';

class WorkflowWorkbenchEntry extends StatelessWidget {
  const WorkflowWorkbenchEntry({super.key});
  @override
  Widget build(BuildContext context) =>
      offlineEdition ? const OfflineWorkflowPage() : const WorkflowPage();
}
