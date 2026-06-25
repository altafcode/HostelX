import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_provider.dart';

class AdminComplaintDetailScreen extends StatefulWidget {
  final String complaintId;

  const AdminComplaintDetailScreen({super.key, required this.complaintId});

  @override
  State<AdminComplaintDetailScreen> createState() => _AdminComplaintDetailScreenState();
}

class _AdminComplaintDetailScreenState extends State<AdminComplaintDetailScreen> {
  final _responseController = TextEditingController();

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    final complaint = adminProv.complaints.firstWhere((c) => c.id == widget.complaintId);
    final createdAt = DateFormat('d MMM yyyy, h:mm a').format(complaint.createdAt);

    Color statusColor;
    switch (complaint.status) {
      case 'Open':
        statusColor = AppColors.red;
        break;
      case 'Under Review':
        statusColor = AppColors.accent;
        break;
      case 'Resolved':
        statusColor = AppColors.emerald;
        break;
      default:
        statusColor = AppColors.textMuted;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Complaint Details', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
                        child: Text(complaint.type, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(complaint.status, style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(complaint.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 16),
                  const Text('Description', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text(complaint.description, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5)),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  _InfoRow(icon: Icons.person, label: 'Submitted By', value: complaint.byUserName),
                  const SizedBox(height: 12),
                  _InfoRow(icon: Icons.apartment, label: 'Against', value: complaint.againstName),
                  const SizedBox(height: 12),
                  _InfoRow(icon: Icons.calendar_today, label: 'Date', value: createdAt),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (complaint.status != 'Resolved') ...[
              const Text('Admin Response', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              TextField(
                controller: _responseController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Type your response here...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        adminProv.updateComplaintStatus(
                          complaint.id,
                          'Under Review',
                          response: _responseController.text.trim(),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated to Under Review')));
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        side: const BorderSide(color: AppColors.accent),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Escalate', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        adminProv.updateComplaintStatus(
                          complaint.id,
                          'Resolved',
                          response: _responseController.text.trim(),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complaint Resolved')));
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Resolve', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    adminProv.updateComplaintStatus(
                      complaint.id,
                      'Resolved',
                      response: _responseController.text.trim(),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complaint Dismissed')));
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
                  child: const Text('Dismiss Complaint'),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.emerald.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.emerald),
                    SizedBox(width: 12),
                    Text('This complaint has been resolved.', style: TextStyle(color: AppColors.emerald, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textMuted),
        const SizedBox(width: 12),
        Text('$label:', style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
      ],
    );
  }
}
