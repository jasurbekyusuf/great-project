import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the platform dialer pre-filled with [phone] via a `tel:` deep link.
///
/// The app never places the call itself — it hands off to the native dialer so
/// the user taps the green button. Spaces / dashes / parentheses are stripped
/// (a leading `+` is kept) so the scheme parses on every OEM dialer.
///
/// Returns `false` when there's no usable number or no app can handle the
/// intent, so the caller can surface a "no phone" message instead.
Future<bool> launchPhoneDial(String? phone) async {
  final raw = phone?.trim() ?? '';
  if (raw.isEmpty) return false;
  final sanitized = raw.replaceAll(RegExp('[^0-9+]'), '');
  if (sanitized.isEmpty) return false;
  final uri = Uri(scheme: 'tel', path: sanitized);
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('launchPhoneDial failed: $e');
    return false;
  }
}
