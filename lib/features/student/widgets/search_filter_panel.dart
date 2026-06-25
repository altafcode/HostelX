import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SearchFilterPanel extends StatelessWidget {
  final double minPrice, maxPrice, minRating;
  final String availability;
  final List<String> selectedAmenities, allAmenities;
  final ValueChanged<double> onMinPrice, onMaxPrice, onMinRating;
  final ValueChanged<String> onAvailability;
  final ValueChanged<String> onAmenityToggle;
  final VoidCallback onReset;

  const SearchFilterPanel({
    super.key,
    required this.minPrice,
    required this.maxPrice,
    required this.minRating,
    required this.availability,
    required this.selectedAmenities,
    required this.allAmenities,
    required this.onMinPrice,
    required this.onMaxPrice,
    required this.onMinRating,
    required this.onAvailability,
    required this.onAmenityToggle,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: AppColors.borderLight),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
              ),
              GestureDetector(
                onTap: onReset,
                child: const Text(
                  'Reset',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Price: PKR ${minPrice.toInt()} – PKR ${maxPrice.toInt()}',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary),
          ),
          RangeSlider(
            min: 0,
            max: 50000,
            activeColor: AppColors.primary,
            values: RangeValues(minPrice, maxPrice),
            onChanged: (v) {
              onMinPrice(v.start);
              onMaxPrice(v.end);
            },
          ),
          Text(
            'Min Rating: ${minRating.toStringAsFixed(1)}★',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary),
          ),
          Slider(
            min: 0,
            max: 5,
            divisions: 10,
            value: minRating,
            activeColor: AppColors.accent,
            onChanged: onMinRating,
          ),
          const SizedBox(height: 4),
          const Text(
            'Availability',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: ['All', 'Open', 'Full'].map((a) {
              final active = availability == a;
              return GestureDetector(
                onTap: () => onAvailability(a),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color:
                            active ? AppColors.primary : AppColors.borderLight),
                  ),
                  child: Text(
                    a,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.white : AppColors.textSecondary),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          const Text(
            'Amenities',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: allAmenities.map((a) {
              final sel = selectedAmenities.contains(a);
              return GestureDetector(
                onTap: () => onAmenityToggle(a),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: sel ? AppColors.primary : AppColors.borderLight),
                  ),
                  child: Text(
                    a,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color:
                            sel ? AppColors.primary : AppColors.textSecondary),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
