import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/error/exceptions.dart';

abstract class LocalStorageService {
  Future<void> saveString(String key, String value);
  Future<String?> getString(String key);
  Future<void> saveInt(String key, int value);
  Future<int?> getInt(String key);
  Future<void> saveBool(String key, bool value);
  Future<bool?> getBool(String key);
  Future<void> saveObject(String key, Map<String, dynamic> value);
  Future<Map<String, dynamic>?> getObject(String key);
  Future<void> remove(String key);
  Future<void> clear();
  Future<bool> hasKey(String key);
}

class LocalStorageServiceImpl implements LocalStorageService {
  final SharedPreferences sharedPreferences;

  LocalStorageServiceImpl(this.sharedPreferences);

  @override
  Future<void> saveString(String key, String value) async {
    try {
      await sharedPreferences.setString(key, value);
    } catch (e) {
      throw CacheException('Failed to save string: $e');
    }
  }

  @override
  Future<String?> getString(String key) async {
    try {
      return sharedPreferences.getString(key);
    } catch (e) {
      throw CacheException('Failed to get string: $e');
    }
  }

  @override
  Future<void> saveInt(String key, int value) async {
    try {
      await sharedPreferences.setInt(key, value);
    } catch (e) {
      throw CacheException('Failed to save int: $e');
    }
  }

  @override
  Future<int?> getInt(String key) async {
    try {
      return sharedPreferences.getInt(key);
    } catch (e) {
      throw CacheException('Failed to get int: $e');
    }
  }

  @override
  Future<void> saveBool(String key, bool value) async {
    try {
      await sharedPreferences.setBool(key, value);
    } catch (e) {
      throw CacheException('Failed to save bool: $e');
    }
  }

  @override
  Future<bool?> getBool(String key) async {
    try {
      return sharedPreferences.getBool(key);
    } catch (e) {
      throw CacheException('Failed to get bool: $e');
    }
  }

  @override
  Future<void> saveObject(String key, Map<String, dynamic> value) async {
    try {
      await sharedPreferences.setString(key, json.encode(value));
    } catch (e) {
      throw CacheException('Failed to save object: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> getObject(String key) async {
    try {
      final jsonString = sharedPreferences.getString(key);
      if (jsonString == null) {
        return null;
      }
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw CacheException('Failed to get object: $e');
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      await sharedPreferences.remove(key);
    } catch (e) {
      throw CacheException('Failed to remove key: $e');
    }
  }

  @override
  Future<void> clear() async {
    try {
      await sharedPreferences.clear();
    } catch (e) {
      throw CacheException('Failed to clear storage: $e');
    }
  }

  @override
  Future<bool> hasKey(String key) async {
    try {
      return sharedPreferences.containsKey(key);
    } catch (e) {
      throw CacheException('Failed to check key: $e');
    }
  }
}
