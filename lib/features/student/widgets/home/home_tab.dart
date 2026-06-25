import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../routes/app_router.dart';
import '../../../../widgets/common/app_tab_bar.dart';
import '../../../../widgets/common/primary_button.dart';
import '../../../../widgets/common/section_header.dart';
import '../../providers/hostel_provider.dart';
import 'home_widgets.dart';
import 'hostel_cards.dart';
import 'hostel_section.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final hostelProvider = context.watch<HostelProvider>();

    return SafeArea(
      child: Column(
        children: [
          const HomeTopBar(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: HomeSearchBar(city: hostelProvider.selectedCity),
                ),
                const SizedBox(height: 12),
                AppTabBar(
                  tabs: AppConstants.homeFilters,
                  selected: hostelProvider.activeFilter,
                  onChanged: hostelProvider.setFilter,
                ),
                const SizedBox(height: 24),
                if (hostelProvider.isLoading &&
                    hostelProvider.allHostels.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 80),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (hostelProvider.error != null &&
                    hostelProvider.allHostels.isEmpty)
                  _ErrorState(
                    error: hostelProvider.error!,
                    onRetry: () => hostelProvider.loadHostels(),
                  )
                else
                  _buildContent(context, hostelProvider),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, HostelProvider hostelProvider) {
    final recentlyViewedInCity = hostelProvider.recentlyViewed
        .where((h) => h.city == hostelProvider.selectedCity)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HostelHorizontalSection(
          title: '✨ ${AppStrings.featuredHostels}',
          actionLabel: AppStrings.seeAll,
          onAction: () => Navigator.of(context).pushNamed(AppRouter.search),
          hostels: hostelProvider.recommended,
          height: 250,
          itemBuilder: (h) => RecommendedCard(hostel: h),
        ),
        HostelHorizontalSection(
          title: '🕘 Recently Viewed',
          actionLabel: AppStrings.seeAll,
          onAction: () => Navigator.of(context).pushNamed(AppRouter.search),
          hostels: recentlyViewedInCity,
          itemBuilder: (h) => PopularCard(hostel: h),
        ),
        HostelHorizontalSection(
          title: AppStrings.mostPopular,
          actionLabel: AppStrings.seeAll,
          onAction: () => Navigator.of(context).pushNamed(AppRouter.search),
          hostels: hostelProvider.mostPopular,
          itemBuilder: (h) => PopularCard(hostel: h),
        ),
        HostelHorizontalSection(
          title: AppStrings.budgetFriendly,
          actionLabel: AppStrings.seeAll,
          onAction: () => Navigator.of(context).pushNamed(AppRouter.search),
          hostels: hostelProvider.budgetFriendly,
          height: 88,
          spacing: 10,
          itemBuilder: (h) => BudgetCard(hostel: h),
        ),
        HostelHorizontalSection(
          title: AppStrings.recentlyAdded,
          actionLabel: AppStrings.seeAll,
          onAction: () => Navigator.of(context).pushNamed(AppRouter.search),
          hostels: hostelProvider.recentlyAdded,
          itemBuilder: (h) => PopularCard(hostel: h, showNewBadge: true),
        ),
        SectionHeader(
          title: '${AppStrings.allListings} ${hostelProvider.selectedCity}',
          actionLabel: AppStrings.seeAll,
          onAction: () => Navigator.of(context).pushNamed(AppRouter.search),
        ),
        const SizedBox(height: 12),
        if (hostelProvider.cityHostels.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('No hostels found in this city.',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
          )
        else
          ...hostelProvider.cityHostels.map((h) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: AllListingsCard(hostel: h),
              )),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.red, size: 48),
            const SizedBox(height: 16),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Retry',
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
