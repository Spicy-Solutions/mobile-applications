import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:sweet_manager/monitoring/models/room.dart';
import 'package:sweet_manager/monitoring/models/room_type.dart';
import 'package:sweet_manager/monitoring/services/room_service.dart';
import 'package:sweet_manager/monitoring/widgets/room_card.dart';
import 'package:sweet_manager/shared/widgets/base_layout.dart';
import '../models/hotel.dart';
import '../services/hotel_service.dart';

class RoomsView extends StatefulWidget {
  const RoomsView({super.key});

  @override
  State<RoomsView> createState() => _RoomsViewState();
}

class _RoomsViewState extends State<RoomsView> {
  final RoomService _roomService = RoomService();
  final HotelService _hotelService = HotelService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  List<Room> _rooms = [];
  Hotel? _hotel;
  bool _isLoading = false;
  String? _error;
  bool _showAddRoomModal = false;
  bool _showStateModal = false;
  bool _isAddingRoom = false;
  bool _isUpdatingState = false;
  bool _isLoadingRoomTypes = false;
  Room? _selectedRoom;
  String _newState = 'Active';
  String userRole = '';

  // ELIMINADO: final TextEditingController _roomNumberController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  int? _selectedRoomTypeId; // Cambiado a nullable
  String _selectedNewRoomState = 'Active';

  List<RoomType> _roomTypes = [
    RoomType(id: 1, name: 'Individual', price: 0),
    RoomType(id: 2, name: 'Doble', price: 0),
    RoomType(id: 3, name: 'Suite', price: 0),
    RoomType(id: 4, name: 'Familiar', price: 0),
  ];

  final List<String> _availableStates = [
    'Active',
    'Inactive',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadInitialData();
    _loadRoomTypes();
  }

  @override
  void dispose() {
    // ELIMINADO: _roomNumberController.dispose();
    super.dispose();
  }

  int _generateNextRoomNumber() {
    if (_rooms.isEmpty) {
      return 101;
    }

    // Obtener el número más alto existente y sumar 1
    final maxRoomNumber = _rooms.map((room) => room.id).reduce((a, b) => a > b ? a : b);
    return maxRoomNumber + 1;
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

  Future<void> _loadRoomTypes() async {
    setState(() {
      _isLoadingRoomTypes = true;
    });

    try {
      final roomTypes = await _roomService.getRoomTypesByHotel();

      // Filtrar tipos duplicados y asegurar que no haya nulls
      final uniqueRoomTypes = <int, RoomType>{};
      for (final roomType in roomTypes) {
        if (roomType.id != 0) { // Excluir IDs inválidos
          uniqueRoomTypes[roomType.id] = roomType;
        }
      }

      final filteredRoomTypes = uniqueRoomTypes.values.toList();

      setState(() {
        _roomTypes = filteredRoomTypes;
        if (_roomTypes.isNotEmpty) {
          _selectedRoomTypeId = _roomTypes.first.id;
        } else {
          // NO agregar tipos por defecto, solo mostrar mensaje
          _selectedRoomTypeId = null;
        }
        _isLoadingRoomTypes = false;
      });
    } catch (e) {
      print('Error loading room types: $e');
      setState(() {
        _roomTypes = []; // Lista vacía en lugar de tipos por defecto
        _selectedRoomTypeId = null;
        _isLoadingRoomTypes = false;
      });
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Cargar habitaciones y hotel en paralelo
      final futures = await Future.wait([
        _roomService.getRoomsByHotel(),
        _loadHotelInfo(),
      ]);

      final rooms = futures[0] as List<Room>;

      setState(() {
        _rooms = rooms;
        _isLoading = false;
      });

      if (rooms.isEmpty) {
        setState(() {
          _error = 'No se encontraron habitaciones para este hotel';
        });
      }

    } catch (error) {
      setState(() {
        _isLoading = false;
        if (error.toString().contains('token') ||
            error.toString().contains('autenticación')) {
          _error = 'Problema de autenticación. Por favor, inicia sesión nuevamente.';
        } else if (error.toString().contains('401')) {
          _error = 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.';
        } else if (error.toString().contains('403')) {
          _error = 'No tienes permisos para ver las habitaciones de este hotel.';
        } else if (error.toString().contains('404')) {
          _error = 'El servicio de habitaciones no está disponible.';
        } else if (error.toString().contains('500')) {
          _error = 'Error del servidor. Por favor, intenta más tarde.';
        } else {
          _error = 'Error al cargar las habitaciones: ${error.toString()}';
        }
      });
    }
  }

  Future<Hotel?> _loadHotelInfo() async {
    try {
      final hotelId = await _roomService.getHotelIdFromToken();
      if (hotelId != null) {
        final hotel = await _hotelService.getHotelById(hotelId.toString());
        setState(() {
          _hotel = hotel;
        });
        return hotel;
      }
    } catch (e) {
      print('Error loading hotel info: $e');
    }
    return null;
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rooms = await _roomService.getRoomsByHotel();

      setState(() {
        _rooms = rooms;
        _isLoading = false;
      });

      if (rooms.isEmpty) {
        setState(() {
          _error = 'No se encontraron habitaciones para este hotel';
        });
      }

    } catch (error) {
      setState(() {
        _isLoading = false;

        if (error.toString().contains('token') ||
            error.toString().contains('autenticación')) {
          _error = 'Problema de autenticación. Por favor, inicia sesión nuevamente.';
        } else if (error.toString().contains('401')) {
          _error = 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.';
        } else if (error.toString().contains('403')) {
          _error = 'No tienes permisos para ver las habitaciones de este hotel.';
        } else if (error.toString().contains('404')) {
          _error = 'El servicio de habitaciones no está disponible.';
        } else if (error.toString().contains('500')) {
          _error = 'Error del servidor. Por favor, intenta más tarde.';
        } else {
          _error = 'Error al cargar las habitaciones: ${error.toString()}';
        }
      });
    }
  }

  Future<void> _addRoom() async {
    if (_selectedRoomTypeId == null || _selectedRoomTypeId == 0) {
      _showErrorSnackBar('Debe seleccionar un tipo de habitación válido');
      return;
    }

    // Verificar que el tipo de habitación seleccionado existe en la lista
    final selectedRoomType = _roomTypes.firstWhere(
          (type) => type.id == _selectedRoomTypeId,
      orElse: () => RoomType(id: 0, name: '', price: 0),
    );

    if (selectedRoomType.id == 0) {
      _showErrorSnackBar('El tipo de habitación seleccionado no es válido');
      return;
    }

    // MODIFICADO: Generar número automáticamente
    final roomNumberInt = _generateNextRoomNumber();
    final roomNumberText = roomNumberInt.toString();

    // Verificar que el número generado no exista (aunque no debería pasar)
    final existingRoomById = _rooms.any((room) => room.id == roomNumberInt);

    if (existingRoomById) {
      _showErrorSnackBar('Ya existe una habitación con el número $roomNumberInt');
      return;
    }

    setState(() {
      _isAddingRoom = true;
    });

    try {
      // Crear el request con el ID específico generado automáticamente
      final request = CreateRoomRequest(
        id: roomNumberInt, // Usar el número generado como ID
        typeRoomId: _selectedRoomTypeId!,
        hotelId: 0, // Se establecerá en el servicio
        state: 'DISPONIBLE', // Usar formato de API
        roomNumber: roomNumberText,
      );

      print('Creating room with request: ${request.toJson()}'); // DEBUG

      await _roomService.createRoom(request);

      await _loadRooms();

      _closeAddRoomModal();
      _showSuccessSnackBar('Habitación $roomNumberText creada exitosamente');

    } catch (error) {
      print('Error creating room: $error'); // DEBUG

      // MEJORADO: Manejo de errores más específico
      String errorMessage = 'Error al crear la habitación';

      if (error.toString().contains('400')) {
        errorMessage = 'El número de habitación ya existe o es inválido';
      } else if (error.toString().contains('401')) {
        errorMessage = 'Tu sesión ha expirado. Inicia sesión nuevamente';
      } else if (error.toString().contains('403')) {
        errorMessage = 'No tienes permisos para crear habitaciones';
      } else if (error.toString().contains('409')) {
        errorMessage = 'Ya existe una habitación con ese número';
      }

      _showErrorSnackBar(errorMessage);
    } finally {
      setState(() {
        _isAddingRoom = false;
      });
    }
  }
  Future<void> _updateRoomState() async {
    if (_selectedRoom == null || _newState.isEmpty) return;

    setState(() {
      _isUpdatingState = true;
    });

    try {
      print('Updating room ${_selectedRoom!.id} from ${_selectedRoom!.state} to $_newState'); // DEBUG

      await _roomService.updateRoomState(_selectedRoom!.id, _newState);

      // Actualizar el estado local
      setState(() {
        final roomIndex = _rooms.indexWhere((r) => r.id == _selectedRoom!.id);
        if (roomIndex != -1) {
          _rooms[roomIndex] = Room(
            id: _rooms[roomIndex].id,
            number: _rooms[roomIndex].number,
            guest: _rooms[roomIndex].guest,
            checkIn: _rooms[roomIndex].checkIn,
            checkOut: _rooms[roomIndex].checkOut,
            available: _newState.toLowerCase() == 'active',
            typeRoomId: _rooms[roomIndex].typeRoomId,
            state: _newState,
          );
        }
      });

      _closeStateModal();
      _showSuccessSnackBar('Estado actualizado exitosamente');

      // Recargar datos después de un breve delay
      Future.delayed(const Duration(seconds: 1), () {
        _refreshDataSilently();
      });

    } catch (error) {
      print('Error updating room state: $error'); // DEBUG

      String errorMessage = 'No se pudo actualizar el estado';

      if (error.toString().contains('sesión ha expirado') ||
          error.toString().contains('inicia sesión nuevamente')) {
        errorMessage = 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.';
        // Aquí podrías agregar lógica para redirigir al login
        // Navigator.pushReplacementNamed(context, '/login');
      } else if (error.toString().contains('Token inválido')) {
        errorMessage = 'Problema de autenticación. Por favor, inicia sesión nuevamente.';
      } else if (error.toString().contains('permisos')) {
        errorMessage = 'No tienes permisos para actualizar el estado de las habitaciones.';
      } else if (error.toString().contains('servidor')) {
        errorMessage = 'Error del servidor. Por favor, intenta más tarde.';
      }

      _showErrorSnackBar(errorMessage);
      _closeStateModal();

    } finally {
      setState(() {
        _isUpdatingState = false;
      });
    }
  }

  Future<void> _refreshDataSilently() async {
    try {
      final rooms = await _roomService.getRoomsByHotel();
      setState(() {
        _rooms = rooms;
      });
    } catch (e) {
      print('Error en recarga silenciosa: $e');
    }
  }

  void _openAddRoomModal() {
    setState(() {
      _showAddRoomModal = true;
      _selectedRoomTypeId = _roomTypes.isNotEmpty ? _roomTypes.first.id : null;
      _selectedNewRoomState = 'Active';
    });
  }

  void _closeAddRoomModal() {
    setState(() {
      _showAddRoomModal = false;
      _isAddingRoom = false;
    });
  }

  void _openStateModal(Room room) {
    setState(() {
      _selectedRoom = room;
      _newState = _availableStates.contains(room.state) ? room.state : 'Active';
      _showStateModal = true;
    });
  }

  void _closeStateModal() {
    setState(() {
      _showStateModal = false;
      _selectedRoom = null;
      _isUpdatingState = false;
      _newState = 'Active';
    });
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ELIMINADO: Widget _buildRoomNumberField() ya no es necesario

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      role: userRole,
      childScreen: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // Header con nombre del hotel
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                child: Column(
                  children: [
                    // Nombre del hotel
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _hotel?.name ?? 'Cargando...',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Botón de refresh en la esquina
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.black87),
                        onPressed: () {
                          _loadInitialData();
                          _loadRoomTypes();
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Contenedor de estadísticas
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: const Color(0xFFF8F9FA),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total de habitaciones: ${_rooms.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Disponibles: ${_rooms.where((r) => r.available).length}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.green,
                      ),
                    ),
                    // AGREGADO: Mostrar el próximo número que se asignará
                    const SizedBox(height: 4),
                    Text(
                      'Próximo número: ${_generateNextRoomNumber()}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              // Grid de habitaciones
              Expanded(
                child: _buildRoomsContent(),
              ),

              // Botones inferiores
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    // Botón Add
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _openAddRoomModal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066CC),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Add'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Modales
          if (_showAddRoomModal && !_isUpdatingState) _buildAddRoomModal(),
          if (_showStateModal && !_isAddingRoom) _buildStateModal(),
        ],
      ),
    );
  }

  Widget _buildRoomsContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando habitaciones...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInitialData,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_rooms.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hotel_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No hay habitaciones registradas',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Agrega tu primera habitación usando el botón Add',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _rooms.length,
      itemBuilder: (context, index) {
        final room = _rooms[index];
        return RoomCardWidget(
          room: room,
          onChangeState: () => _openStateModal(room),
        );
      },
    );
  }

  Widget _buildAddRoomModal() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Agregar Nueva Habitación',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _closeAddRoomModal,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // AGREGADO: Mostrar el número que se asignará automáticamente
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Número de habitación asignado automáticamente: ${_generateNextRoomNumber()}',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ELIMINADO: _buildRoomNumberField(),

                // Dropdown corregido para tipos de habitación
                _isLoadingRoomTypes
                    ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                )
                    : _roomTypes.isEmpty
                    ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.error, color: Colors.red),
                      SizedBox(height: 8),
                      Text(
                        'No hay tipos de habitación disponibles',
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Debe crear tipos de habitación primero',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
                    : DropdownButtonFormField<int>(
                  value: _selectedRoomTypeId,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Habitación',
                    border: OutlineInputBorder(),
                  ),
                  items: _roomTypes.map((type) {
                    return DropdownMenuItem<int>(
                      value: type.id,
                      child: Text(
                          type.price != null
                              ? '${type.name} - S/.${type.price?.toStringAsFixed(2)}'
                              : type.name
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRoomTypeId = value;
                    });
                  },
                  hint: const Text('Seleccionar tipo de habitación'),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _newState, // Quitar la validación condicional
                  decoration: const InputDecoration(
                    labelText: 'Nuevo Estado',
                    border: OutlineInputBorder(),
                  ),
                  items: _availableStates.map((state) {
                    return DropdownMenuItem<String>(
                      value: state,
                      child: Text(state),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _newState = value ?? 'Active'; // Cambiar default a 'Active'
                    });
                  },
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _closeAddRoomModal,
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isAddingRoom || _selectedRoomTypeId == null || _roomTypes.isEmpty
                          ? null
                          : _addRoom,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066CC),
                        foregroundColor: Colors.white,
                      ),
                      child: _isAddingRoom
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Text('Crear Habitación'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStateModal() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Cambiar Estado de Habitación',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _closeStateModal,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (_selectedRoom != null) ...[
                Text(
                  'Habitación: ${_selectedRoom!.number}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Estado actual: ${_selectedRoom!.state}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),

                // Dropdown para seleccionar nuevo estado - CORREGIDO
                DropdownButtonFormField<String>(
                  value: _newState, // Eliminado la validación condicional
                  decoration: const InputDecoration(
                    labelText: 'Nuevo Estado',
                    border: OutlineInputBorder(),
                  ),
                  items: _availableStates.map((state) {
                    return DropdownMenuItem<String>(
                      value: state,
                      child: Row(
                        children: [
                          Icon(
                            state.toLowerCase() == 'active'
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: state.toLowerCase() == 'active' // CORREGIDO: era 'inactive'
                                ? Colors.green
                                : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(state),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _newState = value ?? 'Active';
                    });
                  },
                ),

                const SizedBox(height: 12),

                // Información adicional
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _newState.toLowerCase() == 'active'
                              ? 'La habitación estará disponible para reservas'
                              : 'La habitación no estará disponible para reservas',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isUpdatingState ? null : _closeStateModal,
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isUpdatingState || _newState.isEmpty
                        ? null
                        : _updateRoomState,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066CC),
                      foregroundColor: Colors.white,
                    ),
                    child: _isUpdatingState
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text('Actualizar Estado'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}