import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import '../domain/repositories/profile_repository.dart';

class UserAvatar extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;
  final ProfileRepository profileRepository;
  final bool showEditButton;

  const UserAvatar({
    Key? key,
    this.size = 64,
    this.onTap,
    required this.profileRepository,
    this.showEditButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Center(
            // Use ValueListenableBuilder so avatar updates when photo changes.
            // Some tests supply a mock ProfileRepository without photoVersion;
            // in that case, fall back to building the avatar directly.
            child: Builder(builder: (context) {
              try {
                final dynamic notifier =
                    (profileRepository as dynamic).photoVersion;
                if (notifier is ValueListenable<int>) {
                  return ValueListenableBuilder<int>(
                    valueListenable: notifier,
                    builder: (context, version, child) => _buildAvatar(),
                  );
                }
              } catch (_) {
                // ignore and fall through to direct build
              }
              return _buildAvatar();
            }),
          ),
          if (showEditButton && onTap != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: _buildEditButton(context),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Material(
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Semantics(
          label: 'Foto do perfil do usuário',
          button: onTap != null,
          child: Builder(builder: (context) {
            // Get photo data and handle all possible return types
            Future<Object?> photoFuture;
            try {
              final dynamic result = profileRepository.getPhotoData();
              if (result is Future) {
                photoFuture = result as Future<Object?>;
              } else if (result != null) {
                photoFuture = Future<Object?>.value(result);
              } else {
                photoFuture = Future<Object?>.value(null);
              }
            } catch (_) {
              photoFuture = Future<Object?>.value(null);
            }

            return FutureBuilder<Object?>(
              future: photoFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData ||
                    snapshot.data == null ||
                    snapshot.hasError) {
                  return _buildInitialsAvatar(context);
                }

                try {
                  final data = snapshot.data!;
                  final colorScheme = Theme.of(context).colorScheme;
                  if (data is Uint8List && data.isNotEmpty) {
                    return CircleAvatar(
                      radius: size / 2,
                      backgroundImage: MemoryImage(data),
                      backgroundColor: colorScheme.primaryContainer,
                    );
                  }

                  if (data is File) {
                    return CircleAvatar(
                      radius: size / 2,
                      backgroundImage: FileImage(data),
                      backgroundColor: colorScheme.primaryContainer,
                    );
                  }
                } catch (e) {
                  // Fall through to initials on any error
                }

                return _buildInitialsAvatar(context);
              },
            );
          }),
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar(BuildContext context) {
    final initials = profileRepository.getInitials();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // No dark mode, usar surface para contrastar com o header primary
    // No light mode, usar primaryContainer
    return CircleAvatar(
      radius: size / 2,
      backgroundColor:
          isDark ? colorScheme.surface : colorScheme.primaryContainer,
      child: Text(
        initials,
        style: TextStyle(
          color: isDark ? colorScheme.primary : colorScheme.onPrimaryContainer,
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEditButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      // Use a contrasting background so the small edit button is visible over
      // dark/primary headers (was blending into header color).
      decoration: BoxDecoration(
        color: colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Icon(
              Icons.edit,
              size: size * 0.25,
              color: colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
