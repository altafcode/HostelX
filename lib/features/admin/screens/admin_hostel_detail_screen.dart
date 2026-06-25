import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/hostel_entity.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/entities/booking_entity.dart';
import '../../../widgets/common/status_badge.dart';
import '../providers/admin_provider.dart';

import '../widgets/user_details_sheet.dart';
import 'admin_hostel_tenants_screen.dart';
import 'admin_all_rooms_screen.dart';
import '../../owner/utils/room_inventory.dart';

class AdminHostelDetailScreen extends StatelessWidget {
  final HostelEntity hostel;

  const AdminHostelDetailScreen({super.key, required this.hostel});

  @override
  Widget build(BuildContext context) {
    final adminProv = context.watch<AdminProvider>();
    final NumberFormat currencyFormat =
        NumberFormat.currency(locale: 'en_IN', symbol: 'Rs ', decimalDigits: 0);

    // Find latest status of the hostel from provider
    final updatedHostel = adminProv.getHostelById(hostel.id) ?? hostel;
    final isPending = updatedHostel.approvalStatus == ApprovalStatus.pending;

    final hostelBookings = adminProv.bookings
        .where((b) => b.hostelId == updatedHostel.id)
        .toList();
    final activeHostelBookings =
        hostelBookings.where((b) => b.status.isActive).toList();
    final roomSummaries = summarizeRoomsFromBookings(
      hostel: updatedHostel,
      bookings: activeHostelBookings,
    );
    final totalCapacity =
        roomSummaries.fold<int>(0, (sum, item) => sum + item.totalBeds);
    final occupied =
        roomSummaries.fold<int>(0, (sum, item) => sum + item.occupiedBeds);
    final vacantBeds = totalCapacity - occupied;
    final rentCollected = hostelBookings
        .where((booking) => booking.status.isPaid)
        .fold<double>(0, (sum, booking) => sum + booking.price);
    final commissionEarned = adminProv.calculateCommission(rentCollected);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                backgroundColor: AppColors.primary,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: isPending
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Review Mode',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                      )
                    : const Text('Hostel Details',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        updatedHostel.images.isNotEmpty
                            ? updatedHostel.images[0]
                            : '',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: AppColors.surfaceVariant),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black54, Colors.transparent],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      20, 20, 20, 100), // padding for bottom buttons
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              updatedHostel.name,
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary),
                            ),
                          ),
                          StatusBadge.fromApprovalStatus(
                              updatedHostel.approvalStatus),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(updatedHostel.location,
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 24),
                      const Text('Owner & Documents',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: Text(_initial(updatedHostel.ownerName),
                                style: const TextStyle(color: Colors.white))),
                        title: Text(updatedHostel.ownerName),
                        subtitle: Text(updatedHostel.ownerPhone.isEmpty
                            ? 'Owner contact not provided'
                            : updatedHostel.ownerPhone),
                        trailing: const Icon(Icons.verified,
                            color: AppColors.emerald),
                      ),
                      if (isPending) ...[
                        ...updatedHostel.documentUrls.entries.map(
                          (entry) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.description,
                                color: AppColors.textSecondary),
                            title: Text(entry.key),
                            subtitle: const Text('Uploaded by owner'),
                            trailing: const Icon(Icons.visibility,
                                color: AppColors.primary),
                            onTap: () => _openUrl(entry.value),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _launchDialer(updatedHostel.ownerPhone),
                              icon: const Icon(Icons.phone, size: 18),
                              label: const Text('Contact Owner'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _launchWhatsApp(
                                  updatedHostel.ownerWhatsapp.isEmpty
                                      ? updatedHostel.ownerPhone
                                      : updatedHostel.ownerWhatsapp),
                              icon: const Icon(Icons.message, size: 18),
                              label: const Text('WhatsApp'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.emerald,
                                side:
                                    const BorderSide(color: AppColors.emerald),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('About the Property',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        updatedHostel.description.isNotEmpty
                            ? updatedHostel.description
                            : 'No description provided.',
                        style: const TextStyle(
                            color: AppColors.textSecondary, height: 1.5),
                      ),
                      if (!isPending) ...[
                        const SizedBox(height: 24),
                        const Text('Occupancy Status',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                          'Occupied: $occupied/$totalCapacity beds  |  Vacant: $vacantBeds',
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        ...roomSummaries.map((summary) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${summary.type} - ${summary.fullRooms} full - ${summary.partialRooms} partial - ${summary.vacantRooms} vacant',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    Text(
                                        '${(summary.progress * 100).toInt()}% beds',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: summary.progress
                                        .clamp(0.0, 1.0)
                                        .toDouble(),
                                    backgroundColor: AppColors.borderLight,
                                    color: summary.progress > 0.9
                                        ? AppColors.accent
                                        : AppColors.primary,
                                    minHeight: 8,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminAllRoomsScreen(
                                    hostel: updatedHostel,
                                  ),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('View All Rooms'),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text('Financial Summary',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 2.2,
                          children: [
                            _StatBox('Rent Collected',
                                currencyFormat.format(rentCollected)),
                            _StatBox('Commission Earned',
                                currencyFormat.format(commissionEarned)),
                            _StatBox('Occupancy', '$occupied/$totalCapacity'),
                            _StatBox('Rent Due', currencyFormat.format(0)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                      const Text('Room Configurations',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ...roomSummaries.map((summary) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                      color: AppColors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(12)),
                                  child: const Icon(Icons.bed,
                                      color: AppColors.primary),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(summary.type,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16)),
                                      Text(
                                          '${summary.totalRooms} rooms - ${summary.capacity} beds each - ${summary.occupiedBeds}/${summary.totalBeds} beds filled',
                                          style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Text(
                                    currencyFormat.format(priceForRoomType(
                                        updatedHostel, summary.type)),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                        fontSize: 16)),
                              ],
                            ),
                          )),
                      if (!isPending) ...[
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Recent Tenants',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AdminHostelTenantsScreen(
                                          hostel: updatedHostel),
                                    ),
                                  );
                                },
                                child: const Text('View All')),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Column(
                            children: [
                              _TenantHeader(),
                              const Divider(height: 1),
                              ...activeHostelBookings.take(4).map((b) {
                                final user =
                                    _findUser(adminProv.users, b.userId);
                                if (user == null) {
                                  return const SizedBox.shrink();
                                }
                                return GestureDetector(
                                  onTap: () => showAdminUserBottomSheet(
                                    context: context,
                                    user: user,
                                    adminProv: adminProv,
                                  ),
                                  child: _TenantRow(user: user, booking: b),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      const Text('Administrative Actions',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text(
                          'Critical actions for managing this hostel listing.',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (updatedHostel.approvalStatus ==
                              ApprovalStatus.approved)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _showSuspendDialog(
                                    context, adminProv, updatedHostel),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  foregroundColor: AppColors.accent,
                                  side:
                                      const BorderSide(color: AppColors.accent),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Suspend Listing'),
                              ),
                            ),
                          if (updatedHostel.approvalStatus ==
                              ApprovalStatus.suspended)
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  adminProv.approveHostel(updatedHostel.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Hostel Re-activated.')));
                                },
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: AppColors.emerald,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Activate Listing'),
                              ),
                            ),
                          if (updatedHostel.approvalStatus ==
                                  ApprovalStatus.approved ||
                              updatedHostel.approvalStatus ==
                                  ApprovalStatus.suspended)
                            const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                _showDeleteConfirm(
                                    context, adminProv, updatedHostel);
                              },
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: AppColors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Delete Hostel'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (isPending)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5))
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            _showRejectDialog(context, updatedHostel),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: AppColors.red,
                          side: const BorderSide(color: AppColors.red),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Reject Listing'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          context
                              .read<AdminProvider>()
                              .approveHostel(updatedHostel.id);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content:
                                  Text('${updatedHostel.name} Approved.')));
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.emerald,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Approve Listing'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(
      BuildContext context, AdminProvider adminProv, HostelEntity hostel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Hostel?'),
        content: Text(
            'Are you sure you want to permanently delete ${hostel.name}? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red, foregroundColor: Colors.white),
            onPressed: () {
              // Implementation of delete logic would go here
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${hostel.name} deleted.')));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, HostelEntity hostel) {
    final adminProv = context.read<AdminProvider>();
    String? selectedReason;
    final reasons = ['Missing documents', 'Invalid info', 'Duplicate', 'Other'];
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Reject Hostel',
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Reason',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary)),
                DropdownButton<String>(
                  isExpanded: true,
                  value: selectedReason,
                  hint: const Text('Choose a reason...'),
                  items: reasons
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) => setState(() => selectedReason = val),
                ),
                const SizedBox(height: 16),
                const Text('Additional Notes (Optional)',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    hintText: 'Describe why...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.red,
                    foregroundColor: Colors.white,
                    elevation: 0),
                onPressed: selectedReason == null
                    ? null
                    : () {
                        adminProv.rejectHostel(hostel.id, selectedReason!);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('${hostel.name} Rejected.')));
                      },
                child: const Text('Confirm Reject'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSuspendDialog(
      BuildContext context, AdminProvider adminProv, HostelEntity hostel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Suspend Listing?'),
        content: Text(
            'Are you sure you want to suspend ${hostel.name}? It will no longer be visible to students.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                elevation: 0),
            onPressed: () {
              adminProv.suspendHostel(hostel.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${hostel.name} Suspended.')));
            },
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
  }

  void _launchDialer(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.isEmpty) return;
    await launchUrl(Uri(scheme: 'tel', path: cleaned));
  }

  void _launchWhatsApp(String phone) async {
    var cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.isEmpty) return;
    if (cleaned.startsWith('0')) cleaned = '92${cleaned.substring(1)}';
    await launchUrl(Uri.parse('https://wa.me/$cleaned'),
        mode: LaunchMode.externalApplication);
  }

  void _openUrl(String url) {
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  UserEntity? _findUser(List<UserEntity> users, String userId) {
    for (final user in users) {
      if (user.id == userId) return user;
    }
    return null;
  }

  String _initial(String value) {
    return value.trim().isEmpty ? '?' : value.trim()[0].toUpperCase();
  }
}

class _TenantHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text('Name',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted))),
          Expanded(
              flex: 1,
              child: Text('Room',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted))),
          Expanded(
              flex: 2,
              child: Text('Check-in',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted))),
          Expanded(
              flex: 2,
              child: Text('Payment',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted),
                  textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _TenantRow extends StatelessWidget {
  final UserEntity user;
  final BookingAdminModel booking;

  const _TenantRow({required this.user, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.surfaceVariant,
                  child: Text(_initial(user.name),
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                ),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(user.name,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          Expanded(
              flex: 1,
              child: Text(booking.roomNumber,
                  style: const TextStyle(fontSize: 13))),
          Expanded(
              flex: 2,
              child: Text(DateFormat('d MMM yyyy').format(booking.checkInDate),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary))),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: booking.status == BookingStatus.expired
                      ? AppColors.red.withValues(alpha: 0.1)
                      : AppColors.emerald.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  booking.status == BookingStatus.expired ? 'Pending' : 'Paid',
                  style: TextStyle(
                    color: booking.status == BookingStatus.expired
                        ? AppColors.red
                        : AppColors.emerald,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initial(String value) {
    return value.trim().isEmpty ? '?' : value.trim()[0].toUpperCase();
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;

  const _StatBox(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
