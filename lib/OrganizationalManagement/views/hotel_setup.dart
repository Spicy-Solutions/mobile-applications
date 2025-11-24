import 'package:flutter/material.dart';
import 'package:sweet_manager/OrganizationalManagement/services/setup_service.dart';

class HotelSetupScreen extends StatefulWidget {
  const HotelSetupScreen({super.key});

  @override
  State<HotelSetupScreen> createState() => _HotelSetupScreenState();
}

class _HotelSetupScreenState extends State<HotelSetupScreen> {
  final TextEditingController _inviteAdminController = TextEditingController();

  // Controllers for room counts
  final TextEditingController _simpleRoomCountController = TextEditingController();
  final TextEditingController _doubleRoomCountController = TextEditingController();
  final TextEditingController _masterRoomCountController = TextEditingController();
  final TextEditingController _balconyRoomCountController = TextEditingController();

  // Controllers for room prices
  final TextEditingController _simpleRoomPriceController = TextEditingController();
  final TextEditingController _doubleRoomPriceController = TextEditingController();
  final TextEditingController _masterRoomPriceController = TextEditingController();
  final TextEditingController _balconyRoomPriceController = TextEditingController();

  final SetupService _setupService = SetupService();

  final List<String> _selectedRoomTypes = [];
  bool _isProcessingDetails = false; // Add loading state

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Constants
  static const Color _primaryBlue = Color(0xFF1976D2);
  static const Color _backgroundColor = Color(0xFFF8F9FA);
  static const Color _textColor = Color(0xFF2C3E50);
  static const Color _subtitleColor = Color(0xFF95A5A6);
  static const Color _purpleColor = Color(0xFF9C27B0);
  static const Color _inputBorderColor = Color(0xFFE0E0E0);
  static const double _borderRadius = 8.0;

  // Updated room types list
  static const List<Map<String, String>> _roomTypes = [
    {'key': 'Simple Room', 'display': 'Simple Room'},
    {'key': 'Double Room', 'display': 'Double Room'},
    {'key': 'Master Room', 'display': 'Master Room'},
    {'key': 'Balcony Room', 'display': 'Balcony Room'},
  ];

  @override
  void initState() {
    super.initState();
    _inviteAdminController.text = 'admin.jose@gmail.com';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 32),
                _buildForm(),
                const SizedBox(height: 32),
                _buildActionButtons(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hotel\'s details',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: _textColor,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Complete the form:',
          style: TextStyle(
            fontSize: 16,
            color: _subtitleColor,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRoomTypesSection(),
        const SizedBox(height: 32),
        _buildInviteAdminField(),
      ],
    );
  }

  Widget _buildRoomTypesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Room\'s Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _purpleColor,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _purpleColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '*',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildRoomTypeCheckboxes(),
      ],
    );
  }

  Widget _buildRoomTypeCheckboxes() {
    return Column(
      children: [
        // First row: Simple Room and Double Room
        Row(
          children: [
            Expanded(
              child: _buildRoomTypeWithInputs(
                  _roomTypes[0]['key']!,
                  _roomTypes[0]['display']!,
                  _simpleRoomCountController,
                  _simpleRoomPriceController
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildRoomTypeWithInputs(
                  _roomTypes[1]['key']!,
                  _roomTypes[1]['display']!,
                  _doubleRoomCountController,
                  _doubleRoomPriceController
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Second row: Master Room and Balcony Room
        Row(
          children: [
            Expanded(
              child: _buildRoomTypeWithInputs(
                  _roomTypes[2]['key']!,
                  _roomTypes[2]['display']!,
                  _masterRoomCountController,
                  _masterRoomPriceController
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildRoomTypeWithInputs(
                  _roomTypes[3]['key']!,
                  _roomTypes[3]['display']!,
                  _balconyRoomCountController,
                  _balconyRoomPriceController
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoomTypeWithInputs(
      String roomTypeKey,
      String roomTypeDisplay,
      TextEditingController countController,
      TextEditingController priceController
      ) {
    final isSelected = _selectedRoomTypes.contains(roomTypeKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _isProcessingDetails ? null : () {
            setState(() {
              if (isSelected) {
                _selectedRoomTypes.remove(roomTypeKey);
                countController.clear();
                priceController.clear();
              } else {
                _selectedRoomTypes.add(roomTypeKey);
              }
            });
          },
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isSelected ? _purpleColor : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? _purpleColor : _inputBorderColor,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: isSelected
                    ? const Icon(
                  Icons.check,
                  size: 14,
                  color: Colors.white,
                )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  roomTypeDisplay,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? _purpleColor : _textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isSelected) ...[
          const SizedBox(height: 12),
          // Count input field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_borderRadius),
              border: Border.all(color: _inputBorderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: countController,
              keyboardType: TextInputType.number,
              enabled: !_isProcessingDetails,
              style: const TextStyle(
                fontSize: 12,
                color: _textColor,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                hintText: 'Count',
                hintStyle: TextStyle(
                  color: _subtitleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              validator: (value) {
                if (isSelected && (value == null || value.trim().isEmpty)) {
                  return 'Count required';
                }
                if (isSelected && int.tryParse(value!) == null) {
                  return 'Enter valid number';
                }
                if (isSelected && int.parse(value!) <= 0) {
                  return 'Must be greater than 0';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 8),
          // Price input field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_borderRadius),
              border: Border.all(color: _inputBorderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextFormField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enabled: !_isProcessingDetails,
              style: const TextStyle(
                fontSize: 12,
                color: _textColor,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                hintText: 'Price (\$)',
                hintStyle: TextStyle(
                  color: _subtitleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              validator: (value) {
                if (isSelected && (value == null || value.trim().isEmpty)) {
                  return 'Price required';
                }
                if (isSelected && double.tryParse(value!) == null) {
                  return 'Enter valid price';
                }
                if (isSelected && double.parse(value!) <= 0) {
                  return 'Must be greater than 0';
                }
                return null;
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInviteAdminField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Invite admin',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _subtitleColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_borderRadius),
                  border: Border.all(color: _inputBorderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _inviteAdminController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isProcessingDetails,
                  style: const TextStyle(
                    fontSize: 16,
                    color: _textColor,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                  ),
                  validator: _validateEmail,
                ),
              ),
            ),
            const SizedBox(width: 12)
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          flex: 1,
          child: _buildContinueButton(),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isProcessingDetails ? null : _handleContinue,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isProcessingDetails ? Colors.grey : _primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
          elevation: 0,
        ),
        child: _isProcessingDetails
            ? const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Processing...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        )
            : const Text(
          'Continue',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Helper method to get controllers by room type key
  Map<String, TextEditingController> _getControllersByRoomType(String roomTypeKey) {
    switch (roomTypeKey) {
      case 'Simple Room':
        return {
          'count': _simpleRoomCountController,
          'price': _simpleRoomPriceController,
        };
      case 'Double Room':
        return {
          'count': _doubleRoomCountController,
          'price': _doubleRoomPriceController,
        };
      case 'Master Room':
        return {
          'count': _masterRoomCountController,
          'price': _masterRoomPriceController,
        };
      case 'Balcony Room':
        return {
          'count': _balconyRoomCountController,
          'price': _balconyRoomPriceController,
        };
      default:
        return {
          'count': TextEditingController(),
          'price': TextEditingController(),
        };
    }
  }

  // Validation methods
  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  bool _validateForm() {
    bool isValid = _formKey.currentState!.validate();

    if (_selectedRoomTypes.isEmpty) {
      _showErrorMessage('Please select at least one room type');
      isValid = false;
    }

    return isValid;
  }

  // Action handlers
  void _handleContinue() {
    // Prevent multiple taps
    if (_isProcessingDetails) return;

    if (!_validateForm()) {
      return;
    }

    _processHotelDetails();
  }

  Future<void> _processHotelDetails() async {
    setState(() {
      _isProcessingDetails = true;
    });

    try {
      print('Processing hotel details...');

      // Process each selected room type
      for (String roomTypeKey in _selectedRoomTypes) {
        final controllers = _getControllersByRoomType(roomTypeKey);
        final countController = controllers['count']!;
        final priceController = controllers['price']!;

        final count = int.tryParse(countController.text) ?? 0;
        final price = double.tryParse(priceController.text) ?? 0.0;

        print('Setting up room type: $roomTypeKey');
        print('Count: $count, Price: \$${price.toStringAsFixed(2)}');

        // Call the setup service for each room type
        await _setupService.setUpRoomsWithTypeRoom(
            roomTypeKey,      // description (room type)
            price,           // price
            count            // countRooms
        );

        print('Successfully set up $roomTypeKey');
      }

      // Prepare final hotel details for success dialog
      final hotelDetails = {
        'roomTypes': _selectedRoomTypes.map((roomTypeKey) {
          final controllers = _getControllersByRoomType(roomTypeKey);
          final count = int.tryParse(controllers['count']!.text) ?? 0;
          final price = double.tryParse(controllers['price']!.text) ?? 0.0;

          return {
            'type': roomTypeKey,
            'displayName': roomTypeKey,
            'count': count,
            'price': price,
          };
        }).toList(),
        'inviteAdmin': _inviteAdminController.text.trim(),
      };

      print('All room types processed successfully');
      print('Final hotel details: $hotelDetails');

      if (mounted) {
        _showSuccessDialog(hotelDetails);
      }
    } catch (e) {
      print('Hotel details processing error: $e');
      if (mounted) {
        _showErrorMessage('Failed to save hotel details: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingDetails = false;
        });
      }
    }
  }

  void _showSuccessDialog(Map<String, dynamic> hotelDetails) {
    if (!mounted) return;

    final roomTypesList = (hotelDetails['roomTypes'] as List)
        .map((rt) => '${rt['displayName']}: ${rt['count']} rooms at \$${rt['price'].toStringAsFixed(2)} each')
        .join('\n');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 48,
        ),
        title: const Text('Hotel Details Saved'),
        content: Text(
          'Hotel details have been saved successfully!\n\n'
              'Room Types:\n$roomTypesList\n\n'
              'Admin invited: ${hotelDetails['inviteAdmin']}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _navigateToNextScreen();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _navigateToNextScreen() {
    // Replace with your actual navigation logic
    Navigator.pushReplacementNamed(context, '/hotel/set-up/review').catchError((error) {
      // If route doesn't exist, show error or navigate to a default route
      _showErrorMessage('Navigation error: Unable to proceed to next screen');
    });
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showInfoMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue[600],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose all controllers
    _inviteAdminController.dispose();
    _simpleRoomCountController.dispose();
    _doubleRoomCountController.dispose();
    _masterRoomCountController.dispose();
    _balconyRoomCountController.dispose();
    _simpleRoomPriceController.dispose();
    _doubleRoomPriceController.dispose();
    _masterRoomPriceController.dispose();
    _balconyRoomPriceController.dispose();
    super.dispose();
  }
}