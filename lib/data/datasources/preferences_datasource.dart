import 'dart:typed_data';
import '../../services/preferences_services.dart';

abstract class PreferencesDataSource {
  Future<void> setUserPhotoPath(String? path);
  String? getUserPhotoPath();
  Future<void> setUserPhotoBytes(Uint8List bytes);
  Uint8List? getUserPhotoBytes();
  Future<void> removeUserPhotoBytes();

  Future<void> setUserName(String name);
  String? getUserName();
  Future<void> setUserEmail(String email);
  String? getUserEmail();
}

class PreferencesDataSourceImpl implements PreferencesDataSource {
  final PreferencesService _service;

  PreferencesDataSourceImpl(this._service);

  @override
  Future<void> setUserPhotoPath(String? path) => _service.setUserPhotoPath(path);

  @override
  String? getUserPhotoPath() => _service.getUserPhotoPath();

  @override
  Future<void> setUserPhotoBytes(Uint8List bytes) => _service.setUserPhotoBytes(bytes);

  @override
  Uint8List? getUserPhotoBytes() => _service.getUserPhotoBytes();

  @override
  Future<void> removeUserPhotoBytes() => _service.removeUserPhotoBytes();

  @override
  Future<void> setUserName(String name) => _service.setUserName(name);

  @override
  String? getUserName() => _service.getUserName();

  @override
  Future<void> setUserEmail(String email) => _service.setUserEmail(email);

  @override
  String? getUserEmail() => _service.getUserEmail();
}
