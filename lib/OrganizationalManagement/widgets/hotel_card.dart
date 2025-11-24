import 'package:flutter/material.dart';
import 'package:sweet_manager/OrganizationalManagement/models/hotel.dart';
import 'package:sweet_manager/OrganizationalManagement/models/multimedia.dart';

class HotelCard extends StatelessWidget {
  final Hotel hotel;
  final Multimedia? multimedia;
  final Multimedia? logo;
  final VoidCallback onTap;
  final double minimumPrice;
  const HotelCard({
    super.key,
    required this.hotel,
    required this.multimedia,
    required this.logo,
    required this.onTap,
    required this.minimumPrice
  });

  // Constants
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              flex: 3,
              child: _buildImageSection(),
            ),

            // Content Section
            Expanded(
              flex: 2,
              child: _buildContentSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        // Main Hotel Image
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
              bottom: Radius.circular(12)
          ),
          child: _buildMainImage(),
        ),

        // Logo Overlay
        Positioned(
          bottom: 8,
          left: 8,
          child: _buildLogoOverlay(),
        ),
      ],
    );
  }

  Widget _buildMainImage() {
    final imageUrl = multimedia?.url;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      print('Loading main image for ${hotel.name}: $imageUrl');
      return Image.network(
        imageUrl,
        height: double.infinity,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: double.infinity,
            width: double.infinity,
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorImage('Main image failed to load');
        },
      );
    } else {
      return _buildDefaultImage();
    }
  }

  Widget _buildLogoOverlay() {
    final logoUrl = logo?.url;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: _buildLogoImage(logoUrl),
      ),
    );
  }

  Widget _buildLogoImage(String? logoUrl) {
    if (logoUrl != null && logoUrl.isNotEmpty) {
      print('Loading logo for ${hotel.name}: $logoUrl');
      return Image.network(
        logoUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
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
          print('Error loading logo for ${hotel.name}: $error');
          return _buildDefaultLogo();
        },
      );
    } else {
      print('No logo URL for ${hotel.name}, using default');
      return _buildDefaultLogo();
    }
  }

  Widget _buildDefaultImage() {
    return Container(
      height: double.infinity,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[300]!,
            Colors.blue[600]!,
          ],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hotel,
              size: 40,
              color: Colors.white,
            ),
            SizedBox(height: 8),
            Text(
              'Hotel Image',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorImage(String errorMessage) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              size: 32,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 4),
            Text(
              'Image not available',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultLogo() {
    return Container(
      color: Colors.blue[600],
      child: const Center(
        child: Icon(
          Icons.business,
          size: 20,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildContentSection() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Hotel Name
          Text(
            hotel.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 4),

          // Hotel Address
          Text(
            hotel.address,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 4),

          // Price Information
          Row(
            children: [
              Text(
                minimumPrice > 0 ? 'S/ $minimumPrice' : 'Price not available',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: minimumPrice > 0 ? const Color(0xFF1976D2) : Colors.grey[600],
                ),
              ),
              if (minimumPrice > 0)
                Text(
                  ' per night',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}