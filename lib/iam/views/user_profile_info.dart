import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:sweet_manager/iam/domain/model/aggregates/guest.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:sweet_manager/iam/domain/model/aggregates/owner.dart';
import 'package:sweet_manager/iam/domain/model/commands/update_user_profile_request.dart';
import 'package:sweet_manager/iam/infrastructure/user_service.dart';
import 'package:sweet_manager/shared/infrastructure/misc/token_helper.dart';
import 'package:sweet_manager/shared/infrastructure/services/cloudinary_service.dart';
import 'package:sweet_manager/shared/widgets/base_layout.dart';

// ignore: must_be_immutable
class ProfilePage extends StatefulWidget {
  Owner? ownerProfile;
  Guest? guestProfile;
  String? userType;

  ProfilePage({super.key, this.ownerProfile, this.guestProfile, this.userType});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserService userService = UserService();
  final ImagePicker _picker = ImagePicker();
  final TokenHelper _tokenHelper = TokenHelper();
  late final CloudinaryService cloudinaryService;

  bool _isUploadingPhoto = false;
  String? _selectedImagePath;
  Uint8List? _webImageBytes; // Para web
  String? _tempImageUrl; // URL temporal para preview

  String get userFullName {
    return widget.ownerProfile?.name ??
        widget.guestProfile?.name ??
        'Unknown User';
  }

  String get userRole {
    return widget.ownerProfile != null ? 'Owner' : 'Guest';
  }

  String get userPhotoURL {
    // Prioridad: imagen temporal -> imagen guardada -> default
    return _tempImageUrl ??
        widget.ownerProfile?.photoURL ??
        widget.guestProfile?.photoURL ??
        'https://static.vecteezy.com/system/resources/previews/009/292/244/non_2x/default-avatar-icon-of-social-media-user-vector.jpg';
  }

  final _countries = ['Perú', 'Argentina', 'Chile'];
  final _languages = ['Español', 'Inglés', 'Portugués'];

  Map<String, dynamic> _userData = {};
  final Map<String, bool> _editMode = {
    'name': false,
    'surname': false,
    'email': false,
    'phone': false,
    'password': false,
  };

  final _controllers = {
    'name': TextEditingController(),
    'surname': TextEditingController(),
    'email': TextEditingController(),
    'phone': TextEditingController(),
    'password': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();

    cloudinaryService = CloudinaryService();

    _loadUserData();
  }

  Future<String?> _getRole() async
  {
    // Retrieve token from local storage
    return await _tokenHelper.getRole();
  }

  Future<void> _loadUserData() async {
    if (widget.guestProfile == null && widget.ownerProfile == null) {
      try {
        widget.guestProfile = await userService.getGuestProfile();
        widget.ownerProfile = await userService.getOwnerProfile();

        if (widget.guestProfile != null) {
          widget.userType = 'Guest';
        } else if (widget.ownerProfile != null) {
          widget.userType = 'Owner';
        } else {
          widget.userType = 'unknown';
        }
      } catch (e) {
        print('Error fetching guest profile: $e');
      }
    }

    if (widget.userType == 'Owner') {
      _userData = {
        'name': widget.ownerProfile?.name ?? '',
        'surname': widget.ownerProfile?.surname ?? '',
        'email': widget.ownerProfile?.email ?? '',
        'phone': widget.ownerProfile?.phone ?? '',
        'password': '********',
        'photoURL': widget.ownerProfile?.photoURL ?? '',
      };
    } else if (widget.userType == 'Guest') {
      _userData = {
        'name': widget.guestProfile?.name ?? '',
        'surname': widget.guestProfile?.surname ?? '',
        'email': widget.guestProfile?.email ?? '',
        'phone': widget.guestProfile?.phone ?? '',
        'password': '********',
        'photoURL': widget.guestProfile?.photoURL ?? '',
      };
    } else {
      _userData = {
        'name': 'Unknown User',
        'surname': 'Unknown Surname',
        'email': '',
        'phone': '',
        'password': '********',
        'photoURL': '',
      };
    }

    _controllers['name']!.text = _userData['name'];
    _controllers['surname']!.text = _userData['surname'];
    _controllers['email']!.text = _userData['email'];
    _controllers['phone']!.text = _userData['phone'];
    _controllers['password']!.text = '';
    setState(() {});
  }

  Future<void> _showImagePickerOptions() async {
    if (kIsWeb) {
      // En web, solo mostrar opción de galería
      _showWebImagePicker();
    } else {
      // En móvil, mostrar todas las opciones
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Seleccionar de galería'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Tomar foto'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                if (_userData['photoURL']?.isNotEmpty == true ||
                    _tempImageUrl != null)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Eliminar foto actual'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _removeCurrentPhoto();
                    },
                  ),
              ],
            ),
          );
        },
      );
    }
  }

  void _showWebImagePicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cambiar foto de perfil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Selecciona una imagen desde tu dispositivo:'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _pickImage(ImageSource.gallery);
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Seleccionar'),
                  ),
                  if (_userData['photoURL']?.isNotEmpty == true ||
                      _tempImageUrl != null)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _removeCurrentPhoto();
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Eliminar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // En web, solo funciona gallery
      final ImageSource actualSource = kIsWeb ? ImageSource.gallery : source;

      final XFile? image = await _picker.pickImage(
        source: actualSource,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        if (kIsWeb) {
          // Para web, leer como bytes
          _webImageBytes = await image.readAsBytes();
          // Crear URL temporal para preview
          _tempImageUrl =
              'data:image/jpeg;base64,${base64Encode(_webImageBytes!)}';
        } else {
          // Para móvil, usar path
          _selectedImagePath = image.path;
        }

        setState(() {});
        await _uploadImageToCloudinary(image);
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error seleccionando imagen: $e')),
      );
    }
  }

  Future<void> _uploadImageToCloudinary(XFile image) async {
    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      // Usar el servicio generalizado
      final imageUrl = await cloudinaryService.uploadImage(image,
          folder: null,
          webImageBytes: _webImageBytes, // Requerido para web
          publicId: null,
          tags: null);

      await _updateProfilePhoto(imageUrl);
    } on CloudinaryException catch (e) {
      print('Cloudinary error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error subiendo imagen: ${e.message}')),
      );
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error subiendo imagen: $e')),
      );
    } finally {
      setState(() {
        _isUploadingPhoto = false;
        _selectedImagePath = null;
        _webImageBytes = null;
      });
    }
  }

  Future<void> _updateProfilePhoto(String newPhotoURL) async {
    try {
      _userData['photoURL'] = newPhotoURL;
      _tempImageUrl = newPhotoURL;

      final request = EditUserProfileRequest(
        name: _userData['name'],
        surname: _userData['surname'],
        phone: _userData['phone'],
        email: _userData['email'],
        state: (widget.userType == 'Owner')
            ? widget.ownerProfile?.state
            : widget.guestProfile?.state,
        photoURL: newPhotoURL,
      );

      final success = await userService.updateUserProfile(request);

      if (success) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Foto de perfil actualizada exitosamente')),
        );
      } else {
        throw Exception('Failed to update profile photo');
      }
    } catch (e) {
      print('Error updating profile photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error actualizando foto de perfil: $e')),
      );

      setState(() {
        _userData['photoURL'] = userPhotoURL;
        _tempImageUrl = null;
      });
    }
  }

  Future<void> _removeCurrentPhoto() async {
    try {
      setState(() {
        _tempImageUrl = null;
        _userData['photoURL'] = '';
      });

      await _updateProfilePhoto('');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil eliminada')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error eliminando foto: $e')),
      );
    }
  }

  // Widget para mostrar la imagen según la plataforma
  Widget _buildProfileImage() {
    if (kIsWeb && _webImageBytes != null) {
      // En web, mostrar desde bytes
      return CircleAvatar(
        radius: 32,
        backgroundImage: MemoryImage(_webImageBytes!),
      );
    } else if (!kIsWeb && _selectedImagePath != null) {
      // En móvil, mostrar desde archivo
      return CircleAvatar(
        radius: 32,
        backgroundImage: FileImage(File(_selectedImagePath!)),
      );
    } else {
      // Imagen por defecto o desde URL
      return CircleAvatar(
          radius: 32,
          backgroundImage: NetworkImage(userPhotoURL.isNotEmpty
              ? userPhotoURL
              : 'https://static.vecteezy.com/system/resources/previews/009/292/244/non_2x/default-avatar-icon-of-social-media-user-vector.jpg'));
    }
  }

  Future<void> _updateField(String field) async {
    setState(() => _editMode[field] = false);

    try {
      String newValue = _controllers[field]!.text.trim();
      if (newValue.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Field cannot be empty')));
        return;
      }

      if (newValue == _userData[field]) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$field has not changed')),
        );
        return;
      }

      if (field == 'password') {
        newValue = '********';
      }

      _userData[field] = newValue;

      final request = EditUserProfileRequest(
        name: _userData['name'],
        surname: _userData['surname'],
        phone: _userData['phone'],
        email: _userData['email'],
        state: (widget.userType == 'Owner')
            ? widget.ownerProfile?.state
            : widget.guestProfile?.state,
        photoURL: _userData['photoURL'],
      );

      final success = await userService.updateUserProfile(request);

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update $field')),
        );
        setState(() {
          _userData[field] = _controllers[field]!.text;
        });
        return;
      }

      setState(() {
        _userData[field] = newValue;
        _controllers[field]!.text = newValue;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$field updated successfully')),
      );
    } catch (e) {
      print('Error updating $field: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update $field: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getRole(),
      builder: (context, snapshot) {
        if(snapshot.connectionState == ConnectionState.waiting)
        {
          return const Center(child: CircularProgressIndicator(),);
        }

        if(snapshot.hasData)
        {
          String? role = snapshot.data;

          return BaseLayout(
            role: role,
            childScreen: getContentView()
          );
        }

        return const Center(child: Text('Unable to get information', textAlign: TextAlign.center,));
      }
    );
  }

  Widget getContentView() {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (kIsWeb)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '📱 Funcionalidad completa disponible en dispositivos móviles. En web solo se puede seleccionar desde galería.',
                  style: TextStyle(color: Colors.blue, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            _buildProfileHeader(),
            const SizedBox(height: 16),
            _buildEditableInfo(),
            const SizedBox(height: 16),
            _buildAdditionalForm(),
          ],
        ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              // Avatar
              _buildProfileImage(),

              // Loading overlay
              if (_isUploadingPhoto)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),

              // Edit button overlay
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _isUploadingPhoto ? null : _showImagePickerOptions,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B61B6),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      kIsWeb ? Icons.upload : Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userData['name'] ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(userRole, style: const TextStyle(color: Colors.grey)),
                if (_isUploadingPhoto)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Subiendo foto...',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
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

  Widget _buildEditableInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Personal information',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _editableRow('name', 'Name'),
          _editableRow('surname', 'Surname'),
          _editableRow('email', 'Email address'),
          _editableRow('phone', 'Phone number'),
          _editableRow('password', 'Password'),
        ],
      ),
    );
  }

  Widget _editableRow(String fieldKey, String label) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: _editMode[fieldKey]!
          ? TextField(
              controller: _controllers[fieldKey],
              obscureText: fieldKey == 'password',
              decoration: const InputDecoration(isDense: true),
            )
          : Text(_userData[fieldKey] ?? '',
              style: const TextStyle(color: Colors.grey)),
      trailing: GestureDetector(
        child: Text(
          _editMode[fieldKey]! ? 'Save' : 'Edit',
          style: const TextStyle(color: Colors.blue),
        ),
        onTap: () {
          if (_editMode[fieldKey]!) {
            _updateField(fieldKey);
          } else {
            setState(() => _editMode[fieldKey] = true);
          }
        },
      ),
    );
  }

  Widget _buildAdditionalForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Additional information',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Birth date',
              hintText: 'dd/mm/aaaa',
              suffixIcon: Icon(Icons.calendar_today),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Country'),
            value: _countries.first,
            items: _countries
                .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                .toList(),
            onChanged: (value) {},
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Favorite language'),
            value: _languages.first,
            items: _languages
                .map((l) => DropdownMenuItem<String>(value: l, child: Text(l)))
                .toList(),
            onChanged: (value) {},
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2B61B6),
              minimumSize: const Size.fromHeight(45),
            ),
            child: const Text('Save changes',
                style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}