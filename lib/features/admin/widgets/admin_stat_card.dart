import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AdminStatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final String? trend;
  const AdminStatCard(
      {super.key,
      required this.label,
      required this.value,
      required this.color,
      this.trend});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderLight)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(4))),
            if (trend != null)
              Text(trend!,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: trend!.startsWith('+')
                          ? AppColors.emerald
                          : AppColors.red)),
          ]),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary)),
          Text(label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.8)),
        ]),
      );
}
