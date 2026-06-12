import 'package:flutter/material.dart';
import 'package:loadme_mobile/core/theme/figma_palette.dart';

/// One row of [showCardActionMenu].
class CardMenuAction {
  const CardMenuAction({
    required this.icon,
    required this.label,
    required this.onSelected,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onSelected;
  final bool destructive;
}

/// Figma-styled dropdown anchored to the widget at [context] (e.g. a card's
/// 3-dot button): white rounded card, hairline dividers, red destructive row.
/// Opens below the button and right-aligns to it.
Future<void> showCardActionMenu({
  required BuildContext context,
  required List<CardMenuAction> actions,
}) async {
  final button = context.findRenderObject()! as RenderBox;
  final overlay =
      Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
  final position = RelativeRect.fromRect(
    Rect.fromPoints(
      button.localToGlobal(Offset.zero, ancestor: overlay),
      button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
    ),
    Offset.zero & overlay.size,
  );

  final selected = await showMenu<int>(
    context: context,
    position: position,
    color: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 12,
    shadowColor: const Color(0x29101828),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    constraints: const BoxConstraints(minWidth: 180),
    items: [
      for (var i = 0; i < actions.length; i++) ...[
        if (i > 0) const PopupMenuDivider(height: 1),
        PopupMenuItem<int>(
          value: i,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _MenuRow(action: actions[i]),
        ),
      ],
    ],
  );
  if (selected != null) actions[selected].onSelected();
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.action});
  final CardMenuAction action;

  @override
  Widget build(BuildContext context) {
    final color =
        action.destructive ? FigmaPalette.dangerText : FigmaPalette.inkStrong;
    return Row(
      children: [
        Icon(action.icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text(
          action.label,
          style: TextStyle(
            fontSize: 14,
            height: 18 / 14,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
