import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../domain/repositories/profile_repository.dart';
import '../widgets/user_avatar.dart';
import '../theme/theme_controller.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:typed_data';

class AppDrawer extends StatefulWidget {
  final ProfileRepository profileRepository;
  final List<Map<String, dynamic>> habits;
  final VoidCallback? onManageGoals;

  const AppDrawer({
    Key? key,
    required this.profileRepository,
    this.habits = const [],
    this.onManageGoals,
  }) : super(key: key);

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  ProfileRepository get profileRepository => widget.profileRepository;

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final brightness = MediaQuery.platformBrightnessOf(context);

    // Calcular se está em modo escuro
    final isDark = themeController.mode == ThemeMode.dark ||
        (themeController.mode == ThemeMode.system &&
            brightness == Brightness.dark);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(context),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Histórico'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/history');
            },
          ),
          ListTile(
            leading: const Icon(Icons.flag),
            title: const Text('Gerenciar Metas'),
            onTap: () {
              Navigator.pop(context);
              if (widget.onManageGoals != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  widget.onManageGoals!();
                });
              }
            },
          ),
          ListTile(
            leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode_outlined),
            title: const Text('Tema escuro'),
            trailing: Switch(
              value: isDark,
              onChanged: (value) {
                themeController.toggle(brightness);
              },
            ),
            onTap: () {
              themeController.toggle(brightness);
            },
          ),
          const Divider(),
          // Outros itens do drawer podem ser adicionados aqui
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DrawerHeader(
      decoration: BoxDecoration(
        color: colorScheme.primary,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            profileRepository: profileRepository,
            size: 80,
            onTap: () => _showPhotoOptions(context),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: Text(
              profileRepository.getUserName() ?? 'Usuário',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Flexible(
            child: Text(
              profileRepository.getUserEmail() ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onPrimary.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPhotoOptions(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: ValueListenableBuilder<int>(
          valueListenable: profileRepository.photoVersion,
          builder: (context, _, __) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tirar foto'),
                onTap: () => _handleImageSelection(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Escolher da galeria'),
                onTap: () =>
                    _handleImageSelection(context, ImageSource.gallery),
              ),
              if (profileRepository.hasPhoto())
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remover foto',
                      style: TextStyle(color: Colors.red)),
                  onTap: () => _handlePhotoRemoval(context),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleImageSelection(
      BuildContext context, ImageSource source) async {
    late final Object? imageData;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // On web, XFile supports readAsBytes; on native, we convert to File
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          // Save temp bytes in repository for preview and display
          await profileRepository.saveTempPhotoBytes(bytes);
          imageData = bytes;
        } else {
          imageData = File(pickedFile.path);
        }
      } else {
        imageData = null;
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao selecionar imagem. Tente novamente.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      imageData = null;
    }

    if (!context.mounted) return;
    Navigator.pop(context);

    if (imageData != null) {
      await _showImagePreview(context, imageData);
    }
  }

  Future<void> _showImagePreview(BuildContext context, Object imageData) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Prévia da foto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Builder(builder: (context) {
              try {
                if (imageData is Uint8List) {
                  return Image.memory(
                    imageData,
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                  );
                } else if (imageData is File) {
                  return Image.file(
                    imageData,
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                  );
                }
              } catch (e) {
                // fallthrough to broken image
              }
              return const SizedBox(
                height: 200,
                width: 200,
                child: Center(child: Icon(Icons.broken_image)),
              );
            }),
            const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
                  child: Text(
                    'Sua foto fica apenas neste dispositivo. Você pode remover quando quiser.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
                Text(
                  'Em breve: opção de sincronização com a nuvem (Supabase)',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                if (imageData is Uint8List) {
                  await profileRepository.saveTempPhotoBytes(imageData);
                } else if (imageData is File) {
                  await profileRepository.savePhoto(imageData);
                }
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Foto atualizada com sucesso!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erro ao salvar a foto. Tente novamente.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePhotoRemoval(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover foto'),
        content: const Text('Deseja realmente remover sua foto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await profileRepository.removePhoto();
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto removida com sucesso!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao remover a foto. Tente novamente.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}
