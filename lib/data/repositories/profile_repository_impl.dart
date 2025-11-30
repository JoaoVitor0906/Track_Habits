import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, ValueNotifier;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../domain/repositories/profile_repository.dart';
import '../../services/local_photo_store.dart';
import '../../services/preferences_services.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  static const String _avatarFileName = 'avatar.jpg';
  final PreferencesService _preferencesService;
  final LocalPhotoStore _localPhotoStore;

  Uint8List? _tempPhotoBytes;
  @override
  final ValueNotifier<int> photoVersion = ValueNotifier<int>(0);

  ProfileRepositoryImpl(this._preferencesService, this._localPhotoStore);

  @override
  Future<String?> savePhoto(File photoFile) async {
    try {
      final savedPath = await _localPhotoStore.savePhoto(photoFile);
      print('[ProfileRepositoryImpl] Saved file at $savedPath');

      try {
        final savedFile = File(savedPath);
        final bytes = await savedFile.readAsBytes();
        await _preferencesService.setUserPhotoBytes(bytes);
        print('[ProfileRepositoryImpl] Backed up bytes to SharedPreferences (${bytes.length} bytes)');
      } catch (e) {
        print('[ProfileRepositoryImpl] Failed to backup bytes from saved file: $e');
      }

      try {
        await _preferencesService.setUserPhotoPath(savedPath);
        print('[ProfileRepositoryImpl] Saved path to SharedPreferences');
      } catch (e) {
        print('[ProfileRepositoryImpl] Failed to save path: $e');
      }

      _tempPhotoBytes = null;
      photoVersion.value++;
      return savedPath;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> removePhoto() async {
    bool success = true;
    _tempPhotoBytes = null;

    if (kIsWeb) {
      await _preferencesService.removeUserPhotoBytes();
    }

    final currentPath = _preferencesService.getUserPhotoPath();
    if (currentPath != null) {
      success = await _localPhotoStore.deletePhoto(currentPath);
      if (success) {
        await _preferencesService.setUserPhotoPath(null);
      }
    }

    photoVersion.value++;
    return success;
  }

  @override
  Future<File?> getPhoto() async {
    final photoPath = _preferencesService.getUserPhotoPath();
    if (photoPath == null) return null;

    return _localPhotoStore.getPhoto(photoPath);
  }

  @override
  Future<Object?> getPhotoData() async {
    if (_tempPhotoBytes != null) return _tempPhotoBytes;

    final photoPath = _preferencesService.getUserPhotoPath();
    if (photoPath != null) {
      print('[ProfileRepositoryImpl] Trying photoPath from prefs: $photoPath');
      final file = await _localPhotoStore.getPhoto(photoPath);
      if (file != null) {
        print('[ProfileRepositoryImpl] Found file at $photoPath');
        try {
          final bytes = await file.readAsBytes();
          await _preferencesService.setUserPhotoBytes(bytes);
          print('[ProfileRepositoryImpl] Refreshed SharedPreferences backup (${bytes.length} bytes)');
          return file;
        } catch (e) {
          print('[ProfileRepositoryImpl] Failed to read file bytes: $e');
        }
      } else {
        print('[ProfileRepositoryImpl] No file present at $photoPath');
      }
    }

    final bytes = _preferencesService.getUserPhotoBytes();
    if (bytes != null) {
      try {
        final directory = await getApplicationSupportDirectory();
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        final String savedPath = path.join(directory.path, _avatarFileName);
        final file = File(savedPath);
        await file.writeAsBytes(bytes);
        await _preferencesService.setUserPhotoPath(savedPath);
        return file;
      } catch (e) {
        return bytes;
      }
    }

    return null;
  }

  @override
  Future<void> saveTempPhotoBytes(Uint8List bytes) async {
    _tempPhotoBytes = bytes;
    if (kIsWeb) {
      await _preferencesService.setUserPhotoBytes(bytes);
      photoVersion.value++;
    }
  }

  @override
  bool hasPhoto() {
    if (_tempPhotoBytes != null) {
      return true;
    }

    if (kIsWeb) {
      return _preferencesService.getUserPhotoBytes() != null;
    }
    final photoPath = _preferencesService.getUserPhotoPath();
    return _localPhotoStore.isValidPhotoPath(photoPath);
  }

  @override
  String? getUserName() => _preferencesService.getUserName();

  @override
  String? getUserEmail() => _preferencesService.getUserEmail();

  @override
  Future<void> setUserName(String name) => _preferencesService.setUserName(name);

  @override
  Future<void> setUserEmail(String email) => _preferencesService.setUserEmail(email);

  @override
  String getInitials() {
    final name = getUserName() ?? '';
    final parts = name.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }
}
