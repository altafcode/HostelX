import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../domain/entities/hostel_entity.dart';

// --- Details Header ---
class DetailsHeader extends StatelessWidget {
  final HostelEntity hostel;
  const DetailsHeader({super.key, required this.hostel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hostel.name,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.w800, height: 1.05),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.location_on_outlined,
                size: 13, color: AppColors.textMuted),
            const SizedBox(width: 3),
            Expanded(
                child: Text(hostel.location,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5ECFF)),
          ),
          child: Row(
            children: [
              Expanded(
                  child: _SummaryStat(
                      value: '${hostel.rating}',
                      label: '${hostel.reviewsCount} reviews',
                      valueColor: const Color(0xFFD97706),
                      leading: const Icon(Icons.star_rounded,
                          size: 15, color: AppColors.accent))),
              const _SummaryDivider(),
              Expanded(
                  child: _SummaryStat(
                      value: hostel.type == HostelType.boys ? 'Boys' : 'Girls',
                      label: 'Hostel Type',
                      valueColor: hostel.type == HostelType.boys
                          ? AppColors.boysText
                          : AppColors.girlsText)),
              const _SummaryDivider(),
              Expanded(
                  child: _SummaryStat(
                      value: '${hostel.minContractMonths}mo',
                      label: 'Min Stay',
                      valueColor: AppColors.primary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;
  final Widget? leading;
  const _SummaryStat(
      {required this.value,
      required this.label,
      required this.valueColor,
      this.leading});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 3)],
            Flexible(
                child: Text(value,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: valueColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
          ],
        ),
        const SizedBox(height: 3),
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();
  @override
  Widget build(BuildContext context) => Container(
      height: 30,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: const Color(0xFFE5ECFF));
}

// --- Details Amenities ---
class DetailsAmenities extends StatelessWidget {
  final List<String> facilities;
  const DetailsAmenities({super.key, required this.facilities});

  @override
  Widget build(BuildContext context) {
    const maxDisplay = 8;
    final hasMore = facilities.length > maxDisplay;
    final displayCount = hasMore ? maxDisplay : facilities.length;
    final displayFacilities = facilities.take(displayCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayCount,
          padding: const EdgeInsets.symmetric(vertical: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.92,
          ),
          itemBuilder: (context, index) {
            if (hasMore && index == displayCount - 1) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        '+${facilities.length - 7}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'More',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              );
            }
            final amenity = displayFacilities[index];
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(_getIcon(amenity),
                        size: 20.5, color: const Color(0xFF475569)),
                  ),
                ),
                const SizedBox(height: 5),
                Expanded(
                  child: Text(
                    amenity,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  IconData _getIcon(String name) {
    final value = name.toLowerCase().trim();
    if (value.contains('wifi') || value.contains('internet')) {
        return Icons.wifi_rounded;
    }
    if (value == 'ac' || value.contains('air') || value.contains('cool')) {
        return Icons.ac_unit_rounded;
    }
    if (value.contains('mess') ||
        value.contains('meal') ||
        value.contains('food') ||
        value.contains('dining') ||
        value.contains('kitchen')) {
        return Icons.restaurant_rounded;
    }
    if (value.contains('laundry') || value.contains('washing')) {
        return Icons.local_laundry_service_rounded;
    }
    if (value.contains('shuttle') ||
        value.contains('transport') ||
        value.contains('bus')) {
        return Icons.directions_bus_rounded;
    }
    if (value.contains('generator') || value.contains('power')) {
        return Icons.power_rounded;
    }
    if (value.contains('parking')) {
        return Icons.local_parking_rounded;
    }
    if (value.contains('cctv') ||
        value.contains('camera') ||
        value.contains('security')) {
        return Icons.videocam_rounded;
    }
    if (value.contains('geyser') ||
        value.contains('hot water') ||
        value.contains('water')) {
        return Icons.hot_tub_rounded;
    }
    if (value.contains('backup') || value.contains('ups')) {
        return Icons.bolt_rounded;
    }
    if (value.contains('study')) return Icons.menu_book_rounded;
    if (value.contains('gym')) return Icons.fitness_center_rounded;
    if (value.contains('clean')) return Icons.cleaning_services_rounded;
    if (value.contains('bed')) return Icons.bed_rounded;
    return Icons.home_repair_service_rounded;
  }
}

// --- Details Rooms ---
class DetailsRooms extends StatelessWidget {
  final List<({String title, int price, String features})> rooms;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const DetailsRooms({
    super.key,
    required this.rooms,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Room Types',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        SizedBox(
          height: 105,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: rooms.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final room = rooms[i];
              return _RoomPlanCard(
                title: room.title,
                price: room.price,
                features: room.features,
                selected: selectedIndex == i,
                onTap: () => onSelected(i),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RoomPlanCard extends StatelessWidget {
  final String title;
  final int price;
  final String features;
  final bool selected;
  final VoidCallback onTap;
  const _RoomPlanCard(
      {required this.title,
      required this.price,
      required this.features,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.borderLight,
              width: selected ? 2 : 1),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                if (selected)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8)),
                    child: const Text('SELECTED',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.2)),
                  ),
              ],
            ),
            Text(features,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary, height: 1.2),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            Row(
              children: [
                Text('PKR ${AppHelpers.formatPrice(price)}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary)),
                const SizedBox(width: 4),
                const Text('/month',
                    style:
                        TextStyle(fontSize: 9, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
