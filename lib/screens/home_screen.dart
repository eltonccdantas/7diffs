import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _originalCtrl = TextEditingController();
  final _modifiedCtrl = TextEditingController();

  DiffResult? _diffResult;
  bool _isLoading = false;

  // Mobile tab controller
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _originalCtrl.dispose();
    _modifiedCtrl.dispose();
    _tabController.dispose();
    super.dispose();
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

    final result = await compute(
      runDiffInIsolate,
      (original: original, modified: modified),
    );

    if (mounted) {
      setState(() {
        _diffResult = result;
        _isLoading = false;
      });
    }
  }

  void _clearAll() {
    _originalCtrl.clear();
    _modifiedCtrl.clear();
    setState(() => _diffResult = null);
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
          message: 'Trocar painéis',
          child: IconButton(
            icon: const Icon(Icons.swap_horiz, size: 20),
            onPressed: _swapPanels,
          ),
        ),
        Tooltip(
          message: 'Limpar tudo',
          child: IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, size: 20),
            onPressed: _clearAll,
          ),
        ),
        Tooltip(
          message: isDark ? 'Modo claro' : 'Modo escuro',
          child: IconButton(
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 20),
            onPressed: widget.onToggleTheme,
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
                  hintText: 'Cole o texto original aqui…',
                  onChanged: (_) => _runDiff(),
                ),
              ),
              _VerticalDivider(),
              Expanded(
                child: EditorPanel(
                  label: 'Modificado',
                  controller: _modifiedCtrl,
                  hintText: 'Cole o texto modificado aqui…',
                  onChanged: (_) => _runDiff(),
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
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            indicatorColor: AppTheme.brand,
            labelColor: AppTheme.brand,
            tabs: const [
              Tab(text: 'Original', icon: Icon(Icons.article_outlined, size: 16)),
              Tab(text: 'Modificado', icon: Icon(Icons.edit_document, size: 16)),
              Tab(text: 'Diff', icon: Icon(Icons.difference_outlined, size: 16)),
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
                onChanged: (_) => _runDiff(),
              ),
              // Modified tab
              EditorPanel(
                label: 'Modificado',
                controller: _modifiedCtrl,
                hintText: 'Cole o texto modificado aqui…',
                onChanged: (_) => _runDiff(),
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
