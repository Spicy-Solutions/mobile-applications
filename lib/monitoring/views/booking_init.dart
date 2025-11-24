import 'package:flutter/material.dart';
import 'package:sweet_manager/monitoring/models/room_type.dart';
import 'package:sweet_manager/monitoring/views/booking_payment.dart';
import 'package:sweet_manager/OrganizationalManagement/models/hotel.dart';
import 'package:sweet_manager/shared/widgets/base_layout.dart';



class BookingInit extends StatefulWidget {
  final Hotel hotel;
  final RoomType roomType;

  const BookingInit({
    required this.hotel,
    required this.roomType,
    super.key,
  });

  @override
  State<BookingInit> createState() => _BookingInitState();
}

class _BookingInitState extends State<BookingInit> {
  final TextEditingController _checkInController = TextEditingController();
  final TextEditingController _checkOutController = TextEditingController();
  DateTime? _checkInDate;
  DateTime? _checkOutDate;

  @override
  void initState() {
    super.initState();
    _checkInController.text = 'dd/mm/aaaa';
    _checkOutController.text = 'dd/mm/aaaa';
  }

  @override
  void dispose() {
    _checkInController.dispose();
    _checkOutController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isCheckIn) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInDate = picked;
          _checkInController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';

          // If check-out date is before or same as check-in, clear it
          if (_checkOutDate != null && _checkOutDate!.isBefore(picked.add(const Duration(days: 1)))) {
            _checkOutDate = null;
            _checkOutController.text = 'dd/mm/aaaa';
          }
        } else {
          // Ensure check-out is after check-in
          if (_checkInDate != null && picked.isAfter(_checkInDate!)) {
            _checkOutDate = picked;
            _checkOutController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Check-out date must be after check-in date'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      });
    }
  }

  String _getRoomImage() {
    final Map<String, String> imageMap = {
      'Simple': 'https://images.unsplash.com/photo-1618773928121-c32242e63f39?w=500&h=350&fit=crop',
      'Double': 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=500&h=350&fit=crop',
      'Master': 'https://images.unsplash.com/photo-1590490360182-c33d57733427?w=500&h=350&fit=crop',
      'Balcony': 'https://images.unsplash.com/photo-1591088398332-8a7791972843?w=500&h=350&fit=crop',
      'Suite': 'https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=500&h=350&fit=crop',
      'Premium': 'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=500&h=350&fit=crop',
    };

    for (String key in imageMap.keys) {
      if (widget.roomType.name.toLowerCase().contains(key.toLowerCase())) {
        return imageMap[key]!;
      }
    }

    return 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=500&h=350&fit=crop';
  }

  bool _canContinue() {
    return _checkInDate != null && _checkOutDate != null;
  }

  void _continueToPayment() {
    if (!_canContinue()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both check-in and check-out dates'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Calculate number of nights
    final nights = _checkOutDate!.difference(_checkInDate!).inDays;

    // Navigate to payment page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookingPayment(
          hotel: widget.hotel,
          roomType: widget.roomType,
          checkInDate: _checkInDate!,
          checkOutDate: _checkOutDate!,
          numberOfNights: nights,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      role: 'ROLE_GUEST',
      childScreen: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button and title
              Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back_ios,
                            size: 18,
                            color: Colors.blue,
                          ),
                          Text(
                            'Back',
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
                ],
              ),

              const SizedBox(height: 20),

              // Title
              const Text(
                'Select your dates',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 30),

              // Room image and details
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // Background image
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(_getRoomImage()),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      // Gradient overlay
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),

                      // Room details
                      Positioned(
                        right: 20,
                        bottom: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              widget.roomType.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.roomType.price} by night',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Date selection section
              Row(
                children: [
                  // Check-in date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Check-in Date',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _selectDate(context, true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _checkInController.text,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _checkInController.text == 'dd/mm/aaaa'
                                          ? Colors.grey[500]
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.calendar_today,
                                  size: 20,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Check-out date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Check-out Date',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _selectDate(context, false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _checkOutController.text,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _checkOutController.text == 'dd/mm/aaaa'
                                          ? Colors.grey[500]
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.calendar_today,
                                  size: 20,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Continue to Payment button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canContinue() ? _continueToPayment : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canContinue()
                        ? const Color(0xFF87CEEB) // Light blue color
                        : Colors.grey[300],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: _canContinue() ? 2 : 0,
                  ),
                  child: const Text(
                    'Continue to Payment',
                    style: TextStyle(
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
    );
  }
}