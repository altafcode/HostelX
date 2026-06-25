import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/hostel_entity.dart';
import '../providers/admin_provider.dart';

class AdminPendingListingDetailScreen extends StatelessWidget {
  final HostelEntity hostel;

  const AdminPendingListingDetailScreen({super.key, required this.hostel});

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Verify Listing',
            style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hostel Image and Name
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(hostel.images.isNotEmpty
                      ? hostel.images[0]
                      : 'https://placehold.co/800x400?text=HostelX'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hostel.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    hostel.location,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Hostel Details
            const Text(
              'Hostel Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Gender', hostel.type.name.toUpperCase()),
            _buildDetailRow('Min Contract', '${hostel.minContractMonths} Months'),
            _buildDetailRow('Security Deposit', 'Rs ${hostel.securityDeposit}'),
            _buildDetailRow('Description', hostel.description),
            const SizedBox(height: 24),

            // Owner Details
            const Text(
              'Owner Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Owner Name', hostel.ownerName),
            _buildDetailRow('Contact',
                hostel.ownerPhone.isEmpty ? 'Not provided' : hostel.ownerPhone),
            _buildDetailRow(
                'WhatsApp',
                hostel.ownerWhatsapp.isEmpty
                    ? 'Not provided'
                    : hostel.ownerWhatsapp),
            const SizedBox(height: 24),

            // Verification Documents
            const Text(
              'Verification Documents',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildDocumentCard('Owner CNIC (ID Card)',
                hostel.documentUrls['CNIC Copy (Front & Back)']),
            const SizedBox(height: 8),
            _buildDocumentCard('Property Ownership Proof / Lease',
                hostel.documentUrls['Property Ownership Proof / Lease']),
            const SizedBox(height: 8),
            _buildDocumentCard('NOC from Local Authority',
                hostel.documentUrls['NOC from Local Authority']),
            const SizedBox(height: 100), // Space for bottom buttons
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -5),
            )
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showRejectDialog(context, hostel),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: AppColors.red,
                    side: const BorderSide(color: AppColors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Reject',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    adminProv.approveHostel(hostel.id);
                    Navigator.pop(context); // Go back
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                            Text('${hostel.name} approved successfully!')));
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Approve',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(String title, String? url) {
    return InkWell(
      onTap: url == null ? null : () => _openUrl(url),
      borderRadius: BorderRadius.circular(12),
      child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf, color: AppColors.primary, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  url == null ? 'Not uploaded' : 'Tap to view document',
                  style: TextStyle(
                    fontSize: 12,
                    color: url == null ? AppColors.red : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Icon(url == null ? Icons.error_outline : Icons.remove_red_eye,
              color: url == null ? AppColors.red : AppColors.primary),
        ],
      ),
    ));
  }

  void _openUrl(String url) {
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _showRejectDialog(BuildContext context, HostelEntity hostel) {
    final adminProv = context.read<AdminProvider>();
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Hostel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Provide a reason for rejecting ${hostel.name}'),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red, foregroundColor: Colors.white),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                adminProv.rejectHostel(hostel.id, controller.text);
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context); // Go back from detail screen
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${hostel.name} rejected.')));
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
