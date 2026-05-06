import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/diff_engine.dart';
import '../theme/app_theme.dart';

class DiffView extends StatelessWidget {
  final DiffResult? result;
  final bool isLoading;

  const DiffView({super.key, this.result, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
            ),
            const SizedBox(height: 12),
            Text('Computing differences...', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          ],
        ),
      );
    }

    if (result == null || result!.isEmpty) {
      return _EmptyState();
    }

    if (!result!.hasChanges) {
      return _NoDiffState();
    }

    return _DiffList(result: result!);
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.compare_arrows, size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'Paste or open files in the panels above',
            style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'The diff appears here in real time',
            style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.35), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _NoDiffState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 48, color: isDark ? AppTheme.addedFgDark : AppTheme.addedFgLight),
          const SizedBox(height: 16),
          Text(
            'Texts are identical',
            style: TextStyle(color: cs.onSurface, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'No differences found',
            style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _DiffList extends StatelessWidget {
  final DiffResult result;
  const _DiffList({required this.result});

  @override
  Widget build(BuildContext context) {
    final lines = result.lines;

    return ListView.builder(
      itemCount: lines.length,
      itemExtent: 22,
      itemBuilder: (context, index) => _DiffLineWidget(line: lines[index]),
    );
  }
}

class _DiffLineWidget extends StatelessWidget {
  final DiffLine line;
  const _DiffLineWidget({required this.line});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    final (bgColor, fgColor, marker, inlineBg) = switch (line.type) {
      DiffType.insert => (
          isDark ? AppTheme.addedBgDark : AppTheme.addedBgLight,
          isDark ? AppTheme.addedFgDark : AppTheme.addedFgLight,
          '+',
          isDark ? AppTheme.addedInlineDark : AppTheme.addedInlineLight,
        ),
      DiffType.delete => (
          isDark ? AppTheme.removedBgDark : AppTheme.removedBgLight,
          isDark ? AppTheme.removedFgDark : AppTheme.removedFgLight,
          '-',
          isDark ? AppTheme.removedInlineDark : AppTheme.removedInlineLight,
        ),
      DiffType.equal => (
          Colors.transparent,
          cs.onSurfaceVariant,
          ' ',
          Colors.transparent,
        ),
    };

    final lineNumStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 11,
      color: cs.onSurfaceVariant.withValues(alpha: line.type == DiffType.equal ? 0.4 : 0.7),
    );

    return Container(
      color: bgColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left line number
          SizedBox(
            width: 44,
            child: Text(
              line.leftLineNum?.toString() ?? '',
              textAlign: TextAlign.right,
              style: lineNumStyle,
            ),
          ),
          // Right line number
          SizedBox(
            width: 44,
            child: Text(
              line.rightLineNum?.toString() ?? '',
              textAlign: TextAlign.right,
              style: lineNumStyle,
            ),
          ),
          // Marker column
          SizedBox(
            width: 20,
            child: Text(
              marker,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: fgColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Content
          Expanded(
            child: line.inlineSegments != null
                ? _InlineContent(segments: line.inlineSegments!, fgColor: fgColor, inlineBg: inlineBg)
                : Text(
                    line.text,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: line.type == DiffType.equal ? cs.onSurface : fgColor,
                      height: 1,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _InlineContent extends StatelessWidget {
  final List<InlineSegment> segments;
  final Color fgColor;
  final Color inlineBg;

  const _InlineContent({required this.segments, required this.fgColor, required this.inlineBg});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: segments.map((seg) {
          return WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              color: seg.isChanged ? inlineBg : Colors.transparent,
              child: Text(
                seg.text,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: fgColor,
                  height: 1,
                ),
              ),
            ),
          );
        }).toList(),
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}

// Toolbar for the diff panel header
class DiffPanelHeader extends StatelessWidget {
  final DiffResult? result;
  final String originalText;
  final String modifiedText;

  const DiffPanelHeader({
    super.key,
    this.result,
    required this.originalText,
    required this.modifiedText,
  });

  void _copyDiff(BuildContext context) {
    if (result == null) return;
    final sb = StringBuffer();
    sb.writeln('--- original');
    sb.writeln('+++ modified');
    for (final line in result!.lines) {
      final marker = switch (line.type) {
        DiffType.insert => '+',
        DiffType.delete => '-',
        DiffType.equal => ' ',
      };
      sb.writeln('$marker${line.text}');
    }
    Clipboard.setData(ClipboardData(text: sb.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Diff copied to clipboard'), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final hasResult = result != null && result!.hasChanges;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: cs.outline)),
      ),
      child: Row(
        children: [
          Icon(Icons.difference_outlined, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            'Diff',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          if (hasResult) ...[
            const SizedBox(width: 12),
            _StatChip(
              label: '+${result!.addedLines}',
              color: isDark ? AppTheme.addedFgDark : AppTheme.addedFgLight,
            ),
            const SizedBox(width: 6),
            _StatChip(
              label: '-${result!.removedLines}',
              color: isDark ? AppTheme.removedFgDark : AppTheme.removedFgLight,
            ),
          ],
          const Spacer(),
          if (hasResult)
            Tooltip(
              message: 'Copy unified diff',
              child: InkWell(
                onTap: () => _copyDiff(context),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.copy_outlined, size: 16, color: cs.onSurfaceVariant),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
      ),
    );
  }
}
