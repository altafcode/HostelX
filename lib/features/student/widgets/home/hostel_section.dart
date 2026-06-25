import 'package:flutter/material.dart';
import '../../../../widgets/common/section_header.dart';
import '../../../../domain/entities/hostel_entity.dart';

class HostelHorizontalSection extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final List<HostelEntity> hostels;
  final Widget Function(HostelEntity) itemBuilder;
  final double height;
  final double spacing;

  const HostelHorizontalSection({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.onAction,
    required this.hostels,
    required this.itemBuilder,
    this.height = 218,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    if (hostels.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: hostels.length,
            separatorBuilder: (_, __) => SizedBox(width: spacing),
            itemBuilder: (_, i) => itemBuilder(hostels[i]),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
