import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/hostel_entity.dart';
import '../../../providers/auth_provider.dart';
import '../../../routes/app_router.dart';
import '../../../widgets/common/section_header.dart';
import '../providers/hostel_provider.dart';
import '../widgets/details/details_hero_slider.dart';
import '../widgets/details/hostel_details_widgets.dart';
import '../widgets/details/details_contact_widgets.dart';
import '../widgets/details/details_location_widgets.dart';
import '../widgets/details/details_reviews_widgets.dart';
import '../widgets/details/details_sticky_bar.dart';
import '../widgets/student_common_widgets.dart';
import '../../owner/utils/room_inventory.dart';

class HostelDetailsScreen extends StatefulWidget {
  final String hostelId;
  const HostelDetailsScreen({super.key, required this.hostelId});

  @override
  State<HostelDetailsScreen> createState() => _HostelDetailsScreenState();
}

class _HostelDetailsScreenState extends State<HostelDetailsScreen> {
  int _selectedRoomIndex = 1; // Default to 2-seater which is index 1
  bool _isExpanded = false;

  List<({String title, int price, String features})> _getRooms(
    HostelEntity hostel,
  ) {
    return activeRoomTypesForHostel(hostel).map((type) {
      return (
        title: type,
        price: priceForRoomType(hostel, type),
        features: roomFeatures(type),
      );
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HostelProvider>().addToRecentlyViewed(widget.hostelId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hostelProvider = context.watch<HostelProvider>();
    final hostel = hostelProvider.hostelById(widget.hostelId);
    final reviews = hostelProvider.reviewsFor(widget.hostelId);
    const isBooking = false;

    if (hostel == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // In a real app, this might be managed by a booking state in the provider
    // For now keeping it consistent with original logic if needed,
    // but usually success is a navigation.
    final roomsList = _getRooms(hostel);
    final selectedRoomIndex = _selectedRoomIndex < roomsList.length
        ? _selectedRoomIndex
        : roomsList.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              DetailsHeroSlider(
                hostel: hostel,
                onBack: () => Navigator.of(context).pop(),
              ),
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DetailsHeader(hostel: hostel),
                      const SizedBox(height: 18),
                      const SectionTitle(AppStrings.overview),
                      const SizedBox(height: 8),
                      _OverviewText(
                        description: hostel.description,
                        isExpanded: _isExpanded,
                        onToggle: () =>
                            setState(() => _isExpanded = !_isExpanded),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Facilities',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary)),
                          GestureDetector(
                            onTap: () => _showFacilities(context, hostel),
                            child: const Text('View All',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary)),
                          ),
                        ],
                      ),
                      DetailsAmenities(facilities: hostel.facilities),
                      const SizedBox(height: 10),
                      DetailsRooms(
                        rooms: roomsList,
                        selectedIndex: selectedRoomIndex,
                        onSelected: (i) =>
                            setState(() => _selectedRoomIndex = i),
                      ),
                      const SizedBox(height: 24),
                      SectionHeader(
                        title: AppStrings.location,
                        actionLabel: 'Get Directions',
                        onAction: () => _launchMap(hostel),
                      ),
                      const SizedBox(height: 12),
                      DetailsLocation(
                        hostel: hostel,
                        onTap: () => _launchMap(hostel),
                      ),
                      const SizedBox(height: 24),
                      const SectionTitle(AppStrings.hostedBy),
                      const SizedBox(height: 12),
                      DetailsHostCard(
                        hostel: hostel,
                        onCall: () => _launchDialer(hostel),
                        onWhatsApp: () => _launchWhatsApp(hostel),
                      ),
                      const SizedBox(height: 24),
                      DetailsReviews(hostel: hostel, reviews: reviews),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DetailsStickyBar(
              price: roomsList[selectedRoomIndex].price,
              isLoading: isBooking,
              onBook: () => _handleBook(
                context,
                hostel,
                roomsList[selectedRoomIndex].title,
                roomsList[selectedRoomIndex].price,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBook(
    BuildContext context,
    HostelEntity hostel,
    String roomType,
    int price,
  ) async {
    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);

    if (auth.user == null) {
      _showError('You must be logged in to book.');
      return;
    }

    if (!mounted) return;

    navigator.pushNamed(
      AppRouter.checkout,
      arguments: {
        'hostel': hostel,
        'roomType': roomType,
        'roomNumber': 'Pending',
        'price': price,
      },
    );
  }

  Future<String> _getOwnerPhone(String ownerId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(ownerId)
          .get();
      if (doc.exists) {
        final phone = doc.data()?['phone'] as String?;
        if (phone != null) {
          return phone.replaceAll(RegExp(r'\D'), '');
        }
      }
    } catch (_) {}
    return '';
  }

  String _cleanPhone(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  Future<String> _contactPhone(HostelEntity hostel) async {
    final phone = _cleanPhone(hostel.ownerPhone);
    if (phone.isNotEmpty) return phone;
    return _getOwnerPhone(hostel.ownerId);
  }

  Future<void> _launchDialer(HostelEntity hostel) async {
    final phone = await _contactPhone(hostel);
    if (phone.isEmpty) {
      _showError('Owner phone number is not available.');
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri)) _showError('Could not open the phone dialer.');
  }

  Future<void> _launchWhatsApp(HostelEntity hostel) async {
    String phone = _cleanPhone(hostel.ownerWhatsapp);
    if (phone.isEmpty) phone = await _contactPhone(hostel);
    if (phone.isEmpty) {
      _showError('Owner WhatsApp number is not available.');
      return;
    }
    if (phone.startsWith('0')) {
      phone = '92${phone.substring(1)}';
    }
    final uri = Uri.parse('https://wa.me/$phone');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showError('Could not open WhatsApp.');
    }
  }

  Future<void> _launchMap(HostelEntity hostel) async {
    final hasCoordinates = _hasMapCoordinates(hostel);
    final destination = hasCoordinates
        ? '${hostel.lat},${hostel.lng}'
        : '${hostel.name}, ${hostel.location}, ${hostel.city}';
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': destination,
      'travelmode': 'driving',
    });

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showError('Could not open Google Maps.');
    }
  }

  bool _hasMapCoordinates(HostelEntity hostel) {
    return hostel.lat.abs() > 0.0001 &&
        hostel.lng.abs() > 0.0001 &&
        hostel.lat >= -85 &&
        hostel.lat <= 85 &&
        hostel.lng >= -180 &&
        hostel.lng <= 180;
  }

  void _showFacilities(BuildContext context, HostelEntity hostel) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Facilities',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: hostel.facilities
                  .map((item) => Chip(label: Text(item)))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _OverviewText extends StatelessWidget {
  final String description;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _OverviewText({
    required this.description,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          description,
          maxLines: isExpanded ? null : 4,
          overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            height: 1.6,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onToggle,
          child: Text(
            isExpanded ? 'Read Less' : 'Read More',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
