import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/hostel_entity.dart';
import '../providers/hostel_provider.dart';

class AvailabilityBadge extends StatelessWidget {
  final HostelAvailability availability;
  const AvailabilityBadge({super.key, required this.availability});

  @override
  Widget build(BuildContext context) {
    final isOpen = availability == HostelAvailability.open;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen
            ? AppColors.emerald.withValues(alpha: 0.9)
            : AppColors.red.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isOpen ? 'OPEN' : 'FULL',
        style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5),
      ),
    );
  }
}

class AvailabilityDot extends StatelessWidget {
  final HostelAvailability availability;
  const AvailabilityDot({super.key, required this.availability});

  @override
  Widget build(BuildContext context) {
    final isOpen = availability == HostelAvailability.open;
    return Row(children: [
      Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
              color: isOpen ? AppColors.emerald : AppColors.red,
              borderRadius: BorderRadius.circular(4))),
      const SizedBox(width: 4),
      Text(isOpen ? 'Open' : 'Full',
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isOpen ? AppColors.emerald : AppColors.red)),
    ]);
  }
}

class TypeBadge extends StatelessWidget {
  final HostelType type;
  const TypeBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final isGirls = type == HostelType.girls;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isGirls ? AppColors.girlsBg : AppColors.boysBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isGirls ? 'Girls' : 'Boys',
        style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: isGirls ? AppColors.girlsText : AppColors.boysText),
      ),
    );
  }
}

class HeartButton extends StatelessWidget {
  final String hostelId;
  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final Color? iconColor;

  const HeartButton({
    super.key,
    required this.hostelId,
    this.size = 32,
    this.iconSize = 16,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<HostelProvider>(
      builder: (context, provider, _) {
        final isFav = provider.isFavorite(hostelId);
        return GestureDetector(
          onTap: () => provider.toggleFavorite(hostelId),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(size / 2),
            ),
            child: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: iconSize,
              color: isFav ? Colors.red : (iconColor ?? AppColors.textMuted),
            ),
          ),
        );
      },
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
    );
  }
}
