import 'package:flutter/material.dart';

class ProviderListItem extends StatelessWidget {
  final String id;
  final String name;
  final double? rating;
  final double? distanceKm;
  final String? imageUrl;
  final String? taxIdMasked;
  final Map<String, dynamic>? contact;
  final VoidCallback? onEdit;
  final VoidCallback? onLongPress;

  const ProviderListItem({
    Key? key,
    required this.id,
    required this.name,
    this.rating,
    this.distanceKm,
    this.imageUrl,
    this.taxIdMasked,
    this.contact,
    this.onEdit,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    width: 56,
                    height: 56,
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 56,
                  height: 56,
                  color: Colors.grey.shade200,
                  child: Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              ),
            )
          : CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              child: Icon(Icons.store, color: Colors.grey.shade700),
            ),
      title: Text(name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (taxIdMasked != null) Text(taxIdMasked!),
          if (contact != null &&
              (contact!['phone'] != null || contact!['email'] != null))
            Text(
              '${contact!['phone'] ?? ''}${(contact!['phone'] != null && contact!['email'] != null) ? ' • ' : ''}${contact!['email'] ?? ''}',
              style: TextStyle(fontSize: 12),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (rating != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    SizedBox(width: 4),
                    Text(rating!.toStringAsFixed(1)),
                  ],
                ),
              if (distanceKm != null)
                Text('${distanceKm!.toStringAsFixed(1)} km'),
            ],
          ),
          const SizedBox(width: 8),
          // Edit icon (shows when onEdit is provided)
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
              tooltip: 'Editar',
            ),
        ],
      ),
      onTap: () {},
      onLongPress: onLongPress,
    );
  }
}
