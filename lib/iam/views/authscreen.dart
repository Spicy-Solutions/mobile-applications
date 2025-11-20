import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:sweet_manager/iam/infrastructure/auth_service.dart';
import 'package:sweet_manager/iam/views/account_type_selection_screen.dart';
import 'package:sweet_manager/iam/views/terms_and_conditions.dart';
import 'package:sweet_manager/shared/infrastructure/misc/token_helper.dart';
import 'package:sweet_manager/shared/widgets/base_layout.dart';



class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Login controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  String? _selectedLoginRole;

  // Sign up controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _signupEmailController = TextEditingController();
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _signupPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscureSignupPassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  // State management
  bool _isLoginTab = true;
  bool _isLoading = false;
  bool _isLoginLoading = false; // Nueva variable para el loading del login
  final ScrollController _loginScrollController = ScrollController();
  final ScrollController _signupScrollController = ScrollController();
  final TokenHelper tokenHelper = TokenHelper();

  // Constants
  static const Color _primaryColor = Color(0xFF1976D2);
  static const TextStyle _labelStyle = TextStyle(color: Colors.grey);
  static const EdgeInsets _fieldPadding = EdgeInsets.all(16);
  static const BorderRadius _borderRadius = BorderRadius.all(Radius.circular(8));

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      role: '',
      childScreen: _buildAuthContent(),
    );
  }

  Widget _buildAuthContent() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: _buildAuthScreen(),
      ),
    );
  }

  Widget _buildAuthScreen() {
    const textStyle = TextStyle(fontSize: 14, color: Colors.grey);

    return Padding(
      key: const ValueKey('auth_screen'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text(
            'Welcome to Sweet Manager',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isLoginTab
                ? 'To use the app, please log in or register an account'
                : 'To use the application, please log in or register an organization',
            style: textStyle,
          ),
          const SizedBox(height: 32),
          _buildTabSelector(),
          const SizedBox(height: 24),
          Expanded(child: _buildFormContent()),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: _borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTab('Log in', true),
          _buildTab('Sign up', false),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool isLogin) {
    final bool isActive = _isLoginTab == isLogin;

    return Expanded(
      child: GestureDetector(
        onTap: () => _switchTab(isLogin),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: _borderRadius,
            border: isActive
                ? const Border(bottom: BorderSide(color: _primaryColor, width: 2))
                : null,
          ),
          child: _isLoading && isActive
              ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(_primaryColor),
            ),
          )
              : Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? _primaryColor : Colors.grey,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    final scrollController = _isLoginTab ? _loginScrollController : _signupScrollController;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Scrollbar(
        key: ValueKey(_isLoginTab),
        controller: scrollController,
        thumbVisibility: true,
        trackVisibility: true,
        thickness: 6,
        radius: const Radius.circular(3),
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.only(right: 12),
          child: _isLoginTab ? _buildLoginForm() : _buildSignUpForm(),
        ),
      ),
    );
  }

  Future<void> _switchTab(bool isLogin) async {
    if (_isLoading || _isLoginLoading) return; // Prevenir cambio durante login

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 400));

    setState(() {
      _isLoginTab = isLogin;
      _isLoading = false;
      _selectedLoginRole = null;
    });
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField(
          controller: _emailController,
          label: 'Email',
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _passwordController,
          label: 'Password',
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 16),
        _buildRoleSelection(),
        const SizedBox(height: 24),
        _buildLoginButton(),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: _borderRadius,
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        enabled: !_isLoginLoading, // Deshabilitar campos durante login
        decoration: InputDecoration(
          labelText: label,
          labelStyle: _labelStyle,
          border: InputBorder.none,
          contentPadding: _fieldPadding,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _buildRememberMeCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged: _isLoginLoading ? null : (value) => setState(() => _rememberMe = value ?? false),
          activeColor: _primaryColor,
        ),
        const Text('Remember me', style: _labelStyle),
      ],
    );
  }

  Widget _buildRoleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select your role:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: _borderRadius,
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              _buildRoleOption(
                value: 'guest',
                title: 'Guest',
                subtitle: 'I want to search and book hotel stays',
              ),
              const Divider(height: 1),
              _buildRoleOption(
                value: 'owner',
                title: 'Owner',
                subtitle: 'I want to manage my hotel business',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleOption({
    required String value,
    required String title,
    required String subtitle,
  }) {
    return RadioListTile<String>(
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      value: value,
      groupValue: _selectedLoginRole,
      onChanged: _isLoginLoading ? null : (selectedValue) => setState(() => _selectedLoginRole = selectedValue),
      activeColor: _primaryColor,
      dense: true,
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_selectedLoginRole != null && !_isLoginLoading) ? _handleLogin : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const RoundedRectangleBorder(borderRadius: _borderRadius),
        ),
        child: _isLoginLoading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        )
            : const Text(
          'Log in',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordButton() {
    return Center(
      child: TextButton(
        onPressed: _handleForgotPassword,
        child: const Text(
          'Forgot my password',
          style: TextStyle(color: _primaryColor, fontSize: 14),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final role = _selectedLoginRole!;
    final authService = AuthService();

    // Validate input
    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog('Please fill in all fields');
      return;
    }

    final int roleId = _getRoleId(role);
    if (roleId == 0) {
      _showErrorDialog('Invalid role selection');
      return;
    }

    // Activar loading
    setState(() => _isLoginLoading = true);

    try {
      final bool success = await authService.login(email, password, roleId);

      if (success && mounted) {
        final hotelId = await tokenHelper.getLocality();

        if (hotelId == "0" && roleId == 1){
          Navigator.pushNamed(context, '/advice');
          return;
        }
        if (roleId == 1) {
          Navigator.pushNamed(context, '/hotel/overview');
        } else {
          Navigator.pushNamed(context, '/main');
        }
      } else if (mounted) {
        _showErrorDialog('Invalid credentials');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('An error occurred while trying to log in: $e');
      }
    } finally {
      // Desactivar loading
      if (mounted) {
        setState(() => _isLoginLoading = false);
      }
    }
  }

  int _getRoleId(String role) {
    switch (role) {
      case 'guest':
        return 3;
      case 'owner':
        return 1;
      default:
        return 0;
    }
  }

  void _handleForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Forgot password functionality coming soon')),
    );
  }

  Widget _buildSignUpForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSignUpInputField(
          controller: _fullNameController,
          label: 'Full name',
        ),
        const SizedBox(height: 16),
        _buildSignUpInputField(
          controller: _signupEmailController,
          label: 'Email address',
        ),
        const SizedBox(height: 16),
        _buildSignUpInputField(
          controller: _dniController,
          label: 'DNI',
        ),
        const SizedBox(height: 16),
        _buildSignUpInputField(
          controller: _phoneController,
          label: 'Phone number',
        ),
        const SizedBox(height: 16),
        _buildSignUpInputField(
          controller: _signupPasswordController,
          label: 'Password',
          obscureText: _obscureSignupPassword,
          toggleObscure: true,
          onToggle: () => setState(() => _obscureSignupPassword = !_obscureSignupPassword),
        ),
        const SizedBox(height: 16),
        _buildSignUpInputField(
          controller: _confirmPasswordController,
          label: 'Confirm your password',
          obscureText: _obscureConfirmPassword,
          toggleObscure: true,
          onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
        ),
        const SizedBox(height: 16),
        _buildPasswordHints(),
        const SizedBox(height: 16),
        _buildTermsAndConditions(),
        const SizedBox(height: 24),
        _buildContinueButton(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSignUpInputField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    bool toggleObscure = false,
    VoidCallback? onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: _borderRadius,
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: _labelStyle,
          border: InputBorder.none,
          contentPadding: _fieldPadding,
          suffixIcon: toggleObscure
              ? IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: onToggle,
          )
              : null,
        ),
      ),
    );
  }

  Widget _buildPasswordHints() {
    const passwordRequirements = [
      'At least one character in uppercase and lowercase',
      'At least a number',
      'At least a special character',
      'At least 8 characters',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: passwordRequirements.map((requirement) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              const Icon(Icons.circle, size: 6, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                requirement,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTermsAndConditions() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (value) => setState(() => _acceptTerms = value ?? false),
          activeColor: _primaryColor,
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              children: [
                const TextSpan(text: "I've read and accept the "),
                TextSpan(
                  text: 'Terms and Conditions and Privacy Policy',
                  style: const TextStyle(
                    color: _primaryColor,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = _showTermsAndConditions,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _acceptTerms ? _navigateToAccountTypeSelection : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const RoundedRectangleBorder(borderRadius: _borderRadius),
        ),
        child: const Text(
          'Continue',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _navigateToAccountTypeSelection() {
    // Validate sign-up form
    if (!_validateSignUpForm()) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountTypeSelectionScreen(
          fullName: _fullNameController.text.trim(),
          email: _signupEmailController.text.trim(),
          dni: _dniController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _signupPasswordController.text,
        ),
      ),
    );
  }

  bool _validateSignUpForm() {
    final fullName = _fullNameController.text.trim();
    final email = _signupEmailController.text.trim();
    final dni = _dniController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _signupPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (fullName.isEmpty || email.isEmpty || dni.isEmpty ||
        phone.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showErrorDialog('Please fill in all fields');
      return false;
    }

    if (password != confirmPassword) {
      _showErrorDialog('Passwords do not match');
      return false;
    }

    if (!_isValidEmail(email)) {
      _showErrorDialog('Please enter a valid email address');
      return false;
    }

    if (!_isValidPassword(password)) {
      _showErrorDialog('Password does not meet requirements');
      return false;
    }

    return true;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _isValidPassword(String password) {
    // At least 8 characters, one uppercase, one lowercase, one number, one special character
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showTermsAndConditions() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TermsAndConditionsPage()),
    );
  }

  @override
  void dispose() {
    // Dispose controllers
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _signupEmailController.dispose();
    _dniController.dispose();
    _phoneController.dispose();
    _signupPasswordController.dispose();
    _confirmPasswordController.dispose();

    // Dispose scroll controllers
    _loginScrollController.dispose();
    _signupScrollController.dispose();

    super.dispose();
  }
}