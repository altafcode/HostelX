import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../domain/entities/hostel_entity.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../widgets/common/primary_button.dart';
import '../../../../widgets/common/section_header.dart';
import '../../providers/hostel_provider.dart';

class DetailsReviews extends StatefulWidget {
  final HostelEntity hostel;
  final List<ReviewEntity> reviews;

  const DetailsReviews({
    super.key,
    required this.hostel,
    required this.reviews,
  });

  @override
  State<DetailsReviews> createState() => _DetailsReviewsState();
}

class _DetailsReviewsState extends State<DetailsReviews> {
  bool _isWritingReview = false;
  bool _showAllReviews = false;
  int _selectedReviewRating = 5;
  final TextEditingController _reviewController = TextEditingController();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final user = context.read<AuthProvider>().user;
    final comment = _reviewController.text.trim();
    if (user == null || comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Write a short review before submitting.')));
      return;
    }
    try {
      await context.read<HostelProvider>().addReview(
            ReviewEntity(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              hostelId: widget.hostel.id,
              userId: user.id,
              userName: user.name,
              rating: _selectedReviewRating.toDouble(),
              comment: comment,
              date: 'Just now',
            ),
          );
      if (!mounted) return;
      _reviewController.clear();
      setState(() {
        _selectedReviewRating = 5;
        _isWritingReview = false;
        _showAllReviews = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Review failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: AppStrings.reviews,
          actionLabel: widget.reviews.length > 3
              ? (_showAllReviews ? 'See Less' : AppStrings.seeAll)
              : AppStrings.writeReview,
          onAction: () {
            if (widget.reviews.length > 3) {
              setState(() => _showAllReviews = !_showAllReviews);
            } else {
              setState(() => _isWritingReview = !_isWritingReview);
            }
          },
        ),
        const SizedBox(height: 12),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          crossFadeState: _isWritingReview
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _WriteReviewCard(
              controller: _reviewController,
              selectedRating: _selectedReviewRating,
              onRatingChanged: (rating) =>
                  setState(() => _selectedReviewRating = rating),
              onSubmit: _submitReview,
            ),
          ),
        ),
        if (widget.reviews.isEmpty)
          const _EmptyReviewsCard()
        else ...[
          ...widget.reviews
              .take(_showAllReviews ? widget.reviews.length : 3)
              .map(
                (review) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ReviewCard(review: review),
                ),
              ),
        ],
      ],
    );
  }
}

class _WriteReviewCard extends StatelessWidget {
  final TextEditingController controller;
  final int selectedRating;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmit;

  const _WriteReviewCard({
    required this.controller,
    required this.selectedRating,
    required this.onRatingChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EBFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(AppStrings.writeReview,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Row(
            children: List.generate(
              5,
              (index) => GestureDetector(
                onTap: () => onRatingChanged(index + 1),
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    index < selectedRating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 22,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Share your experience of this hostel',
              hintStyle:
                  const TextStyle(fontSize: 12, color: AppColors.textMuted),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 130,
              child: PrimaryButton(label: 'Submit', onPressed: onSubmit),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyReviewsCard extends StatelessWidget {
  const _EmptyReviewsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16)),
      child: const Row(
        children: [
          Icon(Icons.rate_review_outlined, color: AppColors.textMuted),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No reviews yet. Be the first tenant to leave one.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewEntity review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAEFF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    AppHelpers.getInitials(review.userName),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800)),
                    Text(review.date,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < review.rating.round()
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 14,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(review.comment,
              style: const TextStyle(
                  fontSize: 12, height: 1.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
