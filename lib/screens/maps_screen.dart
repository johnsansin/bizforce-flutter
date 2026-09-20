import 'package:flutter/material.dart';
import 'module_list_screen.dart';

/// Location records supplied by the authenticated backend.
class MapsScreen extends StatelessWidget {
  const MapsScreen({super.key});
  @override
  Widget build(BuildContext context) => const ModuleListScreen(
        title: 'Locations',
        module: 'Locations',
      );
}
