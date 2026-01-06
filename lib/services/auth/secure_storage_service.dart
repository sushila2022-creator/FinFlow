import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  Future<void> writePin(String pin) async {
    await _storage.write(key: 'app_pin', value: pin);
  }

  Future<String?> readPin() async {
    return await _storage.read(key: 'app_pin');
  }
}
