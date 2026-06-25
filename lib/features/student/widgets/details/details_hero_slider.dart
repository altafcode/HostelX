import 'package:flutter/material.dart';
import '../../../../domain/entities/hostel_entity.dart';
import '../../screens/complaint_screen.dart';
import '../student_common_widgets.dart';

class DetailsHeroSlider extends StatefulWidget {
  final HostelEntity hostel;
  final VoidCallback onBack;
  const DetailsHeroSlider({super.key, required this.hostel, required this.onBack});

  @override
  State<DetailsHeroSlider> createState() => _DetailsHeroSliderState();
}

class _DetailsHeroSliderState extends State<DetailsHeroSlider> {
  int _curr = 0;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(30),
        child: Container(
          height: 30,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: CircleOverlayButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: widget.onBack,
        ),
      ),
      actions: [
        CircleOverlayButton(
          icon: Icons.report_problem_outlined,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ComplaintScreen(hostel: widget.hostel),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: HeartButton(
            hostelId: widget.hostel.id,
            size: 34,
            iconSize: 18,
            backgroundColor: Colors.black.withValues(alpha: 0.18),
            iconColor: Colors.white,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              itemCount: widget.hostel.images.length,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (i) => setState(() => _curr = i),
              itemBuilder: (_, i) => Image.network(
                widget.hostel.images[i],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
                ),
              ),
            ),
            IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x18000000), Color(0x08000000), Color(0x9A000000)],
                    stops: [0, 0.55, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: 46,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_curr + 1}/${widget.hostel.images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CircleOverlayButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const CircleOverlayButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
      ),
    );
  }
}
