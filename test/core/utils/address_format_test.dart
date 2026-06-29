import 'package:flutter_test/flutter_test.dart';
import 'package:loadme_mobile/core/utils/address_format.dart';

void main() {
  group('addressCity / addressRegion', () {
    test('split a "City, Region" string on comma or middot', () {
      expect(addressCity('Shahrisabz, Qashqadaryo'), 'Shahrisabz');
      expect(addressRegion('Shahrisabz, Qashqadaryo'), 'Qashqadaryo');
      expect(addressCity('Chilonzor · Toshkent'), 'Chilonzor');
      expect(addressRegion('Chilonzor · Toshkent'), 'Toshkent');
    });

    test('a bare address is all city; region falls back', () {
      expect(addressCity('Jizzax viloyati'), 'Jizzax viloyati');
      expect(addressRegion('Jizzax viloyati'), ''); // no fallback
      expect(addressRegion('Jizzax viloyati', 'UZ'), 'UZ'); // fallback used
    });
  });

  // The Load Details route card (Figma 1711112375) shows "Region, COUNTRY"
  // under each city. addressRegion drops the country when a region exists, so
  // this composes the ISO code back on.
  group('addressRegionCountry', () {
    test('appends the country code after the region', () {
      expect(
        addressRegionCountry('Shahrisabz, Qashqadaryo', 'UZ'),
        'Qashqadaryo, UZ',
      );
      expect(
        addressRegionCountry('Petropavlovsk-Kamchatskiy, Kamchatka', 'RU'),
        'Kamchatka, RU',
      );
    });

    test('region-only address shows just the country', () {
      // Region-level pickups (no district) compose to a bare address, so the
      // city slot already carries the region and the sub-line is the country.
      expect(addressRegionCountry('Jizzax viloyati', 'UZ'), 'UZ');
    });

    test('degrades cleanly with no dangling separators', () {
      expect(addressRegionCountry('Toshkent, Toshkent', null), 'Toshkent');
      expect(addressRegionCountry('Toshkent, Toshkent', ''), 'Toshkent');
      expect(addressRegionCountry('Jizzax viloyati', null), '');
      expect(addressRegionCountry('', 'UZ'), 'UZ');
    });
  });
}
