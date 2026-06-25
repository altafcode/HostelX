import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../student/providers/hostel_provider.dart';
import '../providers/owner_provider.dart';
import 'owner_listing_detail_screen.dart';

class OwnerRevenueDetailScreen extends StatelessWidget {
  final String monthName;
  final int year;
  final int monthIndex;

  const OwnerRevenueDetailScreen({
    super.key,
    required this.monthName,
    required this.year,
    required this.monthIndex,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OwnerProvider>();
    final hostelProv = context.watch<HostelProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs ', decimalDigits: 0);
    
    final breakdown = provider.getHostelBreakdownForMonth(year, monthIndex);
    final totalNet = provider.getMonthlyNetEarnings(year, monthIndex);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('$monthName $year Details', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Net Revenue', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text(currencyFormat.format(totalNet), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Listing-wise Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            ...breakdown.entries.map((e) {
              final matches =
                  hostelProv.allHostels.where((h) => h.name == e.key).toList();
              if (matches.isEmpty) return const SizedBox.shrink();
              final hostel = matches.first;
              final netEarnings = e.value * (1 - provider.commissionRate);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => OwnerListingDetailScreen(hostel: hostel)),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            hostel.images.isNotEmpty ? hostel.images[0] : '',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(width: 60, height: 60, color: AppColors.surfaceVariant, child: const Icon(Icons.apartment)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text('Net: ${currencyFormat.format(netEarnings)}', style: const TextStyle(color: AppColors.emerald, fontWeight: FontWeight.w600, fontSize: 13)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
