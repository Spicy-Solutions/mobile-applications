import 'package:flutter/material.dart';
import 'package:sweet_manager/monitoring/views/type_rooms_booking.dart';
import 'package:sweet_manager/OrganizationalManagement/models/hotel.dart';
import 'package:sweet_manager/OrganizationalManagement/models/multimedia.dart';

// screens/hotel_detail_screen.dart
class HotelDetailScreen extends StatelessWidget {
  final Hotel hotel;
  final Multimedia? multimediaMain;
  final Multimedia? multimediaLogo;
  final List<Multimedia>? multimediaDetails;
  final double minimumPrice;

  const HotelDetailScreen({
    super.key,
    required this.hotel,
    required this.multimediaMain,
    required this.multimediaLogo,
    required this.multimediaDetails,
    required this.minimumPrice
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF1976D2),
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                multimediaMain?.url ??
                    "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTC49nTeeuObEO_ZI-NpfFx2SaVWvh8_bOw9w&s",
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, size: 50),
                  );
                },
                width: double.infinity,
                height: 300,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          hotel.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: ClipOval(
                          child: Image.network(
                            multimediaLogo?.url ??
                                'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTC49nTeeuObEO_ZI-NpfFx2SaVWvh8_bOw9w&s',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  Text(
                    hotel.address,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hotel.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$${minimumPrice.toString()}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                          Text(
                            'per night',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Handle booking
                            Navigator.push(context, MaterialPageRoute(builder: (context) => HotelRoomSelection(hotel: this.hotel)));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Book Now',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
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
    );
  }
}