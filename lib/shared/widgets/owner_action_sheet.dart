import 'package:flutter/material.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';

class OwnerAction {
  const OwnerAction({required this.icon, required this.label, required this.onTap, this.destructive = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
}

// Bottom sheet of context actions (Edit, Archive, Reactivate, Delete) used for
// owner rows in MyLoads / MyTrucks.
Future<void> showOwnerActionSheet(BuildContext context, {required String title, required List<OwnerAction> actions}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
    builder: (ctx) {
      final c = ctx.colors;
      final t = ctx.types;
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(color: c.gray300, borderRadius: BorderRadius.circular(999)),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Text(title, style: t.h3),
              ),
              const SizedBox(height: 4),
              ...actions.map((a) => InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      a.onTap();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
                      child: Row(
                        children: [
                          Icon(a.icon, size: 22, color: a.destructive ? c.error : c.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(a.label, style: t.bodyLgMedium.copyWith(color: a.destructive ? c.error : c.textPrimary)),
                          ),
                          Icon(Icons.chevron_right_rounded, color: c.textMuted, size: 20),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        ),
      );
    },
  );
}
