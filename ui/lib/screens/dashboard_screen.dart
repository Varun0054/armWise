import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/components.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  Map<String, dynamic>? _summary;
  List<dynamic> _alternatives = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() { _loading = true; _error = null; });
    try {
      final summary = await ApiService.getDashboardSummary();
      final alternatives = await ApiService.getAlternatives('default');
      setState(() {
        _summary = summary;
        _alternatives = alternatives;
        _loading = false;
      });
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Compatibility Dashboard',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              IconButton(
                onPressed: _loadDashboard,
                icon: const Icon(Icons.refresh, color: AppTheme.textMuted),
                tooltip: 'Refresh',
              ),
            ],
          ).animate().fadeIn(),
          const SizedBox(height: 24),

          if (_loading)
            const Center(child: CircularProgressIndicator(color: AppTheme.accentBlue)),

          if (_error != null)
            GlassCard(child: Text(_error!, style: const TextStyle(color: AppTheme.riskCrimson))),

          if (_summary != null) ...[
            // Metrics Grid
            Row(
              children: [
                Expanded(child: MetricCard(
                  value: '${_summary!['native'] ?? 0}',
                  label: 'Native ARM64',
                  color: AppTheme.nativeEmerald,
                )),
                const SizedBox(width: 14),
                Expanded(child: MetricCard(
                  value: '${_summary!['likely_compatible'] ?? 0}',
                  label: 'Likely Compatible',
                  color: AppTheme.compatibleBlue,
                )),
                const SizedBox(width: 14),
                Expanded(child: MetricCard(
                  value: '${_summary!['uncertain'] ?? 0}',
                  label: 'Uncertain Coverage',
                  color: AppTheme.uncertainAmber,
                )),
                const SizedBox(width: 14),
                Expanded(child: MetricCard(
                  value: '${_summary!['high_risk'] ?? 0}',
                  label: 'High Risk / Kernel',
                  color: AppTheme.riskCrimson,
                )),
              ],
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 28),

            // Total badge
            GlassCard(
              child: Row(
                children: [
                  const Text('📊', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Knowledge Base Cases',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      ),
                      Text(
                        '${_summary!['total'] ?? 0} sourced, verified compatibility records',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms),
            const SizedBox(height: 28),

            // Alternatives Section
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(text: 'Native ARM64 Alternatives & Recommendations', icon: '🛡️'),
                  const SizedBox(height: 6),
                  const Text(
                    'All recommendations sourced strictly from the local Knowledge Base.',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  if (_alternatives.isEmpty)
                    const Text('No alternatives found in current Knowledge Base.', style: TextStyle(color: AppTheme.textMuted))
                  else
                    ...(_alternatives.map((alt) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.nativeEmerald.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.nativeEmerald.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Text('🔹', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  alt['application'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                Text(
                                  '${alt['category']} · Sourced from ${alt['source']} (${alt['source_date']})',
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          CategoryBadge(category: 'Native'),
                        ],
                      ),
                    ))),
                ],
              ),
            ).animate().fadeIn(duration: 600.ms),

            const SizedBox(height: 28),

            // Architecture Pipeline Card
            _buildPipelineCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildPipelineCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(text: 'ARMWise Analysis Pipeline Architecture', icon: '⚙️'),
          const SizedBox(height: 20),
          _PipelineStep(
            icon: '📥',
            label: 'INPUT',
            desc: 'Dropped .exe · Installed App · Store Package',
            color: AppTheme.accentBlue,
          ),
          _PipelineArrow(),
          _PipelineStep(
            icon: '🔍',
            label: 'EVIDENCE ENGINE (Deterministic)',
            desc: 'PE Header Analysis · Driver Detection · Anti-Cheat Detection · Publisher Signature',
            color: AppTheme.accentCyan,
          ),
          _PipelineArrow(),
          _PipelineStep(
            icon: '🧩',
            label: 'AI RETRIEVAL',
            desc: 'Evidence → Embedding → Cosine Similarity → Top-K Knowledge Base Cases',
            color: AppTheme.nativeEmerald,
          ),
          _PipelineArrow(),
          _PipelineStep(
            icon: '💡',
            label: 'AI REASONING (Local, On-Device)',
            desc: 'Local Inference · Grounded Explanation · Context-Bound Q&A · Zero Cloud',
            color: AppTheme.uncertainAmber,
          ),
          _PipelineArrow(),
          _PipelineStep(
            icon: '📋',
            label: 'ARMWISE REPORT',
            desc: 'Category · Evidence · Similar Cases (Sourced) · Explanation',
            color: AppTheme.compatibleBlue,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 700.ms);
  }
}

class _PipelineStep extends StatelessWidget {
  final String icon;
  final String label;
  final String desc;
  final Color color;

  const _PipelineStep({
    required this.icon,
    required this.label,
    required this.desc,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 13)),
                const SizedBox(height: 3),
                Text(desc, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PipelineArrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 22),
      child: const Icon(Icons.arrow_downward, color: AppTheme.textMuted, size: 18),
    );
  }
}
