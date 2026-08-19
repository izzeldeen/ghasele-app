import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:ghasele/services/amman_boundary_service.dart';

void main() {
  group('isLocationInsideAmman', () {
    test('accepts neighbourhoods inside the service area', () {
      const Map<String, LatLng> served = <String, LatLng>{
        'Sweifieh': LatLng(31.9500, 35.8600),
        'Abdoun': LatLng(31.9400, 35.8850),
        'Jubeiha': LatLng(32.0180, 35.8700),
        'Khalda': LatLng(31.9800, 35.8300),
        'Downtown': LatLng(31.9539, 35.9106),
      };

      served.forEach((String name, LatLng point) {
        expect(
          AmmanBoundaryService.isLocationInsideAmman(point),
          isTrue,
          reason: '$name should be inside Amman',
        );
      });
    });

    test('rejects other Jordanian cities', () {
      const Map<String, LatLng> unserved = <String, LatLng>{
        'Irbid': LatLng(32.5556, 35.8500),
        'Zarqa': LatLng(32.0728, 36.0880),
        'Aqaba': LatLng(29.5320, 35.0060),
        'Madaba': LatLng(31.7160, 35.7950),
        'Salt': LatLng(32.0392, 35.7272),
      };

      unserved.forEach((String name, LatLng point) {
        expect(
          AmmanBoundaryService.isLocationInsideAmman(point),
          isFalse,
          reason: '$name should be outside Amman',
        );
      });
    });
  });

  group('nearestPointInside', () {
    test('leaves an already valid point untouched', () {
      const LatLng abdoun = LatLng(31.9400, 35.8850);
      expect(AmmanBoundaryService.nearestPointInside(abdoun), abdoun);
    });

    test('pulls an outside point back into the polygon', () {
      const LatLng zarqa = LatLng(32.0728, 36.0880);
      final LatLng corrected = AmmanBoundaryService.nearestPointInside(zarqa);

      expect(AmmanBoundaryService.isLocationInsideAmman(corrected), isTrue);
    });

    test('corrects to the nearest edge rather than the city centre', () {
      // Just east of the Sahab boundary: the fix should stay in the east of the
      // city, otherwise a small overshoot would teleport the user downtown.
      const LatLng justOutside = LatLng(31.9200, 36.0900);
      final LatLng corrected =
          AmmanBoundaryService.nearestPointInside(justOutside);

      expect(AmmanBoundaryService.isLocationInsideAmman(corrected), isTrue);
      expect(corrected.longitude, greaterThan(36.0));
    });
  });

  group('buildSearchQuery', () {
    test('scopes a bare neighbourhood name to Amman', () {
      expect(
        AmmanBoundaryService.buildSearchQuery('Sweifieh'),
        'Sweifieh, Amman, Jordan',
      );
    });

    test('does not duplicate scoping the user already typed', () {
      expect(
        AmmanBoundaryService.buildSearchQuery('Abdoun, Amman'),
        'Abdoun, Amman',
      );
      expect(
        AmmanBoundaryService.buildSearchQuery('الصويفية، عمّان'),
        'الصويفية، عمّان',
      );
    });
  });

  group('camera restrictions', () {
    test('bounds enclose the whole polygon', () {
      final LatLngBounds bounds = AmmanBoundaryService.ammanBounds;

      for (final LatLng point in AmmanBoundaryService.ammanPolygon) {
        expect(bounds.contains(point), isTrue);
      }
    });

    test('bounds exclude neighbouring governorates', () {
      final LatLngBounds bounds = AmmanBoundaryService.ammanBounds;

      expect(bounds.contains(const LatLng(32.5556, 35.8500)), isFalse); // Irbid
      expect(bounds.contains(const LatLng(32.0728, 36.0880)), isFalse); // Zarqa
    });
  });
}
