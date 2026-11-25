import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ScreenTimeSnapshot {
  const ScreenTimeSnapshot({required this.available, this.minutes});
  final bool available;
  final int? minutes;
}

/// Android screen-time capabilities owned by the Fitrah launcher channel.
class ScreenTimeService {
  static const MethodChannel _channel = MethodChannel('fitrah_launcher/apps');

  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> hasUsageAccess() async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>('checkUsageStatsPermission') ??
          false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> hasOverlayAccess() async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>('checkOverlayPermission') ??
          false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> cueAvailable({required bool optedIn}) async {
    if (!optedIn || !supported) return false;
    return await hasUsageAccess() && await hasOverlayAccess();
  }

  Future<bool> openUsageSettings() => _open('openUsageStatsSettings');
  Future<bool> openOverlaySettings() => _open('openOverlaySettings');

  Future<bool> _open(String method) async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>(method) ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<ScreenTimeSnapshot> today() async {
    if (!supported || !await hasUsageAccess()) {
      return const ScreenTimeSnapshot(available: false);
    }
    try {
      final minutes = await _channel.invokeMethod<int>(
        'getTodayScreenTimeMinutes',
      );
      return minutes == null
          ? const ScreenTimeSnapshot(available: false)
          : ScreenTimeSnapshot(available: true, minutes: minutes);
    } on PlatformException {
      return const ScreenTimeSnapshot(available: false);
    }
  }

  Future<bool> sync({required bool cueEnabled}) async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>('syncScreenTimeCue', {
            'enabled': cueEnabled,
          }) ??
          false;
    } on PlatformException {
      // A revoked permission or unavailable window must fail open.
      return false;
    }
  }
}
