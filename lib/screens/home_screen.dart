import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/diff_engine.dart';
import '../widgets/editor_panel.dart';
import '../widgets/diff_view.dart';
import '../widgets/diff_counter_badge.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;

  const HomeScreen({
    super.key,
    required this.onToggleTheme,
    required this.themeMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final _originalCtrl = TextEditingController();
  final _modifiedCtrl = TextEditingController();

  DiffResult? _diffResult;
  bool _isLoading = false;
  String _appVersion = '';
  Timer? _debounceTimer;

  // Mobile tab controller
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _appVersion = 'v${info.version}');
    }).catchError((_) {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showWelcomeModal();
    });
  }

  void _showWelcomeModal() {
    final scheme = Theme.of(context).colorScheme;
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (ctx, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeIn,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
      pageBuilder: (ctx, anim, __) => _WelcomeDialog(scheme: scheme, appVersion: _appVersion),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _originalCtrl.dispose();
    _modifiedCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _scheduleDiff() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), _runDiff);
  }

  Future<void> _runDiff() async {
    final original = _originalCtrl.text;
    final modified = _modifiedCtrl.text;

    if (original.isEmpty && modified.isEmpty) {
      setState(() {
        _diffResult = null;
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await compute(runDiffInIsolate, (
        original: original,
        modified: modified,
      ));
      if (mounted) {
        setState(() {
          _diffResult = result;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearAll() {
    _originalCtrl.clear();
    _modifiedCtrl.clear();
    setState(() => _diffResult = null);
  }

  void _showSupportDialog(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SupportSheet(scheme: scheme),
    );
  }

  void _swapPanels() {
    final tmp = _originalCtrl.text;
    _originalCtrl.text = _modifiedCtrl.text;
    _modifiedCtrl.text = tmp;
    _runDiff();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 720;
    return Scaffold(
      appBar: _buildAppBar(context),
      body: isWide ? _buildWideLayout() : _buildNarrowLayout(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isDark = widget.themeMode == ThemeMode.dark;

    return AppBar(
      toolbarHeight: 48,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.brand,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(
              child: Text(
                '7',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'diffs',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      actions: [
        Tooltip(
          message: 'Swap panels',
          child: IconButton(
            icon: const Icon(Icons.swap_horiz, size: 20),
            onPressed: _swapPanels,
          ),
        ),
        Tooltip(
          message: 'Clear all',
          child: IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, size: 20),
            onPressed: _clearAll,
          ),
        ),
        Tooltip(
          message: isDark ? 'Light mode' : 'Dark mode',
          child: IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 20,
            ),
            onPressed: widget.onToggleTheme,
          ),
        ),
        Tooltip(
          message: 'Support',
          child: IconButton(
            icon: const Icon(Icons.favorite_border, size: 20),
            onPressed: () => _showSupportDialog(context),
          ),
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: Theme.of(context).colorScheme.outline),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Column(
      children: [
        // Input panels
        Expanded(
          flex: 4,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: EditorPanel(
                  label: 'Original',
                  controller: _originalCtrl,
                  hintText: 'Paste original text here…',
                  onChanged: (_) => _scheduleDiff(),
                ),
              ),
              _VerticalDivider(),
              Expanded(
                child: EditorPanel(
                  label: 'Modified',
                  controller: _modifiedCtrl,
                  hintText: 'Paste modified text here…',
                  onChanged: (_) => _scheduleDiff(),
                ),
              ),
            ],
          ),
        ),
        // Stats bar
        DiffCounterBadge(result: _diffResult, isLoading: _isLoading),
        // Diff view
        Expanded(
          flex: 5,
          child: Column(
            children: [
              DiffPanelHeader(
                result: _diffResult,
                originalText: _originalCtrl.text,
                modifiedText: _modifiedCtrl.text,
              ),
              Expanded(
                child: DiffView(result: _diffResult, isLoading: _isLoading),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Tabs
        Container(
          color: cs.surfaceContainerHighest,
          child: TabBar(
            controller: _tabController,
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            indicatorColor: AppTheme.brand,
            labelColor: AppTheme.brand,
            tabs: const [
              Tab(
                text: 'Original',
                icon: Icon(Icons.article_outlined, size: 16),
              ),
              Tab(text: 'Modified', icon: Icon(Icons.edit_document, size: 16)),
              Tab(
                text: 'Diff',
                icon: Icon(Icons.difference_outlined, size: 16),
              ),
            ],
          ),
        ),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Original tab
              EditorPanel(
                label: 'Original',
                controller: _originalCtrl,
                hintText: 'Cole o texto original aqui…',
                onChanged: (_) => _scheduleDiff(),
              ),
              // Modified tab
              EditorPanel(
                label: 'Modificado',
                controller: _modifiedCtrl,
                hintText: 'Cole o texto modificado aqui…',
                onChanged: (_) => _scheduleDiff(),
              ),
              // Diff tab
              Column(
                children: [
                  DiffCounterBadge(result: _diffResult, isLoading: _isLoading),
                  DiffPanelHeader(
                    result: _diffResult,
                    originalText: _originalCtrl.text,
                    modifiedText: _modifiedCtrl.text,
                  ),
                  Expanded(
                    child: DiffView(result: _diffResult, isLoading: _isLoading),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Welcome modal ─────────────────────────────────────────────────────────────

class _WelcomeDialog extends StatelessWidget {
  final ColorScheme scheme;
  final String appVersion;
  const _WelcomeDialog({required this.scheme, required this.appVersion});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.difference_outlined, color: scheme.primary, size: 22),
          const SizedBox(width: 10),
          Text(
            'Supported formats',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WelcomeSection(
              scheme: scheme,
              icon: Icons.lock_outline_rounded,
              iconColor: const Color(0xFF22C55E),
              title: 'Your texts never leave your device',
              body: 'Everything happens locally — 7diffs never uploads, sends, '
                  'or stores your content anywhere. No internet connection is '
                  'needed, not even on first launch.\n\n'
                  'This matters for confidential documents, proprietary source '
                  'code, or any text you would rather not send to a cloud service.',
            ),
            const SizedBox(height: 12),
            _WelcomeSection(
              scheme: scheme,
              icon: Icons.folder_open_rounded,
              iconColor: const Color(0xFFF59E0B),
              title: 'Supported formats',
              body: '',
              child: _FormatsGrid(scheme: scheme),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => launchUrl(Uri.parse('https://eltondantas.com')),
                  child: Text(
                    'eltondantas.com =)',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.primary.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                      decorationColor: scheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
              if (appVersion.isNotEmpty)
                Text(
                  appVersion,
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurface.withValues(alpha: 0.22),
                  ),
                ),
            ],
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Got it',
            style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _WelcomeSection extends StatelessWidget {
  const _WelcomeSection({
    required this.scheme,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    this.child,
  });

  final ColorScheme scheme;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.07)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              body,
              style: TextStyle(
                fontSize: 14,
                height: 1.55,
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
          if (child != null) ...[
            const SizedBox(height: 12),
            child!,
          ],
        ],
      ),
    );
  }
}

class _FormatsGrid extends StatelessWidget {
  const _FormatsGrid({required this.scheme});
  final ColorScheme scheme;

  static const _groups = [
    (
      Icons.code_outlined,
      'Source code',
      'Dart · Python · JS · TS\nJava · Kotlin · Swift · Go · Rust',
    ),
    (
      Icons.data_object_outlined,
      'Data & config',
      'JSON · YAML · XML · CSV · SQL',
    ),
    (
      Icons.description_outlined,
      'Text & docs',
      'TXT · Markdown · HTML · CSS\nLog · Conf',
    ),
    (Icons.terminal_outlined, 'Scripts', 'Shell · Bash'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _groups
          .map(
            (g) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    g.$1,
                    size: 18,
                    color: scheme.onSurface.withValues(alpha: 0.45),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.$2,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface.withValues(alpha: 0.9),
                        ),
                      ),
                      Text(
                        g.$3,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface.withValues(alpha: 0.5),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

// ── Support bottom sheet ───────────────────────────────────────────────────────

class _SupportSheet extends StatelessWidget {
  final ColorScheme scheme;
  const _SupportSheet({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.75,
      expand: false,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFEC4899,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Color(0xFFEC4899),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Support 7diffs',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SupportSection(scheme: scheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportSection extends StatefulWidget {
  const _SupportSection({required this.scheme});
  final ColorScheme scheme;

  @override
  State<_SupportSection> createState() => _SupportSectionState();
}

class _SupportSectionState extends State<_SupportSection> {
  static const _pixKey = '3a2b8066-7987-4e10-b0da-8ccc4c9da565';
  static const _paypalUrl =
      'https://www.paypal.com/qrcodes/p2pqrc/XQ3ZNNY4G6KAY';

  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final scheme = widget.scheme;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEC4899).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEC4899).withValues(alpha: 0.18),
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.favorite_rounded,
                color: Color(0xFFEC4899),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Support the project',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '7diffs is free and open source. If it has been useful to you, '
            'consider supporting its development — every contribution helps!',
            style: TextStyle(
              fontSize: 14,
              height: 1.55,
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'PIX (BRAZIL)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () async {
              if (_copied) return;
              await Clipboard.setData(const ClipboardData(text: _pixKey));
              setState(() => _copied = true);
              await Future<void>.delayed(const Duration(milliseconds: 1500));
              if (mounted) setState(() => _copied = false);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: scheme.onSurface.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _pixKey,
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        color: scheme.onSurface.withValues(alpha: 0.85),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(
                          begin: 0.6,
                          end: 1.0,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: _copied
                        ? const Icon(
                            Icons.check_rounded,
                            key: ValueKey('check'),
                            size: 16,
                            color: Color(0xFF22C55E),
                          )
                        : Icon(
                            Icons.copy_rounded,
                            key: const ValueKey('copy'),
                            size: 16,
                            color: scheme.onSurface.withValues(alpha: 0.4),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'PAYPAL',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse(_paypalUrl),
                  mode: LaunchMode.externalApplication,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF003087).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF003087).withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.open_in_new_rounded,
                        size: 15,
                        color: Color(0xFF009CDE),
                      ),
                      SizedBox(width: 7),
                      Text(
                        'Donate via PayPal',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF009CDE),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Layout helpers ─────────────────────────────────────────────────────────────

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return VerticalDivider(
      width: 1,
      thickness: 1,
      color: Theme.of(context).colorScheme.outline,
    );
  }
}
