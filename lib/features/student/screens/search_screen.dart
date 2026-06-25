import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/hostel_entity.dart';
import '../providers/hostel_provider.dart';
import '../widgets/home/hostel_cards.dart';
import '../widgets/search_filter_panel.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _ctrl;
  String _typeFilter = 'All';
  String _availability = 'All';
  double _minPrice = 0;
  double _maxPrice = 50000;
  double _minRating = 0;
  final List<String> _selectedAmenities = [];
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialQuery ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<HostelEntity> _filter(List<HostelEntity> hostels) {
    final q = _ctrl.text.toLowerCase();
    return hostels.where((h) {
      if (h.approvalStatus != ApprovalStatus.approved) return false;
      final matchSearch = q.isEmpty ||
          h.name.toLowerCase().contains(q) ||
          h.location.toLowerCase().contains(q) ||
          h.city.toLowerCase().contains(q);
      final matchType = _typeFilter == 'All' ||
          (_typeFilter == 'Boys' && h.type == HostelType.boys) ||
          (_typeFilter == 'Girls' && h.type == HostelType.girls);
      final matchPrice = h.price >= _minPrice && h.price <= _maxPrice;
      final matchRating = h.rating >= _minRating;
      final matchAmenities = _selectedAmenities.isEmpty ||
          _selectedAmenities.every((a) => h.facilities.contains(a));
      final matchAvail = _availability == 'All' ||
          (_availability == 'Open' &&
              h.availability == HostelAvailability.open) ||
          (_availability == 'Full' &&
              h.availability == HostelAvailability.full);
      return matchSearch &&
          matchType &&
          matchPrice &&
          matchRating &&
          matchAmenities &&
          matchAvail;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final hostels = context.watch<HostelProvider>().allHostels;
    final allAmenities = hostels.expand((h) => h.facilities).toSet().toList();
    final results = _filter(hostels);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _SearchTopSection(
            controller: _ctrl,
            typeFilter: _typeFilter,
            showFilters: _showFilters,
            onSearchChanged: (_) => setState(() {}),
            onToggleFilters: () => setState(() => _showFilters = !_showFilters),
            onTypeChanged: (t) => setState(() => _typeFilter = t),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _showFilters
                ? SearchFilterPanel(
                    minPrice: _minPrice,
                    maxPrice: _maxPrice,
                    minRating: _minRating,
                    availability: _availability,
                    selectedAmenities: _selectedAmenities,
                    allAmenities: allAmenities,
                    onMinPrice: (v) => setState(() => _minPrice = v),
                    onMaxPrice: (v) => setState(() => _maxPrice = v),
                    onMinRating: (v) => setState(() => _minRating = v),
                    onAvailability: (v) => setState(() => _availability = v),
                    onAmenityToggle: (a) => setState(() {
                      _selectedAmenities.contains(a)
                          ? _selectedAmenities.remove(a)
                          : _selectedAmenities.add(a);
                    }),
                    onReset: () => setState(() {
                      _minPrice = 0;
                      _maxPrice = 50000;
                      _minRating = 0;
                      _selectedAmenities.clear();
                      _availability = 'All';
                    }),
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: results.isEmpty
                ? const Center(
                    child: Text('No hostels found.',
                        style: TextStyle(color: AppColors.textMuted)))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, i) => AllListingsCard(hostel: results[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchTopSection extends StatelessWidget {
  final TextEditingController controller;
  final String typeFilter;
  final bool showFilters;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onToggleFilters;
  final ValueChanged<String> onTypeChanged;

  const _SearchTopSection({
    required this.controller,
    required this.typeFilter,
    required this.showFilters,
    required this.onSearchChanged,
    required this.onToggleFilters,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 12, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search hostels, areas, cities...',
                    hintStyle: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.textMuted, size: 18),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onToggleFilters,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: showFilters ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Icon(Icons.tune_rounded,
                      size: 18,
                      color:
                          showFilters ? Colors.white : AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['All', 'Boys', 'Girls'].map((t) {
                final active = typeFilter == t;
                return GestureDetector(
                  onTap: () => onTypeChanged(t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: active
                              ? AppColors.primary
                              : AppColors.borderLight),
                    ),
                    child: Text(
                      t,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color:
                              active ? Colors.white : AppColors.textSecondary),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
