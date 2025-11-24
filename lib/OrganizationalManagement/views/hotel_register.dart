import 'package:flutter/material.dart';
import 'package:sweet_manager/iam/infrastructure/auth_service.dart';
import 'package:sweet_manager/OrganizationalManagement/services/hotel_service.dart';

class HotelRegistrationScreen extends StatefulWidget {
  const HotelRegistrationScreen({super.key});

  @override
  State<HotelRegistrationScreen> createState() => _HotelRegistrationScreenState();
}

class _HotelRegistrationScreenState extends State<HotelRegistrationScreen> {
  final TextEditingController _hotelNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final HotelService _hotelService = HotelService();
  final AuthService _authService = AuthService();
  final FocusNode _hotelNameFocus = FocusNode();
  final FocusNode _addressFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();

  String? _selectedHotelType;
  bool _isProcessingRegistration = false; // Add loading state

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Constants
  static const Color _primaryBlue = Color(0xFF1976D2);
  static const Color _backgroundColor = Color(0xFFF8F9FA);
  static const Color _textColor = Color(0xFF2C3E50);
  static const Color _subtitleColor = Color(0xFF95A5A6);
  static const Color _inputBorderColor = Color(0xFFE0E0E0);
  static const double _borderRadius = 8.0;

  static const List<String> _hotelTypes = [
    'FEATURED',
    'NEAR THE LAKE',
    'WITH A POOL',
    'NEAR THE BEACH',
    'RURAL HOTEL',
    'SUITE',
  ];

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
                const SizedBox(height: 40),
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

  Widget _buildHotelTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hotel Type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _subtitleColor,
          ),
        ),
        const SizedBox(height: 8),
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
          child: DropdownButtonFormField<String>(
            value: _selectedHotelType,
            decoration: const InputDecoration(
              hintText: 'Select hotel type',
              hintStyle: TextStyle(
                color: _subtitleColor,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 20,
              ),
            ),
            style: const TextStyle(
              fontSize: 16,
              color: _textColor,
              fontWeight: FontWeight.w500,
            ),
            icon: const Icon(
              Icons.arrow_drop_down,
              color: _subtitleColor,
            ),
            items: _hotelTypes.map((String type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: _isProcessingRegistration ? null : (String? newValue) {
              setState(() {
                _selectedHotelType = newValue;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Hotel type is required';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: _textColor,
              height: 1.3,
            ),
            children: [
              TextSpan(text: 'Register your new hotel and access\n'),
              TextSpan(text: 'thousands of benefits!'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Complete the\nnext form',
          style: TextStyle(
            fontSize: 16,
            color: _subtitleColor,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        _buildInputField(
          controller: _hotelNameController,
          focusNode: _hotelNameFocus,
          label: 'Hotel Name',
          hintText: 'Royal DeCameron Punta Sal',
          nextFocus: _addressFocus,
          validator: (value) => _validateRequired(value, 'Hotel name'),
        ),
        const SizedBox(height: 20),
        _buildInputField(
          controller: _addressController,
          focusNode: _addressFocus,
          label: 'Address',
          hintText: 'Av. Panamericana N, Punta Sal 2456',
          nextFocus: _emailFocus,
          validator: (value) => _validateRequired(value, 'Address'),
        ),
        const SizedBox(height: 20),
        _buildInputField(
          controller: _emailController,
          focusNode: _emailFocus,
          label: 'Email',
          hintText: 'bookings@decameron.com',
          nextFocus: _phoneFocus,
          keyboardType: TextInputType.emailAddress,
          validator: _validateEmail,
        ),
        const SizedBox(height: 20),
        _buildInputField(
          controller: _phoneController,
          focusNode: _phoneFocus,
          label: 'Phone Number',
          hintText: '073 55 4877',
          keyboardType: TextInputType.phone,
          validator: (value) => _validatePhone(value),
        ),
        const SizedBox(height: 20),
        _buildHotelTypeDropdown(),
        const SizedBox(height: 20),
        _buildInputField(
          controller: _descriptionController,
          focusNode: _descriptionFocus,
          label: 'Description',
          hintText: 'We offer the most modern rooms in the country, from small to large, with beautiful ocean views and incredible service.',
          maxLines: 4,
          textInputAction: TextInputAction.done,
          validator: (value) => _validateRequired(value, 'Description'),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hintText,
    FocusNode? nextFocus,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _subtitleColor,
          ),
        ),
        const SizedBox(height: 8),
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
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            maxLines: maxLines,
            validator: validator,
            enabled: !_isProcessingRegistration,
            style: const TextStyle(
              fontSize: 16,
              color: _textColor,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: _subtitleColor,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: maxLines > 1 ? 16 : 20,
              ),
            ),
            onFieldSubmitted: (_) {
              if (nextFocus != null) {
                FocusScope.of(context).requestFocus(nextFocus);
              } else {
                focusNode.unfocus();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildContinueButton(),
      ],
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isProcessingRegistration ? null : _handleContinue,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isProcessingRegistration ? Colors.grey : _primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
          elevation: 0,
        ),
        child: _isProcessingRegistration
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
              'Registering...',
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

  // Validation methods
  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    // Remove any non-digit characters for validation
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.length != 9) {
      return 'Phone number must be exactly 9 digits';
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

  // Action handlers
  void _handleContinue() {
    // Prevent multiple taps
    if (_isProcessingRegistration) return;

    if (!_formKey.currentState!.validate()) {
      _showErrorMessage('Please fill in all required fields correctly');
      return;
    }

    // Process the form data
    _processHotelRegistration();
  }

  String formatToEnum(String input) {
    return input.toUpperCase().replaceAll(' ', '_');
  }

  Future<void> _processHotelRegistration() async {
    setState(() {
      _isProcessingRegistration = true;
    });

    try {
      final hotelData = {
        'hotelName': _hotelNameController.text.trim(),
        'address': _addressController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'hotelType': _selectedHotelType ?? '',
        'description': _descriptionController.text.trim(),
      };

      print('Starting hotel registration...');
      print('Hotel Data: $hotelData');

      var hotelTypeConverted = hotelData['hotelType']!.toUpperCase().replaceAll(' ', '_');
      // Register the hotel
      await _hotelService.registerHotel(
          hotelData['hotelName']!,
          hotelData['description']!,
          hotelData['email']!,
          hotelData['address']!,
          hotelData['phone']!,
          hotelTypeConverted
      );

      print('Hotel registration completed successfully');

      await _authService.refreshSession();

      // Show success dialog
      if (mounted) {
        _showSuccessDialog(hotelData);
      }
    } catch (e) {
      print('Hotel registration error: $e');
      if (mounted) {
        _showErrorMessage('Registration failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingRegistration = false;
        });
      }
    }
  }

  void _showSuccessDialog(Map<String, String> hotelData) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 48,
        ),
        title: const Text('Registration Successful'),
        content: Text(
          'Hotel "${hotelData['hotelName']}" has been registered successfully!',
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
    Navigator.pushReplacementNamed(context, '/hotel/set-up').catchError((error) {
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

  @override
  void dispose() {
    // Dispose controllers
    _hotelNameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();

    // Dispose focus nodes
    _hotelNameFocus.dispose();
    _addressFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _descriptionFocus.dispose();

    super.dispose();
  }
}