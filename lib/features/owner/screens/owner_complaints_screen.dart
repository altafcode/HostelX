import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/owner_provider.dart';

class OwnerComplaintsScreen extends StatefulWidget {
  const OwnerComplaintsScreen({super.key});

  @override
  State<OwnerComplaintsScreen> createState() => _OwnerComplaintsScreenState();
}

class _OwnerComplaintsScreenState extends State<OwnerComplaintsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Complaints', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Received'),
            Tab(text: 'Filed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildComplaintsList(context, 'Received'),
          _buildComplaintsList(context, 'Filed'),
        ],
      ),
    );
  }

  Widget _buildComplaintsList(BuildContext context, String type) {
    final provider = context.watch<OwnerProvider>();
    final complaints = provider.complaints.where((c) => c.type == type).toList();

    if (complaints.isEmpty) {
      return Center(
        child: Text('No complaints $type.', style: const TextStyle(color: AppColors.textMuted)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: complaints.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final complaint = complaints[index];
        Color statusColor;
        switch (complaint.status) {
          case 'Open':
            statusColor = AppColors.red;
            break;
          case 'Resolved':
            statusColor = AppColors.emerald;
            break;
          case 'Under Review':
            statusColor = AppColors.accent;
            break;
          default:
            statusColor = AppColors.textSecondary;
        }

        return InkWell(
          onTap: () => _showComplaintDetail(context, complaint),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      type == 'Received' ? Icons.feedback_outlined : Icons.report_outlined,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        complaint.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        complaint.status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'By ${complaint.by} • Against ${complaint.against}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  complaint.description,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (complaint.status == 'Open' && type == 'Received')
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _showComplaintDetail(context, complaint),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Respond'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showComplaintDetail(BuildContext context, Complaint complaint) {
    final TextEditingController responseController = TextEditingController();
    final provider = context.read<OwnerProvider>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Complaint Details', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Title: ${complaint.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('By: ${complaint.by}'),
                Text('Against: ${complaint.against}'),
                Text('Date: ${DateFormat('MMM dd, yyyy').format(complaint.date)}'),
                const Divider(height: 24),
                const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(complaint.description),
                if (complaint.ownerResponse != null) ...[
                  const Divider(height: 24),
                  const Text('Your Response:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(complaint.ownerResponse!),
                ] else if (complaint.status == 'Open' && complaint.type == 'Received') ...[
                  const SizedBox(height: 24),
                  TextField(
                    controller: responseController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Enter your response...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            if (complaint.status == 'Open' && complaint.type == 'Received')
              ElevatedButton(
                onPressed: () {
                  if (responseController.text.trim().isNotEmpty) {
                    provider.respondToComplaint(complaint.id, responseController.text.trim());
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Response submitted.')));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Submit Response', style: TextStyle(color: Colors.white)),
              ),
          ],
        );
      },
    );
  }
}
