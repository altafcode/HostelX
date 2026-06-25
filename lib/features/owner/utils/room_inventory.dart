import '../../../domain/entities/booking_entity.dart';
import '../../../domain/entities/hostel_entity.dart';
import '../providers/owner_provider.dart';

class RoomConfig {
  final String number;
  final String type;
  final int capacity;

  const RoomConfig({
    required this.number,
    required this.type,
    required this.capacity,
  });
}

class RoomStatusSummary {
  final String type;
  final int totalRooms;
  final int capacity;
  final int occupiedBeds;
  final int fullRooms;
  final int partialRooms;
  final int vacantRooms;

  const RoomStatusSummary({
    required this.type,
    required this.totalRooms,
    required this.capacity,
    required this.occupiedBeds,
    required this.fullRooms,
    required this.partialRooms,
    required this.vacantRooms,
  });

  int get totalBeds => totalRooms * capacity;
  double get progress => totalBeds == 0 ? 0 : occupiedBeds / totalBeds;
}

String normalizeRoomType(String value) {
  final lower = value.toLowerCase().replaceAll('-', ' ').trim();
  if (lower.contains('single') || lower == '1' || lower.contains('1 seater')) {
    return 'Single Room';
  }
  if (lower.contains('2')) return '2 Seater';
  if (lower.contains('3')) return '3 Seater';
  if (lower.contains('4')) return '4 Seater';
  return value.trim().isEmpty ? 'Standard Room' : value.trim();
}

int roomCapacity(String roomType) {
  switch (normalizeRoomType(roomType)) {
    case 'Single Room':
      return 1;
    case '2 Seater':
      return 2;
    case '3 Seater':
      return 3;
    case '4 Seater':
      return 4;
    default:
      return 1;
  }
}

String roomFeatures(String roomType) {
  switch (normalizeRoomType(roomType)) {
    case 'Single Room':
      return 'Private room + bath';
    case '2 Seater':
      return 'Private bath + balcony';
    case '3 Seater':
      return 'Shared bath + window';
    case '4 Seater':
      return 'Shared bath + economical';
    default:
      return 'Standard room';
  }
}

List<String> activeRoomTypesForHostel(HostelEntity hostel) {
  if (hostel.roomConfigurations.isNotEmpty) {
    final configuredTypes = hostel.roomConfigurations
        .where((config) => config.count > 0)
        .map((config) => normalizeRoomType(config.type))
        .toSet()
        .toList();
    if (configuredTypes.isNotEmpty) return configuredTypes;
  }

  final totalRooms = hostel.totalRooms;
  if (totalRooms <= 0) return const ['Single Room', '2 Seater', '3 Seater'];
  if (totalRooms < 4) return const ['Single Room', '2 Seater'];
  return const ['Single Room', '2 Seater', '3 Seater', '4 Seater'];
}

int priceForRoomType(HostelEntity hostel, String roomType) {
  final normalizedType = normalizeRoomType(roomType);
  for (final config in hostel.roomConfigurations) {
    if (normalizeRoomType(config.type) == normalizedType && config.price > 0) {
      return config.price;
    }
  }

  final basePrice = hostel.price;
  switch (normalizedType) {
    case 'Single Room':
      return basePrice + 4000;
    case '3 Seater':
      return basePrice > 3000 ? basePrice - 3000 : basePrice;
    case '4 Seater':
      return basePrice > 6000 ? basePrice - 6000 : basePrice;
    default:
      return basePrice;
  }
}

List<RoomConfig> buildRoomInventory(HostelEntity hostel) {
  if (hostel.roomConfigurations.isNotEmpty) {
    final rooms = <RoomConfig>[];
    var roomNo = 101;

    for (final config in hostel.roomConfigurations.where((c) => c.count > 0)) {
      final type = normalizeRoomType(config.type);
      for (var i = 0; i < config.count; i += 1) {
        rooms.add(RoomConfig(
          number: roomNo.toString(),
          type: type,
          capacity: roomCapacity(type),
        ));
        roomNo += 1;
      }
    }

    if (rooms.isNotEmpty) return rooms;
  }

  final types = activeRoomTypesForHostel(hostel);
  final totalRooms = hostel.totalRooms > 0 ? hostel.totalRooms : 12;
  final base = totalRooms ~/ types.length;
  var extra = totalRooms % types.length;
  final rooms = <RoomConfig>[];
  var roomNo = 101;

  for (final type in types) {
    var count = base;
    if (extra > 0) {
      count += 1;
      extra -= 1;
    }
    if (count == 0) count = 1;

    for (var i = 0; i < count; i += 1) {
      rooms.add(RoomConfig(
        number: roomNo.toString(),
        type: type,
        capacity: roomCapacity(type),
      ));
      roomNo += 1;
    }
  }

  return rooms;
}

Map<String, int> occupancyByRoomFromTenants(List<Tenant> tenants) {
  final occupancy = <String, int>{};
  for (final tenant in tenants) {
    if (tenant.roomNumber.trim().isEmpty || tenant.roomNumber == 'Pending') {
      continue;
    }
    occupancy[tenant.roomNumber] = (occupancy[tenant.roomNumber] ?? 0) + 1;
  }
  return occupancy;
}

Map<String, int> occupancyByRoomFromBookings(List<BookingEntity> bookings) {
  final occupancy = <String, int>{};
  for (final booking in bookings.where((b) => b.status.isActive)) {
    if (booking.roomNumber.trim().isEmpty || booking.roomNumber == 'Pending') {
      continue;
    }
    occupancy[booking.roomNumber] = (occupancy[booking.roomNumber] ?? 0) + 1;
  }
  return occupancy;
}

List<RoomConfig> availableRoomsForType({
  required HostelEntity hostel,
  required String roomType,
  required List<BookingEntity> bookings,
}) {
  final occupancy = occupancyByRoomFromBookings(
    bookings.where((b) => b.hostelId == hostel.id).toList(),
  );
  final normalizedType = normalizeRoomType(roomType);

  return buildRoomInventory(hostel).where((room) {
    if (normalizeRoomType(room.type) != normalizedType) return false;
    final occupied = occupancy[room.number] ?? 0;
    return occupied < room.capacity;
  }).toList();
}

List<RoomStatusSummary> summarizeRooms({
  required HostelEntity hostel,
  required List<Tenant> tenants,
}) {
  return summarizeRoomsFromOccupancy(
    hostel: hostel,
    occupancy: occupancyByRoomFromTenants(tenants),
  );
}

List<RoomStatusSummary> summarizeRoomsFromBookings({
  required HostelEntity hostel,
  required List<BookingEntity> bookings,
}) {
  return summarizeRoomsFromOccupancy(
    hostel: hostel,
    occupancy: occupancyByRoomFromBookings(
      bookings.where((booking) => booking.hostelId == hostel.id).toList(),
    ),
  );
}

List<RoomStatusSummary> summarizeRoomsFromOccupancy({
  required HostelEntity hostel,
  required Map<String, int> occupancy,
}) {
  final rooms = buildRoomInventory(hostel);
  final result = <RoomStatusSummary>[];

  for (final type in activeRoomTypesForHostel(hostel)) {
    final roomsOfType =
        rooms.where((room) => normalizeRoomType(room.type) == type).toList();
    final capacity = roomCapacity(type);
    final occupiedBeds = roomsOfType.fold<int>(
      0,
      (sum, room) => sum + (occupancy[room.number] ?? 0),
    );
    final fullRooms = roomsOfType
        .where((room) => (occupancy[room.number] ?? 0) >= room.capacity)
        .length;
    final partialRooms = roomsOfType.where((room) {
      final count = occupancy[room.number] ?? 0;
      return count > 0 && count < room.capacity;
    }).length;
    final vacantRooms =
        roomsOfType.where((room) => (occupancy[room.number] ?? 0) == 0).length;

    result.add(RoomStatusSummary(
      type: type,
      totalRooms: roomsOfType.length,
      capacity: capacity,
      occupiedBeds: occupiedBeds,
      fullRooms: fullRooms,
      partialRooms: partialRooms,
      vacantRooms: vacantRooms,
    ));
  }

  return result;
}
