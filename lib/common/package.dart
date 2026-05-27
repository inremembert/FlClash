import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:win32_registry/win32_registry.dart';

String? _windowsDeviceUaSuffix;

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
      ].join(' ');
}
