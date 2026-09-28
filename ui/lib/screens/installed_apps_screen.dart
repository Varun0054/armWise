import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/components.dart';

class InstalledAppsScreen extends StatefulWidget {
  const InstalledAppsScreen({super.key});

  @override
  State<InstalledAppsScreen> createState() => _InstalledAppsScreenState();
}

class _InstalledAppsScreenState extends State<InstalledAppsScreen> {
  bool _loading = false;
  Map<String, dynamic>? _data;
  String? _error;

  Future<void> _runScan() async {
    setState(() { _loading = true; _data = null; _error = null; });
    try {
      final result = await ApiService.scanInstalled();
      setState(() { _data = result; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Installed Applications Bulk Scan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text('Enumerates Windows Registry to classify installed apps', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _runScan,
                  icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.search),
                  label: Text(_loading ? 'Scanning...' : 'Run Registry Scan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (_error != null)
            GlassCard(child: Text(_error!, style: const TextStyle(color: AppTheme.riskCrimson))),

          if (_data != null) ...[
            // Summary row
            _buildSummaryRow(_data!['summary'] as Map<String, dynamic>),
            const SizedBox(height: 24),

            // Results Table
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(text: 'Scan Results', icon: '💻'),
                  const SizedBox(height: 16),
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(2.5),
                      1: FlexColumnWidth(1.5),
                      2: FlexColumnWidth(1.5),
                      3: FlexColumnWidth(2),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.03)),
                        children: const [
                          _TableHeader('Application'),
                          _TableHeader('Architecture'),
                          _TableHeader('Category'),
                          _TableHeader('Risk Signals'),
                        ],
                      ),
                      ...(_data!['results'] as List<dynamic>).map((res) {
                        final ev = res['evidence'] as Map<String, dynamic>;
                        final cat = res['category'] as String;
                        final hasRisk = ev['driver_indicators'] == true || ev['anti_cheat_indicators'] == true;
                        return TableRow(
                          children: [
                            _TableCell(res['application'] as String, bold: true),
                            _TableCell(ev['architecture'] as String? ?? '-', mono: true),
                            _CategoryCell(cat),
                            _TableCell(
                              hasRisk ? '⚠️ Kernel Driver / Anti-Cheat' : '✅ User-Mode Only',
                              color: hasRisk ? AppTheme.riskCrimson : AppTheme.nativeEmerald,
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(Map<String, dynamic> summary) {
    return Row(
      children: [
        Expanded(child: MetricCard(value: '${summary['native'] ?? 0}', label: 'Native ARM64', color: AppTheme.nativeEmerald)),
        const SizedBox(width: 12),
        Expanded(child: MetricCard(value: '${summary['likely_compatible'] ?? 0}', label: 'Likely Compatible', color: AppTheme.compatibleBlue)),
        const SizedBox(width: 12),
        Expanded(child: MetricCard(value: '${summary['uncertain'] ?? 0}', label: 'Uncertain', color: AppTheme.uncertainAmber)),
        const SizedBox(width: 12),
        Expanded(child: MetricCard(value: '${summary['high_risk'] ?? 0}', label: 'High Risk', color: AppTheme.riskCrimson)),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Text(text, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
  );
}

class _TableCell extends StatelessWidget {
  final String text;
  final Color? color;
  final bool bold;
  final bool mono;
  const _TableCell(this.text, {this.color, this.bold = false, this.mono = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    child: Text(
      text,
      style: TextStyle(
        color: color ?? AppTheme.textMain,
        fontSize: 13,
        fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
        fontFamily: mono ? 'JetBrains Mono' : null,
      ),
    ),
  );
}

class _CategoryCell extends StatelessWidget {
  final String category;
  const _CategoryCell(this.category);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    child: SizedBox(
      child: CategoryBadge(category: category),
    ),
  );
}
