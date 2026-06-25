import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/owner_provider.dart';

class OwnerReviewsScreen extends StatelessWidget {
  final String? hostelId;
  final String? hostelName;

  const OwnerReviewsScreen({
    super.key,
    this.hostelId,
    this.hostelName,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OwnerProvider>();
    final reviews = provider.reviews
        .where((review) => hostelId == null || review.hostelId == hostelId)
        .toList();
    final averageRating = reviews.isEmpty
        ? 0.0
        : reviews.fold<double>(0, (sum, review) => sum + review.rating) /
            reviews.length;
    final distribution = _ratingDistribution(reviews);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          hostelName == null ? 'Reviews & Ratings' : '$hostelName Reviews',
          style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Rating
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  Column(
                    children: [
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary),
                      ),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < averageRating.round()
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: AppColors.accent,
                            size: 20,
                          );
                        }),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${reviews.length} Reviews',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      children: [
                        for (final star in [5, 4, 3, 2, 1])
                          _buildProgressRow(
                            star.toString(),
                            distribution[star] ?? 0,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Individual Reviews
            const Text('Recent Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            if (reviews.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Text(
                  'No reviews yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reviews.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return _buildReviewCard(context, review, provider);
                },
              ),
          ],
        ),
      ),
    );
  }

  Map<int, double> _ratingDistribution(List<Review> reviews) {
    if (reviews.isEmpty) return {for (final star in [1, 2, 3, 4, 5]) star: 0};
    final counts = <int, int>{};
    for (final review in reviews) {
      final star = review.rating.round().clamp(1, 5).toInt();
      counts[star] = (counts[star] ?? 0) + 1;
    }
    return {
      for (final star in [1, 2, 3, 4, 5])
        star: (counts[star] ?? 0) / reviews.length,
    };
  }

  Widget _buildProgressRow(String star, double percentage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$star★', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: AppColors.borderLight,
                color: AppColors.accent,
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('${(percentage * 100).toInt()}%', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, Review review, OwnerProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(review.avatarUrl),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(review.date, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppColors.accent,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(review.text, style: const TextStyle(color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          if (review.ownerReply != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(left: 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: const Border(left: BorderSide(color: AppColors.primary, width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Owner Reply', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text(review.ownerReply!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => _showReplyDialog(context, review, provider),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Reply'),
              ),
            ),
        ],
      ),
    );
  }

  void _showReplyDialog(BuildContext context, Review review, OwnerProvider provider) {
    final TextEditingController replyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Reply to Review'),
          content: TextField(
            controller: replyController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Enter your reply...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (replyController.text.trim().isNotEmpty) {
                  await provider.addOwnerReply(
                    review.id,
                    replyController.text.trim(),
                  );
                  if (context.mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Reply', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
