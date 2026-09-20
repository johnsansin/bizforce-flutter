import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Help / support center matching the reference app.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Hi Sin Johnsan',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('How can we help you?',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
          ),
          const SizedBox(height: 24),
          _tile(context, Icons.question_answer_outlined, 'FAQ', () {}),
          _tile(context, Icons.menu_book_outlined, 'Knowledge base portal',
              () {}),
          _tile(context, Icons.school_outlined, 'BizForce CRM Academy', () {}),
          _tile(context, Icons.play_circle_outline, 'Product Tour', () {}),
          _tile(context, Icons.chat_outlined, 'Need help? Chat', () {}),
          _tile(
              context, Icons.request_quote_outlined, 'Request CRM demo', () {}),
          _tile(context, Icons.bug_report_outlined, 'Submit a bug', () {}),
        ],
      ),
    );
  }

  Widget _tile(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label, style: const TextStyle(fontSize: 15)),
        trailing: const Icon(Icons.chevron_right,
            size: 20, color: AppColors.textHint),
        onTap: onTap,
      ),
    );
  }
}
