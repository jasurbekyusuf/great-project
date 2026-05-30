import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';

// Mirrors web phone-reveal pattern used on Load and PostTruck detail pages:
// Phone number is masked behind a "Show phone" button. When pressed, tracks
// the reveal event and shows the full number + call action.
class PhoneReveal extends StatefulWidget {
  const PhoneReveal({
    super.key,
    required this.phone,
    this.onRevealed,
    this.onCall,
    this.label = 'Telefonni ko\'rsatish',
    this.callLabel = 'Qo\'ng\'iroq qilish',
  });

  final String phone;
  final VoidCallback? onRevealed;
  final ValueChanged<String>? onCall;
  final String label;
  final String callLabel;

  @override
  State<PhoneReveal> createState() => _PhoneRevealState();
}

class _PhoneRevealState extends State<PhoneReveal> {
  bool _revealed = false;

  String get _masked {
    final p = widget.phone;
    if (p.length < 6) return '••• •• ••';
    return '${p.substring(0, p.length - 6)} ${'•' * 2} ${'•' * 2} ${'•' * 2}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.types;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: c.primary50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.phone_rounded, color: c.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _revealed ? widget.phone : _masked,
              style: t.bodyLgMedium.copyWith(
                color: c.textPrimary,
                letterSpacing: _revealed ? 0.4 : 1.2,
              ),
            ),
          ),
          if (_revealed)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Copy',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.phone));
                  },
                  icon: Icon(Icons.copy_rounded, size: 18, color: c.textSecondary),
                ),
                Material(
                  color: c.primary,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => widget.onCall?.call(widget.phone),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(widget.callLabel, style: t.button.copyWith(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Material(
              color: c.primary,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  setState(() => _revealed = true);
                  widget.onRevealed?.call();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(widget.label, style: t.button.copyWith(color: Colors.white)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
