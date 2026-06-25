import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class BookingSuccessScreen extends StatelessWidget {
  final String hostelName;
  const BookingSuccessScreen({super.key, required this.hostelName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                    color: Color(0xFFD1FAE5), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_outline_rounded,
                    size: 48, color: AppColors.emerald),
              ),
              const SizedBox(height: 24),
              const Text('Booking Success!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Text('Your request for $hostelName has been sent.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
