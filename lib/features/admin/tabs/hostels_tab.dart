import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/hostel_entity.dart';
import '../../../widgets/common/status_badge.dart';
import '../providers/admin_provider.dart';
import '../screens/admin_hostel_detail_screen.dart';
import '../screens/admin_pending_listing_detail_screen.dart';

class AdminHostelsTab extends StatefulWidget {
  const AdminHostelsTab({super.key});

  @override
  State<AdminHostelsTab> createState() => _AdminHostelsTabState();
}

class _AdminHostelsTabState extends State<AdminHostelsTab> {
  String _searchQuery = '';
  String _selectedCategory = 'All'; // 'All', 'Pending', 'Approved', 'Rejected'

  // Advanced filters
  String? _filterCity;
  HostelType? _filterGender;
  RangeValues _priceRange = const RangeValues(5000, 50000);

  final List<String> _categories = ['All', 'Pending', 'Approved', 'Rejected'];

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    final NumberFormat currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: 'Rs ', decimalDigits: 0);

    List<HostelEntity> filtered = adminProv.hostels.where((h) {
      if (_searchQuery.isNotEmpty &&
          !h.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }

      // Category Filter
      if (_selectedCategory == 'Pending' &&
          h.approvalStatus != ApprovalStatus.pending) {
        return false;
      }
      if (_selectedCategory == 'Approved' &&
          h.approvalStatus != ApprovalStatus.approved) {
        return false;
      }
      if (_selectedCategory == 'Rejected' &&
          h.approvalStatus != ApprovalStatus.rejected) {
        return false;
      }

      // Advanced Filters
      if (_filterCity != null &&
          _filterCity != 'All' &&
          h.city != _filterCity) {
        return false;
      }
      if (_filterGender != null && h.type != _filterGender) {
        return false;
      }
      if (h.price < _priceRange.start || h.price > _priceRange.end) {
        return false;
      }

      return true;
    }).toList();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(AppStrings.hostelManagement,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search hostels...',
                      prefixIcon:
                          const Icon(Icons.search, color: AppColors.textMuted),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.borderLight),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.white),
                    onPressed: _showAdvancedFilters,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategory = cat);
                  },
                  selectedColor: AppColors.primary.withValues(alpha: 0.1),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color:
                        isSelected ? AppColors.primary : AppColors.borderLight,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('No hostels found.',
                        style: TextStyle(color: AppColors.textMuted)))
                : ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final h = filtered[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            if (h.approvalStatus == ApprovalStatus.pending) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AdminPendingListingDetailScreen(
                                          hostel: h),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AdminHostelDetailScreen(hostel: h),
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: AppColors.borderLight)),
                            child: Row(children: [
                              ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(h.images[0],
                                      width: 54,
                                      height: 54,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                          width: 54,
                                          height: 54,
                                          color: AppColors.surfaceVariant,
                                          child: const Icon(
                                              Icons.apartment_rounded,
                                              color: AppColors.textMuted)))),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(h.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: AppColors.textPrimary)),
                                    Text(h.location,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary)),
                                    Text('${currencyFormat.format(h.price)}/mo',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary)),
                                  ])),
                              StatusBadge.fromApprovalStatus(h.approvalStatus),
                            ]),
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

  void _showAdvancedFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Advanced Filters',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                const Text('City',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _filterCity,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                  items: ['All', ...AppConstants.cities]
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    setModalState(
                        () => _filterCity = val == 'All' ? null : val);
                    setState(() => _filterCity = val == 'All' ? null : val);
                  },
                ),
                const SizedBox(height: 16),
                const Text('Gender',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Any'),
                      selected: _filterGender == null,
                      onSelected: (_) {
                        setModalState(() => _filterGender = null);
                        setState(() => _filterGender = null);
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Boys'),
                      selected: _filterGender == HostelType.boys,
                      onSelected: (_) {
                        setModalState(() => _filterGender = HostelType.boys);
                        setState(() => _filterGender = HostelType.boys);
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Girls'),
                      selected: _filterGender == HostelType.girls,
                      onSelected: (_) {
                        setModalState(() => _filterGender = HostelType.girls);
                        setState(() => _filterGender = HostelType.girls);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Price Range',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                RangeSlider(
                  values: _priceRange,
                  min: 5000,
                  max: 50000,
                  divisions: 9,
                  labels: RangeLabels(
                    'Rs ${_priceRange.start.toInt()}',
                    'Rs ${_priceRange.end.toInt()}',
                  ),
                  activeColor: AppColors.primary,
                  onChanged: (vals) {
                    setModalState(() => _priceRange = vals);
                    setState(() => _priceRange = vals);
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Rs ${_priceRange.start.toInt()}'),
                    Text('Rs ${_priceRange.end.toInt()}'),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}
