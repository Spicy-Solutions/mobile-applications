// lib/Monitoring/models/room_model.dart
class Room {
  final int id;
  final String number;
  final String guest;
  final String checkIn;
  final String checkOut;
  final bool available;
  final int typeRoomId;
  final String state;

  Room({
    required this.id,
    required this.number,
    this.guest = '',
    this.checkIn = '',
    this.checkOut = '',
    required this.available,
    required this.typeRoomId,
    required this.state,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    String roomNumber = '';

    // CORREGIDO: Manejar la falta del campo 'number' en la respuesta de la API
    if (json['number'] != null && json['number'].toString().isNotEmpty) {
      roomNumber = json['number'].toString();
    } else if (json['roomNumber'] != null && json['roomNumber'].toString().isNotEmpty) {
      roomNumber = json['roomNumber'].toString();
    } else if (json['name'] != null && json['name'].toString().isNotEmpty) {
      roomNumber = json['name'].toString();
    } else {
      // NUEVO: Si no hay número, usar el ID como número de habitación
      roomNumber = json['id']?.toString() ?? 'Sin número';
    }

    return Room(
      id: json['id'] ?? 0,
      number: roomNumber,
      guest: json['guestName'] ?? json['guest'] ?? '',
      checkIn: json['checkInDate'] ?? json['checkIn'] ?? '',
      checkOut: json['checkOutDate'] ?? json['checkOut'] ?? '',
      available: json['state'] == 'DISPONIBLE' || json['state'] == 'Available' || json['available'] == true,
      typeRoomId: json['typeRoomId'] ?? json['roomTypeId'] ?? 0,
      state: json['state'] ?? json['status'] ?? 'Desconocido',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'guest': guest,
      'checkIn': checkIn,
      'checkOut': checkOut,
      'available': available,
      'typeRoomId': typeRoomId,
      'state': state,
    };
  }
}

class CreateRoomRequest {
  final int typeRoomId;
  final int hotelId;
  final String state;
  final String? roomNumber;
  final String? number;
  final String? name;
  // CORREGIDO: El ID debe ser el número de habitación especificado por el usuario
  final int id;

  CreateRoomRequest({
    required this.typeRoomId,
    required this.hotelId,
    this.state = 'DISPONIBLE', // CORREGIDO: Usar el formato que espera la API
    this.roomNumber,
    this.number,
    this.name,
    required this.id, // CORREGIDO: Hacer obligatorio el ID
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'id': id, // CORREGIDO: Siempre incluir el ID especificado
      'typeRoomId': typeRoomId,
      'hotelId': hotelId,
      'state': state,
    };

    // Incluir el número de habitación si está disponible
    final roomNum = roomNumber ?? number ?? name ?? id.toString();
    json['number'] = roomNum;
    json['roomNumber'] = roomNum;

    return json;
  }
}

class UpdateRoomStateRequest {
  final int id;
  final String state;

  UpdateRoomStateRequest({
    required this.id,
    required this.state,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'state': state,
    };
  }
}