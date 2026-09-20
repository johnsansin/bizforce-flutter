import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../data/api_service.dart';
import '../state/app_state.dart';
import '../widgets/form_widgets.dart';

/// Business card flow: camera/gallery source sheet, then a simple capture
/// preview and a form. Saving creates a real record in the module (Lead or
/// Contact) through the API.
class ScanBusinessCardScreen extends StatefulWidget {
  final String module;
  const ScanBusinessCardScreen({super.key, this.module = 'Leads'});

  @override
  State<ScanBusinessCardScreen> createState() => _ScanBusinessCardScreenState();
}

class _ScanBusinessCardScreenState extends State<ScanBusinessCardScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _organization = TextEditingController();
  final _officePhone = TextEditingController();
  final _mobilePhone = TextEditingController();
  final _email = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _organization.dispose();
    _officePhone.dispose();
    _mobilePhone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_firstName.text.trim().isEmpty && _email.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter at least a name or email')));
      return;
    }
    setState(() => _saving = true);
    final api = context.read<AppState>().api;
    try {
      await api.createRecord(widget.module, {
        'firstName': _firstName.text.trim(),
        'lastName': _lastName.text.trim(),
        'organization': _organization.text.trim(),
        'phone': _officePhone.text.trim(),
        'mobile': _mobilePhone.text.trim(),
        'email': _email.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Save failed: ${e.message}')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to reach the server.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Business card scanner'),
          leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context)),
          actions: [
            TextButton(
                onPressed: _saving ? null : _save,
                child: const Text('Save',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Front Side'),
              Tab(text: 'Back Side'),
            ],
          ),
        ),
        body: Column(
          children: [
            Container(
              height: 150,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt_outlined,
                        size: 44, color: AppColors.textHint),
                    const SizedBox(height: 6),
                    Text(
                      'Point your camera at the business card',
                      style: TextStyle(
                          fontSize: 13,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            // Fields captured from the scanned card.
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LabeledField(
                        label: 'First Name',
                        required: true,
                        child: AppTextField(
                            controller: _firstName, hint: 'Enter First Name')),
                    LabeledField(
                        label: 'Last Name',
                        required: true,
                        child: AppTextField(
                            controller: _lastName, hint: 'Enter Last Name')),
                    LabeledField(
                        label: 'Organization Name',
                        child: AppTextField(
                            controller: _organization,
                            hint: 'Enter Organization')),
                    LabeledField(
                        label: 'Office Phone',
                        child: AppTextField(
                            controller: _officePhone,
                            hint: 'Enter Office Phone')),
                    LabeledField(
                        label: 'Mobile Phone',
                        child: AppTextField(
                            controller: _mobilePhone,
                            hint: 'Enter Mobile Phone')),
                    LabeledField(
                        label: 'Primary Email',
                        child: AppTextField(
                            controller: _email, hint: 'Enter Primary Email')),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _saving
                    ? const Center(child: CircularProgressIndicator())
                    : FilledButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Open camera'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for choosing camera or gallery before scanning.
void showScanSourceSheet(BuildContext context, {String module = 'Leads'}) {
  showModalBottomSheet(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Scan Business Card:',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant))),
          ),
          ListTile(
            leading:
                const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
            title: const Text('Use Camera'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ScanBusinessCardScreen(module: module)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined,
                color: AppColors.primary),
            title: const Text('Use Gallery'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ScanBusinessCardScreen(module: module)));
            },
          ),
        ],
      ),
    ),
  );
}
