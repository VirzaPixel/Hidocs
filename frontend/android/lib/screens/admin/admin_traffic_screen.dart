import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hi_docs/app_theme.dart';
import 'package:hi_docs/utils/theme_context.dart';
import 'package:hi_docs/models/metrics_model.dart';
import 'package:hi_docs/providers/metrics_provider.dart';
import 'package:hi_docs/widgets/common/custom_card.dart';

class AdminTrafficScreen extends StatefulWidget {
  const AdminTrafficScreen({super.key});

  @override
  State<AdminTrafficScreen> createState() => _AdminTrafficScreenState();
}

class _AdminTrafficScreenState extends State<AdminTrafficScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final metrics = Provider.of<MetricsProvider>(context, listen: false);
      metrics.startPolling(seconds: 5);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final metrics = Provider.of<MetricsProvider>(context);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.surfaceLight,
      appBar: AppBar(
        title: const Text('Traffic & Health Monitoring'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Interval Refresh',
            onSelected: (val) {
              if (val == 0) {
                metrics.stopPolling();
              } else {
                metrics.startPolling(seconds: val);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 5, child: Text('Auto-Refresh: 5s')),
              const PopupMenuItem(value: 10, child: Text('Auto-Refresh: 10s')),
              const PopupMenuItem(value: 0, child: Text('Matikan Auto-Refresh')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => metrics.fetchAllMetrics(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Realtime RPS'),
            Tab(text: 'System & DB'),
            Tab(text: 'Live Exams'),
          ],
        ),
      ),
      body: metrics.isLoading && metrics.realtime == null
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRealtimeTab(metrics, isDark),
                _buildSystemTab(metrics, isDark),
                _buildLiveExamsTab(metrics, isDark),
              ],
            ),
    );
  }

  Widget _buildRealtimeTab(MetricsProvider metrics, bool isDark) {
    final rt = metrics.realtime;
    final history = metrics.history;

    if (rt == null) {
      return const Center(child: Text('Data telemetry tidak tersedia'));
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Requests / Sec (RPS)',
                value: rt.requestsPerSecond.toStringAsFixed(1),
                icon: Icons.speed_rounded,
                color: context.primary,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'P95 Latency',
                value: '${rt.latencyP95Ms.toStringAsFixed(1)} ms',
                icon: Icons.timer_outlined,
                color: AppTheme.warning,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Concurrent Users',
                value: rt.activeConcurrentUsers.toString(),
                icon: Icons.people_alt_outlined,
                color: AppTheme.success,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'Total Errors',
                value: rt.totalErrorCount.toString(),
                icon: Icons.error_outline_rounded,
                color: AppTheme.error,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        CustomCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RPS Time-Series Trend',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              if (history != null && history.rpsSeries.isNotEmpty)
                _TimeSeriesBarWidget(history: history, isDark: isDark)
              else
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text('Belum ada data traffic time-series tercatat'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSystemTab(MetricsProvider metrics, bool isDark) {
    final sys = metrics.system;
    if (sys == null) {
      return const Center(child: Text('Data sistem tidak tersedia'));
    }

    final dbUsageRatio = sys.dbMaxConnections > 0
        ? sys.dbOpenConnections / sys.dbMaxConnections
        : 0.0;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        CustomCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('System Health & Go Goroutines', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _GaugeBar(label: 'CPU Usage', valuePercent: sys.cpuUsagePercent, color: Colors.blue),
              const SizedBox(height: 12),
              _GaugeBar(label: 'Memory Allocated', valuePercent: (sys.memoryAllocatedMb / 512) * 100, customLabel: '${sys.memoryAllocatedMb.toStringAsFixed(1)} MB', color: Colors.purple),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Active Goroutines', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  Text('${sys.goroutinesCount}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CustomCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('PostgreSQL Connection Pool', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _GaugeBar(label: 'DB Pool Usage', valuePercent: dbUsageRatio * 100, customLabel: '${sys.dbOpenConnections}/${sys.dbMaxConnections} open', color: Colors.teal),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _InfoPill(label: 'In Use', value: sys.dbInUse.toString(), color: Colors.orange)),
                  const SizedBox(width: 8),
                  Expanded(child: _InfoPill(label: 'Idle', value: sys.dbIdle.toString(), color: Colors.green)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLiveExamsTab(MetricsProvider metrics, bool isDark) {
    final exams = metrics.liveExams;

    if (exams.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.quiz_outlined, size: 48, color: Colors.grey.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text('Tidak ada ujian aktif saat ini'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: exams.length,
      itemBuilder: (ctx, idx) {
        final item = exams[idx];
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.live_tv_rounded, color: context.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.formTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Students: ${item.activeStudents} active | Submissions: ${item.submissionsCompleted}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : AppTheme.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _GaugeBar extends StatelessWidget {
  final String label;
  final double valuePercent;
  final String? customLabel;
  final Color color;

  const _GaugeBar({
    required this.label,
    required this.valuePercent,
    this.customLabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = valuePercent.clamp(0.0, 100.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Text(customLabel ?? '${clamped.toStringAsFixed(1)}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: clamped / 100,
            minHeight: 10,
            backgroundColor: color.withValues(alpha: 0.15),
            color: color,
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          Text(value, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _TimeSeriesBarWidget extends StatelessWidget {
  final TrafficHistoryModel history;
  final bool isDark;

  const _TimeSeriesBarWidget({required this.history, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final maxRps = history.rpsSeries.fold<double>(1.0, (prev, curr) => curr > prev ? curr : prev);

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(history.rpsSeries.length, (idx) {
          final rps = history.rpsSeries[idx];
          final heightRatio = rps / maxRps;
          final time = history.timestamps.length > idx ? history.timestamps[idx] : '';

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    rps.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: (80 * heightRatio).clamp(10.0, 80.0),
                    decoration: BoxDecoration(
                      color: context.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    time,
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
