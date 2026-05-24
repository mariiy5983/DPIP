import 'dart:async';
import 'dart:math';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/core/preference.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

const int _kMinUpdateIntervalMs = 86400 * 1000; // 1 day

Future<void> updateInfoToServer() async {
  final latitude = Preference.locationLatitude;
  final longitude = Preference.locationLongitude;
  if (latitude == null || longitude == null) return;

  final token = Preference.notifyToken;
  if (token.isEmpty) return;

  final elapsed = DateTime.now().millisecondsSinceEpoch - (Preference.lastUpdateToServerTime ?? 0);
  if (elapsed <= _kMinUpdateIntervalMs) return;

  // 50% sampling
  if (Random().nextInt(2) != 0) return;

  try {
    ExpTech().updateDeviceLocation(
      token: token,
      coordinates: LatLng(latitude, longitude),
    );
  } catch (e) {
    print('Network info update failed: $e');
  }
}
