import 'package:flutter/material.dart';
import '../core/app_colors.dart';

import '../widgets/common.dart';

import 'module_create_screen.dart';

/// Documents: list (PDF tiles), create/link/upload actions and detail.
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final List<_Doc> _docs = [
    const _Doc('CLASS_Seven_DIARY_20_-_8_-_26(2).pdf', 'PDF', 'yyy', 2.4),
    const _Doc('Sale_Agreement_08.pdf', 'PDF', 'Sale agreement', 1.1),
  ];

  void _addDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
                leading: const Icon(Icons.create_outlined),
                title: const Text('Create'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => CreateRecordScreen(
                              module: 'Documents', fields: fieldSpecDocs())));
                }),
            ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Link'),
                onTap: () => Navigator.pop(context)),
            ListTile(
                leading: const Icon(Icons.upload_file_outlined),
                title: const Text('Upload Multiple Files'),
                onTap: () => Navigator.pop(context)),
            ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: const Text('Scan Business Card'),
                onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      ),
      body: _docs.isEmpty
          ? const EmptyState(
              title: 'There are no Documents.',
              body: 'You can add Documents by clicking the button below',
              icon: Icons.folder_open)
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _docs.length,
              separatorBuilder: (context, index) => Divider(
                  height: 1, indent: 72, color: Theme.of(context).dividerColor),
              itemBuilder: (context, i) {
                final doc = _docs[i];
                return ListTile(
                  leading: Container(
                    width: 44,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(doc.extension,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary)),
                  ),
                  title: Text(doc.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  subtitle: Text(doc.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  trailing: const Icon(Icons.chevron_right,
                      size: 20, color: AppColors.textHint),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

List<CreateField> fieldSpecDocs() => const [
      CreateField('Active', 'Basic Information',
          type: FieldType.yesno, initial: 'Yes'),
      CreateField('File Name', 'Basic Information', required: true),
      CreateField('Document Type', 'File Sharing Info',
          type: FieldType.select, options: ['Private', 'Public', 'Shared']),
      CreateField('Description', 'Description Details',
          type: FieldType.multiline),
    ];

class _Doc {
  final String name;
  final String extension;
  final String title;
  final double sizeMb;
  const _Doc(this.name, this.extension, this.title, this.sizeMb);
}
