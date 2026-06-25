import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/hostel_entity.dart';
import '../providers/owner_provider.dart';
import '../utils/room_inventory.dart' as inventory;
import '../widgets/tenant_details_sheet.dart';

class Room {
  final String roomNumber;
  final String roomType;
  final int capacity;
  final List<Tenant> occupants;

  Room({
    required this.roomNumber,
    required this.roomType,
    required this.capacity,
    required this.occupants,
  });

  bool get isFull => occupants.length >= capacity;
  bool get isVacant => occupants.isEmpty;
  String get status => isFull ? 'Occupied' : (isVacant ? 'Vacant' : 'Partial');
}

class OwnerAllRoomsScreen extends StatefulWidget {
  final HostelEntity hostel;

  const OwnerAllRoomsScreen({super.key, required this.hostel});

  @override
  State<OwnerAllRoomsScreen> createState() => _OwnerAllRoomsScreenState();
}

class _OwnerAllRoomsScreenState extends State<OwnerAllRoomsScreen> {
  String _searchQuery = '';
  late List<Room> _allRooms;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OwnerProvider>();
    final tenants = provider.tenants
        .where((t) => t.hostelName == widget.hostel.name)
        .toList();

    _allRooms = [];

    Map<String, List<Tenant>> roomGroups = {};
    for (var t in tenants) {
      roomGroups.putIfAbsent(t.roomNumber, () => []).add(t);
    }

    for (var config in inventory.buildRoomInventory(widget.hostel)) {
      final occupants = roomGroups[config.number] ?? [];
      _allRooms.add(Room(
        roomNumber: config.number,
        roomType: config.type,
        capacity: config.capacity,
        occupants: occupants,
      ));
    }

    final filteredRooms = _allRooms.where((room) {
      return room.roomNumber
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          room.roomType.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          room.occupants.any(
              (o) => o.name.toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Rooms - ${widget.hostel.name}',
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search room or tenant...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                filled: true,
                fillColor: AppColors.background,
              ),
            ),
          ),
          Expanded(
            child: filteredRooms.isEmpty
                ? const Center(
                    child: Text('No rooms found matching your search.',
                        style: TextStyle(color: AppColors.textMuted)))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredRooms.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final room = filteredRooms[index];

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Theme(
                          data: Theme.of(context)
                              .copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: room.isVacant
                                    ? AppColors.emerald.withValues(alpha: 0.1)
                                    : (room.isFull
                                        ? AppColors.accent
                                            .withValues(alpha: 0.1)
                                        : Colors.blue.withValues(alpha: 0.1)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  room.roomNumber,
                                  style: TextStyle(
                                    color: room.isVacant
                                        ? AppColors.emerald
                                        : (room.isFull
                                            ? AppColors.accent
                                            : Colors.blue),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              room.roomType,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            subtitle: Text(
                              '${room.occupants.length} / ${room.capacity} occupied',
                              style: TextStyle(
                                color: room.isFull
                                    ? AppColors.accent
                                    : AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: room.isVacant
                                    ? AppColors.emerald
                                    : (room.isFull
                                        ? AppColors.accent
                                        : Colors.blue),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                room.status,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            children: [
                              if (room.occupants.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('No occupants in this room.',
                                      style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 13)),
                                )
                              else
                                ...room.occupants.map((occupant) => ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 24, vertical: 0),
                                      leading: CircleAvatar(
                                        radius: 14,
                                        backgroundImage:
                                            NetworkImage(occupant.avatarUrl),
                                      ),
                                      title: Text(occupant.name,
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600)),
                                      subtitle: const Text('View details',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.primary)),
                                      trailing: const Icon(Icons.chevron_right,
                                          size: 16),
                                      onTap: () => showTenantDetailsSheet(
                                          context, occupant, provider),
                                    )),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
