import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../domain/entities/hostel_entity.dart';
import '../../../../routes/app_router.dart';
import '../student_common_widgets.dart';

class FacilityIcon extends StatelessWidget {
  final String facility;
  const FacilityIcon({super.key, required this.facility});

  @override
  Widget build(BuildContext context) {
    return Icon(_getIcon(facility), size: 16, color: AppColors.primary);
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

class RecommendedCard extends StatelessWidget {
  final HostelEntity hostel;
  const RecommendedCard({super.key, required this.hostel});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.76;
    return GestureDetector(
      onTap: () => Navigator.of(context)
          .pushNamed(AppRouter.hostelDetails, arguments: hostel.id),
      child: SizedBox(
        width: width,
        height: 250,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.network(
                hostel.images[0],
                width: width,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    width: width, height: 250, color: AppColors.surfaceVariant),
              ),
            ),
            Container(
              width: width,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x22000000),
                    Color(0x05000000),
                    Color(0xE0000000)
                  ],
                  stops: [0.0, 0.38, 1.0],
                ),
              ),
            ),
            Positioned(
                top: 12,
                left: 12,
                child: AvailabilityBadge(availability: hostel.availability)),
            Positioned(
                top: 12, right: 12, child: HeartButton(hostelId: hostel.id)),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.18)),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(children: [
                              const Icon(Icons.star_rounded,
                                  color: AppColors.accent, size: 13),
                              const SizedBox(width: 3),
                              Text('${hostel.rating}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                              Text(' (${hostel.reviewsCount})',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 10)),
                            ]),
                          ),
                          const Spacer(),
                          TypeBadge(type: hostel.type),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        hostel.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            height: 1.1),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(children: [
                        const Icon(Icons.location_on_outlined,
                            color: Colors.white70, size: 12),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            hostel.location,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children:
                                  hostel.facilities.take(3).map((facility) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    facility,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                      'Rs. ${AppHelpers.formatPrice(hostel.price)}',
                                      style: const TextStyle(
                                          color: AppColors.accent,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800)),
                                  const SizedBox(width: 4),
                                  const Text('/month',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 9)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class PopularCard extends StatelessWidget {
  final HostelEntity hostel;
  final bool showNewBadge;
  const PopularCard(
      {super.key, required this.hostel, this.showNewBadge = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context)
          .pushNamed(AppRouter.hostelDetails, arguments: hostel.id),
      child: Container(
        width: 152,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                hostel.images[0],
                height: 110,
                width: 152,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    height: 110, width: 152, color: AppColors.surfaceVariant),
              ),
            ),
            if (showNewBadge)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                      color: AppColors.emerald,
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text('NEW',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5)),
                ),
              ),
            Positioned(
                top: 8,
                right: 8,
                child:
                    HeartButton(hostelId: hostel.id, size: 26, iconSize: 13)),
          ]),
          Expanded(
              child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(hostel.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(hostel.location,
                  style:
                      const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const Spacer(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.star_rounded,
                          size: 10, color: AppColors.accent),
                      const SizedBox(width: 2),
                      Text('${hostel.rating}',
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF92400E))),
                    ]),
                  ),
                ),
                const SizedBox(width: 4),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Rs. ${AppHelpers.formatPriceShort(hostel.price)}',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary)),
                      const SizedBox(width: 2),
                      const Text('/mo',
                          style: TextStyle(
                              fontSize: 8, color: AppColors.textMuted)),
                    ],
                  ),
                ]),
              ]),
            ]),
          )),
        ]),
      ),
    );
  }
}

class BudgetCard extends StatelessWidget {
  final HostelEntity hostel;
  const BudgetCard({super.key, required this.hostel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context)
          .pushNamed(AppRouter.hostelDetails, arguments: hostel.id),
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              hostel.images[0],
              width: 66,
              height: 66,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                  width: 66,
                  height: 66,
                  color: AppColors.surfaceVariant,
                  child: const Icon(Icons.apartment_rounded,
                      color: AppColors.textMuted)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hostel.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 10, color: AppColors.textMuted),
                    const SizedBox(width: 2),
                    Expanded(
                        child: Text(hostel.location,
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                  ]),
                ],
              ),
              const SizedBox(height: 5),
              Flexible(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: hostel.facilities
                      .take(3)
                      .map((f) => FacilityIcon(facility: f))
                      .toList(),
                ),
              ),
            ],
          )),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                            color: AppColors.emerald,
                            borderRadius: BorderRadius.circular(4))),
                    const SizedBox(width: 3),
                    const Text('Open',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.emerald)),
                  ]),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Rs. ${AppHelpers.formatPriceShort(hostel.price)}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(width: 4),
                    const Text('/mo',
                        style:
                            TextStyle(fontSize: 9, color: AppColors.textMuted)),
                  ]),
                ]),
          ),
        ]),
      ),
    );
  }
}

class AllListingsCard extends StatelessWidget {
  final HostelEntity hostel;
  const AllListingsCard({super.key, required this.hostel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context)
          .pushNamed(AppRouter.hostelDetails, arguments: hostel.id),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(18)),
            child: Image.network(
              hostel.images[0],
              width: 110,
              height: 110,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                  width: 110,
                  height: 110,
                  color: AppColors.surfaceVariant,
                  child: const Icon(Icons.apartment_rounded,
                      color: AppColors.textMuted)),
            ),
          ),
          Expanded(
              child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                TypeBadge(type: hostel.type),
                const Spacer(),
                AvailabilityDot(availability: hostel.availability),
              ]),
              const SizedBox(height: 6),
              Text(hostel.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.location_on_outlined,
                    size: 11, color: AppColors.textMuted),
                const SizedBox(width: 2),
                Expanded(
                    child: Text(hostel.location,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Flexible(
                  child: Row(children: [
                    const Icon(Icons.star_rounded,
                        size: 13, color: AppColors.accent),
                    const SizedBox(width: 2),
                    Text('${hostel.rating}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: AppColors.textPrimary)),
                    const SizedBox(width: 2),
                    Flexible(
                        child: Text(' (${hostel.reviewsCount})',
                            style: const TextStyle(
                                fontSize: 10, color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                  ]),
                ),
                const SizedBox(width: 8),
                Text('Rs. ${AppHelpers.formatPrice(hostel.price)}/mo',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        fontSize: 13)),
              ]),
              const SizedBox(height: 8),
              Wrap(
                  spacing: 8,
                  children: hostel.facilities
                      .take(5)
                      .map((f) => FacilityIcon(facility: f))
                      .toList()),
            ]),
          )),
        ]),
      ),
    );
  }
}
