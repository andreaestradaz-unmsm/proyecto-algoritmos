import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoIcons;
import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_theme.dart';
import 'glass_card.dart';

/// Estado vacío en cristal translúcido **Liquid Glass** consistente con la
/// estética del reproductor principal.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.structureBadge,
    this.actionLabel,
    this.onAction,
    this.accentColor,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? structureBadge;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: GlassCard(
            borderRadius: 30,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (structureBadge != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.pureWhite.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppTheme.pureWhite.withValues(alpha: 0.28),
                        width: 0.85,
                      ),
                    ),
                    child: Text(
                      structureBadge!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.pureWhite,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.pureWhite.withValues(alpha: 0.12),
                    border: Border.all(
                      color: AppTheme.pureWhite.withValues(alpha: 0.28),
                      width: 1.0,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: AppTheme.pureWhite,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.pureWhite,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: AppTheme.pureWhite.withValues(alpha: 0.72),
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: onAction,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.pureWhite.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppTheme.pureWhite.withValues(alpha: 0.42),
                          width: 0.9,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.add,
                            size: 16,
                            color: AppTheme.pureWhite,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            actionLabel!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: AppTheme.pureWhite,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
