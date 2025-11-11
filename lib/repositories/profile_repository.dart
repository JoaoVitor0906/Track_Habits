import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, ValueNotifier;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../services/local_photo_store.dart';
import '../services/preferences_services.dart';

class ProfileRepository {
  static const String _avatarFileName = 'avatar.jpg';
  final PreferencesService _preferencesService;
  final LocalPhotoStore _localPhotoStore;

  // In-memory bytes cache (used on web for preview and temporary storage)
  Uint8List? _tempPhotoBytes;
  // Notifier used to signal UI when the photo changes (save/remove)
  final ValueNotifier<int> photoVersion = ValueNotifier<int>(0);

  ProfileRepository(this._preferencesService, this._localPhotoStore);

  // Photo methods
  Future<String?> savePhoto(File photoFile) async {
    try {
      // Save the file
      final savedPath = await _localPhotoStore.savePhoto(photoFile);
      print('[ProfileRepository] Saved file at $savedPath');
      
      // Backup the bytes to SharedPreferences (read from saved file to ensure persistence)
      try {
        final savedFile = File(savedPath);
        final bytes = await savedFile.readAsBytes();
        await _preferencesService.setUserPhotoBytes(bytes);
        print('[ProfileRepository] Backed up bytes to SharedPreferences (${bytes.length} bytes)');
      } catch (e) {
        print('[ProfileRepository] Failed to backup bytes from saved file: $e');
      }
      
      // Save the path
      try {
        await _preferencesService.setUserPhotoPath(savedPath);
        print('[ProfileRepository] Saved path to SharedPreferences');
      } catch (e) {
        print('[ProfileRepository] Failed to save path: $e');
      }
      
      // clear any in-memory temp bytes and notify listeners
      _tempPhotoBytes = null;
      photoVersion.value++;
      return savedPath;
    } catch (e) {
      return null;
    }
  }

  Future<bool> removePhoto() async {
    bool success = true;
    
    // Clear temporary bytes
    _tempPhotoBytes = null;
    
    // Remove web storage if available
    if (kIsWeb) {
      await _preferencesService.removeUserPhotoBytes();
    }
    
    // Remove native storage if available
    final currentPath = _preferencesService.getUserPhotoPath();
    if (currentPath != null) {
      success = await _localPhotoStore.deletePhoto(currentPath);
      if (success) {
        await _preferencesService.setUserPhotoPath(null);
      }
    }
    
    // Always notify listeners of the change, regardless of success
    photoVersion.value++;
    return success;
  }

  Future<File?> getPhoto() async {
    final photoPath = _preferencesService.getUserPhotoPath();
    if (photoPath == null) return null;

    return _localPhotoStore.getPhoto(photoPath);
  }

  /// Returns either a File (native platforms) or Uint8List (web or temp) representing the photo.
  Future<Object?> getPhotoData() async {
  // 1. Try in-memory temp bytes first (preview/session)
    if (_tempPhotoBytes != null) return _tempPhotoBytes;

    // 2. Try to get from file system
    final photoPath = _preferencesService.getUserPhotoPath();
    if (photoPath != null) {
      print('[ProfileRepository] Trying photoPath from prefs: $photoPath');
      final file = await _localPhotoStore.getPhoto(photoPath);
      if (file != null) {
        print('[ProfileRepository] Found file at $photoPath');
        // Refresh the backup in SharedPreferences
        try {
          final bytes = await file.readAsBytes();
          await _preferencesService.setUserPhotoBytes(bytes);
          print('[ProfileRepository] Refreshed SharedPreferences backup (${bytes.length} bytes)');
          return file;
        } catch (e) {
          print('[ProfileRepository] Failed to read file bytes: $e');
          // If reading file fails, continue to next recovery method
        }
      } else {
        print('[ProfileRepository] No file present at $photoPath');
      }
    }

    // 3. Try to recover from SharedPreferences backup
    final bytes = _preferencesService.getUserPhotoBytes();
    if (bytes != null) {
      // Try to restore the file from bytes
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
        // If restoration fails, return the bytes directly
        return bytes;
      }
    }

    return null;
  }

  /// Save bytes in-memory (useful for web preview and session storage).
  Future<void> saveTempPhotoBytes(Uint8List bytes) async {
    _tempPhotoBytes = bytes;
    if (kIsWeb) {
      // For web, we need to persist the bytes since we don't have file system access
      await _preferencesService.setUserPhotoBytes(bytes);
      photoVersion.value++;
    }
  }

  bool hasPhoto() {
    // First check for temporary photo bytes in memory
    if (_tempPhotoBytes != null) {
      return true;
    }
    
    // Then check platform-specific storage
    if (kIsWeb) {
      return _preferencesService.getUserPhotoBytes() != null;
    }
    final photoPath = _preferencesService.getUserPhotoPath();
    return _localPhotoStore.isValidPhotoPath(photoPath);
  }

  // User info methods
  String? getUserName() => _preferencesService.getUserName();
  String? getUserEmail() => _preferencesService.getUserEmail();

  Future<void> setUserName(String name) => _preferencesService.setUserName(name);
  Future<void> setUserEmail(String email) => _preferencesService.setUserEmail(email);

  String getInitials() {
    final name = getUserName() ?? '';
    final parts = name.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }
}