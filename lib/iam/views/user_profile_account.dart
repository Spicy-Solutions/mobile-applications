import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sweet_manager/iam/domain/model/aggregates/guest.dart';
import 'package:sweet_manager/iam/domain/model/aggregates/owner.dart';
import 'package:sweet_manager/iam/infrastructure/user_service.dart';
import 'package:sweet_manager/iam/views/user_profile_info.dart';
import 'package:sweet_manager/iam/views/user_profile_preferences.dart';
import 'package:sweet_manager/shared/infrastructure/misc/token_helper.dart';
import 'package:sweet_manager/shared/widgets/base_layout.dart';



class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final UserService userService = UserService();
  Guest? guestProfile;
  Owner? ownerProfile;
  int? roleId;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAccountData();
  }

  String get userFullName {
    return ownerProfile?.name ?? guestProfile?.name ?? 'Unknown User';
  }

  String get userRole {
    return ownerProfile != null ? 'Owner' : 'Guest';
  }

  String get userPhotoURL {
    return ownerProfile?.photoURL ??
        guestProfile?.photoURL ??
        'https://static.vecteezy.com/system/resources/previews/009/292/244/non_2x/default-avatar-icon-of-social-media-user-vector.jpg';
  }

  Future<void> _initializeAccountData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });


      // Get role ID first
      await _getRoleId();
      
      // Then fetch user profile
      await _fetchUserProfile();

      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      
      guestProfile = await userService.getGuestProfile();
      ownerProfile = await userService.getOwnerProfile();
      
      setState(() {});
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  Future<void> _getRoleId() async {
    try {
      
      final roleString = await TokenHelper().getRole();
      if (roleString == null) {
        throw Exception('Role ID not found in token');
      }

      roleId = roleString == "ROLE_OWNER" ? 1 : 3;
      
      setState(() {});
    } catch (e) {
      throw Exception('Failed to get role ID: $e');
    }
  }

  void navigateTo(BuildContext context, String routeName) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlaceholderPage(title: routeName)),
    );
  }

  Future<void> logOut() async {
    try {
      const storage = FlutterSecureStorage();
      await storage.delete(key: 'token');
      await storage.delete(key: 'roleId');
      await storage.delete(key: 'id');
      await storage.delete(key: 'userId');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out successfully')),
        );

        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading account...'),
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to load account',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Unknown error occurred',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _initializeAccountData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (roleId == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Unable to determine user role',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Build the main content with proper role
    final role = roleId == 1 ? "ROLE_OWNER" : "ROLE_GUEST";
    
    return BaseLayout(
      role: role,
      childScreen: _buildContentView(),
    );
  }

  Widget _buildContentView() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          const Text(
            'Account',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 4,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Container(
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2B61B6),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(userPhotoURL),
                  onBackgroundImageError: (exception, stackTrace) {
                    print('Error loading profile image: $exception');
                  },
                ),
                const SizedBox(height: 8),
                Column(
                  children: [
                    Text(
                      userFullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userRole,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                _buildListTile(
                  context,
                  icon: Icons.person,
                  text: 'Personal Information',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfilePage(
                          ownerProfile: ownerProfile,
                          guestProfile: guestProfile,
                          userType: userRole,
                        ),
                      ),
                    );
                    // Refresh profile data after returning
                    _fetchUserProfile();
                  },
                  isSelected: true,
                ),
                if (roleId == 3)
                  _buildListTile(
                    context,
                    icon: Icons.tune,
                    text: 'My preferences as a Guest',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserPreferencesPage(),
                        ),
                      );
                    },
                  ),
                _buildListTile(
                  context,
                  icon: Icons.schedule,
                  text: 'My Reservations',
                  onTap: () => Navigator.pushNamed(context, '/guest-reservation'),
                ),
                _buildListTile(
                  context,
                  icon: Icons.logout,
                  text: 'Logout',
                  onTap: logOut,
                  textColor: Colors.red,
                  iconColor: Colors.red,
                ),
                const Divider(height: 1),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'SweetManager',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
    bool isSelected = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.black54),
      title: Text(
        text,
        style: TextStyle(
          color: textColor ?? Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: isSelected ? Colors.blue[50] : null,
      onTap: onTap,
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String title;

  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title Page')),
    );
  }
}