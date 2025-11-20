import 'package:flutter/material.dart';
import 'package:sweet_manager/iam/infrastructure/auth_service.dart';

class AccountTypeSelectionScreen extends StatefulWidget {
  final String fullName;
  final String email;
  final String dni;
  final String phone;
  final String password;

  const AccountTypeSelectionScreen({
    Key? key,
    required this.fullName,
    required this.email,
    required this.dni,
    required this.phone,
    required this.password,
  }) : super(key: key);

  @override
  State<AccountTypeSelectionScreen> createState() => _AccountTypeSelectionScreenState();
}

class _AccountTypeSelectionScreenState extends State<AccountTypeSelectionScreen> {
  String? _selectedAccountType;

  Widget _buildOption({
    required String value,
    required String title,
    required String subtitle,
  }) {
    final selected = _selectedAccountType == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedAccountType = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF1976D2) : Colors.grey[300]!,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _selectedAccountType,
              onChanged: (val) => setState(() => _selectedAccountType = val),
              activeColor: const Color(0xFF1976D2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSignUp() async {
    final nameParts = widget.fullName.trim().split(' ');
    final name = nameParts.isNotEmpty ? nameParts[0] : '';
    final surname = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    final dni = widget.dni.trim();
    final id = int.tryParse(dni);
    final authService = AuthService();

    if (id == null) {
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text("Error"),
          content: Text("El DNI debe ser un número válido."),
        ),
      );
      return;
    }

    final success = await (() async {
      if (_selectedAccountType == 'guest') {
        return await authService.signupGuest(
          id, name, surname, widget.phone,
          widget.email, widget.password, '',
        );
      } else {
        return await authService.signupOwner(
          id, name, surname, widget.phone,
          widget.email, widget.password, '',
        );
      }
    })();

    if (success) {
      Navigator.pushNamed(context, '/home');
    } else {
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('Error'),
          content: Text('Error al registrar usuario'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1976D2),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Text('A last step!',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Color(0xFF1976D2))),
                    const SizedBox(height: 16),
                    const Text(
                      'At SweetManager we care about providing the best experience possible.',
                      style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Who this account will be for?',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    const SizedBox(height: 24),
                    _buildOption(
                      value: 'guest',
                      title: 'Guest',
                      subtitle: 'I will use my account to search, book a stay within a hotel.',
                    ),
                    _buildOption(
                      value: 'chief_owner',
                      title: 'Chief owner',
                      subtitle:
                          'I will be in charge of all the activities inside my hotel and I will manage what is necessary for my clients.',
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _selectedAccountType != null ? _handleSignUp : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 0,
                        ),
                        child: const Text('Sign up',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}