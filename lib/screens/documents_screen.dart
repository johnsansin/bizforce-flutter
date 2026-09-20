import 'package:flutter/material.dart';
import 'module_list_screen.dart';

/// Documents supplied by the authenticated backend.
class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});
  @override
  Widget build(BuildContext context) => const ModuleListScreen(
        title: 'Documents',
        module: 'Documents',
      );
}
