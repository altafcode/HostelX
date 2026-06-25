import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/hostel_entity.dart';

class DetailsLocation extends StatelessWidget {
  final HostelEntity hostel;
  final VoidCallback? onTap;

  const DetailsLocation({
    super.key,
    required this.hostel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 158,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF1FAF0), Color(0xFFE3F1E7)],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(child: _MapPreviewBackground(hostel: hostel)),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.05),
                          Colors.black.withValues(alpha: 0.10),
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Transform.translate(
                    offset: const Offset(0, -14),
                    child: const Icon(
                      Icons.location_on_outlined,
                      size: 42,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.place_outlined,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${hostel.location}, ${hostel.city}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MapPreviewBackground extends StatelessWidget {
  final HostelEntity hostel;

  const _MapPreviewBackground({required this.hostel});

  @override
  Widget build(BuildContext context) {
    if (_hasCoordinates) {
      return Image.network(
        _tileUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            CustomPaint(painter: MapPatternPainter()),
      );
    }

    return CustomPaint(painter: MapPatternPainter());
  }

  bool get _hasCoordinates {
    return hostel.lat.abs() > 0.0001 &&
        hostel.lng.abs() > 0.0001 &&
        hostel.lat >= -85 &&
        hostel.lat <= 85 &&
        hostel.lng >= -180 &&
        hostel.lng <= 180;
  }

  String get _tileUrl {
    const zoom = 15;
    final latRad = hostel.lat * math.pi / 180;
    const tiles = 1 << zoom;
    final x = ((hostel.lng + 180) / 360 * tiles).floor();
    final y = ((1 -
                math.log(math.tan(latRad) + (1 / math.cos(latRad))) /
                    math.pi) /
            2 *
            tiles)
        .floor();
    return 'https://tile.openstreetmap.org/$zoom/$x/$y.png';
  }
}

class MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = const Color(0xFFD7E8D8)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(size.width * 0.08, size.height * 0.2),
        Offset(size.width * 0.92, size.height * 0.68), road);
    canvas.drawLine(Offset(size.width * 0.2, size.height * 0.88),
        Offset(size.width * 0.65, size.height * 0.18), road);
    canvas.drawLine(Offset(size.width * 0.05, size.height * 0.55),
        Offset(size.width * 0.8, size.height * 0.38), road);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
