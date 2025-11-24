// views/reservations_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../widgets/reservation_card.dart';
import '../../iam/infrastructure/auth_service.dart';
import 'package:sweet_manager/shared/widgets/base_layout.dart';
import '../../shared/infrastructure/misc/token_helper.dart';

class ReservationsView extends StatefulWidget {
  const ReservationsView({Key? key}) : super(key: key);

  @override
  _ReservationsViewState createState() => _ReservationsViewState();
}

class _ReservationsViewState extends State<ReservationsView> {
  final BookingService _bookingService = BookingService();
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final TokenHelper _tokenHelper = TokenHelper();

  List<Booking> _reservations = [];
  bool _isLoading = false;
  String? _error;
  String userRole = '';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadReservations();
  }

  Future<void> _loadUserRole() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) return;

      final parts = token.split('.');
      if (parts.length != 3) return;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payloadMap = json.decode(decoded);

      final role = payloadMap['http://schemas.microsoft.com/ws/2008/06/identity/claims/role']?.toString();

      setState(() {
        userRole = role ?? 'ROLE_GUEST';
      });
    } catch (e) {
      print('Error loading user role: $e');
      setState(() {
        userRole = 'ROLE_GUEST';
      });
    }
  }

  Future<void> _loadReservations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Verificar si está autenticado
      final isAuth = await _authService.isAuthenticated();
      if (!isAuth) {
        throw Exception('No está autenticado. Por favor, inicie sesión.');
      }

      // Verificar que se pueda obtener el hotel ID del token
      final hotelId = await _tokenHelper.getLocality();
      if (hotelId == null) {
        throw Exception('No se pudo obtener el ID del hotel desde el token');
      }

      print('Loading active reservations for hotel ID: $hotelId');

      // Usar el nuevo método que obtiene reservas activas por hotel
      final reservations = await _bookingService.getActiveBookingsByHotel();

      setState(() {
        _reservations = reservations;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading reservations: $e');
      setState(() {
        if (e.toString().contains('No autorizado') || e.toString().contains('No está autenticado')) {
          _error = 'Sesión expirada. Por favor, inicie sesión nuevamente.';
        } else if (e.toString().contains('No se pudo obtener el ID del hotel')) {
          _error = 'Error al obtener información del hotel. Verifique su sesión.';
        } else {
          _error = 'Error al cargar las reservas. Por favor, inténtalo de nuevo.';
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAuthError() async {
    // Redirigir al login o mostrar diálogo
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sesión Expirada'),
          content: const Text('Su sesión ha expirado. Por favor, inicie sesión nuevamente.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Aquí puedes navegar al login
                // Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelReservation(Booking booking) async {
    final confirmed = await _showCancelConfirmation(booking);
    if (!confirmed) return;

    try {
      final success = await _bookingService.updateBooking(
        booking.id,
        'cancelled',
      );

      if (success) {
        setState(() {
          final index = _reservations.indexWhere((r) => r.id == booking.id);
          if (index != -1) {
            _reservations[index] = Booking(
              id: booking.id,
              paymentCustomerId: booking.paymentCustomerId,
              roomId: booking.roomId,
              description: booking.description,
              startDate: booking.startDate,
              finalDate: booking.finalDate,
              priceRoom: booking.priceRoom,
              nightCount: booking.nightCount,
              amount: booking.amount,
              state: 'cancelled',
              preferenceId: booking.preferenceId,
              hotelName: booking.hotelName,
              hotelLogo: booking.hotelLogo,
              hotelPhone: booking.hotelPhone,
            );
          }
        });

        _showSuccessMessage('Reserva cancelada exitosamente');
      } else {
        throw Exception('Failed to cancel reservation');
      }
    } catch (e) {
      if (e.toString().contains('No autorizado')) {
        _handleAuthError();
      } else {
        _showErrorMessage('Error al cancelar la reserva. Por favor, inténtalo de nuevo.');
      }
    }
  }

  Future<bool> _showCancelConfirmation(Booking booking) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar cancelación'),
          content: Text(
            '¿Estás seguro de que deseas cancelar la reserva en ${booking.hotelName ?? "este hotel"}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Sí, cancelar'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      role: userRole,
      childScreen: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Title section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          color: Colors.white,
          child: const Column(
            children: [
              Text(
                'Active Reservations',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Manage all active reservations\nfor your hotel',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        // Content body
        Expanded(
          child: Container(
            color: Colors.grey[50],
            child: _buildReservationsContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildReservationsContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF2196F3),
            ),
            SizedBox(height: 16),
            Text(
              'Cargando reservas activas...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _error!.contains('Sesión expirada') ? Icons.lock_outline : Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _error!.contains('Sesión expirada') ? _handleAuthError : _loadReservations,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
              ),
              child: Text(_error!.contains('Sesión expirada') ? 'Iniciar Sesión' : 'Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_reservations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No hay reservas activas actualmente.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _reservations.length,
      itemBuilder: (context, index) {
        final reservation = _reservations[index];
        return ReservationCard(
          booking: reservation,
          onCancel: reservation.canCancel
              ? () => _cancelReservation(reservation)
              : null,
        );
      },
    );
  }
}