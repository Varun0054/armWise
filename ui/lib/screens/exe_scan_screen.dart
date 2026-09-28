import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/components.dart';

class ExeScanScreen extends StatefulWidget {
  const ExeScanScreen({super.key});

  @override
  State<ExeScanScreen> createState() => _ExeScanScreenState();
}

class _ExeScanScreenState extends State<ExeScanScreen> {
  bool _isDragging = false;
  bool _isScanning = false;
  Map<String, dynamic>? _result;
  String? _error;
  final _questionController = TextEditingController();
  String? _askAnswer;
  bool _isAsking = false;

  Future<void> _scanBytes(List<int> bytes, String filename) async {
    setState(() { _isScanning = true; _result = null; _error = null; _askAnswer = null; });
    try {
      final data = await ApiService.scanExeBytes(bytes, filename);
      setState(() { _result = data; _isScanning = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isScanning = false; });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['exe'],
      withData: true, // Loads bytes into memory for Web & Desktop
    );
    if (result != null && result.files.single.bytes != null) {
      final file = result.files.single;
      await _scanBytes(file.bytes!, file.name);
    }
  }

  Future<void> _sendAsk() async {
    final q = _questionController.text.trim();
    if (q.isEmpty || _result == null) return;
    setState(() { _isAsking = true; _askAnswer = null; });
    try {
      final answer = await ApiService.ask(_result!['application'] as String, q);
      setState(() { _askAnswer = answer; _isAsking = false; });
    } catch (e) {
      setState(() { _askAnswer = 'Error: $e'; _isAsking = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDropzone(),
          const SizedBox(height: 24),
          if (_isScanning)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppTheme.accentBlue),
                    SizedBox(height: 16),
                    Text('Running deterministic evidence engine...', style: TextStyle(color: AppTheme.textMuted)),
                  ],
                ),
              ),
            ),
          if (_error != null)
            GlassCard(
              child: Row(
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.riskCrimson))),
                ],
              ),
            ),
          if (_result != null) ...[
            _buildResultCard(_result!),
            const SizedBox(height: 24),
            _buildAskPanel(),
          ],
        ],
      ),
    );
  }

  Widget _buildDropzone() {
    return DropTarget(
      onDragDone: (details) async {
        final files = details.files;
        if (files.isNotEmpty) {
          final file = files.first;
          final bytes = await file.readAsBytes();
          await _scanBytes(bytes, file.name);
        }
      },
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      child: GestureDetector(
        onTap: _pickFile,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
          decoration: BoxDecoration(
            color: _isDragging ? AppTheme.accentBlue.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isDragging ? AppTheme.accentBlue : AppTheme.borderColor,
              width: _isDragging ? 2.5 : 1.5,
              style: BorderStyle.solid,
            ),
            boxShadow: [
              BoxShadow(
                color: _isDragging ? AppTheme.accentBlue.withOpacity(0.15) : Colors.black.withOpacity(0.03),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                _isDragging ? '📂' : '📥',
                style: const TextStyle(fontSize: 48),
              ).animate(target: _isDragging ? 1 : 0).scale(end: const Offset(1.15, 1.15)),
              const SizedBox(height: 16),
              Text(
                _isDragging ? 'Release to Analyze' : 'Drag & Drop .exe File',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textMain),
              ),
              const SizedBox(height: 8),
              Text(
                'or click to browse · ARMWise performs deterministic on-device PE analysis',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildResultCard(Map<String, dynamic> data) {
    final evidence = data['evidence'] as Map<String, dynamic>;
    final category = data['category'] as String;
    final cases = data['retrieved_cases'] as List<dynamic>? ?? [];
    final explanation = data['explanation'] as String? ?? '';
    final insufficient = data['insufficient_evidence'] as bool? ?? false;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['application'] as String,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.accentBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${evidence['architecture']} · ${evidence['native_arm64'] == true ? 'Native ARM64' : 'Prism Emulated'}',
                        style: GoogleFonts.jetBrainsMono(
                          color: AppTheme.accentBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              CategoryBadge(category: category),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppTheme.borderColor),
          const SizedBox(height: 20),

          // Indicators Grid
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              IndicatorTile(
                icon: evidence['driver_indicators'] == true ? '⚠️' : '✅',
                label: 'Kernel Drivers',
                value: evidence['driver_indicators'] == true ? 'Detected' : 'Not Detected',
                valueColor: evidence['driver_indicators'] == true ? AppTheme.riskCrimson : AppTheme.nativeEmerald,
              ),
              IndicatorTile(
                icon: evidence['anti_cheat_indicators'] == true ? '⛔' : '✅',
                label: 'Anti-Cheat Engine',
                value: evidence['anti_cheat_indicators'] == true ? 'Detected' : 'None Found',
                valueColor: evidence['anti_cheat_indicators'] == true ? AppTheme.riskCrimson : AppTheme.nativeEmerald,
              ),
              IndicatorTile(
                icon: evidence['has_signature'] == true ? '🔐' : '🔓',
                label: 'Publisher Signature',
                value: evidence['publisher'] as String? ?? 'Unknown',
              ),
              IndicatorTile(
                icon: '📦',
                label: 'Import Dependencies',
                value: '${evidence['dependency_count'] ?? 0} DLL dependencies',
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Insufficient evidence banner
          if (insufficient) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.uncertainAmber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.uncertainAmber.withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Text('⚠️', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Insufficient evidence in local Knowledge Base for a definitive rating. Assessment is based solely on PE binary indicators.',
                      style: TextStyle(color: AppTheme.uncertainAmber, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // AI Explanation
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.accentBlue.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accentBlue.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('💡 ', style: TextStyle(fontSize: 16)),
                    Text(
                      'Grounded On-Device AI Explanation',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accentBlue,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(explanation, style: const TextStyle(height: 1.6, fontSize: 14, color: AppTheme.textMain)),
              ],
            ),
          ),

          // Retrieved Cases
          if (cases.isNotEmpty) ...[
            const SizedBox(height: 24),
            const SectionTitle(text: 'Sourced Knowledge Base Cases', icon: '🔍'),
            const SizedBox(height: 12),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  children: const [
                    _TableHeader('Application'),
                    _TableHeader('Outcome'),
                    _TableHeader('Source & Date'),
                    _TableHeader('Similarity'),
                  ],
                ),
                ...cases.map((c) {
                  final outcome = c['observed_result'] as String;
                  Color outcomeColor = AppTheme.textMuted;
                  if (outcome == 'works') outcomeColor = AppTheme.nativeEmerald;
                  if (outcome == 'fails') outcomeColor = AppTheme.riskCrimson;
                  if (outcome == 'works_with_limitations') outcomeColor = AppTheme.uncertainAmber;

                  final sim = ((c['similarity'] as double) * 100).toStringAsFixed(0);
                  return TableRow(
                    children: [
                      _TableCell(c['application'] as String, bold: true),
                      _TableCell(outcome, color: outcomeColor),
                      _TableCell('${c['source']} (${c['source_date']})'),
                      _TableCell('$sim%'),
                    ],
                  );
                }),
              ],
            ),
          ] else ...[
            const SizedBox(height: 16),
            const SectionTitle(text: 'No high-confidence cases matched in Knowledge Base', icon: 'ℹ️'),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.04);
  }

  Widget _buildAskPanel() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(text: 'Ask Grounded Follow-Up Question', icon: '💬'),
          const SizedBox(height: 6),
          const Text(
            'Answers are based strictly on retrieved evidence and static analysis — no external knowledge.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _questionController,
                  style: const TextStyle(color: AppTheme.textMain),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Why does this application fail on ARM64?',
                  ),
                  onSubmitted: (_) => _sendAsk(),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isAsking ? null : _sendAsk,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isAsking
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Ask', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (_askAnswer != null) ...[
            const SizedBox(height: 16),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.accentBlue.withOpacity(0.25)),
              ),
              child: Text(_askAnswer!, style: const TextStyle(height: 1.55, fontSize: 14)),
            ).animate().fadeIn(duration: 300.ms),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(text, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
      );
}

class _TableCell extends StatelessWidget {
  final String text;
  final Color? color;
  final bool bold;
  const _TableCell(this.text, {this.color, this.bold = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(
          text,
          style: TextStyle(
            color: color ?? AppTheme.textMain,
            fontSize: 13,
            fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      );
}
