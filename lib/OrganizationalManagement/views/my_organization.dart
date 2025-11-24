import 'package:flutter/material.dart';
import 'package:sweet_manager/iam/infrastructure/profile_service.dart';
import 'package:sweet_manager/OrganizationalManagement/services/hotel_service.dart';
import 'package:sweet_manager/OrganizationalManagement/services/admin_service.dart';
import 'package:sweet_manager/OrganizationalManagement/models/hotel.dart';
import 'package:sweet_manager/shared/infrastructure/misc/token_helper.dart';
import '../widgets/organization_card.dart';
import 'package:sweet_manager/shared/widgets/base_layout.dart';

class OrganizationPage extends StatefulWidget {
  const OrganizationPage({super.key});

  @override
  State<OrganizationPage> createState() => _OrganizationPageState();
}

class _OrganizationPageState extends State<OrganizationPage> {
  final ProfileService _profileService = ProfileService();
  final HotelService _hotelService = HotelService();
  final AdminService _adminService = AdminService();
  final TokenHelper _tokenHelper = TokenHelper();

  Map<String, dynamic>? currentUser;
  Hotel? currentHotel;
  List<Map<String, dynamic>> currentHotelAdmins = [];
  bool isLoading = true;
  bool isHotelLoading = true;
  bool isAdminsLoading = true;
  bool showModal = false;
  bool showAdminModal = false;
  String? errorMessage;
  bool hasAuthError = false;
  String? userRole = '';

  // Controllers para el modal de admin
  final TextEditingController _adminEmailController = TextEditingController();
  bool isAddingAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _checkSessionAndLoadUser();
    _loadHotelInfo();
    _loadCurrentHotelAdmins();
  }

  @override
  void dispose() {
    _adminEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      setState((){
        isLoading = true;
        errorMessage = null;
        hasAuthError = false;
      });

      Map<String, dynamic>? response;
      response = await _profileService.getCurrentOwner();

      if (response != null) {
        setState(() {
          currentUser = response;
          isLoading = false;
        });
        print('Current user loaded successfully: ${currentUser?['name'] ?? 'Unknown'}');
      } else {
        print('No user data received from API');
        setState(() {
          currentUser = null;
          isLoading = false;
        });
      }
    }
    catch(e) {
      setState(() {
        currentUser = null;
        isLoading = false;
        errorMessage = 'Failed to load user information. Please try again.';
      });
    }
  }

  Future<void> _loadCurrentHotelAdmins() async {
    try {
      setState(() {
        isAdminsLoading = true;
      });

      final admins = await _adminService.getCurrentHotelAdmins();

      setState(() {
        currentHotelAdmins = admins;
        isAdminsLoading = false;
      });

      print('Loaded ${admins.length} admins for current hotel');
    } catch (e) {
      print('Error loading current hotel admins: $e');
      setState(() {
        currentHotelAdmins = [];
        isAdminsLoading = false;
      });
    }
  }

  Future<void> _loadHotelInfo() async {
    try {
      setState(() {
        isHotelLoading = true;
      });

      final hotelId = await _tokenHelper.getLocality();
      // Obtener todos los hoteles y buscar el del usuario actual
      final hotel = await _hotelService.getHotelById(int.parse(hotelId!));

      currentHotel = hotel;
      setState(() {
        isHotelLoading = false;
      });
    } catch (e) {
      print('Error loading hotel info: $e');
      setState(() {
        currentHotel = null;
        isHotelLoading = false;
      });
    }
  }

  Future<void> _checkSessionAndLoadUser() async {
    try {
      // Verificar si hay una sesión activa
      final hasSession = await _profileService.hasActiveSession();

      if (!hasSession) {
        setState(() {
          hasAuthError = true;
          errorMessage = 'No active session found. Please login.';
          isLoading = false;
        });
        return;
      }

      // Extraer el rol del token si no se ha cargado aún
      if (userRole == null || userRole!.isEmpty) {
        userRole = await _profileService.getUserRoleFromToken();
      }

      await _loadCurrentUser();
    } catch (e) {
      print('Error checking session: $e');
      setState(() {
        hasAuthError = true;
        errorMessage = 'Authentication error. Please login again.';
        isLoading = false;
      });
    }
  }

  void _showAuthErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session Expired'),
        content: const Text('Your session has expired. Please login again to continue.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToLogin();
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  void _navigateToLogin() {
    // Navegar a la pantalla de login
    Navigator.pushNamed(context, '/home');
  }

  void _showEditUserModal() {
    if (hasAuthError || currentUser == null) {
      _showAuthErrorDialog();
      return;
    }

    setState(() {
      showModal = true;
    });
  }

  void _hideEditUserModal() {
    setState(() {
      showModal = false;
    });
  }

  void _showAddAdminModal() {
    if (hasAuthError || currentUser == null) {
      _showAuthErrorDialog();
      return;
    }

    setState(() {
      showAdminModal = true;
    });
    _adminEmailController.clear();
  }

  void _hideAddAdminModal() {
    setState(() {
      showAdminModal = false;
    });
  }

  Future<void> _addAdminToHotel() async {
    if (_adminEmailController.text.trim().isEmpty || currentHotel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isAddingAdmin = true;
    });

    try {
      final email = _adminEmailController.text.trim();

      // Buscar el admin por email
      Map<String, dynamic>? adminData = await _adminService.getAdminByEmail(email);

      // Si no se encuentra, intentar buscar con el hotelId específico
      if (adminData == null) {
        print('Admin not found globally, searching in current hotel...');
        adminData = await _adminService.getAdminByEmailAndHotel(email, currentHotel!.id);
      }

      if (adminData == null) {
        // Mostrar información más detallada del error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Admin not found with email: $email\nPlease verify the email address is correct and the user is registered as an admin.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }

      // Obtener el ID del admin
      final adminId = adminData['id'];

      if (adminId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid admin data received from server'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print('Found admin: $adminData');
      print('Assigning admin $adminId to hotel ${currentHotel!.id}');

      // Asignar el admin al hotel usando el PUT endpoint
      final success = await _adminService.assignAdminToHotel(adminId, currentHotel!.id);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Admin ${adminData['name'] ?? adminData['username'] ?? 'Unknown'} assigned successfully to ${currentHotel!.name}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        _hideAddAdminModal();

        // Recargar la información del hotel/admins
        _loadHotelInfo();
        _loadCurrentHotelAdmins(); // Recargar los admins del hotel actual
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to assign admin to hotel. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }

    } catch (e) {
      print('Error adding admin: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        isAddingAdmin = false;
      });
    }
  }

  void _handleUpdateUser(Map<String, dynamic> updatedData) async {
    try {
      print('Updating user with data: $updatedData');

      bool success;
      if (userRole?.contains('GUEST') == true) {
        success = await _profileService.updateCurrentGuest(updatedData);
      } else if (userRole?.contains('OWNER') == true) {
        success = await _profileService.updateCurrentOwner(updatedData);
      } else {
        success = await _profileService.updateCurrentGuest(updatedData);
      }

      if (success) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User information updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Recargar los datos del usuario
        _loadCurrentUser();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update user information'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error updating user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating user: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _refreshUser() {
    if (hasAuthError) {
      _checkSessionAndLoadUser();
    } else {
      _loadCurrentUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      role: userRole,
      childScreen: Stack(
        children: [
          _buildContent(),

          // Modal para agregar admin
          if (showAdminModal)
            _buildAddAdminModal(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: Column(
        children: [
          // Contenido principal
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(20),
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  children: [
                    // Header
                    _buildHeader(),
                    const SizedBox(height: 30),

                    // Content
                    if (hasAuthError)
                      _buildErrorState()
                    else
                      Column(
                        children: [
                          _buildUserProfile(),
                          const SizedBox(height: 30),
                          _buildAdminsList(),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminsList() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Hotel Administrators',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (isAdminsLoading)
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${currentHotelAdmins.length} Admin${currentHotelAdmins.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          if (isAdminsLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (currentHotelAdmins.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No administrators found',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No administrators are currently assigned to this hotel.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
          // Wrap with fixed-size containers to prevent inflation
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: currentHotelAdmins.map((admin) =>
                  Container(
                    width: 180, // Fixed width - adjust as needed
                    height: 240, // Fixed height - adjust as needed
                    child: _buildAdminCard(admin),
                  )
              ).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAdminCard(Map<String, dynamic> admin) {
    // Transform admin data to match UserCard expectations
    Map<String, dynamic> adminUserData = {
      'name': admin['name'] ?? admin['username'] ?? 'Unknown Admin',
      'email': admin['email'],
      'phone': admin['phone'],
      'isActive': admin['isActive'] ?? true,
      'lastConnection': admin['lastConnection'],
      'lastUse': admin['lastUse'],
      'createdAt': admin['createdAt'],
      'updatedAt': admin['updatedAt'],
      // Add any other fields that might be present
      if (admin['id'] != null) 'id': admin['id'],
      if (admin['documentNumber'] != null) 'documentNumber': admin['documentNumber'],
      if (admin['nationality'] != null) 'nationality': admin['nationality'],
      if (admin['birthDate'] != null) 'birthDate': admin['birthDate'],
    };

    return UserCard(
      userData: adminUserData,
      userRole: 'ROLE_ADMIN', // Set admin role
      onTap: () => _showAdminDetails(adminUserData),
    );
  }

  void _showAdminDetails(Map<String, dynamic> adminData) {
    showDialog(
      context: context,
      builder: (context) => UserDetailsModal(
        userData: adminData,
        userRole: 'ROLE_ADMIN',
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  int _getCardColumns(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) {
      return 4; // Large screens
    } else if (screenWidth > 800) {
      return 3; // Medium screens
    } else if (screenWidth > 600) {
      return 2; // Small screens
    } else {
      return 1; // Very small screens
    }
  }
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.business_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isHotelLoading)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Text(
                    currentHotel?.name ?? 'Hotel Name Not Available',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                const SizedBox(height: 4),
                if (currentHotel != null)
                  Text(
                    currentHotel!.category,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          // Botón para agregar admin (solo para owners)
          if (userRole?.contains('OWNER') == true)
            ElevatedButton.icon(
              onPressed: _showAddAdminModal,
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Add Admin'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddAdminModal() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Add Administrator',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _hideAddAdminModal,
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Info text
              if (currentHotel != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Adding administrator to: ${currentHotel!.name}',
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Email input
              const Text(
                'Administrator Email',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _adminEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Enter administrator email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue.shade600),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: isAddingAdmin ? null : _hideAddAdminModal,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isAddingAdmin ? null : _addAdminToHotel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: isAddingAdmin
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Text(
                        'Add Admin',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              size: 40,
              color: Colors.orange.shade400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Authentication Required',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            errorMessage ?? 'Please login to view your profile',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _navigateToLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Login',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile() {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(60),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 3,
          ),
        ),
      );
    }

    if (errorMessage != null && !hasAuthError) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Error Loading Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _refreshUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (currentUser == null) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.person_outline_rounded,
                size: 40,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No profile found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Unable to load your profile information',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Profile Card - Usando el widget UserCard actualizado
        UserCard(
          userData: currentUser!,
          userRole: userRole,
          onTap: () => _showUserDetails(currentUser!),
        ),
      ],
    );
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => UserDetailsModal(
        userData: user,
        userRole: userRole,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }
}