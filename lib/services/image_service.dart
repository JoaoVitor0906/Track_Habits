import 'dart:io';
import 'package:flutter/painting.dart' show decodeImageFromList;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';

class ImageService {
  static const int maxWidth = 512;
  static const int maxHeight = 512;
  static const int targetSizeKB = 200;
  static const int initialQuality = 80;

  final ImagePicker _picker;

  ImageService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  Future<File?> pickImage({
    required ImageSource source,
    bool shouldCompress = true,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
      );

      if (pickedFile == null) return null;

      final File originalFile = File(pickedFile.path);
      if (!shouldCompress) return originalFile;

      return compressImage(originalFile);
    } catch (e) {
      throw Exception('Erro ao selecionar imagem: ${e.toString()}');
    }
  }

  Future<File> compressImage(File file, {int quality = initialQuality}) async {
    final String dir = path.dirname(file.path);
    final String name = path.basenameWithoutExtension(file.path);
    final String ext = path.extension(file.path);
    final String targetPath = path.join(dir, '${name}_compressed$ext');

    var result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      quality: quality,
      minWidth: maxWidth,
      minHeight: maxHeight,
      // Remove EXIF data
      keepExif: false,
    );

    if (result == null) {
      throw Exception('Falha ao comprimir imagem');
    }

    // Verifica se o tamanho está dentro do limite
    final int compressedSize = await result.length();
    if (compressedSize > targetSizeKB * 1024 && quality > 30) {
      // Se ainda estiver muito grande, tenta comprimir mais
      await File(result.path).delete();
      return compressImage(file, quality: quality - 20);
    }

    // Deleta o arquivo original para economizar espaço
    if (file.path != result.path) {
      await file.delete();
    }

    return File(result.path);
  }

  Future<void> validateImageSize(File file) async {
    final int fileSize = await file.length();
    if (fileSize > 10 * 1024 * 1024) { // 10MB
      throw Exception('A imagem é muito grande. Por favor, escolha uma imagem menor que 10MB.');
    }
  }

  Future<ImageInfo> getImageDimensions(File imageFile) async {
    final decodedImage = await decodeImageFromList(await imageFile.readAsBytes());
    return ImageInfo(
      width: decodedImage.width,
      height: decodedImage.height,
      sizeInBytes: await imageFile.length(),
    );
  }
}

class ImageInfo {
  final int width;
  final int height;
  final int sizeInBytes;

  ImageInfo({
    required this.width,
    required this.height,
    required this.sizeInBytes,
  });

  double get sizeInMB => sizeInBytes / (1024 * 1024);
  
  @override
  String toString() {
    return 'Dimensões: ${width}x$height, Tamanho: ${sizeInMB.toStringAsFixed(2)}MB';
  }
}