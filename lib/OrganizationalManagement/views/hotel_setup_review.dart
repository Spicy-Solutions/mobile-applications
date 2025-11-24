import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sweet_manager/OrganizationalManagement/services/multimedia_service.dart';
// Import your Cloudinary service
import 'package:sweet_manager/shared/infrastructure/services/cloudinary_service.dart';

class HotelSetupReviewScreen extends StatefulWidget {
  const HotelSetupReviewScreen({super.key});

  @override
  State<HotelSetupReviewScreen> createState() => _HotelPhotoUploadScreenState();
}

class _HotelPhotoUploadScreenState extends State<HotelSetupReviewScreen> {
  final ImagePicker _picker = ImagePicker();
  late final CloudinaryService cloudinaryService;
  final MultimediaService _multimediaService = MultimediaService();

  // Mobile file storage
  File? _logoImage;
  File? _mainImage;
  File? _roomImage;
  File? _poolImage;

  // Web bytes storage
  Uint8List? _logoImageBytes;
  Uint8List? _mainImageBytes;
  Uint8List? _roomImageBytes;
  Uint8List? _poolImageBytes;

  // XFile storage for Cloudinary upload
  XFile? _logoXFile;
  XFile? _mainXFile;
  XFile? _roomXFile;
  XFile? _poolXFile;

  // Upload states
  bool _isProcessingSetup = false; // Renamed for clarity
  Map<String, String?> _uploadedImageUrls = {
    'logo': null,
    'main': null,
    'room': null,
    'pool': null,
  };

  // Constants
  static const Color _primaryBlue = Color(0xFF1976D2);
  static const Color _backgroundColor = Color(0xFFF8F9FA);
  static const Color _textColor = Color(0xFF2C3E50);
  static const Color _subtitleColor = Color(0xFF95A5A6);
  static const Color _borderColor = Color(0xFFE0E0E0);
  static const Color _tealColor = Color(0xFF00695C);
  static const double _borderRadius = 12.0;

  @override
  void initState() {
    super.initState();
    cloudinaryService = CloudinaryService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 40),
              _buildContent(),
              const SizedBox(height: 32),
              _buildActionButtons(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget({
    required File? file,
    required Uint8List? bytes,
    required double width,
    required double height,
  }) {
    if (kIsWeb && bytes != null) {
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: const Icon(
              Icons.error,
              color: Colors.grey,
              size: 24,
            ),
          );
        },
      );
    } else if (!kIsWeb && file != null) {
      return Image.file(
        file,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: const Icon(
              Icons.error,
              color: Colors.grey,
              size: 24,
            ),
          );
        },
      );
    } else {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Icon(
          Icons.error,
          color: Colors.grey,
          size: 24,
        ),
      );
    }
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Everything ready?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: _textColor,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Choose and upload a photo of your hotel so it can\nbe found by the entire SweetManager community.',
          style: TextStyle(
            fontSize: 16,
            color: _subtitleColor,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: _buildLogoSection(),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 1,
          child: _buildPhotosSection(),
        ),
      ],
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: _isProcessingSetup ? null : () => _pickImage(ImageType.logo),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: _hasLogoImage() ? Colors.transparent : _tealColor,
              shape: BoxShape.circle,
              border: _hasLogoImage()
                  ? Border.all(color: _primaryBlue, width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _hasLogoImage()
                ? ClipOval(
              child: Stack(
                children: [
                  _buildImageWidget(
                    file: _logoImage,
                    bytes: _logoImageBytes,
                    width: 120,
                    height: 120,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            )
                : const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 32,
                  color: Colors.white,
                ),
                SizedBox(height: 8),
                Text(
                  'Add Logo',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildHotelInfo(),
      ],
    );
  }

  // Helper method to check if logo image exists
  bool _hasLogoImage() {
    return (kIsWeb && _logoImageBytes != null) || (!kIsWeb && _logoImage != null);
  }

  Widget _buildHotelInfo() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Royal Decameron Punta Sal',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _textColor,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Av. Panamericana N, Punta Sal 24560',
          style: TextStyle(
            fontSize: 14,
            color: _subtitleColor,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 16),
        Text(
          'We offer the most modern rooms in the country, from small to large, with beautiful ocean views and incredible service.',
          style: TextStyle(
            fontSize: 14,
            color: _textColor,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosSection() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 250),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPhotoUpload(
            image: _mainImage,
            imageBytes: _mainImageBytes,
            onTap: () => _pickImage(ImageType.main),
            height: 100,
            label: 'Main Hotel Photo',
          ),
          const SizedBox(height: 12),
          Flexible(
            child: Row(
              children: [
                Expanded(
                  child: _buildPhotoUpload(
                    image: _roomImage,
                    imageBytes: _roomImageBytes,
                    onTap: () => _pickImage(ImageType.room),
                    height: 70,
                    label: 'Room Photo',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildPhotoUpload(
                    image: _poolImage,
                    imageBytes: _poolImageBytes,
                    onTap: () => _pickImage(ImageType.pool),
                    height: 70,
                    label: 'Pool Photo',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoUpload({
    required File? image,
    required Uint8List? imageBytes,
    required VoidCallback onTap,
    required double height,
    required String label,
  }) {
    final hasImage = image != null || imageBytes != null;

    return GestureDetector(
      onTap: _isProcessingSetup ? null : onTap,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_borderRadius),
          border: Border.all(
            color: hasImage ? _primaryBlue : _borderColor,
            width: hasImage ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: hasImage
            ? ClipRRect(
          borderRadius: BorderRadius.circular(_borderRadius - 1),
          child: Stack(
            children: [
              _buildImageWidget(
                file: image,
                bytes: imageBytes,
                width: double.infinity,
                height: double.infinity,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        )
            : _buildPlaceholder(label),
      ),
    );
  }

  Widget _buildPlaceholder(String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _subtitleColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.add_photo_alternate_outlined,
            size: 16,
            color: _subtitleColor,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Add Photo',
          style: TextStyle(
            fontSize: 10,
            color: _subtitleColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              color: _subtitleColor.withOpacity(0.8),
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          flex: 1,
          child: _buildFinishButton(),
        ),
      ],
    );
  }

  Widget _buildFinishButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isProcessingSetup ? null : _handleFinish,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isProcessingSetup ? Colors.grey : _primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          elevation: 0,
        ),
        child: _isProcessingSetup
            ? const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Processing...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        )
            : const Text(
          'Finish',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Image picker methods
  Future<void> _pickImage(ImageType type) async {
    try {
      await _showImageSourceDialog(type);
    } catch (e) {
      _showErrorMessage('Failed to open image selector: ${e.toString()}');
    }
  }

  Future<void> _pickImageFromSource(ImageSource source, ImageType type) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          // For web, read as bytes
          final Uint8List imageBytes = await pickedFile.readAsBytes();
          setState(() {
            switch (type) {
              case ImageType.logo:
                _logoImageBytes = imageBytes;
                _logoImage = null;
                _logoXFile = pickedFile;
                break;
              case ImageType.main:
                _mainImageBytes = imageBytes;
                _mainImage = null;
                _mainXFile = pickedFile;
                break;
              case ImageType.room:
                _roomImageBytes = imageBytes;
                _roomImage = null;
                _roomXFile = pickedFile;
                break;
              case ImageType.pool:
                _poolImageBytes = imageBytes;
                _poolImage = null;
                _poolXFile = pickedFile;
                break;
            }
          });
        } else {
          // For mobile, use File
          final File imageFile = File(pickedFile.path);
          if (await imageFile.exists()) {
            // Try to read the file to ensure it's valid
            await imageFile.readAsBytes();

            setState(() {
              switch (type) {
                case ImageType.logo:
                  _logoImage = imageFile;
                  _logoImageBytes = null;
                  _logoXFile = pickedFile;
                  break;
                case ImageType.main:
                  _mainImage = imageFile;
                  _mainImageBytes = null;
                  _mainXFile = pickedFile;
                  break;
                case ImageType.room:
                  _roomImage = imageFile;
                  _roomImageBytes = null;
                  _roomXFile = pickedFile;
                  break;
                case ImageType.pool:
                  _poolImage = imageFile;
                  _poolImageBytes = null;
                  _poolXFile = pickedFile;
                  break;
              }
            });
          } else {
            _showErrorMessage('Selected image file is not accessible');
          }
        }
      }
    } on PlatformException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'photo_access_denied':
          errorMessage = 'Photo access denied. Please grant permission in device settings.';
          break;
        case 'camera_access_denied':
          errorMessage = 'Camera access denied. Please grant permission in device settings.';
          break;
        case 'invalid_image':
          errorMessage = 'The selected file is not a valid image.';
          break;
        default:
          errorMessage = 'Failed to pick image: ${e.message ?? e.code}';
      }
      _showErrorMessage(errorMessage);
    } catch (e) {
      _showErrorMessage('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<void> _showImageSourceDialog(ImageType type) async {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Image Source',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _textColor,
                ),
              ),
              const SizedBox(height: 24),
              _buildImageSourceOption(
                icon: Icons.photo_library,
                title: 'Gallery',
                subtitle: 'Choose from your photos',
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromSource(ImageSource.gallery, type);
                },
              ),
              if (!kIsWeb) ...[
                const SizedBox(height: 16),
                _buildImageSourceOption(
                  icon: Icons.camera_alt,
                  title: 'Camera',
                  subtitle: 'Take a new photo',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromSource(ImageSource.camera, type);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: _borderColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _primaryBlue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: _subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Cloudinary upload methods
  Future<void> _uploadImagesToCloudinary() async {
    print('Starting Cloudinary uploads...');

    try {
      // Upload each image if it exists
      if (_logoXFile != null) {
        print('Uploading logo image...');
        _uploadedImageUrls['logo'] = await _uploadSingleImage(
          _logoXFile!,
          'logo',
          _logoImageBytes,
        );
        print('Logo uploaded successfully: ${_uploadedImageUrls['logo']}');
      }

      if (_mainXFile != null) {
        print('Uploading main image...');
        _uploadedImageUrls['main'] = await _uploadSingleImage(
          _mainXFile!,
          'main',
          _mainImageBytes,
        );
        print('Main image uploaded successfully: ${_uploadedImageUrls['main']}');
      }

      if (_roomXFile != null) {
        print('Uploading room image...');
        _uploadedImageUrls['room'] = await _uploadSingleImage(
          _roomXFile!,
          'room',
          _roomImageBytes,
        );
        print('Room image uploaded successfully: ${_uploadedImageUrls['room']}');
      }

      if (_poolXFile != null) {
        print('Uploading pool image...');
        _uploadedImageUrls['pool'] = await _uploadSingleImage(
          _poolXFile!,
          'pool',
          _poolImageBytes,
        );
        print('Pool image uploaded successfully: ${_uploadedImageUrls['pool']}');
      }

      print('All images uploaded successfully!');
      print('Final uploaded URLs: $_uploadedImageUrls');

    } catch (e) {
      print('Error uploading images: $e');
      throw Exception('Failed to upload images: ${e.toString()}');
    }
  }

  Future<String> _uploadSingleImage(
      XFile imageFile,
      String imageType,
      Uint8List? webBytes,
      ) async {
    try {
      final imageUrl = await cloudinaryService.uploadImage(
        imageFile,
        folder: 'hotel_setup',
        webImageBytes: webBytes,
        publicId: 'hotel_${imageType}_${DateTime.now().millisecondsSinceEpoch}',
        tags: ['hotel', 'setup', imageType],
      );

      return imageUrl;
    } on CloudinaryException catch (e) {
      print('Cloudinary error uploading $imageType: $e');
      throw Exception('Failed to upload $imageType image: ${e.message}');
    } catch (e) {
      print('Error uploading $imageType image: $e');
      throw Exception('Failed to upload $imageType image: $e');
    }
  }

  // Action handlers
  void _handleBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      _showInfoMessage('No previous screen available');
    }
  }

  void _handleFinish() {
    // Prevent multiple taps
    if (_isProcessingSetup) return;

    final hasMainImage = _mainImage != null || _mainImageBytes != null;
    final hasPoolImage = _poolImage != null || _poolImageBytes != null;
    final hasRoomImage = _roomImage != null || _roomImageBytes != null;
    final hasLogoImage = _logoImage != null || _logoImageBytes != null;

    if (!hasMainImage || !hasPoolImage || !hasRoomImage || !hasLogoImage) {
      _showErrorMessage('Please ensure to upload all the photos.');
      return;
    }

    _processHotelSetup();
  }

  Future<void> _processHotelSetup() async {
    setState(() {
      _isProcessingSetup = true;
    });

    try {
      print('Starting hotel setup process...');

      // Step 1: Upload images to Cloudinary
      print('Step 1: Uploading images to Cloudinary...');
      await _uploadImagesToCloudinary();

      // Step 2: Register multimedia with the service
      print('Step 2: Registering multimedia...');
      await _registerMultimedia();

      // Step 3: Create final hotel setup data
      final hotelSetup = {
        'logoImageUrl': _uploadedImageUrls['logo'],
        'mainImageUrl': _uploadedImageUrls['main'],
        'roomImageUrl': _uploadedImageUrls['room'],
        'poolImageUrl': _uploadedImageUrls['pool'],
        'completedAt': DateTime.now().toIso8601String(),
      };

      print('Hotel setup completed successfully');
      print('Final setup data: $hotelSetup');

      // Show success dialog
      if (mounted) {
        _showSuccessDialog(hotelSetup);
      }
    } catch (e) {
      print('Hotel setup processing error: $e');
      if (mounted) {
        _showErrorMessage('Failed to complete hotel setup: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingSetup = false;
        });
      }
    }
  }

  Future<void> _registerMultimedia() async {
    try {
      print('Registering multimedia with service...');

      // Register logo
      if (_uploadedImageUrls['logo'] != null) {
        print('Registering logo multimedia...');
        await _multimediaService.registerMultimedia(
            _uploadedImageUrls['logo']!,
            "LOGO",
            1
        );
        print('Logo multimedia registered successfully');
      }

      // Register main image
      if (_uploadedImageUrls['main'] != null) {
        print('Registering main image multimedia...');
        await _multimediaService.registerMultimedia(
            _uploadedImageUrls['main']!,
            "MAIN",
            1
        );
        print('Main image multimedia registered successfully');
      }

      // Register room image as detail
      if (_uploadedImageUrls['room'] != null) {
        print('Registering room image multimedia...');
        await _multimediaService.registerMultimedia(
            _uploadedImageUrls['room']!,
            "DETAIL",
            2
        );
        print('Room image multimedia registered successfully');
      }

      // Register pool image as detail
      if (_uploadedImageUrls['pool'] != null) {
        print('Registering pool image multimedia...');
        await _multimediaService.registerMultimedia(
            _uploadedImageUrls['pool']!,
            "DETAIL",
            3
        );
        print('Pool image multimedia registered successfully');
      }

      print('All multimedia registered successfully');
    } catch (e) {
      print('Error registering multimedia: $e');
      throw Exception('Failed to register multimedia: ${e.toString()}');
    }
  }

  void _showSuccessDialog(Map<String, dynamic> hotelSetup) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 48,
        ),
        title: const Text('Hotel Setup Complete!'),
        content: const Text(
          'Congratulations! Your hotel has been successfully registered with SweetManager. '
              'Your property is now ready to welcome guests and be discovered by travelers worldwide.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _navigateToDashboard();
            },
            child: const Text('Go to Hotel Overview'),
          ),
        ],
      ),
    );
  }

  void _navigateToDashboard() {
    // Replace with your actual navigation logic
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/hotel/overview',
          (route) => false,
    ).catchError((error) {
      print('Navigation error: $error');
      // If route doesn't exist, show error or navigate to a default route
      _showErrorMessage('Navigation error: Unable to reach dashboard');
    });
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showInfoMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue[600],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

enum ImageType { logo, main, room, pool }