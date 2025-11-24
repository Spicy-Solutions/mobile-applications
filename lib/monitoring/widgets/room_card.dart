import 'package:flutter/material.dart';
import 'package:sweet_manager/monitoring/models/room.dart';

class RoomCardWidget extends StatelessWidget {
  final Room room;
  final VoidCallback? onChangeState;

  const RoomCardWidget({
    super.key,
    required this.room,
    this.onChangeState,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: AspectRatio(
                aspectRatio: 5 / 6,
                child: Container(
                  decoration: BoxDecoration(
                    color: room.state.toUpperCase() == 'ACTIVE' ? const Color(0xFFE6F0FF) : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: room.state.toUpperCase() == 'ACTIVE' ? const Color(0xFF0066CC) : const Color(0xFFDDD),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.brown[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Image.asset(
                            '../assets/images/door.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.door_front_door, size: 30, color: Colors.brown);
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        top: 30,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              room.number.isNotEmpty ? room.number : 'Habitación ${room.id}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getStateColor(room.state).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                room.state,
                style: TextStyle(
                  fontSize: 12,
                  color: _getStateColor(room.state),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),
            if (room.guest.isNotEmpty)
              Text(
                room.guest,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (room.checkIn.isNotEmpty || room.checkOut.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  children: [
                    if (room.checkIn.isNotEmpty)
                      Text('In: ${room.checkIn}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    if (room.checkOut.isNotEmpty)
                      Text('Out: ${room.checkOut}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            const Spacer(),
            SizedBox(
              height: 30,
              child: ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: room.state.toUpperCase() == 'ACTIVE' ? const Color(0xFFE6F0FF) : const Color(0xFFFF6B6B),
                  foregroundColor: room.state.toUpperCase() == 'ACTIVE' ? const Color(0xFF0066CC) : Colors.white,
                  disabledBackgroundColor: room.state.toUpperCase() == 'ACTIVE' ? const Color(0xFFE6F0FF) : const Color(0xFFFF6B6B),
                  disabledForegroundColor: room.state.toUpperCase() == 'ACTIVE' ? const Color(0xFF0066CC) : Colors.white,
                ),
                child: Text(
                  room.state.toUpperCase() == 'ACTIVE'? 'Disponible' : 'No Disponible',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 30,
              child: OutlinedButton(
                onPressed: onChangeState,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0066CC),
                  side: const BorderSide(color: Color(0xFF0066CC)),
                ),
                child: const Text(
                  'Cambiar Estado',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStateColor(String state) {
    switch (state.toLowerCase()) {
      case 'disponible':
      case 'available':
        return Colors.green;
      case 'ocupada':
      case 'occupied':
        return Colors.red;
      case 'mantenimiento':
      case 'maintenance':
        return Colors.orange;
      case 'limpieza':
      case 'cleaning':
        return Colors.blue;
      case 'fuera de servicio':
      case 'out of service':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}