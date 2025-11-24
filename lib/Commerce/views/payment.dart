import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sweetmanager/Commerce/services/contract_owner_service.dart';
import 'package:sweetmanager/Commerce/services/payment_service.dart';

class PaymentCheckoutScreen extends StatefulWidget {
  const PaymentCheckoutScreen({super.key, required this.cardIdentifier});

  final int cardIdentifier;

  @override
  State<PaymentCheckoutScreen> createState() => _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends State<PaymentCheckoutScreen> {
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expirationController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final ContractOwnerService _contractOwnerService = ContractOwnerService();
  final PaymentService _paymentService = PaymentService();
  final FocusNode _cardNumberFocus = FocusNode();
  final FocusNode _expirationFocus = FocusNode();
  final FocusNode _cvvFocus = FocusNode();

  late int cardIdentifier;
  bool _isProcessingPayment = false; // Add loading state

  @override
  void initState() {
    super.initState();
    cardIdentifier = widget.cardIdentifier;
  }

  // Constants
  static const Color _primaryBlue = Color(0xFF1976D2);
  static const Color _backgroundColor = Color(0xFFF5F5F5);
  static const Color _cardBackground = Colors.white;
  static const double _borderRadius = 16.0;
  static const double _inputBorderRadius = 8.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              _buildHeader(),
              const SizedBox(height: 60),
              _buildPaymentCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          'Payment and checkout',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Complete the form',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(_borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlanHeader(),
          const SizedBox(height: 24),
          _buildCreditCardIcon(),
          const SizedBox(height: 24),
          _buildPaymentMethods(),
          const SizedBox(height: 24),
          _buildCardForm(),
          const SizedBox(height: 32),
          _buildPayButton(),
        ],
      ),
    );
  }

  Widget _buildPlanHeader() {
    String planName;
    String totalAmount;
    
    switch (cardIdentifier) {
      case 1:
        planName = 'PLAN BASICO';
        totalAmount = 'Total \$29.99';
        break;
      case 2:
        planName = 'PLAN REGULAR';
        totalAmount = 'Total \$58.99';
        break;
      default:
        planName = 'PLAN PREMIUM';
        totalAmount = 'Total \$110.69';
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              planName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              totalAmount,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        Image.asset(
          'assets/images/niubiz_logo.png',
          height: 24,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'niubiz',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCreditCardIcon() {
    return Center(
      child: Container(
        width: 60,
        height: 40,
        decoration: BoxDecoration(
          color: _primaryBlue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.credit_card,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildPaymentMethods() {
    final paymentMethods = [
      {'image': 'assets/images/amex_logo.png', 'fallbackIcon': Icons.account_balance},
      {'image': 'assets/images/visa_logo.png', 'fallbackIcon': Icons.credit_card},
      {'image': 'assets/images/diners_logo.png', 'fallbackIcon': Icons.credit_card},
      {'image': 'assets/images/mastercard_logo.png', 'fallbackIcon': Icons.credit_card},
      {'image': 'assets/images/google_pay_logo.png', 'fallbackIcon': Icons.account_balance_wallet},
      {'image': 'assets/images/apple_pay_logo.png', 'fallbackIcon': Icons.payment},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: paymentMethods.map((method) {
        return _buildPaymentMethodCard(
          imagePath: method['image'] as String,
          fallbackIcon: method['fallbackIcon'] as IconData,
        );
      }).toList(),
    );
  }

  Widget _buildPaymentMethodCard({
    required String imagePath,
    required IconData fallbackIcon,
  }) {
    return Container(
      width: 40,
      height: 28,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Image.asset(
        imagePath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            fallbackIcon,
            size: 16,
            color: Colors.grey[600],
          );
        },
      ),
    );
  }

  Widget _buildCardForm() {
    return Column(
      children: [
        _buildCardNumberField(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildExpirationField()),
            const SizedBox(width: 16),
            Expanded(child: _buildCvvField()),
          ],
        ),
      ],
    );
  }

  Widget _buildCardNumberField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(_inputBorderRadius),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: _cardNumberController,
        focusNode: _cardNumberFocus,
        keyboardType: TextInputType.number,
        enabled: !_isProcessingPayment,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          _CardNumberInputFormatter(),
        ],
        decoration: const InputDecoration(
          hintText: 'Card number',
          hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        onSubmitted: (_) => FocusScope.of(context).requestFocus(_expirationFocus),
      ),
    );
  }

  Widget _buildExpirationField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(_inputBorderRadius),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: _expirationController,
        focusNode: _expirationFocus,
        keyboardType: TextInputType.number,
        enabled: !_isProcessingPayment,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          _ExpirationDateInputFormatter(),
        ],
        decoration: const InputDecoration(
          hintText: 'Expiration Date',
          hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        onSubmitted: (_) => FocusScope.of(context).requestFocus(_cvvFocus),
      ),
    );
  }

  Widget _buildCvvField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(_inputBorderRadius),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: _cvvController,
        focusNode: _cvvFocus,
        keyboardType: TextInputType.number,
        obscureText: true,
        enabled: !_isProcessingPayment,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
        ],
        decoration: const InputDecoration(
          hintText: 'CVV',
          hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        onSubmitted: (_) => _handlePayment(),
      ),
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessingPayment ? null : _handlePayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isProcessingPayment ? Colors.grey : _primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_inputBorderRadius),
          ),
          elevation: 0,
        ),
        child: _isProcessingPayment
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
                    'PROCESSING...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              )
            : const Text(
                'PAY',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
      ),
    );
  }

  void _handlePayment() {
    // Prevent multiple taps
    if (_isProcessingPayment) return;
    
    // Validate form
    if (!_validateForm()) return;

    // Process payment
    _processPayment();
  }

  bool _validateForm() {
    final cardNumber = _cardNumberController.text.replaceAll(' ', '');
    final expiration = _expirationController.text;
    final cvv = _cvvController.text;

    if (cardNumber.length < 13 || cardNumber.length > 19) {
      _showErrorMessage('Please enter a valid card number');
      return false;
    }

    if (expiration.length != 5) {
      _showErrorMessage('Please enter a valid expiration date');
      return false;
    }

    if (cvv.length < 3 || cvv.length > 4) {
      _showErrorMessage('Please enter a valid CVV');
      return false;
    }

    return true;
  }

  Future<void> _processPayment() async {
    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // Calculate amount based on plan
      double amount;
      switch (cardIdentifier) {
        case 1:
          amount = 29.99;
          break;
        case 2:
          amount = 58.99;
          break;
        default:
          amount = 110.69;
          break;
      }

      final today = DateTime.now();
      final description = 'CONTRACT - ${today.day}/${today.month}/${today.year}';

      print('Starting payment process...');
      print('Amount: \$${amount.toStringAsFixed(2)}');
      print('Description: $description');

      // Register contract owner
      print('Registering contract owner...');
      await _contractOwnerService.registerContractOwner(cardIdentifier);
      print('Contract owner registered successfully');

      // Register payment
      print('Registering payment...');
      await _paymentService.registerPaymentOwner(description, amount.toInt());
      print('Payment registered successfully');

      // Show success message
      if (mounted) {
        _showSuccessMessage();
      }
    } catch (e) {
      print('Payment processing error: $e');
      if (mounted) {
        _showErrorMessage('Payment failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessMessage() {
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
        title: const Text('Payment Successful'),
        content: const Text('Your payment has been processed successfully.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // Navigate to hotel register or back to previous screen
              Navigator.pushNamed(context, '/hotel/register').catchError((error) {
                // If route doesn't exist, just go back
                Navigator.pop(context);
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expirationController.dispose();
    _cvvController.dispose();
    _cardNumberFocus.dispose();
    _expirationFocus.dispose();
    _cvvFocus.dispose();
    super.dispose();
  }
}

// Custom input formatter for card number (adds spaces every 4 digits)
class _CardNumberInputFormatter extends TextInputFormatter {
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
    
    final formattedText = buffer.toString();
    
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

// Custom input formatter for expiration date (MM/YY format)
class _ExpirationDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length && i < 4; i++) {
      if (i == 2) {
        buffer.write('/');
      }
      buffer.write(text[i]);
    }
    
    final formattedText = buffer.toString();
    
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}