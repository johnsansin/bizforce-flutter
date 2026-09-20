import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../widgets/common.dart';

/// Maps screen: a stylized map with meeting time/shortest route controls,
/// scheduled events and nearby clients. (Swap in a real map plugin, e.g.
/// google_maps_flutter, when you wire up the backend.)
class MapsScreen extends StatelessWidget {
  const MapsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Maps')),
      body: Stack(
        children: [
          // Placeholder map area.
          Container(
            height: 360,
            color: const Color(0xFFE3E8EE),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.map_outlined,
                      size: 72, color: Color(0xFFB9C2CE)),
                  const SizedBox(height: 8),
                  Text('Map view',
                      style:
                          TextStyle(fontSize: 15, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ),
          // Overlay controls at the top.
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Row(
              children: [
                Expanded(
                  child: _pill(context,
                      icon: Icons.schedule,
                      label: 'Meeting Time',
                      selected: true,
                      onTap: () {}),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _pill(context,
                      icon: Icons.route,
                      label: 'Shortest Route',
                      selected: false,
                      onTap: () {}),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 340,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  const Text('Scheduled',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text('No events for the day',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  const Text('Nearby',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  _clientCard(context, 'Ali Traders', '2.3 km'),
                  _clientCard(context, 'Master Jee Motors', '4.1 km'),
                  _clientCard(context, 'SM Solutions', '6.8 km'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context,
      {required IconData icon,
      required String label,
      required bool selected,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _clientCard(BuildContext context, String name, String distance) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          RecordAvatar(name),
          const SizedBox(width: 12),
          Expanded(
              child: Text(name,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600))),
          Text(distance,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          const Icon(Icons.location_on_outlined,
              size: 18, color: AppColors.primary),
        ],
      ),
    );
  }
}

/// Shared "Create Payment" quick screen used from the payments flow.
class CreatePaymentScreen extends StatelessWidget {
  const CreatePaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context)),
        title: const Text('Create Payment'),
        actions: [SaveButton(onPressed: () => Navigator.pop(context, true))],
      ),
      body: const Center(
          child: Text('Payment form (amount, status, mode, assigned to)',
              style: TextStyle(color: AppColors.textSecondary))),
    );
  }
}
