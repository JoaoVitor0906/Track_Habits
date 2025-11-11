import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'image_service.dart';

class LocalPhotoStore {
  static const String _avatarFileName = 'avatar.jpg';
  final ImageService _imageService;

  LocalPhotoStore({ImageService? imageService}) 
      : _imageService = imageService ?? ImageService();

  Future<String> savePhoto(File photoFile) async {
    await _imageService.validateImageSize(photoFile);
    
    // Try all available storage directories
    final List<Directory> directories = await Future.wait([
      getApplicationSupportDirectory(),
      getApplicationDocumentsDirectory(),
      getTemporaryDirectory(),
    ]);
    
    String? savedPath;
    File? savedFile;
    
    // Try saving in each directory until successful
    for (final directory in directories) {
      try {
        // Log attempt
        print('[LocalPhotoStore] Trying to save to ${directory.path}');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        
        final String attemptPath = path.join(directory.path, _avatarFileName);
        final compressedFile = await _imageService.compressImage(photoFile);
        
        await compressedFile.copy(attemptPath);
        
        // Test if the file was actually saved and is readable
        final testFile = File(attemptPath);
        if (await testFile.exists() && await testFile.length() > 0) {
          savedPath = attemptPath;
          savedFile = testFile;
          
          // Clean up the temporary compressed file
          if (compressedFile.path != attemptPath) {
            await compressedFile.delete();
          }
          break;
        }
      } catch (e) {
        // Log error and continue to next directory
        print('[LocalPhotoStore] Failed to save in ${directory.path}: $e');
        continue;
      }
    }
    
    if (savedPath == null || savedFile == null) {
      throw Exception('Failed to save photo in any available directory');
    }
    
    return savedPath;
  }

  Future<bool> deletePhoto(String photoPath) async {
    try {
      final file = File(photoPath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<File?> getPhoto(String photoPath) async {
    final file = File(photoPath);
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  /// Reads photo bytes from disk (native platforms). Returns null if not available.
  Future<Uint8List?> getPhotoBytes(String photoPath) async {
    try {
      final file = File(photoPath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    } catch (e) {
      // ignore and return null
    }
    return null;
  }

  bool isValidPhotoPath(String? photoPath) {
    if (photoPath == null) return false;
    return File(photoPath).existsSync();
  }
}