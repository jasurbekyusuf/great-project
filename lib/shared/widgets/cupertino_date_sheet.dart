import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loadme_mobile/core/services/app_l10n.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';

// iOS-style 3-column date / time picker shown as a modal bottom sheet.
// Mirrors the Figma `Add load_date` mock: bold "Date" title, 3 wheel columns
// (day / month / year for date; hours / minutes for time).
Future<DateTime?> showCupertinoDateSheet(BuildContext context, {
  required DateTime initial,
  String? title,
  DateTime? minimum,
  DateTime? maximum,
  CupertinoDatePickerMode mode = CupertinoDatePickerMode.date,
}) {
  var picked = initial;
  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (ctx) {
      final c = ctx.colors;
      final t = ctx.types;
      final l10n = ProviderScope.containerOf(ctx, listen: false).read(
        appL10nProvider,
      );
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: c.gray300, borderRadius: BorderRadius.circular(999)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(title ?? l10n.tr('common.date'), style: t.h2),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: Theme.of(ctx).brightness,
                    primaryColor: c.primary,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: t.bodyLgMedium.copyWith(color: c.textPrimary),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    initialDateTime: initial,
                    minimumDate: minimum,
                    maximumDate: maximum,
                    mode: mode,
                    use24hFormat: true,
                    onDateTimeChanged: (v) => picked = v,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l10n.tr('common.cancel')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, picked),
                      child: Text(l10n.tr('common.confirm')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<TimeOfDay?> showCupertinoTimeSheet(BuildContext context, {
  required TimeOfDay initial,
  String? title,
}) async {
  final resolvedTitle = title ??
      ProviderScope.containerOf(context, listen: false)
          .read(appL10nProvider)
          .tr('common.time');
  final now = DateTime.now();
  final initialDate = DateTime(now.year, now.month, now.day, initial.hour, initial.minute);
  final picked = await showCupertinoDateSheet(
    context,
    initial: initialDate,
    title: resolvedTitle,
    mode: CupertinoDatePickerMode.time,
  );
  if (picked == null) return null;
  return TimeOfDay(hour: picked.hour, minute: picked.minute);
}
