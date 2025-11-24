// models/booking.dart
class Booking {
  final String id;
  final String paymentCustomerId;
  final String roomId;
  final String? description;
  final DateTime startDate;
  final DateTime finalDate;
  final double priceRoom;
  final int nightCount;
  final double amount;
  final String state;
  final String? preferenceId;
  final String? hotelName;
  final String? hotelLogo;
  final String? hotelPhone;


  Booking({
    required this.id,
    required this.paymentCustomerId,
    required this.roomId,
    this.description,
    required this.startDate,
    required this.finalDate,
    required this.priceRoom,
    required this.nightCount,
    required this.amount,
    required this.state,
    this.preferenceId,
    this.hotelName,
    this.hotelLogo,
    this.hotelPhone,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    try {
      return Booking(
        id: json['id']?.toString() ?? '',
        paymentCustomerId: json['paymentCustomerId']?.toString() ??
            json['customerId']?.toString() ?? '',
        roomId: json['roomId']?.toString() ??
            json['room_id']?.toString() ?? '',
        description: json['description']?.toString(),
        startDate: _parseDate(json['startDate']) ?? DateTime.now(),
        finalDate: _parseDate(json['finalDate']) ?? DateTime.now().add(const Duration(days: 1)),
        priceRoom: _parseDouble(json['priceRoom'] ?? json['price_room'] ?? json['price']),
        nightCount: _parseInt(json['nightCount'] ?? json['night_count']),
        amount: _parseDouble(json['amount']),
        state: json['state']?.toString().toLowerCase() ?? 'inactive',
        preferenceId: json['preferenceId']?.toString() ??
            json['preference_id']?.toString(),
        hotelName: json['hotelName']?.toString() ??
            json['hotel_name']?.toString() ?? 'Hotel',
        hotelLogo: json['hotelLogo']?.toString() ??
            json['hotel_logo']?.toString(),
      );
    } catch (e) {
      print('Error in Booking.fromJson: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  // Métodos auxiliares estáticos para parsing seguro
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      if (value is String) {
        return DateTime.parse(value);
      }
      return null;
    } catch (e) {
      print('Error parsing date: $value - $e');
      return null;
    }
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    try {
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        return double.parse(value);
      }
      return 0.0;
    } catch (e) {
      print('Error parsing double: $value - $e');
      return 0.0;
    }
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    try {
      if (value is int) {
        return value;
      }
      if (value is String) {
        return int.parse(value);
      }
      if (value is double) {
        return value.toInt();
      }
      return 0;
    } catch (e) {
      print('Error parsing int: $value - $e');
      return 0;
    }
  }

  static int _calculateNightCount(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 1;
    final difference = end.difference(start).inDays;
    return difference > 0 ? difference : 1;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paymentCustomerId': paymentCustomerId,
      'roomId': roomId,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'finalDate': finalDate.toIso8601String(),
      'priceRoom': priceRoom,
      'nightCount': nightCount,
      'amount': amount,
      'state': state,
      'preferenceId': preferenceId,
      'hotelName': hotelName,
      'hotelLogo': hotelLogo,
    };
  }

  String get statusText {
    switch (state.toLowerCase()) {
      case 'active':
      case 'confirmed':
        return 'ACTIVE';
      case 'cancelled':
        return 'CANCELLED';
      case 'pending':
        return 'PENDING';
      default:
        return 'INACTIVE';
    }
  }

  bool get canCancel {
    return state.toLowerCase() == 'active' || state.toLowerCase() == 'confirmed';
  }

  static Booking fromDisplayableBooking(Map<String, dynamic> displayableBooking) {
    return Booking.fromJson(displayableBooking);
  }

  static Map<String, dynamic> toDisplayableBooking(Booking booking) {
    return booking.toJson();
  }
}