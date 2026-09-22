import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/utils/theme_context.dart';
import 'package:hi_docs/providers/admin_provider.dart';
import 'package:hi_docs/providers/auth_provider.dart';
import 'package:hi_docs/providers/metrics_provider.dart';
import 'package:hi_docs/providers/response_provider.dart';
import 'package:hi_docs/widgets/common/custom_card.dart';
import 'package:hi_docs/screens/admin/admin_traffic_screen.dart';
import 'package:hi_docs/utils/custom_page_route.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentTab();
    });
  }

  @override
  void dispose() {
    try {
      Provider.of<MetricsProvider>(context, listen: false).stopPolling();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _loadCurrentTab() async {
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final metrics = Provider.of<MetricsProvider>(context, listen: false);
    if (auth.isSuperAdmin) {
      await admin.fetchAdmins();
      return;
    }
    if (_tab == 0) {
      await admin.fetchDashboardStats();
    } else if (_tab == 1) {
      await admin.fetchCreators();
    } else if (_tab == 2) {
      await admin.fetchAllForms();
    } else if (_tab == 3) {
      await metrics.fetchAllMetrics();
      metrics.startPolling(seconds: 5);
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
      ]),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Future<void> _showAddCreatorDialog() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Tambah Creator Baru', style: TextStyle(fontSize: 18)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Creator',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(v.trim())) return 'Format email tidak valid (contoh: name@domain.com)';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final admin = Provider.of<AdminProvider>(context, listen: false);
                final success = await admin.createCreator(
                  nameCtrl.text.trim(),
                  emailCtrl.text.trim(),
                  passCtrl.text,
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  if (success) {
                    _showSnack('Creator baru berhasil ditambahkan.', AppTheme.success);
                  } else {
                    _showSnack(admin.errorMessage ?? 'Gagal menambahkan creator', AppTheme.error);
                  }
                }
              },
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
              label: const Text('Tambah'),
            ),
          ],
          backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        );
      },
    );
  }

  Future<void> _showAddAdminDialog() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Tambah Admin Baru (Superadmin)', style: TextStyle(fontSize: 18)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Admin',
                      prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Admin',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(v.trim())) return 'Format email tidak valid (contoh: name@domain.com)';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password Admin',
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final admin = Provider.of<AdminProvider>(context, listen: false);
                final success = await admin.createAdmin(
                  nameCtrl.text.trim(),
                  emailCtrl.text.trim(),
                  passCtrl.text,
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  if (success) {
                    _showSnack('Akun Admin baru berhasil dibuat.', AppTheme.success);
                  } else {
                    _showSnack(admin.errorMessage ?? 'Gagal membuat akun admin', AppTheme.error);
                  }
                }
              },
              icon: const Icon(Icons.add_moderator_rounded, size: 16),
              label: const Text('Buat Admin'),
            ),
          ],
          backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        );
      },
    );
  }

  Future<void> _deleteForm(String formId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.delete_outline_rounded, color: AppTheme.error),
          SizedBox(width: 10),
          Text('Hapus Form', style: TextStyle(fontSize: 18)),
        ]),
        content: Text(
          'Yakin ingin menghapus form "$title"? Action ini tidak dapat dibatalkan.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.delete_rounded, size: 16),
            label: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final admin = Provider.of<AdminProvider>(context, listen: false);
    final success = await admin.deleteForm(formId);
    if (mounted) {
      if (success) {
        final rp = Provider.of<ResponseProvider>(context, listen: false);
        rp.removeResponsesByForm(formId);
        _showSnack('Form berhasil dihapus.', AppTheme.success);
      } else {
        _showSnack(admin.errorMessage ?? 'Gagal menghapus form', AppTheme.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSuper = auth.isSuperAdmin;

    final tabTitles = isSuper
        ? ['Admins']
        : ['Overview', 'Creators', 'Forms', 'Monitoring'];

    final List<Widget> bodies = isSuper
        ? [_buildAdmins()]
        : [_buildOverview(), _buildCreators(), _buildForms(), _buildMonitoring()];

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.surfaceLight,
      appBar: AppBar(
        title: Text(isSuper ? 'Super Admin Dashboard' : 'Admin Dashboard'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                context.primaryDark,
                context.primary,
                context.primaryLight,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: Colors.white),
            tooltip: 'Profile',
            onPressed: () {
              // Buka profile (reuse SettingsScreen untuk admin/superadmin)
              Navigator.push(
                context,
                CustomPageRoute(page: Scaffold(
                    appBar: AppBar(title: const Text('Profile')),
                    body: _AdminProfileView(isSuper: isSuper),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () async {
              final nav = Navigator.of(context);
              final auth2 = Provider.of<AuthProvider>(context, listen: false);
              nav.pushNamedAndRemoveUntil('/login', (_) => false);
              await auth2.logout();
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: List.generate(tabTitles.length, (i) {
                final active = _tab == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _tab = i);
                      _loadCurrentTab();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: active ? Colors.white.withValues(alpha: 0.95) : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Text(
                        tabTitles[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: active ? context.primary : Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _tab < bodies.length ? _tab : 0,
        children: bodies,
      ),
      floatingActionButton: isSuper
          ? FloatingActionButton.extended(
              onPressed: _showAddAdminDialog,
              backgroundColor: AppTheme.accentDark,
              elevation: 3,
              icon: const Icon(Icons.add_moderator_rounded, color: Colors.white),
              label: const Text('Add Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            )
          : _tab == 1
              ? FloatingActionButton.extended(
                  onPressed: _showAddCreatorDialog,
                  backgroundColor: context.primary,
                  elevation: 3,
                  icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
                  label: const Text('Add Creator', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                )
              : null,
    );
  }

  Widget _buildOverview() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);
    final admin = Provider.of<AdminProvider>(context);
    final stats = admin.dashboardStats ?? {};

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: admin.fetchDashboardStats,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.group_rounded,
                  label: 'Total Users',
                  value: (stats['total_users'] ?? 0).toString(),
                  color: context.primary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoTile(
                  icon: Icons.edit_document,
                  label: 'Total Forms',
                  value: (stats['total_forms'] ?? 0).toString(),
                  color: AppTheme.success,
                  isDark: isDark,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.quiz_rounded,
                  label: 'Active Exams',
                  value: (stats['active_exams'] ?? 0).toString(),
                  color: AppTheme.warning,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoTile(
                  icon: Icons.fact_check_rounded,
                  label: 'Responses',
                  value: (stats['total_responses'] ?? 0).toString(),
                  color: AppTheme.accentDark,
                  isDark: isDark,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            _InfoTile(
              icon: Icons.workspace_premium_rounded,
              label: 'Total Creators',
              value: (stats['total_creators'] ?? 0).toString(),
              color: context.primary,
              isDark: isDark,
              fullWidth: true,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.primaryWith(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.primaryWith(0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, color: context.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Admin berfokus pada pengawasan creator, form, dan pengguna sistem. '
                      '${auth.currentUser?.name ?? 'Anda'} memiliki hak akses '
                      '${auth.isSuperAdmin ? 'Superadmin' : 'Admin'}.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreators() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final admin = Provider.of<AdminProvider>(context);

    if (admin.isLoadingCreators) {
      return const Center(child: CircularProgressIndicator());
    }

    if (admin.creators.isEmpty) {
      return _EmptyState(
        icon: Icons.group_outlined,
        title: 'Belum ada Creator',
        subtitle: 'Tekan "+ Add Creator" untuk membuat akun creator baru',
        isDark: isDark,
      );
    }

    return RefreshIndicator(
      onRefresh: admin.fetchCreators,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        itemCount: admin.creators.length,
        itemBuilder: (_, index) {
          final creator = admin.creators[index];
          final active = creator.isActive;

          return CustomCard(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Center(
                    child: Text(
                      creator.name.isEmpty ? '?' : creator.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.success,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        creator.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        creator.email,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch.adaptive(
                  value: active,
                  onChanged: (v) async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Text(v ? 'Aktifkan Creator' : 'Nonaktifkan Creator'),
                        content: Text(
                          v
                              ? 'Apakah Anda yakin ingin mengaktifkan kembali akses creator "${creator.name}"?'
                              : 'Apakah Anda yakin ingin memblokir/menonaktifkan akses creator "${creator.name}"?',
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: v ? AppTheme.success : AppTheme.error,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(v ? 'Aktifkan' : 'Nonaktifkan'),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true || !mounted) return;

                    final ok = await admin.toggleCreatorStatus(creator.id, v);
                    if (mounted) {
                      if (!ok) {
                        _showSnack(admin.errorMessage ?? 'Gagal mengubah status', AppTheme.error);
                      } else {
                        _showSnack('Status creator "${creator.name}" diperbarui.', AppTheme.success);
                      }
                    }
                  },
                  activeTrackColor: AppTheme.success,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildForms() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final admin = Provider.of<AdminProvider>(context);

    if (admin.isLoadingForms) {
      return const Center(child: CircularProgressIndicator());
    }

    if (admin.allForms.isEmpty) {
      return _EmptyState(
        icon: Icons.article_outlined,
        title: 'Belum ada Form Sistem',
        subtitle: 'Form yang dibuat oleh seluruh pengguna akan tampil di sini',
        isDark: isDark,
      );
    }

    return RefreshIndicator(
      onRefresh: admin.fetchAllForms,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: admin.allForms.length,
        itemBuilder: (_, index) {
          final form = admin.allForms[index];
          final formId = (form['id'] ?? '').toString();
          final title = (form['title'] ?? '-').toString();
          final status = (form['status'] ?? 'ACTIVE').toString();
          final isActive = status == 'ACTIVE';

          return CustomCard(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: context.primaryWith(0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(Icons.article_rounded, size: 22, color: context.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(children: [
                        _MiniPill(
                          text: (form['creator_name'] ?? 'Creator').toString(),
                          color: context.primary,
                        ),
                        const SizedBox(width: 6),
                        _MiniPill(
                          text: isActive ? 'Active' : 'Closed',
                          color: isActive ? AppTheme.success : AppTheme.error,
                        ),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    final metrics = Provider.of<MetricsProvider>(context, listen: false);
                    final res = await metrics.fetchFormMetrics(formId);
                    if (!mounted) return;
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: Row(children: [Icon(Icons.analytics_outlined, color: context.primary, size: 20), const SizedBox(width: 8), Expanded(child: Text(title, style: const TextStyle(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis))]),
                        content: res == null
                            ? Text(metrics.errorMessage ?? 'Gagal memuat metrik form', style: const TextStyle(color: AppTheme.error, fontSize: 12))
                            : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: res.entries.map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(e.key, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)), const SizedBox(width: 12), Flexible(child: Text(e.value.toString(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700), textAlign: TextAlign.right))]))).toList()),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
                      ),
                    );
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: context.primaryWith(0.10), borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.insert_chart_outlined_rounded, size: 19, color: context.primary),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _deleteForm(formId, title),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, size: 19, color: AppTheme.error),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdmins() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final admin = Provider.of<AdminProvider>(context);

    if (admin.isLoadingAdmins) {
      return const Center(child: CircularProgressIndicator());
    }

    if (admin.admins.isEmpty) {
      return _EmptyState(
        icon: Icons.admin_panel_settings_outlined,
        title: 'Belum ada Admin Tambahan',
        subtitle: 'Superadmin dapat membuat akun Admin baru dengan menekan "+ Add Admin"',
        isDark: isDark,
      );
    }

    return RefreshIndicator(
      onRefresh: admin.fetchAdmins,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        itemCount: admin.admins.length,
        itemBuilder: (_, index) {
          final adminUser = admin.admins[index];

          return CustomCard(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.accentDark.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Center(
                    child: Text(
                      adminUser.name.isEmpty ? 'A' : adminUser.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.accentDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        adminUser.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        adminUser.email,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const _MiniPill(text: 'Admin Role', color: AppTheme.accentDark),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonitoring() {
    final metrics = Provider.of<MetricsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rt = metrics.realtime;
    final sys = metrics.system;
    final history = metrics.history;

    // Spike detection thresholds (tanpa Live Exams)
    final rps = rt?.requestsPerSecond ?? 0;
    final p95 = rt?.latencyP95Ms ?? 0;
    final cpu = sys?.cpuUsagePercent ?? 0;
    final dbRatio = (sys != null && sys.dbMaxConnections > 0) ? sys.dbOpenConnections / sys.dbMaxConnections * 100 : 0;
    final isSpike = rps > 80 || p95 > 500 || cpu > 80 || dbRatio > 80;

    return RefreshIndicator(
      onRefresh: () async {
        await metrics.fetchAllMetrics();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          if (isSpike)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.error.withValues(alpha: 0.25))),
              child: Row(children: [
                Container(width: 36, height: 36, decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 20)),
                const SizedBox(width: 12),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Lonjakan Terdeteksi!', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.error, fontSize: 13)), SizedBox(height: 2), Text('RPS / Latency / CPU / DB Pool di atas ambang. Siaga scale DB / tambah instance.', style: TextStyle(fontSize: 12, height: 1.4)) ])),
              ]),
            ),
          Row(children: [
            Expanded(child: _MonitorCard(label: 'RPS', value: rt == null ? '-' : rps.toStringAsFixed(1), sub: rt == null ? 'Menunggu' : 'Req/detik', icon: Icons.speed_rounded, color: rps > 80 ? AppTheme.error : context.primary, isDark: isDark)),
            const SizedBox(width: 10),
            Expanded(child: _MonitorCard(label: 'P95 Latency', value: rt == null ? '-' : '${p95.toStringAsFixed(0)}ms', sub: p95 > 500 ? 'Tinggi!' : 'Normal', icon: Icons.timer_outlined, color: p95 > 500 ? AppTheme.error : AppTheme.warning, isDark: isDark)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _MonitorCard(label: 'CPU', value: sys == null ? '-' : '${cpu.toStringAsFixed(0)}%', sub: sys == null ? '-' : '${sys.goroutinesCount} goroutines', icon: Icons.memory_rounded, color: cpu > 80 ? AppTheme.error : Colors.blue, isDark: isDark)),
            const SizedBox(width: 10),
            Expanded(child: _MonitorCard(label: 'DB Pool', value: sys == null ? '-' : '${sys.dbOpenConnections}/${sys.dbMaxConnections}', sub: '${dbRatio.toStringAsFixed(0)}% used', icon: Icons.storage_rounded, color: dbRatio > 80 ? AppTheme.error : Colors.teal, isDark: isDark)),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context, CustomPageRoute(page: const AdminTrafficScreen())),
                icon: const Icon(Icons.show_chart_rounded, size: 18),
                label: const Text('Buka Detail Traffic', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                style: ElevatedButton.styleFrom(backgroundColor: context.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(onPressed: () => metrics.fetchAllMetrics(), icon: const Icon(Icons.refresh_rounded), tooltip: 'Refresh', style: IconButton.styleFrom(backgroundColor: isDark ? AppTheme.darkCard : Colors.white, side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.border))),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: isDark ? AppTheme.darkCard : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Icon(Icons.trending_up_rounded, size: 18, color: context.primary), const SizedBox(width: 8), const Text('Traffic History (RPS)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)), const Spacer(), if (metrics.isPolling) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)), child: Row(children: [Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle)), const SizedBox(width: 4), Text('Live ${metrics.pollIntervalSeconds}s', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.success))]))]),
              const SizedBox(height: 12),
              if (history != null && history.rpsSeries.isNotEmpty)
                SizedBox(
                  height: 90,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(history.rpsSeries.length, (i) {
                      final maxRps = history.rpsSeries.fold<double>(1, (p, c) => c > p ? c : p);
                      final v = history.rpsSeries[i];
                      final h = (v / maxRps * 70).clamp(8.0, 70.0);
                      final isPeak = v == maxRps && v > 50;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                            Text(v.toStringAsFixed(0), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: isPeak ? AppTheme.error : AppTheme.textMuted)),
                            const SizedBox(height: 3),
                            Container(height: h, decoration: BoxDecoration(color: isPeak ? AppTheme.error : context.primary, borderRadius: BorderRadius.circular(5))),
                            const SizedBox(height: 4),
                            Text(history.timestamps.length > i ? history.timestamps[i] : '', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ]),
                        ),
                      );
                    }),
                  ),
                )
              else
                const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: Text('Belum ada data traffic', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)))),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: context.primaryWith(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: context.primaryWith(0.15))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.lightbulb_outline_rounded, size: 16, color: context.primary), SizedBox(width: 8), Expanded(child: Text('Tips antisipasi lonjakan: pantau RPS, P95 Latency, CPU & DB Pool. Jika RPS >80 atau DB >80% → scale DB max_connections / tambah instance. Cek Traffic History untuk tren.', style: TextStyle(fontSize: 12, height: 1.4, color: AppTheme.textSecondary)))]),
          ),
        ],
      ),
    );
  }
}

class _MonitorCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color color;
  final bool isDark;
  const _MonitorCard({required this.label, required this.value, required this.sub, required this.icon, required this.color, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: isDark ? AppTheme.darkCard : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, size: 16, color: color), const SizedBox(width: 6), Expanded(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis))]),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary)),
        const SizedBox(height: 2),
        Text(sub, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  final bool fullWidth;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String text;
  final Color color;

  const _MiniPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

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
            child: Icon(icon, size: 36, color: context.primaryWith(0.4)),
          ),
          const SizedBox(height: 20),
          Text(title,
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _AdminProfileView extends StatelessWidget {
  final bool isSuper;
  const _AdminProfileView({required this.isSuper});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (user == null) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: isSuper ? [AppTheme.warning, const Color(0xFFE5890A)] : [context.primary, context.primaryLight]),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(children: [
            Container(width: 58, height: 58, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(18)), child: Center(child: Text(user.name.isEmpty ? '?' : user.name.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26)))),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 2),
              Text(user.email, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)), child: Text(isSuper ? 'SUPER ADMIN' : 'ADMINISTRATOR', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.8))),
            ])),
          ]),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(color: isDark ? AppTheme.darkCard : AppTheme.surfaceCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border)),
          child: Column(children: [
            ListTile(leading: const Icon(Icons.badge_outlined), title: const Text('Username'), subtitle: Text(user.name)),
            const Divider(height: 1),
            ListTile(leading: const Icon(Icons.email_outlined), title: const Text('Email'), subtitle: Text(user.email)),
            const Divider(height: 1),
            ListTile(leading: Icon(isSuper ? Icons.workspace_premium_rounded : Icons.admin_panel_settings_rounded, color: isSuper ? AppTheme.warning : context.primary), title: Text(isSuper ? 'Super Admin' : 'Admin'), subtitle: Text(isSuper ? 'Kelola admin & sistem' : 'Kelola creator & form')),
          ]),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () async {
              final nav = Navigator.of(context);
              nav.pushNamedAndRemoveUntil('/login', (_) => false);
              await auth.logout();
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          ),
        ),
        const SizedBox(height: 12),
        Center(child: Text('HiDocs • Admin Panel', style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted))),
      ],
    );
  }
}