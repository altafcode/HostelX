import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/user_entity.dart';
import '../providers/admin_provider.dart';

void showAdminUserBottomSheet({
  required BuildContext context,
  required UserEntity user,
  required AdminProvider adminProv,
}) {
  final booking = adminProv.getBookingForUser(user.id);
  final NumberFormat currencyFormat =
      NumberFormat.currency(locale: 'en_IN', symbol: 'Rs ', decimalDigits: 0);
  final fullDateFormat = DateFormat('d MMM yyyy, h:mm a');
  final shortDateFormat = DateFormat('d MMM yyyy');

  // Stats for owners
  int ownerListings = 0;
  int ownerTenants = 0;
  double ownerEarnings = 0;

  if (user.role == UserRole.owner) {
    final hostels = adminProv.hostels.where((h) => h.ownerId == user.id || h.ownerName == user.name).toList();
    ownerListings = hostels.length;
    final hostelIds = hostels.map((h) => h.id).toList();
    final ownerBookings = adminProv.bookings.where((b) => hostelIds.contains(b.hostelId)).toList();
    ownerTenants = ownerBookings.length;
    ownerEarnings = ownerBookings.fold(0.0, (sum, b) => sum + b.rentAmount) *
        (1 - adminProv.commissionRate);
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.surfaceVariant,
                child: Text(user.name[0],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: AppColors.primary)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    Text(user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    Text('Join Date: ${user.joinedDate ?? 'Not specified'}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: user.role == UserRole.tenant ? Colors.blue.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  user.role.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: user.role == UserRole.tenant ? Colors.blue : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Profile Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.email_outlined, 'Email', user.email),
          _buildInfoRow(Icons.phone_outlined, 'Phone', user.phone ?? 'Not provided'),
          _buildInfoRow(Icons.location_city_rounded, 'City', user.city ?? 'Not specified'),
          _buildInfoRow(Icons.work_outline, 'Occupation', user.occupation?.name.toUpperCase() ?? 'Not specified'),
          _buildInfoRow(Icons.calendar_today_outlined, 'Joined Date', user.joinedDate ?? 'Not specified'),
          
          if (user.role == UserRole.tenant) ...[
            const Divider(height: 32),
            const Text('Booking Status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (booking != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.hostelName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    _buildBookingDetail('Room', '${booking.roomNumber} (${booking.roomType})'),
                    _buildBookingDetail('Check-in', fullDateFormat.format(booking.checkInDate)),
                    _buildBookingDetail('Contract End', shortDateFormat.format(booking.contractEndDate)),
                    _buildBookingDetail('Monthly Rent', currencyFormat.format(booking.rentAmount)),
                    const Divider(height: 20),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Escalation', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text('+10% after 12 months', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent)),
                      ],
                    ),
                  ],
                ),
              )
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('No active booking',
                      style: TextStyle(color: AppColors.textMuted, fontStyle: FontStyle.italic)),
                ),
              ),
          ],

          if (user.role == UserRole.owner) ...[
            const Divider(height: 32),
            const Text('Business Overview',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildOwnerStat('Listings', ownerListings.toString()),
                _buildOwnerStat('Tenants', ownerTenants.toString()),
                _buildOwnerStat('Net Earnings', currencyFormat.format(ownerEarnings)),
              ],
            ),
          ],

          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    if (user.status == UserStatus.active) {
                      adminProv.disableUser(user.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('User disabled.')));
                    } else {
                      adminProv.enableUser(user.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('User enabled.')));
                    }
                    Navigator.pop(ctx);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: user.status == UserStatus.active ? AppColors.accent : AppColors.emerald,
                    side: BorderSide(color: user.status == UserStatus.active ? AppColors.accent : AppColors.emerald),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(user.status == UserStatus.active ? 'Disable Account' : 'Enable Account'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    adminProv.deleteUser(user.id);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User deleted.')));
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0),
                  child: const Text('Delete User'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}

Widget _buildInfoRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    ),
  );
}

Widget _buildBookingDetail(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

Widget _buildOwnerStat(String label, String value) {
  return Expanded(
    child: Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    ),
  );
}
