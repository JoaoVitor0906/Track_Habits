import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

abstract class ProfileRepository {
  ValueNotifier<int> get photoVersion;

  Future<String?> savePhoto(File photoFile);
  Future<bool> removePhoto();
  Future<File?> getPhoto();
  Future<Object?> getPhotoData();
  Future<void> saveTempPhotoBytes(Uint8List bytes);
  bool hasPhoto();

  String? getUserName();
  String? getUserEmail();

  String getInitials();

  Future<void> setUserName(String name);
  Future<void> setUserEmail(String email);
}
