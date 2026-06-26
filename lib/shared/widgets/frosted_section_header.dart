import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Figma section header ("Header", 375×96) shared across the profile
/// sub-screens (Chat, Qo'llanmalar, Saqlanganlar, …) so they stay identical.
///
/// A frosted white-@48% surface with a 24px rounded bottom and a soft
/// #000000-@8% drop shadow. The 24px-tall nav row sits 12px below the status
/// bar and 16px above the header's bottom edge; the title is optically centred
/// between the leading back chevron and a 24px trailing slot (invisible by
/// default — mirroring the Figma bookmark placeholder so the title stays
/// centred).
class FrostedSectionHeader extends StatelessWidget {
  const FrostedSectionHeader({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
  });

  final String title;

  /// Defaults to `context.pop()` (these screens are always pushed).
  final VoidCallback? onBack;

  /// Optional 24×24 trailing action; an invisible placeholder when null.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0x7AFFFFFF), // white @ 48%
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000), // #000000 @ 8%
            offset: Offset(0, 2),
            blurRadius: 14,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: SizedBox(
            height: 24,
            child: Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onBack ?? () => context.pop(),
                  child: const Icon(LucideIcons.chevronLeft,
                      size: 24, color: Color(0xFF000000)),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 24 / 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF101828),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 24, height: 24, child: trailing),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
