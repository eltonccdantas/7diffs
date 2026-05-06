import 'package:flutter/material.dart';
import '../core/diff_engine.dart';
import '../theme/app_theme.dart';

class DiffCounterBadge extends StatelessWidget {
  final DiffResult? result;
  final bool isLoading;

  const DiffCounterBadge({super.key, this.result, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (isLoading || result == null) {
      return const SizedBox(height: 48);
    }

    final hunks = result!.hunkCount;
    final isExactlySeven = hunks == 7;
    final hasChanges = result!.hasChanges;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: cs.outline),
          bottom: BorderSide(color: cs.outline),
        ),
      ),
      child: Row(
        children: [
          // Hunk counter
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: hasChanges
                ? _HunkBadge(
                    key: ValueKey(hunks),
                    count: hunks,
                    isExactlySeven: isExactlySeven,
                    isDark: isDark,
                  )
                : const SizedBox.shrink(),
          ),
          if (hasChanges) const SizedBox(width: 12),
          // Description text
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: hasChanges
                  ? Text(
                      key: ValueKey('$hunks-${result!.addedLines}-${result!.removedLines}'),
                      _buildDescription(hunks, result!, isExactlySeven),
                      style: TextStyle(
                        fontSize: 12,
                        color: isExactlySeven
                            ? AppTheme.brand
                            : cs.onSurfaceVariant,
                        fontWeight: isExactlySeven ? FontWeight.w600 : FontWeight.normal,
                      ),
                    )
                  : Text(
                      key: const ValueKey('identical'),
                      result!.isEmpty ? '' : 'Texts are identical — no differences found',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.addedFgDark
                            : AppTheme.addedFgLight,
                      ),
                    ),
            ),
          ),
          // Line stats
          if (hasChanges) ...[
            _LineStatBadge(
              label: '+${result!.addedLines}',
              color: isDark ? AppTheme.addedFgDark : AppTheme.addedFgLight,
            ),
            const SizedBox(width: 6),
            _LineStatBadge(
              label: '-${result!.removedLines}',
              color: isDark ? AppTheme.removedFgDark : AppTheme.removedFgLight,
            ),
          ],
        ],
      ),
    );
  }

  String _buildDescription(int hunks, DiffResult result, bool isExactlySeven) {
    final hunkWord = hunks == 1 ? 'block' : 'blocks';
    if (isExactlySeven) {
      return '🎯 7 differences found! You found all 7 errors!';
    }
    return '$hunks $hunkWord of difference  ·  ${result.unchangedLines} unchanged lines';
  }
}

class _HunkBadge extends StatelessWidget {
  final int count;
  final bool isExactlySeven;
  final bool isDark;

  const _HunkBadge({
    super.key,
    required this.count,
    required this.isExactlySeven,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = isExactlySeven
        ? AppTheme.brand
        : (isDark ? AppTheme.brandLight : AppTheme.brand);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isExactlySeven ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'diff${count == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LineStatBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _LineStatBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
