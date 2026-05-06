import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class EditorPanel extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  const EditorPanel({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    this.onChanged,
  });

  @override
  State<EditorPanel> createState() => _EditorPanelState();
}

class _EditorPanelState extends State<EditorPanel> {
  bool _isDragOver = false;
  String? _fileName;

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'txt', 'md', 'dart', 'py', 'js', 'ts', 'json', 'yaml', 'yml',
        'xml', 'html', 'css', 'java', 'kt', 'swift', 'go', 'rs', 'cpp',
        'c', 'h', 'sh', 'toml', 'ini', 'conf', 'log', 'csv', 'sql',
      ],
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      String content;
      try {
        if (file.bytes != null) {
          content = String.fromCharCodes(file.bytes!);
        } else if (file.path != null) {
          content = await File(file.path!).readAsString();
        } else {
          return;
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not read file — it may be binary or corrupted.')),
          );
        }
        return;
      }
      setState(() => _fileName = file.name);
      widget.controller.text = content;
      widget.onChanged?.call(content);
    }
  }

  void _clear() {
    widget.controller.clear();
    setState(() => _fileName = null);
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Panel header
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            border: Border(bottom: BorderSide(color: cs.outline)),
          ),
          child: Row(
            children: [
              Icon(
                widget.label == 'Original'
                    ? Icons.article_outlined
                    : Icons.edit_document,
                size: 14,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              if (_fileName != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '— $_fileName',
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const Spacer(),
              _HeaderButton(
                icon: Icons.folder_open_outlined,
                tooltip: 'Open file',
                onTap: _pickFile,
              ),
              const SizedBox(width: 4),
              _HeaderButton(
                icon: Icons.clear,
                tooltip: 'Clear',
                onTap: widget.controller.text.isEmpty ? null : _clear,
              ),
            ],
          ),
        ),

        // Text area
        Expanded(
          child: DragTarget<String>(
            onWillAcceptWithDetails: (_) {
              setState(() => _isDragOver = true);
              return true;
            },
            onLeave: (_) => setState(() => _isDragOver = false),
            onAcceptWithDetails: (details) {
              setState(() => _isDragOver = false);
              widget.controller.text = details.data;
              widget.onChanged?.call(details.data);
            },
            builder: (context, candidateData, rejectedData) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: _isDragOver
                      ? cs.primary.withValues(alpha: 0.08)
                      : (isDark
                          ? const Color(0xFF0D1117)
                          : const Color(0xFFFAFAFA)),
                  border: _isDragOver
                      ? Border.all(color: cs.primary, width: 2)
                      : null,
                ),
                child: TextField(
                  controller: widget.controller,
                  onChanged: widget.onChanged,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.5,
                    color: cs.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: _isDragOver
                        ? 'Drop here...'
                        : widget.hintText,
                    hintStyle: TextStyle(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              );
            },
          ),
        ),

        // Line count footer
        ValueListenableBuilder(
          valueListenable: widget.controller,
          builder: (context, value, _) {
            final text = value.text;
            final lines = text.isEmpty
                ? 0
                : text.endsWith('\n')
                    ? text.split('\n').length - 1
                    : text.split('\n').length;
            final chars = text.length;
            return Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                border: Border(top: BorderSide(color: cs.outline)),
              ),
              alignment: Alignment.centerRight,
              child: Text(
                '$lines lines  ·  $chars characters',
                style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _HeaderButton({required this.icon, required this.tooltip, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            size: 16,
            color: onTap == null
                ? cs.onSurfaceVariant.withValues(alpha: 0.3)
                : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
