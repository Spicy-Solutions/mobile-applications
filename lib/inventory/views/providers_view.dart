import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sweet_manager/shared/infrastructure/misc/token_helper.dart';
import 'package:sweet_manager/shared/widgets/base_layout.dart';
import '../../iam/infrastructure/auth_service.dart';
import '../models/provider.dart';
import '../services/provider_service.dart';
import '../widgets/provider_card.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class ProvidersView extends StatefulWidget {
  const ProvidersView({super.key});

  @override
  State<ProvidersView> createState() => _ProvidersViewState();
}

class _ProvidersViewState extends State<ProvidersView> {
  final ProviderService _providerService = ProviderService();
  final AuthService _authService = AuthService();
  List<Provider> _providers = [];
  final TokenHelper _tokenHelper = TokenHelper();
  bool _loading = true;
  late Future<bool> _fetchProvidersCall;
  String? _hotelId; // Agregamos esta variable para almacenar el hotelId

  @override
  void initState() {
    super.initState();
    _fetchProvidersCall = _fetchProviders();
  }

  Future<bool> _fetchProviders() async {
    final hotelId = await _tokenHelper.getLocality();
    if (hotelId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener el hotelId del token')),
      );
      setState(() => _loading = false);
      return false;
    }

    // Guardamos el hotelId para usar en otras operaciones
    _hotelId = hotelId;

    final result = await _providerService.getProvidersByHotelId(hotelId);
    setState(() {
      _providers = result.where((p) => p.state.toLowerCase() == 'active').toList();
      _loading = false;
    });
    return true;
  }

  void _showDetails(Provider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey, // Cambiamos a un color sólido para evitar CORS
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(provider.name, textAlign: TextAlign.center),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Email: ${provider.email}'),
            Text('Phone: ${provider.phone}'),
            Text('Estado: ${provider.state}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showProviderForm(provider);
            },
            child: const Text('Editar'),
          ),
        ],
      ),
    );
  }

  void _showProviderForm([Provider? provider]) {
    final isEditing = provider != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: provider?.name ?? '');
    final emailController = TextEditingController(text: provider?.email ?? '');
    final phoneController = TextEditingController(text: provider?.phone ?? '');
    final stateController = TextEditingController(text: provider?.state ?? 'Active');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEditing ? 'Editar Proveedor' : 'Agregar Proveedor'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El email es requerido';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Ingrese un email válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El teléfono es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: stateController,
                  decoration: const InputDecoration(
                    labelText: 'Estado *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El estado es requerido';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final newProvider = Provider(
                  id: isEditing ? provider.id : 0,
                  name: nameController.text.trim(),
                  email: emailController.text.trim(),
                  phone: phoneController.text.trim(),
                  state: stateController.text.trim(),
                );

                Navigator.of(context).pop();

                if (isEditing) {
                  _updateProvider(provider.id, newProvider);
                } else {
                  _createProvider(newProvider);
                }
              }
            },
            child: Text(isEditing ? 'Actualizar' : 'Guardar'),
          ),
        ],
      ),
    );
  }

  void _createProvider(Provider provider) async {
    // Verificamos que tengamos el hotelId antes de proceder
    if (_hotelId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se pudo obtener el ID del hotel')),
      );
      return;
    }

    setState(() => _loading = true);

    // Pasamos el hotelId al método createProvider
    final success = await _providerService.createProvider(provider, _hotelId!);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proveedor creado exitosamente')),
      );
      _fetchProviders();
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al crear el proveedor')),
      );
    }
  }

  void _updateProvider(int providerId, Provider provider) async {
    setState(() => _loading = true);

    final success = await _providerService.updateProvider(providerId, provider);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proveedor actualizado exitosamente')),
      );
      _fetchProviders();
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al actualizar el proveedor')),
      );
    }
  }

  void _deleteProvider(Provider provider) async {
    final success = await _providerService.deleteProvider(provider.id);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proveedor eliminado exitosamente')),
      );
      _fetchProviders();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar el proveedor')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _fetchProvidersCall,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            return BaseLayout(role: "ROLE_OWNER", childScreen: getContentBuild(context));
          }

          return const Center(child: Text('Unable to get information', textAlign: TextAlign.center,));
        }
    );
  }

  Widget getContentBuild(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _providers.isEmpty
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'No hay proveedores para mostrar.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _fetchProvidersCall = _fetchProviders();
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Recargar'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => _showProviderForm(),
              icon: const Icon(Icons.add),
              label: const Text('Agregar Proveedor'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: _providers.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemBuilder: (context, index) {
            final provider = _providers[index];
            return ProviderCard(
              provider: provider,
              onDetailsPressed: () => _showDetails(provider),
              onDeletePressed: () => _deleteProvider(provider),
              onEditPressed: () => _showProviderForm(provider),
            );
          },
        ),
      ),
      floatingActionButton: _providers.isNotEmpty ? FloatingActionButton(
        onPressed: () => _showProviderForm(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }
}