import 'package:flutter/material.dart';
import 'package:sweet_manager/iam/domain/model/aggregates/guest.dart';
import 'package:sweet_manager/iam/domain/model/aggregates/owner.dart';
import 'package:sweet_manager/iam/domain/model/commands/update_guest_preferences.dart';
import 'package:sweet_manager/iam/domain/model/entities/guest_preference.dart';
import 'package:sweet_manager/iam/infrastructure/user_service.dart';
import 'package:sweet_manager/shared/widgets/base_layout.dart';

// ignore: must_be_immutable
class UserPreferencesPage extends StatefulWidget {
  final UserService userService = UserService();
  Guest? guestProfile;
  Owner? ownerProfile;

  UserPreferencesPage({super.key});

  @override
  _GuestProfileScreenState createState() => _GuestProfileScreenState();
}

class _GuestProfileScreenState extends State<UserPreferencesPage> {
  // Opciones predefinidas
  final List<String> lightOptions = ['Warm', 'Cold', 'Natural'];
  final List<String> drinkOptions = ['Water', 'Soda', 'Coffee', 'Tea', 'Juice', 'Energy Drink'];
  final List<String> foodOptions = ['Vegetarian', 'Vegan', 'Meat', 'Seafood', 'Gluten-Free', 'Dairy-Free', 'No Restrictions'];

  // Variable para guardar la referencia de las preferencias actuales
  GuestPreferences? currentPreferences;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  String get userFullName {
    return widget.ownerProfile?.name ??
        widget.guestProfile?.name ??
        'Unknown User';
  }

  String get userRole {
    return widget.ownerProfile != null ? 'Owner' : 'Guest';
  }

  Future<void> fetchUserProfile() async {
    try {
      widget.guestProfile = await widget.userService.getGuestProfile();
      widget.ownerProfile = await widget.userService.getOwnerProfile();
      setState(() {});

      await recoverGuestPreferences();

      print(
          'User profile fetched successfully: ${widget.guestProfile?.toJson()}');
      print(
          'Owner profile fetched successfully: ${widget.ownerProfile?.toJson()}');
    } catch (e) {
      print('Error fetching user profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<GuestPreferences?> recoverGuestPreferences() async {
    if (widget.guestProfile == null) {
      print('Guest profile is null, cannot recover preferences');
      return null;
    }

    try {
      final response = await widget.userService.getGuestPreferences();

      if (response != null) {
        // Guardar la referencia de las preferencias actuales
        currentPreferences = response;

        setState(() {
          temperature = response.temperature.toString();
          temperatureValue = response.temperature.toDouble();
        });

        return response;
      } else {
        print('No preferences found for guest ID ${widget.guestProfile!.id}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No preferences found')),
        );
        return null;
      }
    } catch (e) {
      print('Error recovering guest preferences: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to recover preferences')),
      );
      return null;
    }
  }

  Future<void> updateGuestPreferences(int temperature) async {
    if (widget.guestProfile == null) {
      print('Guest profile is null, cannot update preferences');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guest profile not found')),
      );
      return;
    }

    if (temperature <= 10 || temperature > 40 || temperature is String) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid temperature')),
      );
      return;
    }

    try {
      final updatedPreferences = EditGuestPreferences(
        temperature: temperature,
        guestId: widget.guestProfile!.id,
      );

      // Usar la referencia guardada en lugar de hacer otra llamada al servidor
      if (currentPreferences == null) {
        // Create new preferences if none exist
        await widget.userService.setGuestPreferences(GuestPreferences(
          id: 0, // New preference, ID will be assigned by the backend
          guestId: widget.guestProfile!.id,
          temperature: temperature,
        ));
      } else {
        // Update existing preferences usando la referencia guardada
        await widget.userService
            .updateGuestPreferences(updatedPreferences, currentPreferences!.id);

        // Actualizar la referencia local con la nueva temperatura
        currentPreferences = GuestPreferences(
          id: currentPreferences!.id,
          guestId: currentPreferences!.guestId,
          temperature: temperature,
        );
      }

      // Update the local state with the new temperature
      setState(() {
        this.temperature = temperature.toString();
        this.temperatureValue = temperature.toDouble();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences updated successfully')),
      );
    } catch (e) {
      print('Error updating guest preferences: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update preferences')),
      );
    }
  }

  String temperature = '';
  double temperatureValue = 22.0; // Valor por defecto para el slider
  String lightType = 'Warm';
  String foodPreferences = 'No Restrictions';
  String drinkPreferences = 'Water';
  bool isSmoker = false; // Nueva variable para smoker option

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      childScreen: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                userFullName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userRole,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),

              // Temperature Slider
              TemperatureSliderItem(
                title: 'Ideal Temperature for the room (C°)',
                value: temperatureValue,
                onChanged: (newValue) {
                  setState(() {
                    temperatureValue = newValue;
                    temperature = newValue.round().toString();
                  });
                },
                onChangeEnd: (finalValue) async {
                  await updateGuestPreferences(finalValue.round());
                },
              ),
              const SizedBox(height: 24),

              // Light Type Dropdown with Save/Cancel
              DropdownPreferenceItemWithButtons(
                title: 'Light Type',
                value: lightType,
                options: lightOptions,
                onSave: (newValue) {
                  setState(() {
                    lightType = newValue;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Light preferences updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Food Preferences Dropdown with Save/Cancel
              DropdownPreferenceItemWithButtons(
                title: 'Food Preferences',
                value: foodPreferences,
                options: foodOptions,
                onSave: (newValue) {
                  setState(() {
                    foodPreferences = newValue;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Food preferences updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Drink Preferences Dropdown with Save/Cancel
              DropdownPreferenceItemWithButtons(
                title: 'Drink Preferences',
                value: drinkPreferences,
                options: drinkOptions,
                onSave: (newValue) {
                  setState(() {
                    drinkPreferences = newValue;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Drink preferences updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Smoker Option with Save/Cancel
              SmokerPreferenceItemWithButtons(
                title: 'Smoker Option',
                value: isSmoker,
                onSave: (newValue) {
                  setState(() {
                    isSmoker = newValue;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Smoker preferences updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Request Card Button
              GestureDetector(
                onTap: () => _showRequestCardModal(),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Couldn't find your entry card",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Request cancellation of your previous access card to obtain a new one.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.open_in_new,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Request',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Add extra padding at the bottom to ensure content doesn't get cut off
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      role: 'ROLE_GUEST',
    );
  }

  void _showRequestCardModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return RequestCardModal();
      },
    );
  }
}

// Componente para el slider de temperatura
class TemperatureSliderItem extends StatelessWidget {
  final String title;
  final double value;
  final Function(double) onChanged;
  final Function(double) onChangeEnd;

  const TemperatureSliderItem({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '10°C',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Expanded(
                child: Slider(
                  value: value,
                  min: 10.0,
                  max: 40.0,
                  divisions: 14,
                  label: '${value.round()}°C',
                  onChanged: onChanged,
                  onChangeEnd: onChangeEnd,
                  activeColor: Colors.blue[600],
                ),
              ),
              Text(
                '40°C',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          Center(
            child: Text(
              '${value.round()}°C',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Componente para dropdown con botones Save/Cancel
class DropdownPreferenceItemWithButtons extends StatefulWidget {
  final String title;
  final String value;
  final List<String> options;
  final Function(String) onSave;

  const DropdownPreferenceItemWithButtons({
    super.key,
    required this.title,
    required this.value,
    required this.options,
    required this.onSave,
  });

  @override
  _DropdownPreferenceItemWithButtonsState createState() => _DropdownPreferenceItemWithButtonsState();
}

class _DropdownPreferenceItemWithButtonsState extends State<DropdownPreferenceItemWithButtons> {
  late String selectedValue;
  late String originalValue;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.value;
    originalValue = widget.value;
  }

  @override
  void didUpdateWidget(DropdownPreferenceItemWithButtons oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      selectedValue = widget.value;
      originalValue = widget.value;
    }
  }

  bool get hasChanged => selectedValue != originalValue;

  void _save() {
    widget.onSave(selectedValue);
    setState(() {
      originalValue = selectedValue;
    });
  }

  void _cancel() {
    setState(() {
      selectedValue = originalValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedValue,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: widget.options.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  selectedValue = newValue;
                });
              }
            },
          ),
          if (hasChanged) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _cancel,
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// Nuevo componente para smoker option con botones Save/Cancel
class SmokerPreferenceItemWithButtons extends StatefulWidget {
  final String title;
  final bool value;
  final Function(bool) onSave;

  const SmokerPreferenceItemWithButtons({
    super.key,
    required this.title,
    required this.value,
    required this.onSave,
  });

  @override
  _SmokerPreferenceItemWithButtonsState createState() => _SmokerPreferenceItemWithButtonsState();
}

class _SmokerPreferenceItemWithButtonsState extends State<SmokerPreferenceItemWithButtons> {
  late bool selectedValue;
  late bool originalValue;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.value;
    originalValue = widget.value;
  }

  @override
  void didUpdateWidget(SmokerPreferenceItemWithButtons oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      selectedValue = widget.value;
      originalValue = widget.value;
    }
  }

  bool get hasChanged => selectedValue != originalValue;

  void _save() {
    widget.onSave(selectedValue);
    setState(() {
      originalValue = selectedValue;
    });
  }

  void _cancel() {
    setState(() {
      selectedValue = originalValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      selectedValue ? Icons.smoking_rooms : Icons.smoke_free,
                      color: selectedValue ? Colors.orange[600] : Colors.green[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      selectedValue ? 'Smoker' : 'Non-smoker',
                      style: TextStyle(
                        fontSize: 14,
                        color: selectedValue ? Colors.orange[600] : Colors.green[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: selectedValue,
                onChanged: (bool value) {
                  setState(() {
                    selectedValue = value;
                  });
                },
                activeColor: Colors.orange[600],
                inactiveThumbColor: Colors.green[600],
                inactiveTrackColor: Colors.green[200],
              ),
            ],
          ),
          if (hasChanged) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _cancel,
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class RequestCardModal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Image
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue[400]!, Colors.blue[600]!],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.credit_card,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Request New Entry Card',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Your previous access card will be cancelled and a new one will be issued. This process may take up to 24 hours to complete.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('Cancel'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                Text('Card request submitted successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          child: Text('Request'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}