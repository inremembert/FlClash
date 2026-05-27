import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:fl_clash/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constant.dart';

class Preferences {
  static Preferences? _instance;
  Completer<SharedPreferences?> sharedPreferencesCompleter = Completer();

  Future<bool> get isInit async =>
      await sharedPreferencesCompleter.future != null;

  Preferences._internal() {
    SharedPreferences.getInstance()
        .then((value) => sharedPreferencesCompleter.complete(value))
        .onError((_, _) => sharedPreferencesCompleter.complete(null));
  }

  factory Preferences() {
    _instance ??= Preferences._internal();
    return _instance!;
  }

  Future<int> getVersion() async {
    final preferences = await sharedPreferencesCompleter.future;
    return preferences?.getInt('version') ?? 0;
  }

  Future<void> setVersion(int version) async {
    final preferences = await sharedPreferencesCompleter.future;
    await preferences?.setInt('version', version);
  }

  Future<String?> getOrCreateUaInstallId() async {
    final preferences = await sharedPreferencesCompleter.future;
    const key = 'uaInstallId';
    final installId = preferences?.getString(key);
    if (installId != null && installId.isNotEmpty) {
      return installId;
    }

    final newInstallId = _uuidV4();
    await preferences?.setString(key, newInstallId);
    return newInstallId;
  }

  Future<void> saveShareState(SharedState shareState) async {
    final preferences = await sharedPreferencesCompleter.future;
    await preferences?.setString('sharedState', json.encode(shareState));
  }

  Future<Map<String, Object?>?> getConfigMap() async {
    try {
      final preferences = await sharedPreferencesCompleter.future;
      final configString = preferences?.getString(configKey);
      if (configString == null) return null;
      final Map<String, Object?>? configMap = json.decode(configString);
      return configMap;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, Object?>?> getClashConfigMap() async {
    try {
      final preferences = await sharedPreferencesCompleter.future;
      final clashConfigString = preferences?.getString(clashConfigKey);
      if (clashConfigString == null) return null;
      return json.decode(clashConfigString);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearClashConfig() async {
    try {
      final preferences = await sharedPreferencesCompleter.future;
      await preferences?.remove(clashConfigKey);
      return;
    } catch (_) {
      return;
    }
  }

  Future<Config?> getConfig() async {
    final configMap = await getConfigMap();
    if (configMap == null) {
      return null;
    }
    return Config.fromJson(configMap);
  }

  Future<bool> saveConfig(Config config) async {
    final preferences = await sharedPreferencesCompleter.future;
    return preferences?.setString(configKey, json.encode(config)) ?? false;
  }

  Future<void> clearPreferences() async {
    final sharedPreferencesIns = await sharedPreferencesCompleter.future;
    await sharedPreferencesIns?.clear();
  }
}

final preferences = Preferences();

String _uuidV4() {
  final random = _secureRandom();
  final bytes = List.generate(16, (_) => random.nextInt(256));

  bytes[6] = (bytes[6] & 0x0F) | 0x40;
  bytes[8] = (bytes[8] & 0x3F) | 0x80;

  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();

  return [
    hex.substring(0, 8),
    hex.substring(8, 12),
    hex.substring(12, 16),
    hex.substring(16, 20),
    hex.substring(20, 32),
  ].join('-');
}

Random _secureRandom() {
  try {
    return Random.secure();
  } catch (_) {
    return Random();
  }
}
