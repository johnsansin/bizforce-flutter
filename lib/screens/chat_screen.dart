import 'package:flutter/material.dart';
import 'module_list_screen.dart';

/// Conversations supplied by the authenticated backend.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});
  @override
  Widget build(BuildContext context) => const ModuleListScreen(
        title: 'Chat',
        module: 'Conversations',
      );
}
