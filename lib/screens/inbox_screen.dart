import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Inbox welcome/help screen.
class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const items = <(IconData, String, String)>[
      (
        Icons.forum_outlined,
        'Conversations',
        'Add each group mailbox and the team members that can see it'
      ),
      (
        Icons.person_add_alt,
        'Assign',
        'Each received email in a group mailbox can be assigned to a member for follow-up.'
      ),
      (
        Icons.done_all_outlined,
        'Mark as Done',
        'Once work on an email is complete, it can be marked as Done to push it to the "Done" box.'
      ),
      (
        Icons.comment_outlined,
        'Comments',
        'Collaborate with other team members on an email through @mentions in comments'
      ),
      (
        Icons.auto_awesome,
        'Automate Actions',
        'Received emails are automatically linked to relevant contacts and other records'
      ),
      (
        Icons.quickreply_outlined,
        'Canned Response',
        'Save time composing replies using pre-built email templates'
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Inbox')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Welcome to Inbox',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            "Inbox makes your company's group mailboxes visible, actionable and collaborative right inside BizForce CRM.",
            style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(item.$1, size: 26, color: AppColors.primary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.$2,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text(item.$3,
                            style: TextStyle(
                                fontSize: 13.5,
                                height: 1.35,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
