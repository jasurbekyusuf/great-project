/// Helpers for splitting a "City, Region, Country" address string.
///
/// The separator regex is compiled once (module-level) rather than per call —
/// these run for every card in a scrolling list.
final RegExp _separator = RegExp('[,·]');

/// City = the text before the first comma / middot separator.
String addressCity(String address) => address.split(_separator).first.trim();

/// Region = everything after the city, or [fallback] when the address is a
/// bare city (keeps the two-line route layout intact).
String addressRegion(String address, [String fallback = '']) {
  final parts = address.split(_separator);
  return parts.length > 1 ? parts.sublist(1).join(',').trim() : fallback;
}

/// Route-stop sub-line: "Region, COUNTRY" (e.g. "Qashqadaryo, UZ"), matching
/// the Figma load-details design which always shows the ISO country code after
/// the region.
///
/// [addressRegion] on its own *drops* the country whenever a region is present
/// (the country is only its bare-city fallback), so the code is re-appended
/// here. Degrades cleanly: a region-only address yields just the country, a
/// bare country just the region, and an empty input an empty string — never a
/// dangling ", " fragment.
String addressRegionCountry(String address, [String? country]) {
  final region = addressRegion(address);
  final code = (country ?? '').trim();
  if (region.isNotEmpty && code.isNotEmpty) return '$region, $code';
  return region.isNotEmpty ? region : code;
}
