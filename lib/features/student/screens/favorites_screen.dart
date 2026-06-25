import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../providers/hostel_provider.dart';
import '../widgets/home/hostel_cards.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hostelProvider = context.watch<HostelProvider>();
    final hostels = hostelProvider.favoriteHostels;

    return SafeArea(
      child: CustomScrollView(slivers: [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Text(AppStrings.savedHostels,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
          ),
        ),
        if (hostels.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border_rounded,
                      size: 48, color: AppColors.textMuted),
                  SizedBox(height: 16),
                  Text('No saved hostels yet.',
                      style: TextStyle(color: AppColors.textMuted)),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: AllListingsCard(hostel: hostels[i]),
                ),
                childCount: hostels.length,
              ),
            ),
          ),
      ]),
    );
  }
}
