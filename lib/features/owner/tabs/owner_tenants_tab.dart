import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/owner_provider.dart';
import '../widgets/tenant_details_sheet.dart';

class OwnerTenantsTab extends StatefulWidget {
  final String? hostelFilter;
  const OwnerTenantsTab({super.key, this.hostelFilter});

  @override
  State<OwnerTenantsTab> createState() => _OwnerTenantsTabState();
}

class _OwnerTenantsTabState extends State<OwnerTenantsTab> {
  String _searchQuery = '';
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Active', 'Expiring Soon', 'Overdue', 'Past'];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OwnerProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs ', decimalDigits: 0);

    List<Tenant> filteredTenants = provider.tenants.where((t) {
      if (widget.hostelFilter != null && t.hostelName != widget.hostelFilter) return false;

      bool matchesSearch = t.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                           t.hostelName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           t.roomNumber.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      final daysRemaining = t.checkOut.difference(DateTime.now()).inDays;
      
      switch (_selectedFilter) {
        case 'Active':
          return daysRemaining > 7 && t.paymentStatus != 'Overdue';
        case 'Expiring Soon':
          return daysRemaining >= 0 && daysRemaining <= 7;
        case 'Overdue':
          return t.paymentStatus == 'Overdue';
        case 'Past':
          return daysRemaining < 0;
        case 'All':
        default:
          return true;
      }
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.hostelFilter != null ? AppBar(
        backgroundColor: Colors.white,
        title: Text('Tenants - ${widget.hostelFilter}', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
      ) : null,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.hostelFilter == null)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Text(
                  'Tenants',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search tenants, rooms...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = filter == _selectedFilter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedFilter = filter);
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.1),
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.borderLight,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filteredTenants.isEmpty
                  ? const Center(
                      child: Text('No tenants found.',
                          style: TextStyle(color: AppColors.textMuted)))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filteredTenants.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final tenant = filteredTenants[index];
                        return _buildTenantCard(context, tenant, currencyFormat, provider);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTenantCard(BuildContext context, Tenant tenant, NumberFormat currencyFormat, OwnerProvider provider) {
    Color statusColor;
    switch (tenant.paymentStatus) {
      case 'Paid':
        statusColor = AppColors.emerald;
        break;
      case 'Pending':
        statusColor = AppColors.accent;
        break;
      case 'Overdue':
        statusColor = AppColors.red;
        break;
      default:
        statusColor = AppColors.textSecondary;
    }

    final dateFormat = DateFormat('d MMM yyyy');

    return InkWell(
      onTap: () => showTenantDetailsSheet(context, tenant, provider),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: NetworkImage(tenant.avatarUrl),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tenant.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tenant.paymentStatus,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${tenant.hostelName} • ${tenant.roomNumber} (${tenant.roomType})',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          '${dateFormat.format(tenant.checkIn)} - ${dateFormat.format(tenant.checkOut)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        flex: 2,
                        child: Text(
                          '${currencyFormat.format(tenant.monthlyRent)}/mo',
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
