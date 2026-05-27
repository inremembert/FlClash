import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:win32_registry/win32_registry.dart';

String? _windowsDeviceUaSuffix;
String? _windowsInstallUaSuffix;

String? get windowsInstallUaSuffix {
  if (!Platform.isWindows) return null;
  if (_windowsInstallUaSuffix != null) return _windowsInstallUaSuffix;

  try {
    final appData = Platform.environment['APPDATA'];
    if (appData == null || appData.isEmpty) return null;

    final file = File('$appData\\FlClash\\ua_install_id');
    if (file.existsSync()) {
      final installId = file.readAsStringSync().trim();
      if (RegExp(r'^[a-z0-9]{5}$').hasMatch(installId)) {
        _windowsInstallUaSuffix = installId;
        return _windowsInstallUaSuffix;
      }
    }

    final installId = _generateInstallId();
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(installId);
    _windowsInstallUaSuffix = installId;
    return _windowsInstallUaSuffix;
  } catch (_) {
    return null;
  }
}

String? get windowsDeviceUaSuffix {
  if (!Platform.isWindows) return null;
  if (_windowsDeviceUaSuffix != null) return _windowsDeviceUaSuffix;

  try {
    final key = Registry.openPath(
      RegistryHive.localMachine,
      path: r'SOFTWARE\Microsoft\Cryptography',
    );
    final machineGuid = key.getStringValue('MachineGuid')?.trim();
    key.close();

    if (machineGuid == null || machineGuid.isEmpty) return null;

    final deviceSeed = [
      machineGuid.toLowerCase(),
      Platform.localHostname.toLowerCase(),
    ].join('|');
    final digest = sha256.convert(utf8.encode(deviceSeed));
    _windowsDeviceUaSuffix = 'pc-${digest.toString().substring(0, 16)}';
    return _windowsDeviceUaSuffix;
  } catch (_) {
    return null;
  }
}

extension PackageInfoExtension on PackageInfo {
  String get ua => [
        'FlClash/v$version',
        'clash-verge',
        'Platform/${Platform.operatingSystem}',
        if (windowsDeviceUaSuffix case final deviceUaSuffix?)
          deviceUaSuffix,
        if (windowsInstallUaSuffix case final installUaSuffix?)
          installUaSuffix,
      ].join(' ');
}

String _generateInstallId() {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final random = _secureRandom();
  return List.generate(5, (_) => chars[random.nextInt(chars.length)]).join();
}

Random _secureRandom() {
  try {
    return Random.secure();
  } catch (_) {
    return Random();
  }
}
