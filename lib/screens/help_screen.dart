import 'package:flutter/material.dart';
import 'module_list_screen.dart';

/// Support tickets supplied by the authenticated backend.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});
  @override
  Widget build(BuildContext context) => const ModuleListScreen(
        title: 'Help & Support',
        module: 'Tickets',
      );
}
