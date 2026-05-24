import 'dart:math';

import 'package:dpip/api/model/location/location.dart';
import 'package:dpip/api/model/wave_time.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/extensions/iterable.dart';
import 'package:dpip/utils/extensions/latlng.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

const double ln10 = 2.302585092994046; // Math.log(10)

/// Cached `(int depth, original key string)` pairs from [Global.timeTable].
///
/// The travel-time table keys never change at runtime, so we parse them once
/// and reuse the result for every EEW tick.
List<({int depth, String key})>? _depthKeyCache;

/// Returns the travel-time table whose depth key is closest to [depth].
List<({double P, double R, double S})> _closestTable(double depth) {
  final cache = _depthKeyCache ??= List.unmodifiable(
    Global.timeTable.keys.map((k) => (depth: int.parse(k), key: k)),
  );

  var best = cache.first;
  var bestDist = (best.depth - depth).abs();
  for (var i = 1; i < cache.length; i++) {
    final entry = cache[i];
    final d = (entry.depth - depth).abs();
    if (d < bestDist) {
      bestDist = d;
      best = entry;
    }
  }
  return Global.timeTable[best.key]!;
}

({double p, double s, double sT}) calcWaveRadius(
  double depth,
  int time,
  int now,
) {
  double pDist = 0;
  double sDist = 0;
  double sT = 0;

  final double t = (now - time) / 1000.0;

  final timeTable = _closestTable(depth);
  ({double P, double R, double S})? prevTable;

  for (final table in timeTable) {
    if (pDist == 0 && table.P > t) {
      if (prevTable != null) {
        final double tDiff = table.P - prevTable.P;
        final double rDiff = table.R - prevTable.R;
        final double tOffset = t - prevTable.P;
        final double rOffset = (tOffset / tDiff) * rDiff;
        pDist = prevTable.R + rOffset;
      } else {
        pDist = table.R;
      }
    }

    if (sDist == 0 && table.S > t) {
      if (prevTable != null) {
        final double tDiff = table.S - prevTable.S;
        final double rDiff = table.R - prevTable.R;
        final double tOffset = t - prevTable.S;
        final double rOffset = (tOffset / tDiff) * rDiff;
        sDist = prevTable.R + rOffset;
      } else {
        sDist = table.R;
        sT = table.S;
      }
    }

    if (pDist != 0 && sDist != 0) break;
    prevTable = table;
  }

  if (pDist < 0) pDist = 0;
  if (sDist < 0) sDist = 0;

  return (p: pDist, s: sDist, sT: sT);
}

int findClosest(List<int> arr, double target) {
  return arr.reduce(
    (prev, curr) => (curr - target).abs() < (prev - target).abs() ? curr : prev,
  );
}

Map<String, dynamic> eewAreaPga(
  double lat,
  double lon,
  double depth,
  double mag,
  Map<String, Location> region,
) {
  final Map<String, dynamic> json = {};
  double eewMaxI = 0.0;

  // Hoist epicenter + magnitude-dependent factors out of the per-region loop
  // (region can have hundreds of entries).
  final epicenter = LatLng(lat, lon);
  final depthSq = depth * depth;
  final pgaScale = 1.657 * exp(1.533 * mag);

  region.forEach((String key, Location info) {
    final double distSurface = epicenter.to(LatLng(info.lat, info.lng)) / 1000;
    final double dist = sqrt(distSurface * distSurface + depthSq);
    final double pga = pgaScale * pow(dist, -1.607);
    double i = pgaToFloat(pga);
    if (i >= 4.5) {
      i = eewAreaPgv([lat, lon], [info.lat, info.lng], depth, mag);
    }
    if (i > eewMaxI) eewMaxI = i;
    json[key] = {'dist': dist, 'i': i};
  });

  json['max_i'] = eewMaxI;
  return json;
}

double eewAreaPgv(
  List<double> epicenterLocation,
  List<double> pointLocation,
  double depth,
  double magW,
) {
  // Compute pow(10, 0.5*magW) once and reuse for `long` and the gpv600 term.
  // long = pow(10, 0.5*magW - 1.85) / 2 = tenHalfMag * pow(10, -1.85) / 2.
  final double tenHalfMag = pow(10, 0.5 * magW).toDouble();
  final double long = tenHalfMag * 0.014125375446227544 / 2;
  final double epicenterDistance = epicenterLocation.asLatLng.to(pointLocation.asLatLng) / 1000;
  final double hypocenterDistance =
      sqrt(depth * depth + epicenterDistance * epicenterDistance) - long;
  final double x = max(hypocenterDistance, 3);
  final double gpv600 = pow(
    10,
    0.58 * magW + 0.0038 * depth - 1.29 - log(x + 0.0028 * tenHalfMag) / ln10 - 0.002 * x,
  ).toDouble();
  final double pgv400 = gpv600 * 1.31;
  return 2.68 + 1.72 * log(pgv400) / ln10;
}

double sWaveTimeByDistance(double depth, double sDist) {
  double sTime = 0.0;

  final timeTable = _closestTable(depth);
  ({double P, double R, double S})? prevTable;

  for (final table in timeTable) {
    if (sTime == 0 && table.R >= sDist) {
      if (prevTable != null) {
        final double rDiff = table.R - prevTable.R;
        final double tDiff = table.S - prevTable.S;
        final double rOffset = sDist - prevTable.R;
        final double tOffset = (rOffset / rDiff) * tDiff;
        sTime = prevTable.S + tOffset;
      } else {
        sTime = table.S;
      }
    }

    if (sTime != 0) break;
    prevTable = table;
  }

  return sTime * 1000;
}

double pWaveTimeByDistance(double depth, double pDist) {
  double pTime = 0.0;

  final timeTable = _closestTable(depth);
  ({double P, double R, double S})? prevTable;

  for (final table in timeTable) {
    if (pTime == 0 && table.R >= pDist) {
      if (prevTable != null) {
        final double rDiff = table.R - prevTable.R;
        final double tDiff = table.P - prevTable.P;
        final double rOffset = pDist - prevTable.R;
        final double tOffset = (rOffset / rDiff) * tDiff;
        pTime = prevTable.P + tOffset;
      } else {
        pTime = table.P;
      }
    }

    if (pTime != 0) break;
    prevTable = table;
  }

  return pTime * 1000;
}

double pgaToFloat(double pga) => 2 * log(pga) / ln10 + 0.7;

int pgaToIntensity(double pga) => intensityFloatToInt(pgaToFloat(pga));

int intensityFloatToInt(double floatValue) {
  if (floatValue < 0.5) return 0;
  if (floatValue < 1.5) return 1;
  if (floatValue < 2.5) return 2;
  if (floatValue < 3.5) return 3;
  if (floatValue < 4.5) return 4;
  if (floatValue < 5.0) return 5; // 5弱
  if (floatValue < 5.5) return 6; // 5強
  if (floatValue < 6.0) return 7; // 6弱
  if (floatValue < 6.5) return 8; // 6強
  return 9; // 7
}

String intensityToNumberString(int level) => switch (level) {
  5 => '5⁻',
  6 => '5⁺',
  7 => '6⁻',
  8 => '6⁺',
  9 => '7',
  _ => level.toString(),
};

/// Cached sqrt(3), used as the S/P time ratio (see derivation in [calculateWaveTime]).
final double _sqrt3 = sqrt(3);

WaveTime calculateWaveTime(double depth, double distance) {
  final double za = depth;
  final double xb = distance;

  final double g0;
  final double G;
  if (depth <= 40) {
    g0 = 5.10298;
    G = 0.06659;
  } else {
    g0 = 7.804799;
    G = 0.004573;
  }

  final double g0OverG = g0 / G;
  final double zc = -g0OverG;
  final double xc = (xb * xb - 2 * g0OverG * za - za * za) / (2 * xb);

  double thetaA = atan((za - zc) / xc);
  if (thetaA < 0) thetaA += pi;
  thetaA = pi - thetaA;
  final double thetaB = atan(-zc / (xb - xc));
  double ptime = (1 / G) * log(tan(thetaA / 2) / tan(thetaB / 2));

  // S-wave: g0_ = g0/sqrt(3), g_ = G/sqrt(3), so g0_/g_ == g0/G, meaning
  // zc_ == zc, xc_ == xc, and both thetas are identical to the P branch.
  // Therefore stime = (1/g_) * log_arg = (sqrt(3)/G) * log_arg = sqrt(3) * ptime.
  double stime = ptime * _sqrt3;

  if (distance / ptime > 7) ptime = distance / 7;
  if (distance / stime > 4) stime = distance / 4;
  return WaveTime(p: ptime, s: stime);
}

({double dist, double i}) eewLocationInfo(
  double mag,
  double depth,
  double eqLat,
  double eqLng,
  double userLat,
  double userLon,
) {
  final distSurface = LatLng(eqLat, eqLng).to(LatLng(userLat, userLon)) / 1000;
  final dist = sqrt(distSurface * distSurface + depth * depth);
  final pga = 1.657 * exp(1.533 * mag) * pow(dist, -1.607);
  var intensity = pgaToFloat(pga);
  if (intensity >= 4.5) {
    intensity = eewAreaPgv([eqLat, eqLng], [userLat, userLon], depth, mag);
  }
  return (dist: dist, i: intensity);
}
