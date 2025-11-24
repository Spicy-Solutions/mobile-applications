import 'package:flutter/material.dart';
import '../models/booking.dart';

class ReservationCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onCancel;

  const ReservationCard({
    Key? key,
    required this.booking,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hotel logo
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2196F3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: booking.hotelLogo != null && booking.hotelLogo!.isNotEmpty
                  ? ClipOval(
                child: Image.network(
                  booking.hotelLogo!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildDefaultLogo(),
                ),
              )
                  : _buildDefaultLogo(),
            ),

            const SizedBox(height: 8),

            // Hotel name - usando la información real del hotel
            Flexible(
              child: Text(
                booking.hotelName ?? 'Hotel',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 6),
            // Teléfono del hotel
            if (booking.hotelPhone != null && booking.hotelPhone!.isNotEmpty)
              Text(
                booking.hotelPhone!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 8),

            // Booking info - mostrar fechas de la reserva
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.blue,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_formatDate(booking.startDate)} - ${_formatDate(booking.finalDate)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Amount
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Text(
                'S/. ${booking.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ),


            const SizedBox(height: 8),

            // Status badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(booking.state),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                booking.statusText,
                style: TextStyle(
                  color: _getStatusTextColor(booking.state),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 8),

            // Cancel button
            if (booking.canCancel)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    side: BorderSide(color: Colors.grey[400]!),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  Widget _buildDefaultLogo() {
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF2196F3),
      ),
      child: const Icon(
        Icons.hotel,
        color: Colors.white,
        size: 30,
      ),
    );
  }

  Color _getStatusColor(String state) {
    switch (state.toLowerCase()) {
      case 'active':
      case 'confirmed':
        return const Color(0xFFE3F2FD);
      case 'cancelled':
      case 'inactive':
        return const Color(0xFFFFEBEE);
      case 'pending':
        return const Color(0xFFFFF3E0);
      default:
        return const Color(0xFFFFEBEE);
    }
  }

  Color _getStatusTextColor(String state) {
    switch (state.toLowerCase()) {
      case 'active':
      case 'confirmed':
        return const Color(0xFF1976D2);
      case 'cancelled':
      case 'inactive':
        return const Color(0xFFD32F2F);
      case 'pending':
        return const Color(0xFFF57C00);
      default:
        return const Color(0xFFD32F2F);
    }
  }
}