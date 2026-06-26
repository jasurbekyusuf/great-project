import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Month-grid calendar bottom sheet — Figma "Date picker menu" (6819:15324).
///
/// A white r12 card with a `‹ September 2026 ›` month header, a `Mo Tu We Th
/// Fr Sa Su` weekday row, and 5–6 week rows of date cells. The selected day is
/// a soft-blue (#EBF1FF) circle with #004EEA text; in-month days are #707071
/// and spill-over days from the neighbouring month are #ACACAD. A pinned blue
/// "Tayyor" button confirms and returns the chosen [DateTime] (null if
/// dismissed). Labels mirror the Figma mock exactly (English month/day names).
Future<DateTime?> showDsCalendarSheet(
  BuildContext context, {
  required DateTime initial,
  DateTime? minimum,
  DateTime? maximum,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFF6F7F9),
    barrierColor: Colors.black.withValues(alpha: 0.40),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) =>
        _CalendarSheet(initial: initial, minimum: minimum, maximum: maximum),
  );
}

const _monthNames = <String>[
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const _dayNames = <String>['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

const _kInk = Color(0xFF0C0C0C); // month + year label
const _kMuted = Color(0xFF707071); // weekday labels + in-month dates
const _kOutside = Color(0xFFACACAD); // spill-over (other month) dates
const _kSelBg = Color(0xFFEBF1FF); // selected day highlight
const _kSelFg = Color(0xFF004EEA); // selected day text
const _kBlue = Color(0xFF004EEA);

class _CalendarSheet extends StatefulWidget {
  const _CalendarSheet({required this.initial, this.minimum, this.maximum});
  final DateTime initial;
  final DateTime? minimum;
  final DateTime? maximum;

  @override
  State<_CalendarSheet> createState() => _CalendarSheetState();
}

class _CalendarSheetState extends State<_CalendarSheet> {
  late DateTime _view = DateTime(widget.initial.year, widget.initial.month);
  late DateTime _sel =
      DateTime(widget.initial.year, widget.initial.month, widget.initial.day);

  bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime? get _min => widget.minimum == null
      ? null
      : DateTime(
          widget.minimum!.year, widget.minimum!.month, widget.minimum!.day);
  DateTime? get _max => widget.maximum == null
      ? null
      : DateTime(
          widget.maximum!.year, widget.maximum!.month, widget.maximum!.day);

  bool _disabled(DateTime d) =>
      (_min != null && d.isBefore(_min!)) || (_max != null && d.isAfter(_max!));

  void _shiftMonth(int delta) =>
      setState(() => _view = DateTime(_view.year, _view.month + delta));

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1E4EA),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _monthHeader(),
                  const SizedBox(height: 8),
                  _dayNamesRow(),
                  const SizedBox(height: 4),
                  ..._weekRows(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _doneButton(),
          ],
        ),
      ),
    );
  }

  Widget _monthHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _navArrow(LucideIcons.chevronLeft, () => _shiftMonth(-1)),
          Expanded(
            child: Text(
              '${_monthNames[_view.month - 1]} ${_view.year}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w600,
                color: _kInk,
              ),
            ),
          ),
          _navArrow(LucideIcons.chevronRight, () => _shiftMonth(1)),
        ],
      ),
    );
  }

  Widget _navArrow(IconData icon, VoidCallback onTap) {
    return InkResponse(
      onTap: onTap,
      radius: 20,
      child: SizedBox(
        width: 24,
        height: 24,
        child: Icon(icon, size: 18, color: _kInk),
      ),
    );
  }

  Widget _dayNamesRow() {
    return Row(
      children: [
        for (final d in _dayNames)
          Expanded(
            child: Center(
              child: Text(
                d,
                style: const TextStyle(
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: FontWeight.w500,
                  color: _kMuted,
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _weekRows() {
    final first = DateTime(_view.year, _view.month, 1);
    final lead = (first.weekday + 6) % 7; // Monday-first offset
    final start = first.subtract(Duration(days: lead));
    final daysInMonth = DateTime(_view.year, _view.month + 1, 0).day;
    final rowsNeeded = ((lead + daysInMonth) / 7).ceil();

    final rows = <Widget>[];
    for (var w = 0; w < rowsNeeded; w++) {
      rows.add(Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: _dayCell(
                DateTime(start.year, start.month, start.day + w * 7 + i),
              ),
            ),
        ],
      ));
    }
    return rows;
  }

  Widget _dayCell(DateTime day) {
    final inMonth = day.month == _view.month && day.year == _view.year;
    final selected = _same(day, _sel);
    final disabled = _disabled(day);
    final color = selected
        ? _kSelFg
        : (inMonth && !disabled ? _kMuted : _kOutside);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: disabled
          ? null
          : () => setState(() {
                _sel = day;
                if (!inMonth) _view = DateTime(day.year, day.month);
              }),
      child: SizedBox(
        height: 40,
        child: Center(
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? _kSelBg : Colors.transparent,
            ),
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 16,
                height: 1,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _doneButton() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _kBlue,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D101828), offset: Offset(0, 1), blurRadius: 2),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.pop(context, _sel),
          child: Container(
            height: 48,
            alignment: Alignment.center,
            child: const Text(
              'Tayyor',
              style: TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
