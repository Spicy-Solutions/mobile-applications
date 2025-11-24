import 'package:flutter/material.dart';
import 'package:sweet_manager/monitoring/services/room_service.dart';
import 'package:sweet_manager/monitoring/views/booking_init.dart';
import 'package:sweet_manager/monitoring/models/room_type.dart';
import 'package:sweet_manager/shared/widgets/base_layout.dart';
import 'package:sweet_manager/OrganizationalManagement/models/hotel.dart';

class HotelRoomSelection extends StatefulWidget {
  final Hotel hotel;

  const HotelRoomSelection({required this.hotel, super.key});

  @override
  State<HotelRoomSelection> createState() => _HotelRoomSelectionState();
}

class _HotelRoomSelectionState extends State<HotelRoomSelection> {
  final RoomService _roomService = RoomService();
  List<RoomType> _typeRooms = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTypeRooms();
  }

  Future<void> _loadTypeRooms() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final typeRooms = await _roomService.getTypeRoomsByHotel(widget.hotel.id);

      // Filter distinct room types by name (case-insensitive)
      final Map<String, RoomType> distinctRoomsMap = {};

      for (final roomType in typeRooms) {
        final normalizedName = roomType.name.toLowerCase().trim();

        // If we haven't seen this room type name before, or if this one has a better price
        if (!distinctRoomsMap.containsKey(normalizedName)) {
          distinctRoomsMap[normalizedName] = roomType;
        } else {
          // Keep the one with the lower price if there are duplicates
          final existingRoom = distinctRoomsMap[normalizedName]!;
          final existingPrice = _extractNumericPrice(existingRoom.price.toString());
          final currentPrice = _extractNumericPrice(roomType.price.toString());

          if (currentPrice < existingPrice) {
            distinctRoomsMap[normalizedName] = roomType;
          }
        }
      }

      setState(() {
        _typeRooms = distinctRoomsMap.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading room types: $e';
        _isLoading = false;
      });
    }
  }

  // Helper method to extract numeric value from price string
  double _extractNumericPrice(String price) {
    try {
      // Remove currency symbols and extract numbers
      final numericString = price.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(numericString) ?? double.infinity;
    } catch (e) {
      return double.infinity;
    }
  }

  // Default room images for different room types
  String _getRoomImage(String roomTypeName) {
    final Map<String, String> imageMap = {
      'Simple': 'https://images.unsplash.com/photo-1618773928121-c32242e63f39?w=400&h=300&fit=crop',
      'Double': 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=400&h=300&fit=crop',
      'Master': 'https://images.unsplash.com/photo-1590490360182-c33d57733427?w=400&h=300&fit=crop',
      'Balcony': 'https://images.unsplash.com/photo-1591088398332-8a7791972843?w=400&h=300&fit=crop',
      'Suite': 'https://images.unsplash.com/photo-1566665797739-1674de7a421a?w=400&h=300&fit=crop',
      'Premium': 'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=400&h=300&fit=crop',
    };

    // Try to find a matching image based on room type name
    for (String key in imageMap.keys) {
      if (roomTypeName.toLowerCase().contains(key.toLowerCase())) {
        return imageMap[key]!;
      }
    }

    // Default image if no match found
    return 'https://images.unsplash.com/photo-1618773928121-c32242e63f39?w=400&h=300&fit=crop';
  }

  // Generate description based on room type name
  String _getRoomDescription(String roomTypeName) {
    final Map<String, String> descriptionMap = {
      'Simple': 'Comfortable room with essential amenities and city view',
      'Double': 'Spacious room with double bed and modern facilities',
      'Master': 'Luxurious master room with premium amenities',
      'Balcony': 'Beautiful room with private balcony and scenic views',
      'Suite': 'Elegant suite with separate living area and premium services',
      'Premium': 'Premium room with top-tier amenities and exclusive services',
    };

    // Try to find a matching description based on room type name
    for (String key in descriptionMap.keys) {
      if (roomTypeName.toLowerCase().contains(key.toLowerCase())) {
        return descriptionMap[key]!;
      }
    }

    // Default description
    return 'Comfortable room with modern amenities and great service';
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      role: 'ROLE_GUEST',
      childScreen: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header
              Text(
                widget.hotel.name,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.hotel.address,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),

              // Description
              const Text(
                'Discover the best rooms available at our hotel. Choose your perfect stay from our selection of comfortable and luxurious rooms. Click on a room to see more details and proceed with your booking.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // Content based on loading state
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTypeRooms,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_typeRooms.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.hotel_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No room types available for ${widget.hotel.name}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTypeRooms,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    // Room Cards Grid - Dynamic based on actual type rooms
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 0.75,
      ),
      itemCount: _typeRooms.length,
      itemBuilder: (context, index) {
        final roomType = _typeRooms[index];
        return _buildRoomCard(
          context: context,
          roomType: roomType,
          imageAsset: _getRoomImage(roomType.name),
          description: _getRoomDescription(roomType.name),
        );
      },
    );
  }

  Widget _buildRoomCard({
    required BuildContext context,
    required RoomType roomType,
    required String imageAsset,
    required String description,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () async {
          // Handle room selection
          try {
            // Show loading indicator
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
            );

            // The room type is already available since we loaded it from the service
            // Close loading indicator
            Navigator.of(context).pop();

            // Navigate to booking page with the selected room type
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => BookingInit(
                  hotel: widget.hotel,
                  roomType: roomType,
                ),
              ),
            );
          } catch (e) {
            // Close loading indicator if still open
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }

            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error processing room selection: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Room Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  image: DecorationImage(
                    image: NetworkImage(imageAsset),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {},
                  ),
                  color: Colors.grey[300],
                ),
                child: imageAsset.isEmpty
                    ? const Center(
                  child: Icon(
                    Icons.hotel,
                    size: 40,
                    color: Colors.grey,
                  ),
                )
                    : null,
              ),
            ),

            // Room Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Room info section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            roomType.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Text(
                              description,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Price section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          roomType.price.toString(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const Text(
                          'per night',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
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