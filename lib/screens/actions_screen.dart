import 'package:flutter/material.dart';
import 'module_list_screen.dart';

/// CRM activities supplied by the authenticated backend.
class ActionsScreen extends StatelessWidget {
  const ActionsScreen({super.key});
  @override
  Widget build(BuildContext context) => const ModuleListScreen(
        title: 'Actions',
        module: 'Activities',
      );
}
