import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Single source of truth for the Amman service area.
///
/// Every map screen restriction - the initial camera, the pannable bounds, the
/// zoom limits, search filtering and tap validation - reads from [ammanPolygon]
/// here, so widening or shrinking the delivery area later is a one-list edit
/// rather than a hunt through the UI code.
class AmmanBoundaryService {
  AmmanBoundaryService._();

  /// Approximate Greater Amman service area, ordered anticlockwise.
  ///
  /// A polygon rather than a radius because Amman is markedly wider east-west
  /// through Marka and Sahab than it is north-south, and a circle big enough to
  /// reach Sahab also swallows Zarqa. Vertices are deliberately coarse: this
  /// describes where drivers will collect, not the municipal border.
  static const List<LatLng> ammanPolygon = <LatLng>[
    LatLng(32.0900, 35.8700), // Abu Nsair / Shafa Badran, northern edge
    LatLng(32.0750, 35.9600), // north-east above Shafa Badran
    LatLng(32.0200, 36.0200), // east of Marka
    LatLng(31.9600, 36.0600), // eastern edge, north of Sahab
    LatLng(31.8800, 36.0600), // Sahab, south-east corner
    LatLng(31.8300, 36.0000), // southern edge
    LatLng(31.8000, 35.9000), // Umm Al Basateen / south Qwaysimah
    LatLng(31.8100, 35.8000), // Naour, south-west
    LatLng(31.8800, 35.7400), // west of Wadi Es Sir
    LatLng(31.9600, 35.7300), // western edge
    LatLng(32.0200, 35.7800), // north-west
    LatLng(32.0600, 35.8200), // back up towards Abu Nsair
  ];

  /// Whether ordering is restricted to the Amman polygon.
  ///
  /// Turned off by product decision: customers may now pick any location. While false the
  /// map pans anywhere, zooms out past the governorate, searches are not rewritten to
  /// ", Amman, Jordan", and the silent snap-back that pulled the pin home is inert.
  /// The polygon and its helpers are left intact so this is a one-line reversal.
  static const bool enforceServiceArea = false;

  /// Downtown Amman - the camera target before any GPS fix arrives.
  static const LatLng ammanCenter = LatLng(31.9539, 35.9106);

  /// Low enough to see the whole service area, high enough that neighbouring
  /// governorates never fill the screen and invite a pan attempt.
  static const double minZoom = 11.0;
  static const double maxZoom = 20.0;

  /// Default zoom when focusing a specific point (GPS fix, search result).
  static const double focusZoom = 15.0;

  /// Axis-aligned box around [ammanPolygon], derived rather than written out so
  /// it cannot drift away from the polygon when the polygon is edited.
  static final LatLngBounds ammanBounds = _computeBounds();

  /// Unbounded while the service area is off - a bounded camera stops the pan at the box
  /// edge, which reads as a frozen map rather than a refusal.
  static final CameraTargetBounds cameraTargetBounds = enforceServiceArea
      ? CameraTargetBounds(ammanBounds)
      : CameraTargetBounds.unbounded;

  /// minZoom 11 exists to keep neighbouring governorates off screen. With the restriction
  /// lifted that only prevents zooming out far enough to reach another city.
  static final MinMaxZoomPreference zoomPreference = enforceServiceArea
      ? const MinMaxZoomPreference(minZoom, maxZoom)
      : const MinMaxZoomPreference(3.0, maxZoom);

  static final LatLng _centroid = _computeCentroid();

  /// True when [location] falls inside the Amman service area.
  ///
  /// Standard ray casting: count how many polygon edges a ray cast east from
  /// the point crosses; an odd count means the point is enclosed.
  /// Whether ordering, panning and searching are permitted at [location].
  ///
  /// Answers "may the user act here", which is what the service-area flag governs. With the
  /// restriction off this is always true, switching every caller off at once rather than
  /// leaving ten call sites to drift apart. For "is this point actually in Amman" - which
  /// stays meaningful either way - use [isWithinPolygon].
  static bool isLocationInsideAmman(LatLng location) =>
      !enforceServiceArea || isWithinPolygon(location);

  /// The raw geometric test, independent of [enforceServiceArea].
  ///
  /// Used to decide where to *open* the map: a GPS fix on another continent is a poor place
  /// to start even when ordering there is allowed, so the camera still falls back to Amman.
  static bool isWithinPolygon(LatLng location) {
    final double lat = location.latitude;
    final double lng = location.longitude;
    bool inside = false;

    for (int i = 0, j = ammanPolygon.length - 1;
        i < ammanPolygon.length;
        j = i++) {
      final double latI = ammanPolygon[i].latitude;
      final double lngI = ammanPolygon[i].longitude;
      final double latJ = ammanPolygon[j].latitude;
      final double lngJ = ammanPolygon[j].longitude;

      // Edges that straddle the point's latitude are the only ones the ray can
      // cross; the second test asks whether the crossing lies to the east.
      final bool straddles = (latI > lat) != (latJ > lat);
      if (straddles &&
          lng < (lngJ - lngI) * (lat - latI) / (latJ - latI) + lngI) {
        inside = !inside;
      }
    }

    return inside;
  }

  /// The closest allowed point to [location], used to pull a strayed camera
  /// back rather than snapping it to the city centre - a small correction reads
  /// as a nudge, whereas teleporting downtown feels broken.
  static LatLng nearestPointInside(LatLng location) {
    if (isWithinPolygon(location)) return location;

    // Longitude degrees shrink towards the poles, so compare in a locally flat
    // projection or the "nearest" edge comes out wrong by ~15% at this latitude.
    final double lngScale = math.cos(_centroid.latitude * math.pi / 180.0);

    LatLng? closest;
    double closestDistance = double.infinity;

    for (int i = 0, j = ammanPolygon.length - 1;
        i < ammanPolygon.length;
        j = i++) {
      final LatLng candidate =
          _projectOntoSegment(location, ammanPolygon[j], ammanPolygon[i], lngScale);
      final double dLat = candidate.latitude - location.latitude;
      final double dLng = (candidate.longitude - location.longitude) * lngScale;
      final double distance = dLat * dLat + dLng * dLng;

      if (distance < closestDistance) {
        closestDistance = distance;
        closest = candidate;
      }
    }

    if (closest == null) return ammanCenter;

    // The projection lands exactly on the border, where the inside test is a
    // coin flip. Step a hair towards the centroid until it reads as inside.
    for (final double inset in <double>[0.002, 0.01, 0.05]) {
      final LatLng nudged = LatLng(
        closest.latitude + (_centroid.latitude - closest.latitude) * inset,
        closest.longitude + (_centroid.longitude - closest.longitude) * inset,
      );
      if (isWithinPolygon(nudged)) return nudged;
    }

    return ammanCenter;
  }

  /// Biases a free-text search towards Amman before it reaches the platform
  /// geocoder, which exposes no bounding-box or country parameter of its own.
  /// Results are still validated against the polygon afterwards - this only
  /// improves what comes back, it does not enforce anything.
  static String buildSearchQuery(String query) {
    final String trimmed = query.trim();

    // Without the restriction, appending ", Amman, Jordan" would drag every search back
    // into the city the user is trying to leave.
    if (!enforceServiceArea) return trimmed;

    final String lower = trimmed.toLowerCase();

    final bool alreadyScoped = lower.contains('amman') ||
        lower.contains('jordan') ||
        trimmed.contains('عمان') ||
        trimmed.contains('عمّان') ||
        trimmed.contains('الأردن');

    return alreadyScoped ? trimmed : '$trimmed, Amman, Jordan';
  }

  static LatLng _projectOntoSegment(
    LatLng point,
    LatLng start,
    LatLng end,
    double lngScale,
  ) {
    final double startX = start.longitude * lngScale;
    final double startY = start.latitude;
    final double endX = end.longitude * lngScale;
    final double endY = end.latitude;
    final double pointX = point.longitude * lngScale;
    final double pointY = point.latitude;

    final double dx = endX - startX;
    final double dy = endY - startY;
    final double lengthSquared = dx * dx + dy * dy;

    if (lengthSquared == 0) return start;

    // Clamped so the projection stays on the segment instead of running off
    // along the infinite line through it.
    final double t = (((pointX - startX) * dx + (pointY - startY) * dy) /
            lengthSquared)
        .clamp(0.0, 1.0);

    return LatLng(startY + dy * t, (startX + dx * t) / lngScale);
  }

  static LatLngBounds _computeBounds() {
    double minLat = ammanPolygon.first.latitude;
    double maxLat = ammanPolygon.first.latitude;
    double minLng = ammanPolygon.first.longitude;
    double maxLng = ammanPolygon.first.longitude;

    for (final LatLng point in ammanPolygon) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  static LatLng _computeCentroid() {
    double latSum = 0;
    double lngSum = 0;

    for (final LatLng point in ammanPolygon) {
      latSum += point.latitude;
      lngSum += point.longitude;
    }

    return LatLng(latSum / ammanPolygon.length, lngSum / ammanPolygon.length);
  }
}
