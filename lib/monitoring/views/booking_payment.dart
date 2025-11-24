import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sweet_manager/Commerce/services/payment_service.dart';
import 'package:sweet_manager/shared/widgets/base_layout.dart';
import '../../iam/infrastructure/preferences_service.dart';
import '../models/booking.dart';
import '../models/room_type.dart';
import '../services/booking_service.dart';
import '../services/room_service.dart';

class BookingPayment extends StatefulWidget {
  final Hotel hotel;
  final RoomType roomType;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int numberOfNights;
  const BookingPayment({
    required this.hotel,
    required this.roomType,
    required this.checkInDate,
    required this.checkOutDate,
    required this.numberOfNights,
    super.key,
  });

  @override
  State<BookingPayment> createState() => _BookingPaymentState();
}

class _BookingPaymentState extends State<BookingPayment> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expirationController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final PaymentService _paymentService = PaymentService();
  final BookingService _bookingService = BookingService();
  final RoomService _roomService = RoomService();
  final PreferencesService _preferencesService = PreferencesService();

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Don't set placeholder text initially - leave fields empty
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cardNumberController.dispose();
    _expirationController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  double get _totalAmount {
    // Extract numeric value from price and multiply by nights
    final priceString = widget.roomType.price.toString();
    final numericPrice = double.tryParse(priceString.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
    return numericPrice * widget.numberOfNights;
  }

  String get _formattedCheckInDate {
    const months = [
      '', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    const weekdays = [
      '', 'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'
    ];

    return '${weekdays[widget.checkInDate.weekday]}, ${widget.checkInDate.day} de ${months[widget.checkInDate.month]} de ${widget.checkInDate.year}';
  }

  String get _formattedCheckOutDate {
    const months = [
      '', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    const weekdays = [
      '', 'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'
    ];

    return '${weekdays[widget.checkOutDate.weekday]}, ${widget.checkOutDate.day} de ${months[widget.checkOutDate.month]} de ${widget.checkOutDate.year}';
  }

  bool _isFormValid() {
    return _fullNameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _cardNumberController.text.isNotEmpty &&
        _expirationController.text.isNotEmpty &&
        _cvvController.text.isNotEmpty;
  }

  Future<void> _processPayment() async {
    print('🔥 Payment process started');

    // Validate form first
    if (!_isFormValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields with valid information'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      print('📝 Form data:');
      print('- Name: ${_fullNameController.text}');
      print('- Email: ${_emailController.text}');
      print('- Total: ${_totalAmount.toInt()}');

      // Step 1: Create Payment Customer
      print('💳 Creating payment customer...');
      final paymentCustomerResponse = await _paymentService.registerPaymentCustomer(_totalAmount.toInt());

      print('💳 Payment customer response: $paymentCustomerResponse');

      // Step 2: Get available room
      print('🏨 Getting room by type...');
      final roomId = await _roomService.getRoomByTypeRoomId(widget.roomType.id);
      print('🏨 Room ID found: $roomId');

      final preferenceId = await _preferencesService.getPreferenceByGuestId();

      // Step 3: Create Booking with payment customer ID
      print('📅 Creating booking...');
      final booking = Booking(
        id: '', // Will be set by backend
        paymentCustomerId: paymentCustomerResponse.toString(),
        roomId: roomId.toString(),
        startDate: widget.checkInDate,
        finalDate: widget.checkOutDate,
        priceRoom: double.tryParse(widget.roomType.price.toString().replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0,
        nightCount: widget.numberOfNights,
        amount: _totalAmount,
        description: 'RESERVA',
        state: 'ACTIVE',
        preferenceId: preferenceId.toString(),
      );

      await _bookingService.createBooking(booking);
      print('✅ Booking created successfully');

      // Show success message
      _showSuccessDialog(roomId);

    } catch (e) {
      print('❌ Payment error: $e');
      _showErrorDialog('Error processing payment: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showSuccessDialog(int roomId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text('Payment Successful!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your booking has been confirmed for:'),
              const SizedBox(height: 10),
              Text('• Room: ${widget.roomType.name} - ${roomId}'),
              Text('• Hotel: ${widget.hotel.name}'),
              Text('• Dates: ${widget.checkInDate.day}/${widget.checkInDate.month}/${widget.checkInDate.year} - ${widget.checkOutDate.day}/${widget.checkOutDate.month}/${widget.checkOutDate.year}'),
              Text('• Total: S/ ${_totalAmount.toInt()}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Navigate back to hotel list or main page
                Navigator.of(context).pushNamed('/main');
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text('Payment Error'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      role: 'ROLE_GUEST',
      childScreen: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_ios, size: 18, color: Colors.blue),
                        Text(
                          'Volver',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Title
                const Text(
                  'Complete your booking',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle
                const Text(
                  'Please fill in your details to complete the booking. Ensure all information is correct before proceeding with the payment.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 30),

                // Summary section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Summary of your booking',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildSummaryRow('Room:', widget.roomType.name),
                      _buildSummaryRow('Check-in date:', _formattedCheckInDate),
                      _buildSummaryRow('Check-out date:', _formattedCheckOutDate),
                      _buildSummaryRow('Nights:', '${widget.numberOfNights}'),
                      const Divider(height: 30),
                      _buildSummaryRow(
                        'Total:',
                        'S/ ${_totalAmount.toInt()}',
                        isTotal: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Niubiz logo placeholder
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'niubiz',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // Form fields
                _buildTextField(
                    'Full name',
                    _fullNameController,
                    'Please enter your full name',
                    placeholder: 'Ingresa tu nombre completo'
                ),
                const SizedBox(height: 20),

                _buildTextField(
                    'Email',
                    _emailController,
                    'Please enter a valid email',
                    inputType: TextInputType.emailAddress,
                    placeholder: 'tu@email.com'
                ),
                const SizedBox(height: 20),

                _buildTextField(
                    'Phone',
                    _phoneController,
                    'Please enter your phone number',
                    inputType: TextInputType.phone,
                    placeholder: '+51 999 999 999'
                ),
                const SizedBox(height: 20),

                _buildTextField(
                    'Card number',
                    _cardNumberController,
                    'Please enter card number',
                    inputType: TextInputType.number,
                    inputFormatters: [_CardNumberFormatter()],
                    placeholder: '1234 5678 9012 3456'
                ),
                const SizedBox(height: 20),

                // Expiration and CVV row
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                          'Expiration date',
                          _expirationController,
                          'MM/YY',
                          inputType: TextInputType.number,
                          inputFormatters: [_ExpirationDateFormatter()],
                          placeholder: 'MM/YY'
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildTextField(
                          'CVV',
                          _cvvController,
                          'CVV',
                          inputType: TextInputType.number,
                          inputFormatters: [LengthLimitingTextInputFormatter(3)],
                          placeholder: '123'
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Pay button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isProcessing
                          ? Colors.grey[400]
                          : const Color(0xFF4285F4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: _isProcessing ? 0 : 2,
                    ),
                    child: _isProcessing
                        ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Processing...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                        : Text(
                      'Pagar S/ ${_totalAmount.toInt()}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller,
      String validationMessage, {
        TextInputType inputType = TextInputType.text,
        List<TextInputFormatter>? inputFormatters,
        String? placeholder,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: inputType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: Colors.grey[500]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          // Remove the problematic validation that was causing issues
        ),
      ],
    );
  }
}

// Custom formatter for card number
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

// Custom formatter for expiration date
class _ExpirationDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final text = newValue.text.replaceAll('/', '');
    if (text.length > 4) return oldValue;

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(text[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}