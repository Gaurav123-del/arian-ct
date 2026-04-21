import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/emergency_contact.dart';
import 'alert_screen.dart';
import 'safety_timer_screen.dart';

class MainMonitoringScreen extends StatefulWidget {
  final List<EmergencyContact> contacts;

  const MainMonitoringScreen({super.key, required this.contacts});

  @override
  State<MainMonitoringScreen> createState() => _MainMonitoringScreenState();
}

class _MainMonitoringScreenState extends State<MainMonitoringScreen>
    with TickerProviderStateMixin {

  static const _orange = Color(0xFFFFAB40);

  late TabController _tabController;

  // ── Monitoring state ──────────────────────────────────────────────────────
  bool _isMonitoring = false;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnim;

  // ── Shared timer state (fed back by SafetyTimerTab via callback) ──────────
  bool _timerRunning = false;
  bool _timerPaused = false;
  bool _isUrgent = false;
  String _timerDisplay = '00:00';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _waveController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  // ── Monitoring ────────────────────────────────────────────────────────────
  void _toggleMonitoring() {
    setState(() => _isMonitoring = !_isMonitoring);
    if (_isMonitoring) {
      _pulseController.repeat(reverse: true);
      _waveController.repeat();
    } else {
      _pulseController.stop();
      _pulseController.reset();
      _waveController.stop();
      _waveController.reset();
    }
  }

  void _simulateAlert() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AlertScreen(
        contactCount: widget.contacts.isEmpty ? 5 : widget.contacts.length,
        onBack: () => Navigator.of(context).pop(),
      ),
    ));
  }

  // ── Timer state callback from SafetyTimerTab ──────────────────────────────
  void _onTimerStateChanged({
    required bool timerRunning,
    required bool timerPaused,
    required bool isUrgent,
    required String timerDisplay,
  }) {
    setState(() {
      _timerRunning = timerRunning;
      _timerPaused = timerPaused;
      _isUrgent = isUrgent;
      _timerDisplay = timerDisplay;
    });
  }

  void _showContactsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ContactsSheet(contacts: widget.contacts),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Self Live Monitoring'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline_rounded,
                color: AppTheme.textSecondary),
            onPressed: _showContactsSheet,
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: AppTheme.background,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13),
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_rounded, size: 15),
                        SizedBox(width: 6),
                        Text('Monitor'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.timer_rounded, size: 15),
                        SizedBox(width: 6),
                        Text('Safety Timer'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMonitorTab(),
          SafetyTimerTab(
            contacts: widget.contacts,
            onStateChanged: _onTimerStateChanged,
          ),
        ],
      ),
    );
  }

  // ── Monitor Tab ───────────────────────────────────────────────────────────
  Widget _buildMonitorTab() {
    return SafeArea(
      child: Column(
        children: [
          // Status banner
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: _isMonitoring
                ? AppTheme.green.withOpacity(0.1)
                : AppTheme.surfaceLight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isMonitoring ? AppTheme.green : AppTheme.textHint,
                    boxShadow: _isMonitoring
                        ? [BoxShadow(
                            color: AppTheme.green.withOpacity(0.6),
                            blurRadius: 6,
                            spreadRadius: 1)]
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isMonitoring ? 'Monitoring Active' : 'Monitoring: OFF',
                  style: TextStyle(
                    color: _isMonitoring
                        ? AppTheme.green
                        : AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Live timer pill — taps to Safety Timer tab
          if (_timerRunning || _timerPaused)
            GestureDetector(
              onTap: () => _tabController.animateTo(1),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                color: _orange.withOpacity(0.08),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer_rounded,
                        color: _isUrgent ? AppTheme.red : _orange, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      _timerPaused
                          ? 'Safety Timer paused — tap to view'
                          : 'Safety Timer: $_timerDisplay → tap to view',
                      style: TextStyle(
                        color: _isUrgent ? AppTheme.red : _orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Big monitoring button with wave rings
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_isMonitoring) ...[
                        AnimatedBuilder(
                          animation: _waveController,
                          builder: (_, __) => _WaveRing(
                              size: 220,
                              opacity: (1 - _waveController.value) * 0.25,
                              color: AppTheme.green),
                        ),
                        AnimatedBuilder(
                          animation: _waveController,
                          builder: (_, __) => _WaveRing(
                              size: 260,
                              opacity: (1 - _waveController.value) * 0.12,
                              color: AppTheme.green),
                        ),
                      ],
                      AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, child) => Transform.scale(
                          scale: _isMonitoring ? _pulseAnim.value : 1.0,
                          child: child,
                        ),
                        child: GestureDetector(
                          onTap: _toggleMonitoring,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isMonitoring
                                  ? AppTheme.green
                                  : AppTheme.surfaceLight,
                              border: Border.all(
                                color: _isMonitoring
                                    ? AppTheme.green
                                    : AppTheme.borderColor,
                                width: 2,
                              ),
                              boxShadow: _isMonitoring
                                  ? [BoxShadow(
                                      color: AppTheme.green.withOpacity(0.35),
                                      blurRadius: 40,
                                      spreadRadius: 6)]
                                  : [const BoxShadow(
                                      color: Colors.black38,
                                      blurRadius: 20,
                                      offset: Offset(0, 4))],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isMonitoring
                                      ? Icons.stop_rounded
                                      : Icons.play_arrow_rounded,
                                  color: _isMonitoring
                                      ? AppTheme.background
                                      : AppTheme.textPrimary,
                                  size: 52,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _isMonitoring ? 'STOP' : 'START',
                                  style: TextStyle(
                                    color: _isMonitoring
                                        ? AppTheme.background
                                        : AppTheme.textPrimary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    letterSpacing: 2,
                                  ),
                                ),
                                Text(
                                  'MONITORING',
                                  style: TextStyle(
                                    color: _isMonitoring
                                        ? AppTheme.background.withOpacity(0.7)
                                        : AppTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isMonitoring
                        ? Column(
                            key: const ValueKey('active'),
                            children: [
                              const Text('🟢 Monitoring Active',
                                  style: TextStyle(
                                      color: AppTheme.green,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18)),
                              const SizedBox(height: 6),
                              Text('Listening for distress signals…',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13)),
                            ],
                          )
                        : const Column(
                            key: ValueKey('inactive'),
                            children: [
                              Text('Tap to Start',
                                  style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18)),
                              SizedBox(height: 6),
                              Text('Monitoring is currently off',
                                  style: AppTheme.bodyText),
                            ],
                          ),
                  ),

                  const SizedBox(height: 48),

                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.people_rounded,
                          label: 'Contacts',
                          value: widget.contacts.isEmpty
                              ? '0'
                              : '${widget.contacts.length}',
                          color: AppTheme.accentBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.mic_rounded,
                          label: 'Voice AI',
                          value: 'Ready',
                          color: AppTheme.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _tabController.animateTo(1),
                          child: _InfoCard(
                            icon: Icons.timer_rounded,
                            label: 'Timer',
                            value: _timerRunning
                                ? _timerDisplay
                                : _timerPaused
                                    ? 'Paused'
                                    : 'Set',
                            color: _timerRunning
                                ? _orange
                                : _timerPaused
                                    ? AppTheme.textSecondary
                                    : AppTheme.textHint,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (_isMonitoring)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: GestureDetector(
                onTap: _simulateAlert,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.red.withOpacity(0.3)),
                  ),
                  child: const Center(
                    child: Text(
                      '⚠️  Simulate Emergency Alert (Demo)',
                      style: TextStyle(
                          color: AppTheme.red,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
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

// ── Wave Ring ─────────────────────────────────────────────────────────────────
class _WaveRing extends StatelessWidget {
  final double size;
  final double opacity;
  final Color color;
  const _WaveRing(
      {required this.size, required this.opacity, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(opacity), width: 2),
      ),
    );
  }
}

// ── Info Card ─────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 2),
          Text(label,
              style:
                  const TextStyle(color: AppTheme.textHint, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Contacts Bottom Sheet ─────────────────────────────────────────────────────
class _ContactsSheet extends StatelessWidget {
  final List<EmergencyContact> contacts;
  const _ContactsSheet({required this.contacts});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Emergency Contacts', style: AppTheme.headingSmall),
          const SizedBox(height: 4),
          Text('${contacts.length} contacts added',
              style:
                  const TextStyle(color: AppTheme.textHint, fontSize: 12)),
          const SizedBox(height: 16),
          if (contacts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('No contacts added yet',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ),
            )
          else
            ...contacts.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.green.withOpacity(0.1),
                      ),
                      child: Center(
                        child: Text(c.name[0].toUpperCase(),
                            style: const TextStyle(
                                color: AppTheme.green,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name,
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w500)),
                        Text(c.phone,
                            style: const TextStyle(
                                color: AppTheme.textHint, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}