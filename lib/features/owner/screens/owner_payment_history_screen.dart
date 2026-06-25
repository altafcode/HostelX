import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/owner_provider.dart';
import 'owner_payout_detail_screen.dart';

class OwnerPaymentHistoryScreen extends StatefulWidget {
  const OwnerPaymentHistoryScreen({super.key});

  @override
  State<OwnerPaymentHistoryScreen> createState() => _OwnerPaymentHistoryScreenState();
}

class _OwnerPaymentHistoryScreenState extends State<OwnerPaymentHistoryScreen> {
  int _selectedYear = 2026;
  String _selectedMonth = 'All';
  String _searchQuery = '';

  final List<int> _years = [2025, 2026];
  final List<String> _months = ['All', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OwnerProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs ', decimalDigits: 0);

    final filteredPayouts = provider.payouts.where((payout) {
      final date = payout.date;
      final query = _searchQuery.toLowerCase();
      final hostelNames = payout.hostelNames.join(' ').toLowerCase();
      final transferId = (payout.transferId ?? '').toLowerCase();

      final matchesYear = date.year == _selectedYear;
      final matchesMonth = _selectedMonth == 'All' || DateFormat.MMM().format(date) == _selectedMonth;
      final matchesSearch = query.isEmpty ||
          hostelNames.contains(query) ||
          transferId.contains(query) ||
          payout.status.toLowerCase().contains(query);

      return matchesYear && matchesMonth && matchesSearch;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Payment History', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search hostel or transfer...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<int>(
                          isExpanded: true,
                          underline: const SizedBox(),
                          value: _selectedYear,
                          items: _years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                          onChanged: (val) => setState(() => _selectedYear = val!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          underline: const SizedBox(),
                          value: _selectedMonth,
                          items: _months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                          onChanged: (val) => setState(() => _selectedMonth = val!),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredPayouts.isEmpty
                ? const Center(child: Text('No payouts found for this criteria.', style: TextStyle(color: AppColors.textMuted)))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredPayouts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final payout = filteredPayouts[index];
                      final hostelLabel = payout.hostelNames.isEmpty
                          ? 'Hostel payout'
                          : payout.hostelNames.join(', ');

                      return InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                OwnerPayoutDetailScreen(payout: payout),
                          ),
                        ),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Row(
                            children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.emerald.withValues(alpha: 0.12),
                              child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.emerald),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(hostelLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(
                                    '${DateFormat('d MMM yyyy').format(payout.date)} - Stripe payout',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                  ),
                                  if ((payout.transferId ?? '').isNotEmpty)
                                    Text(
                                      payout.transferId!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(currencyFormat.format(payout.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.emerald.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    payout.status,
                                    style: const TextStyle(color: AppColors.emerald, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
