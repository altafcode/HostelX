import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Display
  static const TextStyle displayLarge = TextStyle(
    fontSize: 30, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary, letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 24, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  // Headings
  static const TextStyle headingLarge = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary, height: 1.6,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // Labels
  static const TextStyle labelBold = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 10, fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  // Caption
  static const TextStyle caption = TextStyle(
    fontSize: 10, fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );

  static const TextStyle captionBold = TextStyle(
    fontSize: 10, fontWeight: FontWeight.w700,
    color: AppColors.textMuted, letterSpacing: 0.8,
  );

  // Price
  static const TextStyle priceMain = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static const TextStyle priceMedium = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w800,
    color: AppColors.primary,
  );

  static const TextStyle priceSmall = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w800,
    color: AppColors.primary,
  );

  // Button
  static const TextStyle buttonText = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w700,
    color: Colors.white,
  );
}
