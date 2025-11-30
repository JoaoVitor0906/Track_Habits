import 'dart:io';
import 'dart:typed_data';
import '../../services/local_photo_store.dart';

abstract class LocalPhotoDataSource {
  Future<String> savePhoto(File photoFile);
  Future<bool> deletePhoto(String photoPath);
  Future<File?> getPhoto(String photoPath);
  Future<Uint8List?> getPhotoBytes(String photoPath);
  bool isValidPhotoPath(String? photoPath);
}

class LocalPhotoDataSourceImpl implements LocalPhotoDataSource {
  final LocalPhotoStore _store;

  LocalPhotoDataSourceImpl(this._store);

  @override
  Future<String> savePhoto(File photoFile) => _store.savePhoto(photoFile);

  @override
  Future<bool> deletePhoto(String photoPath) => _store.deletePhoto(photoPath);

  @override
  Future<File?> getPhoto(String photoPath) => _store.getPhoto(photoPath);

  @override
  Future<Uint8List?> getPhotoBytes(String photoPath) => _store.getPhotoBytes(photoPath);

  @override
  bool isValidPhotoPath(String? photoPath) => _store.isValidPhotoPath(photoPath);
}
