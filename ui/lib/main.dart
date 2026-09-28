import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'theme/app_theme.dart';
import 'screens/exe_scan_screen.dart';
import 'screens/installed_apps_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(const ARMWiseApp());
}

class ARMWiseApp extends StatelessWidget {
  const ARMWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ARMWise — Snapdragon ARM64 Advisor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  bool _backendOnline = false;

  static const _tabs = [
    {'icon': '⚡', 'label': '.exe Advisor'},
    {'icon': '💻', 'label': 'Installed Apps'},
    {'icon': '📊', 'label': 'Dashboard'},
  ];

  @override
  void initState() {
    super.initState();
    _checkBackend();
  }

  Future<void> _checkBackend() async {
    final ok = await ApiService.checkHealth();
    setState(() => _backendOnline = ok);
  }

  Widget _buildScreen() {
    switch (_selectedIndex) {
      case 0: return const ExeScanScreen();
      case 1: return const InstalledAppsScreen();
      case 2: return const DashboardScreen();
      default: return const ExeScanScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: Column(
        children: [
          // App Header
          _buildHeader(),
          // Tab Bar
          _buildTabBar(),
          // Content
          Expanded(child: _buildScreen()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Brand Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.accentBlue, AppTheme.accentCyan],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: AppTheme.accentBlue.withOpacity(0.3), blurRadius: 10)],
            ),
            alignment: Alignment.center,
            child: Text(
              'A',
              style: GoogleFonts.outfit(
                fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white,
              ),
            ),
          ).animate().scale(duration: 400.ms),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ARMWise',
                style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textMain),
              ),
              Text(
                'Qualcomm® Snapdragon® On-Device AI Compatibility Advisor',
                style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.textMuted, letterSpacing: 0.3),
              ),
            ],
          ),
          const Spacer(),
          // Backend status
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: (_backendOnline ? AppTheme.nativeEmerald : AppTheme.riskCrimson).withOpacity(0.1),
              border: Border.all(
                color: (_backendOnline ? AppTheme.nativeEmerald : AppTheme.riskCrimson).withOpacity(0.4),
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                _PulseDot(color: _backendOnline ? AppTheme.nativeEmerald : AppTheme.riskCrimson),
                const SizedBox(width: 8),
                Text(
                  _backendOnline ? 'Backend Online • OpenRouter AI' : 'Backend Offline',
                  style: TextStyle(
                    color: _backendOnline ? AppTheme.nativeEmerald : AppTheme.riskCrimson,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _checkBackend,
            icon: const Icon(Icons.refresh, color: AppTheme.textMuted, size: 18),
            tooltip: 'Refresh backend connection',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final selected = _selectedIndex == i;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: TextButton(
                onPressed: () => setState(() => _selectedIndex = i),
                style: TextButton.styleFrom(
                  backgroundColor: selected
                      ? AppTheme.accentBlue.withOpacity(0.1)
                      : Colors.transparent,
                  foregroundColor: selected ? AppTheme.accentBlue : AppTheme.textMuted,
                  side: selected
                      ? BorderSide(color: AppTheme.accentBlue.withOpacity(0.4))
                      : BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: Text(
                  '${_tabs[i]['icon']} ${_tabs[i]['label']}',
                  style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.5 + _anim.value * 0.5),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: widget.color.withOpacity(0.4 * _anim.value), blurRadius: 6)],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}
