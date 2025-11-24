import 'package:flutter/material.dart';

class UserCard extends StatelessWidget {
  final Map<String, dynamic> userData;
  final String? userRole;
  final VoidCallback? onTap;

  const UserCard({
    Key? key,
    required this.userData,
    this.userRole,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar circular
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade200,
              ),
              child: ClipOval(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _getAvatarColors(),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(userData['name'] ?? 'U'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Nombre
            Text(
              userData['name'] ?? 'Unknown User',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 4),

            // Rol
            Text(
              _getRoleText(),
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Información adicional (MAC, IP, etc.)
            if (userData.containsKey('macAddress') || userData.containsKey('ipAddress')) ...[
              if (userData['macAddress'] != null)
                Text(
                  'MAC: ${userData['macAddress']}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
              if (userData['ipAddress'] != null)
                Text(
                  'IP address: ${userData['ipAddress']}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],

            // Información de última conexión
            if (userData.containsKey('lastConnection') || userData.containsKey('lastUse'))
              Text(
                'Last ${userData.containsKey('lastConnection') ? 'connection' : 'use'}: ${_getLastActivity()}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),

            const SizedBox(height: 12),

            // Badge de estado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _getStatusText(),
                style: TextStyle(
                  color: _getStatusColor(),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    List<String> nameParts = name.trim().split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.isNotEmpty) {
      return nameParts[0][0].toUpperCase();
    }
    return 'U';
  }

  List<Color> _getAvatarColors() {
    // Generar colores basados en el nombre del usuario para consistencia
    final String name = userData['name'] ?? 'Unknown';
    final int hash = name.hashCode;

    final List<List<Color>> colorPairs = [
      [Colors.blue.shade300, Colors.blue.shade500],
      [Colors.purple.shade300, Colors.purple.shade500],
      [Colors.green.shade300, Colors.green.shade500],
      [Colors.orange.shade300, Colors.orange.shade500],
      [Colors.teal.shade300, Colors.teal.shade500],
      [Colors.brown.shade300, Colors.brown.shade500],
    ];

    return colorPairs[hash.abs() % colorPairs.length];
  }

  String _getRoleText() {
    if (userRole?.contains('GUEST') == true) {
      return 'Guest';
    } else if (userRole?.contains('OWNER') == true) {
      return 'Owner';
    } else if (userRole?.contains('ADMIN') == true) {
      return 'Admin';
    }
    return 'User';
  }

  Color _getStatusColor() {
    if (userRole?.contains('ADMIN') == true) {
      return userData['isActive'] == true ? Colors.green : Colors.grey;
    } else if (userData['isActive'] == true) {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
  }
  String _getStatusText() {
    if (userData['isActive'] == true) {
      return 'ACTIVE';
    } else {
      return 'INACTIVE';
    }
  }

  String _getLastActivity() {
    String? lastActivity = userData['lastConnection'] ?? userData['lastUse'];
    if (lastActivity != null) {
      try {
        final DateTime date = DateTime.parse(lastActivity);
        final Duration difference = DateTime.now().difference(date);

        if (difference.inDays > 0) {
          return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
        } else if (difference.inHours > 0) {
          return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
        } else if (difference.inMinutes > 0) {
          return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
        } else {
          return 'Just now';
        }
      } catch (e) {
        return lastActivity;
      }
    }
    return '1 hour ago'; // Default fallback
  }
}

// Modal para mostrar detalles del usuario
// Modal para mostrar detalles del usuario
class UserDetailsModal extends StatelessWidget {
  final Map<String, dynamic> userData;
  final String? userRole;
  final VoidCallback onClose;

  const UserDetailsModal({
    Key? key,
    required this.userData,
    this.userRole,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'User Details',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Content - Scrollable
            Flexible(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar y info básica
                      _buildBasicInfo(),

                      const SizedBox(height: 24),

                      // Información personal
                      _buildPersonalInfo(),

                      const SizedBox(height: 20),

                      // Información técnica
                      _buildTechnicalInfo(),

                      const SizedBox(height: 20),

                      // Información de actividad
                      _buildActivityInfo(),

                      const SizedBox(height: 24),

                      // Botón de cerrar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onClose,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Center(
      child: Column(
        children: [
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: _getAvatarColors(),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                _getInitials(userData['name'] ?? 'U'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Nombre
          Text(
            userData['name'] ?? 'Unknown User',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Rol con badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getStatusColor().withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              _getRoleText(),
              style: TextStyle(
                color: _getStatusColor(),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return _buildSection(
      title: 'Personal Information',
      icon: Icons.person_outline,
      children: [
        if (userData['name'] != null)
          _buildInfoRow('Full Name', userData['name']),
        if (userData['email'] != null)
          _buildInfoRow('Email', userData['email']),
        if (userData['phone'] != null)
          _buildInfoRow('Phone', userData['phone']),
        if (userData['documentNumber'] != null)
          _buildInfoRow('Document Number', userData['documentNumber']),
        if (userData['nationality'] != null)
          _buildInfoRow('Nationality', userData['nationality']),
        if (userData['birthDate'] != null)
          _buildInfoRow('Birth Date', _formatDate(userData['birthDate'])),
      ],
    );
  }

  Widget _buildTechnicalInfo() {
    final hasNetworkInfo = userData['macAddress'] != null ||
        userData['ipAddress'] != null ||
        userData['deviceName'] != null ||
        userData['roomNumber'] != null;

    if (!hasNetworkInfo) return const SizedBox.shrink();

    return _buildSection(
      title: 'Network & Device Information',
      icon: Icons.wifi_outlined,
      children: [
        if (userData['macAddress'] != null)
          _buildInfoRow('MAC Address', userData['macAddress']),
        if (userData['ipAddress'] != null)
          _buildInfoRow('IP Address', userData['ipAddress']),
        if (userData['deviceName'] != null)
          _buildInfoRow('Device Name', userData['deviceName']),
        if (userData['roomNumber'] != null)
          _buildInfoRow('Room Number', userData['roomNumber'].toString()),
      ],
    );
  }

  Widget _buildActivityInfo() {
    return _buildSection(
      title: 'Activity Information',
      icon: Icons.access_time_outlined,
      children: [
        _buildInfoRow('Status', _getStatusText(),
            valueColor: _getStatusColor(),
            showStatusIcon: true),
        if (userData['lastConnection'] != null)
          _buildInfoRow('Last Connection', _getLastActivity()),
        if (userData['lastUse'] != null && userData['lastConnection'] == null)
          _buildInfoRow('Last Use', _getLastActivity()),
        if (userData['createdAt'] != null)
          _buildInfoRow('Created At', _formatDate(userData['createdAt'])),
        if (userData['updatedAt'] != null)
          _buildInfoRow('Last Update', _formatDate(userData['updatedAt'])),
        if (userData['totalConnections'] != null)
          _buildInfoRow('Total Connections', userData['totalConnections'].toString()),
        if (userData['totalTimeConnected'] != null)
          _buildInfoRow('Total Time Connected', _formatDuration(userData['totalTimeConnected'])),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      String label,
      String? value, {
        Color? valueColor,
        bool showStatusIcon = false,
      }) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                if (showStatusIcon) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: valueColor ?? Colors.black87,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: valueColor ?? Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods (copiados del UserCard para mantener consistencia)
  String _getInitials(String name) {
    List<String> nameParts = name.trim().split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.isNotEmpty) {
      return nameParts[0][0].toUpperCase();
    }
    return 'U';
  }

  List<Color> _getAvatarColors() {
    final String name = userData['name'] ?? 'Unknown';
    final int hash = name.hashCode;

    final List<List<Color>> colorPairs = [
      [Colors.blue.shade300, Colors.blue.shade500],
      [Colors.purple.shade300, Colors.purple.shade500],
      [Colors.green.shade300, Colors.green.shade500],
      [Colors.orange.shade300, Colors.orange.shade500],
      [Colors.teal.shade300, Colors.teal.shade500],
      [Colors.brown.shade300, Colors.brown.shade500],
    ];

    return colorPairs[hash.abs() % colorPairs.length];
  }

  String _getRoleText() {
    if (userRole?.contains('GUEST') == true) {
      return 'Guest User';
    } else if (userRole?.contains('OWNER') == true) {
      return 'Owner';
    } else if (userRole?.contains('ADMIN') == true) {
      return 'Administrator';
    }
    return 'User';
  }

  Color _getStatusColor() {
    if (userData['isActive'] == true) {
      return Colors.green;
    } else {
      return Colors.grey;
    }
  }

  String _getStatusText() {
    if (userData['isActive'] == true) {
      return 'Active';
    } else {
      return 'Inactive';
    }
  }

  String _getLastActivity() {
    String? lastActivity = userData['lastConnection'] ?? userData['lastUse'];
    if (lastActivity != null) {
      try {
        final DateTime date = DateTime.parse(lastActivity);
        final Duration difference = DateTime.now().difference(date);

        if (difference.inDays > 0) {
          return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
        } else if (difference.inHours > 0) {
          return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
        } else if (difference.inMinutes > 0) {
          return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
        } else {
          return 'Just now';
        }
      } catch (e) {
        return lastActivity;
      }
    }
    return 'Never';
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';

    try {
      final DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatDuration(dynamic duration) {
    if (duration == null) return 'N/A';

    try {
      final int minutes = int.parse(duration.toString());
      final int hours = minutes ~/ 60;
      final int remainingMinutes = minutes % 60;

      if (hours > 0) {
        return '${hours}h ${remainingMinutes}m';
      } else {
        return '${remainingMinutes}m';
      }
    } catch (e) {
      return duration.toString();
    }
  }
}