import 'package:flutter/material.dart';
import '../models/provider.dart';

class ProviderCard extends StatelessWidget {
  final Provider provider;
  final VoidCallback onDetailsPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback onEditPressed;

  const ProviderCard({
    super.key,
    required this.provider,
    required this.onDetailsPressed,
    required this.onDeletePressed,
    required this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12), // Reduced padding
        child: Column(
          mainAxisSize: MainAxisSize.min, // Allow card to size itself
          mainAxisAlignment: MainAxisAlignment.start, // Changed from center
          children: [
            const CircleAvatar(
              radius: 25, // Reduced from 30
              backgroundColor: Colors.blue,
              child: Icon(
                Icons.person,
                size: 25, // Reduced from 30
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8), // Reduced spacing
            Text(
              provider.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), // Reduced font size
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4), // Reduced spacing
            Text(
              provider.email,
              style: const TextStyle(color: Colors.grey, fontSize: 11), // Reduced font size
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8), // Reduced spacing
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Edit button
                Expanded(
                  child: ElevatedButton(
                    onPressed: onEditPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8), // Adjusted padding
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      minimumSize: Size.zero, // Remove default minimum size
                    ),
                    child: const Text(
                      'Edit',
                      style: TextStyle(color: Colors.white, fontSize: 11), // Reduced font size
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Details button
                Expanded(
                  child: ElevatedButton(
                    onPressed: onDetailsPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8), // Adjusted padding
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      minimumSize: Size.zero, // Remove default minimum size
                    ),
                    child: const Text(
                      'Detail',
                      style: TextStyle(color: Colors.white, fontSize: 11), // Reduced font size
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6), // Reduced spacing
            // Delete button (full width)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('¿Estás seguro?'),
                      content: const Text('¿Realmente quieres eliminar este proveedor?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onDeletePressed();
                          },
                          child: const Text(
                            'Eliminar',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8), // Adjusted padding
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: const BorderSide(color: Colors.red, width: 1),
                  ),
                  minimumSize: Size.zero, // Remove default minimum size
                ),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red, fontSize: 11), // Reduced font size
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}