import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/utils/theme_context.dart';
import 'package:hi_docs/providers/auth_provider.dart';
import 'package:hi_docs/providers/form_provider.dart';
import 'package:hi_docs/providers/response_provider.dart';
import 'package:hi_docs/models/form_model.dart';
import 'package:hi_docs/widgets/common/custom_card.dart';

import 'package:hi_docs/l10n/app_localizations.dart';
import 'package:hi_docs/l10n/l10n_extension.dart';
import 'package:hi_docs/widgets/common/dynamic_header.dart';
import 'package:hi_docs/widgets/form/form_theme.dart';
import 'package:hi_docs/widgets/common/page_top_bar.dart';
import 'package:hi_docs/screens/forms/create_form_screen.dart';
import 'package:hi_docs/screens/forms/form_detail_screen.dart';
import 'package:hi_docs/screens/forms/import_guide_screen.dart';
import 'package:hi_docs/screens/exam/qr_generator_screen.dart';
import 'package:hi_docs/screens/home/settings_screen.dart';
import 'package:hi_docs/utils/custom_page_route.dart';


class CreatorHomeScreen extends StatefulWidget {
  const CreatorHomeScreen({super.key});
  @override
  State<CreatorHomeScreen> createState() => _CreatorHomeScreenState();
}

class _CreatorHomeScreenState extends State<CreatorHomeScreen>
    with WidgetsBindingObserver {
  int _tab = 0;
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FormProvider>().loadForms();
      }
    });
    // Periodically re-evaluate isExpired -> isActive (getter uses DateTime.now)
    // agar pill Aktif/Tutup otomatis berubah tanpa perlu hot restart / buka detail.
    _autoCloseTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      context.read<FormProvider>().syncExpiredForms();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Saat kembali dari background / hot restart selesai, force re-check
      context.read<FormProvider>().syncExpiredForms();
      context.read<FormProvider>().loadForms(forceRefresh: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth         = Provider.of<AuthProvider>(context);
    final formProvider = Provider.of<FormProvider>(context);
    final l10n = AppLocalizations.of(context);

    final List<Widget> screens = [
      _DashboardTab(
        auth: auth,
        formProvider: formProvider,
        onViewAll: () {
          setState(() {
            _tab = 1;
          });
        },
      ),
      _FormsTab(
        formProvider: formProvider
      ),
      const SettingsScreen(isCreatorMode: true),
    ];

    return Scaffold(
      body: screens[_tab],
      floatingActionButton: _tab == 1
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(context,
                  CustomPageRoute(page: const CreateFormScreen())),
              backgroundColor: context.primary,
              elevation: 3,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(l10n.isIndonesian ? 'Form Baru' : 'New Form',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            )
          : null,
      bottomNavigationBar: _BottomNav(
        currentIndex: _tab,
        onTap: (i) {
          setState(() => _tab = i);
          if (mounted) {
            context.read<FormProvider>().loadForms();
          }
        },
        items: [
          _NavItem(
              icon: Icons.space_dashboard_outlined,
              activeIcon: Icons.space_dashboard_rounded,
              label: l10n.home),
          _NavItem(
              icon: Icons.article_outlined,
              activeIcon: Icons.article_rounded,
              label: l10n.isIndonesian ? 'Form' : 'Forms'),
          _NavItem(
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings_rounded,
              label: l10n.profile),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final AuthProvider auth;
  final FormProvider formProvider;
  final VoidCallback onViewAll;

  const _DashboardTab({
    required this.auth,
    required this.formProvider,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final myForms = formProvider.getFormsByCreator(user.id);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => formProvider.loadForms(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: CreatorHeader(auth: auth),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                  Row(children: [
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.add_circle_rounded,
                        label: 'Form Baru',
                        color: context.primary,
                        onTap: () async {
                          await Navigator.push(
                              context,
                              CustomPageRoute(page:
                                      const CreateFormScreen()));
                          if (context.mounted) {
                            context.read<FormProvider>().loadForms();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.description_rounded,
                        label: 'Impor Word',
                        color: context.primary,
                        onTap: () => _showImportDialog(context, isExcel: false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.table_chart_rounded,
                        label: 'Impor Excel',
                        color: AppTheme.success,
                        onTap: () => _showImportDialog(context, isExcel: true),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 28),

                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                    Text('Form Terbaru',
                        style: Theme.of(context).textTheme.titleLarge),
                    TextButton(
                      onPressed: onViewAll,
                      style: TextButton.styleFrom(
                        foregroundColor: context.primary,
                      ),
                      child: const Text('Lihat Semua'),
                    ),
                  ]),
                  const SizedBox(height: 8),

                  if (myForms.isEmpty && formProvider.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (myForms.isEmpty)
                    const _EmptyState(
                      icon: Icons.article_outlined,
                      title: 'Belum ada form',
                      subtitle: 'Ketuk "Form Baru" untuk memulai',
                    )
                  else
                    ...myForms
                        .take(4)
                        .map((f) => _FormCard(
                              form: f,
                              onTap: () async {
                                await Navigator.push(
                                    context,
                                    CustomPageRoute(page:
                                            FormDetailScreen(form: f)));
                                if (context.mounted) {
                                  context.read<FormProvider>().loadForms();
                                }
                              },
                            )),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImportDialog(BuildContext context, {bool isExcel = false}) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(
            isExcel ? Icons.table_chart_rounded : Icons.description_rounded,
            color: isExcel ? AppTheme.success : dialogCtx.primary,
          ),
          const SizedBox(width: 10),
          Text(
            isExcel ? 'Impor Excel' : 'Impor Word',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isExcel
                  ? 'Ubah berkas spreadsheet Excel (.xlsx) menjadi form secara otomatis.'
                  : 'Ubah dokumen Word (.docx) menjadi template form secara otomatis.',
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                Navigator.pop(dialogCtx);
                Navigator.push(
                  context,
                  CustomPageRoute(page: ImportGuideScreen(
                      initialTab: isExcel ? 'excel' : 'word',
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: (isExcel ? AppTheme.success : dialogCtx.primary)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (isExcel ? AppTheme.success : dialogCtx.primary)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.help_outline_rounded,
                      size: 18,
                      color: isExcel ? AppTheme.success : dialogCtx.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lihat Panduan Format ${isExcel ? "Excel" : "Word"}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isExcel ? AppTheme.success : dialogCtx.primary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: isExcel ? AppTheme.success : dialogCtx.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Batal')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogCtx);
              _handlePickAndImport(context, isExcel: isExcel);
            },
            icon: const Icon(Icons.folder_open_rounded, size: 16),
            label: const Text('Pilih File'),
            style: isExcel
                ? ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _handlePickAndImport(BuildContext context, {bool isExcel = false}) async {
    try {
      final ext = isExcel ? ['xlsx', 'csv'] : ['docx'];
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ext,
      );

      if (picked == null) {
        return;
      }

      // Validate extension
      final fileName = picked.name.toLowerCase();
      final valid = isExcel
          ? (fileName.endsWith('.xlsx') || fileName.endsWith('.csv'))
          : fileName.endsWith('.docx');

      if (!valid) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isExcel
                    ? 'Hanya file .xlsx atau .csv yang didukung.'
                    : 'Hanya file .docx yang didukung.',
              ),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
        return;
      }

      // Validate size > 0
      final size = await picked.length() ?? 0;
      if (size == 0) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('File kosong atau gagal dibaca.'),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
        return;
      }

      // Validate size limit 10 MB
      if (size > 10 * 1024 * 1024) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('File terlalu besar (maks 10 MB).'),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
        return;
      }

      final String? filePath = picked.path;
      Uint8List? fileBytes;
      try {
        fileBytes = await picked.readAsBytes();
        if (fileBytes.isEmpty) fileBytes = null;
      } catch (_) {
        fileBytes = null;
      }

      if ((filePath == null || filePath.isEmpty) && fileBytes == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Gagal membaca file. Coba lagi.'),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
        return;
      }

      if (!context.mounted) return;

      // Show blocking loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (loadingCtx) => PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Mengupload ${fileName.length > 24 ? '${fileName.substring(0, 24)}…' : fileName}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  isExcel ? 'Parsing spreadsheet Excel…' : 'Parsing dokumen Word…',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );

      final formProvider = Provider.of<FormProvider>(context, listen: false);

      final imported = isExcel
          ? await formProvider.importExcel(
              filePath: filePath,
              fileBytes: fileBytes,
              fileName: fileName,
            )
          : await formProvider.importDocx(
              filePath: filePath,
              fileBytes: fileBytes,
              fileName: fileName,
            );

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // close loading

      if (imported != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Berhasil import: "${imported.title}" (${imported.questions.length} soal)'),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );

        // Open CreateFormScreen with pre-populated questions without saving to database yet
        Navigator.push(
          context,
          CustomPageRoute(page: CreateFormScreen(
              initialQuestions: imported.questions,
              initialTabIndex: 1, // Tab 1: Questions Focus
            ),
          ),
        );
      } else {
        final errMsg = formProvider.error ?? 'Gagal mengimport dokumen.';
        formProvider.clearError();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errMsg),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        // Close loading if still open
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}

class CreatorHeader extends StatelessWidget {
  final AuthProvider auth;
  const CreatorHeader({required this.auth, super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = auth.currentUser;
    final top = MediaQuery.of(context).padding.top;

    return DynamicHeader(
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.isIndonesian
                      ? 'Mode Pembuat Form 🎨'
                      : 'Form Creator Mode 🎨',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user == null
                      ? l10n.helloWave
                      : user.name.split(' ').first,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                CustomPageRoute(
                  page: const SettingsScreen(isCreatorMode: true),
                ),
              );
            },
            child: CircleAvatar(
              radius: 25,
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              child: Text(
                user != null && user.name.isNotEmpty
                    ? user.name[0].toUpperCase()
                    : 'C',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormsTab extends StatefulWidget {
  final FormProvider formProvider;
  const _FormsTab({required this.formProvider});

  @override
  State<_FormsTab> createState() => _FormsTabState();
}

class _FormsTabState extends State<_FormsTab> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _selectedCategory = '';
  List<String> _remoteCategories = [];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCats());
  }

  Future<void> _loadCats() async {
    try {
      final cats = await widget.formProvider.fetchCategories();
      if (!mounted) return;
      setState(() => _remoteCategories = cats);
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final allForms = widget.formProvider.forms;
    final catSet = <String>{};
    for (final f in allForms) {
      final c = f.category.trim();
      if (c.isNotEmpty) catSet.add(c);
    }
    for (final c in _remoteCategories) {
      final t = c.trim();
      if (t.isNotEmpty) catSet.add(t);
    }
    final cats = catSet.toList()..sort();
    final byCat = _selectedCategory.isEmpty
        ? allForms
        : allForms
            .where((f) =>
                f.category.trim().toLowerCase() ==
                _selectedCategory.toLowerCase())
            .toList();
    final filtered = _query.isEmpty
        ? byCat
        : byCat.where((f) {
            final searchable =
                '${f.title} ${f.slug} ${f.customLinkAlias} ${f.typeForApi}'
                    .toLowerCase();
            return searchable.contains(_query);
          }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.surfaceLight,
      appBar: PageTopBar(
        title: AppLocalizations.of(context).isIndonesian ? 'Form Saya' : 'My Forms',
        subtitle: '${filtered.length} ${AppLocalizations.of(context).isIndonesian ? 'form' : 'forms'}',
        icon: Icons.article_rounded,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: AppLocalizations.of(context).signOut,
            onPressed: () async {
              final nav = Navigator.of(context);
              final a = Provider.of<AuthProvider>(context, listen: false);
              nav.pushNamedAndRemoveUntil('/login', (_) => false);
              await a.logout();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari form, link, atau tipe...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => _searchCtrl.clear(),
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppTheme.darkSurface : Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.border),
                ),
              ),
            ),
          ),
          if (cats.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                children: [
                  ChoiceChip(
                    label: Text(l10n.filterAll),
                    selected: _selectedCategory.isEmpty,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = ''),
                  ),
                  const SizedBox(width: 8),
                  for (final c in cats) ...[
                    ChoiceChip(
                      label: Text(c),
                      selected: _selectedCategory == c,
                      onSelected: (_) => setState(() =>
                          _selectedCategory =
                              _selectedCategory == c ? '' : c),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => widget.formProvider.loadForms(),
              child: filtered.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: _EmptyState(
                          icon: Icons.search_off_rounded,
                          title: _query.isEmpty ? 'Belum ada form' : 'Tidak ada hasil',
                          subtitle: _query.isEmpty
                              ? 'Ketuk tombol + untuk membuat form pertama'
                              : 'Coba kata kunci lain',
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _FormCard(
                        form: filtered[i],
                        onTap: () async {
                          await Navigator.push(
                              context,
                              CustomPageRoute(page:
                                      FormDetailScreen(form: filtered[i])));
                          if (context.mounted) {
                            context.read<FormProvider>().loadForms();
                          }
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSearchDelegate extends SearchDelegate {
  final List<FormModel> forms;
  _FormSearchDelegate(this.forms);

  @override
  String get searchFieldLabel => 'Cari form...';

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(
            icon: const Icon(Icons.clear_rounded),
            onPressed: () => query = ''),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final q = query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? forms
        : forms.where((f) {
            final s =
                '${f.title} ${f.slug} ${f.customLinkAlias} ${f.typeForApi}'.toLowerCase();
            return s.contains(q);
          }).toList();
    if (filtered.isEmpty) {
      return const Center(child: Text('Tidak ada hasil'));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      itemCount: filtered.length,
      itemBuilder: (_, i) => _FormCard(
        form: filtered[i],
        onTap: () {
          close(context, null);
          Navigator.push(
              context,
              CustomPageRoute(page: FormDetailScreen(form: filtered[i])));
        },
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final FormModel form;
  final VoidCallback onTap;
  const _FormCard({required this.form, required this.onTap});

  void _copyLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: form.fullLink));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Link berhasil disalin!'),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Form?'),
        content: Text(
            'Apakah Anda yakin ingin menghapus "${form.title}"? Data yang dihapus tidak dapat dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(dialogCtx);

              final fp = Provider.of<FormProvider>(context, listen: false);
              final rp = Provider.of<ResponseProvider>(context, listen: false);
              final ok = await fp.deleteForm(form.id);

              if (ok) {
                rp.removeResponsesByForm(form.id);
                messenger.showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Form berhasil dihapus.'),
                      ],
                    ),
                    backgroundColor: AppTheme.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              } else {
                final message = fp.error ?? 'Gagal menghapus form.';
                fp.clearError();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: AppTheme.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryTextColor = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final secondaryTextColor = isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted;

    final formColor = FormTheme.primaryOf(form.themeColor);

    return CustomCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          height: 6,
          decoration: BoxDecoration(
            gradient: FormTheme.headerGradient(
                form.themeColor, form.coverGradient),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(18),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: formColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.article_rounded,
              size: 22,
              color: formColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  form.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: primaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                CustomPageRoute(page: QRGeneratorScreen(form: form),
                ),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkSurface
                    : formColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: formColor.withValues(alpha: 0.18),
                ),
              ),
              child: Icon(
                Icons.qr_code_2_rounded,
                size: 18,
                color: formColor,
              ),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () => _confirmDelete(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.error.withValues(alpha: 0.18),
                ),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: AppTheme.error,
              ),
            ),
          ),
          const SizedBox(width: 6),
          _StatusPill(isActive: form.isActive),
        ]),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => _copyLink(context),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkBg : context.primaryFaint, 
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Icon(
                Icons.link_rounded,
                size: 14, 
                color: isDark ? context.primaryLight : context.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  form.fullLink,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? context.primary : context.primary,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.copy_rounded,
                size: 14,
                color: secondaryTextColor,
              ),
            ]),
          ),
        ),
          ]),
        ),
      ]),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.border),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.textSecondary),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isActive;
  const _StatusPill({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.success.withValues(alpha: 0.10)
            : AppTheme.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isActive
                ? AppTheme.success.withValues(alpha: 0.30)
                : AppTheme.error.withValues(alpha: 0.30)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppTheme.success : AppTheme.error),
        ),
        const SizedBox(width: 5),
        Text(isActive ? 'Aktif' : 'Tutup',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isActive ? AppTheme.success : AppTheme.error)),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState(
      {required this.icon,
      required this.title,
      required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: context.primaryWith(0.07),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon,
                size: 36,
                color: context.primaryWith(0.4)),
          ),
          const SizedBox(height: 20),
          Text(title,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textMuted),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(
      {required this.icon,
      required this.activeIcon,
      required this.label});
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_NavItem> items;
  const _BottomNav(
      {required this.currentIndex,
      required this.onTap,
      required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black
                  .withValues(alpha: isDark ? 0.30 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          items: items
              .map((i) => BottomNavigationBarItem(
                    icon: Icon(i.icon),
                    activeIcon: Icon(i.activeIcon),
                    label: i.label,
                  ))
              .toList(),
        ),
      ),
    );
  }
}