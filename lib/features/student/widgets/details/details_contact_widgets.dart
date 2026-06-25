import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../domain/entities/hostel_entity.dart';

class DetailsHostCard extends StatelessWidget {
  final HostelEntity hostel;
  final VoidCallback onWhatsApp;
  final VoidCallback onCall;

  const DetailsHostCard({
    super.key,
    required this.hostel,
    required this.onWhatsApp,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAEFF7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFFFD66B), Color(0xFFF59E0B)]),
              borderRadius: BorderRadius.circular(23),
            ),
            child: Center(
              child: Text(
                AppHelpers.getInitials(hostel.ownerName),
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hostel.ownerName,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const Text(
                  'Hostel Owner',
                  style:
                      TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  hostel.ownerPhone.trim().isEmpty
                      ? 'Contact details available after listing review'
                      : hostel.ownerPhone,
                  style:
                      const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _RoundContactButton(icon: Icons.call_rounded, onTap: onCall),
          const SizedBox(width: 8),
          _RoundContactButton(icon: Icons.message_rounded, onTap: onWhatsApp),
        ],
      ),
    );
  }
}

class _RoundContactButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundContactButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF4FF),
          borderRadius: BorderRadius.circular(19),
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
    );
  }
}
