import 'package:flutter/material.dart';
import 'package:sweet_manager/shared/widgets/base_layout.dart';
import '../../monitoring/models/hotel.dart';
import '../../monitoring/services/hotel_service.dart';
import '../services/multimedia_service.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'package:sweet_manager/Monitoring/services/room_service.dart';

class HotelOverview extends StatefulWidget {

  const HotelOverview({Key? key}) : super(key: key);

  @override
  State<HotelOverview> createState() => _HotelOverviewState();
}

class _HotelOverviewState extends State<HotelOverview> {
  final RoomService _roomService = RoomService();
  final HotelService _hotelService = HotelService();
  final MultimediaService _multimediaService = MultimediaService();

  Hotel? _hotel;
  List<String> hotelImages = [];
  bool isLoading = true;
  bool isLoadingImages = true;
  String? error;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? userRole = '';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadHotelData(); // Esta función ahora maneja todo
  }

  Future<void> _loadHotelData() async {
    try {
      setState(() {
        isLoading = true;
        isLoadingImages = true;
        error = null;
      });

      // 1. Obtener hotelId del token (fuente única de verdad)
      final tokenHotelId = await _roomService.getHotelIdFromToken();

      if (tokenHotelId == null) {
        throw Exception('No se pudo obtener el hotel ID del token');
      }

      // 2. Usar el hotelId del token para todo
      final hotelIdToUse = tokenHotelId;

      // 3. Cargar info del hotel e imágenes en paralelo
      final results = await Future.wait([
        _hotelService.getHotelById(hotelIdToUse.toString()),
        _multimediaService.getHotelImages(hotelIdToUse),
      ]);

      final hotel = results[0] as Hotel;
      final images = results[1] as List<String>;
      setState(() {
        _hotel = hotel;
        hotelImages = images.isEmpty ? [
          'https://via.placeholder.com/400x200.png?text=No+Images+Available',
          'https://via.placeholder.com/400x200.png?text=No+Images+Available',
          'https://via.placeholder.com/400x200.png?text=No+Images+Available',
        ] : images;
        isLoading = false;
        isLoadingImages = false;
      });

    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
        isLoadingImages = false;
      });
    }
  }

  Future<void> _loadUserRole() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null) return;

      final parts = token.split('.');
      if (parts.length != 3) return;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payloadMap = json.decode(decoded);

      final role = payloadMap['http://schemas.microsoft.com/ws/2008/06/identity/claims/role']?.toString();

      setState(() {
        userRole = role ?? 'ROLE_OWNER';
      });
    } catch (e) {
      print('Error loading user role: $e');
      setState(() {
        userRole = 'ROLE_OWNER';
      });
    }
  }

  // Función para editar teléfono
  Future<void> _editPhone() async {
    final TextEditingController phoneController = TextEditingController(text: _hotel!.phone);

    final newPhone = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Teléfono'),
          content: TextField(
            controller: phoneController,
            decoration: const InputDecoration(
              labelText: 'Número de teléfono',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(phoneController.text),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (newPhone != null && newPhone.isNotEmpty && newPhone != _hotel!.phone) {
      await _updateHotelField('phone', newPhone);
    }
  }

  // Función para editar email
  Future<void> _editEmail() async {
    final TextEditingController emailController = TextEditingController(text: _hotel!.email);

    final newEmail = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Email'),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(emailController.text),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (newEmail != null && newEmail.isNotEmpty && newEmail != _hotel!.email) {
      await _updateHotelField('email', newEmail);
    }
  }

  // Alternativa usando updateHotel completo (si prefieres actualizar todo el objeto)
  Future<void> _updateHotelField(String field, String value) async {
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Obtener hotelId del token
      final hotelId = await _roomService.getHotelIdFromToken();
      if (hotelId == null) {
        throw Exception('No se pudo obtener el hotel ID');
      }

      // Crear Map con todos los datos del hotel
      final Map<String, dynamic> hotelData = {
        'id': _hotel!.id,
        'name': field == 'name' ? value : _hotel!.name,
        'address': field == 'address' ? value : _hotel!.address,
        'city': field == 'city' ? value : _hotel!.city,
        'ownerId': _hotel!.ownerId,
        'description': field == 'description' ? value : _hotel!.description,
        'phone': field == 'phone' ? value : _hotel!.phone,
        'email': field == 'email' ? value : _hotel!.email,
        'category': field == 'category' ? value : _hotel!.category,
      };

      // Actualizar en el servidor
      final Hotel? updatedHotelResult = await _hotelService.updateHotel(
          hotelId.toString(),
          hotelData
      );

      // Actualizar estado local
      setState(() {
        _hotel = updatedHotelResult ?? Hotel(
          id: _hotel!.id,
          name: field == 'name' ? value : _hotel!.name,
          address: field == 'address' ? value : _hotel!.address,
          city: field == 'city' ? value : _hotel!.city,
          ownerId: _hotel!.ownerId,
          description: field == 'description' ? value : _hotel!.description,
          phone: field == 'phone' ? value : _hotel!.phone,
          email: field == 'email' ? value : _hotel!.email,
          category: field == 'category' ? value : _hotel!.category,
        );
      });

      // Quitar loading
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Campo actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      // Quitar loading
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Mostrar error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      role: userRole,
      childScreen: _buildContent(),
    );
  }


  Widget _buildContent() {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? _buildErrorWidget()
          : _hotel != null
          ? _buildHotelContent()
          : const Center(child: Text('No se encontró el hotel')),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error al cargar el hotel',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            error!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadHotelData,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildHotelContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con título
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _hotel!.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _hotel!.address,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Galería de imágenes
          _buildImageGallery(),

          const SizedBox(height: 16),

          // Texto "Discover how everyone see your hotel"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Discover how everyone see your hotel',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Sección de Descripción
          _buildDescriptionSection(),

          const SizedBox(height: 16),

          // Sección de Contacto
          _buildContactSection(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    if (isLoadingImages) {
      return Container(
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (hotelImages.isEmpty) {
      // Placeholder cuando no hay imágenes
      return Container(
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Imagen principal placeholder
            Expanded(
              flex: 2,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.hotel, size: 50, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      _hotel!.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
            // Columna de imágenes pequeñas placeholder
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Icon(Icons.bed, color: Colors.grey[400]),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Icon(Icons.restaurant, color: Colors.grey[400]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mostrar imágenes reales
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Imagen principal
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Image.network(
                hotelImages[0], // MAIN IMAGE
                height: 200,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, size: 50, color: Colors.grey),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Columna de imágenes pequeñas
          Expanded(
            flex: 1,
            child: Column(
              children: [
                if (hotelImages.length > 1)
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                      ),
                      child: Image.network(
                        hotelImages[1],
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Icon(Icons.bed, color: Colors.grey[400]),
                    ),
                  ),
                const SizedBox(height: 4),
                if (hotelImages.length > 2)
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(12),
                      ),
                      child: Image.network(
                        hotelImages[2],
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Icon(Icons.restaurant, color: Colors.grey[400]),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _hotel!.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phone
          Row(
            children: [
              const Text(
                'Phone Number',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: _editPhone,
              ),
            ],
          ),
          Text(
            _hotel!.phone,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          // Email
          Row(
            children: [
              const Text(
                'Email',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: _editEmail,
              ),
            ],
          ),
          Text(
            _hotel!.email,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}