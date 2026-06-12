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
