import 'package:flutter/material.dart';
import 'dart:async';
import '../theme.dart';
import '../models/emergency_contact.dart';
import 'alert_screen.dart';

typedef OnTimerStateChanged = void Function({
  required bool timerRunning,
  required bool timerPaused,
  required bool isUrgent,
  required String timerDisplay,
});

class SafetyTimerTab extends StatefulWidget {
  final List<EmergencyContact> contacts;
  final OnTimerStateChanged onStateChanged;

  const SafetyTimerTab({
    super.key,
    required this.contacts,
    required this.onStateChanged,
  });

  @override
  State<SafetyTimerTab> createState() => _SafetyTimerTabState();
}

class _SafetyTimerTabState extends State<SafetyTimerTab> {
  static const _orange = Color(0xFFFFAB40);

  // ── Picker state ──────────────────────────────────────────────────────────
  int _selectedHours = 0;
  int _selectedMinutes = 5;
  int _selectedSeconds = 0;

  late FixedExtentScrollController _hourCtrl;
  late FixedExtentScrollController _minuteCtrl;
  late FixedExtentScrollController _secondCtrl;

  // ── Timer state ───────────────────────────────────────────────────────────
  bool _timerRunning = false;
  bool _timerPaused = false;
  int _remainingSeconds = 0;
  Timer? _countdownTimer;

  // ── Derived ───────────────────────────────────────────────────────────────
  int get _totalSelected =>
      _selectedHours * 3600 + _selectedMinutes * 60 + _selectedSeconds;

  double get _timerProgress {
    final total = _totalSelected;
    if (total == 0) return 0;
    return 1 - (_remainingSeconds / total);
  }

  bool get _isUrgent => _remainingSeconds <= 30 && _timerRunning;

  String get _timerDisplay {
    final h = _remainingSeconds ~/ 3600;
    final m = (_remainingSeconds % 3600) ~/ 60;
    final s = _remainingSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _accentColor => _isUrgent ? AppTheme.red : _orange;

  @override
  void initState() {
    super.initState();
    _hourCtrl = FixedExtentScrollController(initialItem: _selectedHours);
    _minuteCtrl = FixedExtentScrollController(initialItem: _selectedMinutes);
    _secondCtrl = FixedExtentScrollController(initialItem: _selectedSeconds);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    _secondCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onStateChanged(
      timerRunning: _timerRunning,
      timerPaused: _timerPaused,
      isUrgent: _isUrgent,
      timerDisplay: _timerDisplay,
    );
  }

  // ── Timer controls ────────────────────────────────────────────────────────
  void _startTimer() {
    if (_totalSelected == 0) return;
    _countdownTimer?.cancel();
    setState(() {
      _remainingSeconds = _totalSelected;
      _timerRunning = true;
      _timerPaused = false;
    });
    _notify();
    _runTick();
  }

  void _runTick() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds <= 0) {
        t.cancel();
        setState(() => _timerRunning = false);
        _notify();
        _simulateAlert();
      } else {
        setState(() => _remainingSeconds--);
        _notify();
      }
    });
  }

  void _pauseTimer() {
    _countdownTimer?.cancel();
    setState(() => _timerPaused = true);
    _notify();
  }

  void _resumeTimer() {
    setState(() => _timerPaused = false);
    _notify();
    _runTick();
  }

  void _resetTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _timerRunning = false;
      _timerPaused = false;
      _remainingSeconds = 0;
    });
    _notify();
  }

  void _applyPreset(int h, int m, int s) {
    setState(() {
      _selectedHours = h;
      _selectedMinutes = m;
      _selectedSeconds = s;
    });
    _hourCtrl.jumpToItem(h);
    _minuteCtrl.jumpToItem(m);
    _secondCtrl.jumpToItem(s);
  }

  void _simulateAlert() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AlertScreen(
        contactCount:
            widget.contacts.isEmpty ? 5 : widget.contacts.length,
        onBack: () => Navigator.of(context).pop(),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _orange.withOpacity(0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _orange.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.timer_rounded,
                        color: _orange, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Safety Timer',
                            style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 16)),
                        SizedBox(height: 3),
                        Text(
                            'SOS auto-sends to your contacts when timer ends',
                            style: TextStyle(
                                color: AppTheme.textHint, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── RUNNING STATE ─────────────────────────────────────────────
            if (_timerRunning || _timerPaused) ...[
              Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 230,
                      height: 230,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 230,
                            height: 230,
                            child: CircularProgressIndicator(
                              value: _timerProgress,
                              strokeWidth: 12,
                              backgroundColor: AppTheme.surfaceLight,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  _accentColor),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_timerPaused)
                                const Text('PAUSED',
                                    style: TextStyle(
                                        color: AppTheme.textHint,
                                        fontSize: 11,
                                        letterSpacing: 2,
                                        fontWeight: FontWeight.w600))
                              else
                                Text(_isUrgent ? '🚨' : '⏱',
                                    style: const TextStyle(fontSize: 24)),
                              const SizedBox(height: 6),
                              Text(
                                _timerDisplay,
                                style: TextStyle(
                                  color: _accentColor,
                                  fontSize: 44,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isUrgent
                                    ? 'SOS sending soon!'
                                    : _timerPaused
                                        ? 'Timer paused'
                                        : 'SOS Countdown',
                                style: TextStyle(
                                  color: _isUrgent
                                      ? AppTheme.red
                                      : AppTheme.textHint,
                                  fontSize: 12,
                                  fontWeight: _isUrgent
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _timerProgress,
                        minHeight: 6,
                        backgroundColor: AppTheme.surfaceLight,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(_accentColor),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${widget.contacts.isEmpty ? 'No' : widget.contacts.length} contacts will receive SOS',
                          style: const TextStyle(
                              color: AppTheme.textHint, fontSize: 11),
                        ),
                        Text(
                          '${(_timerProgress * 100).toInt()}% elapsed',
                          style: TextStyle(
                              color: _accentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _timerPaused ? _resumeTimer : _pauseTimer,
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: _orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: _orange.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _timerPaused
                                  ? Icons.play_arrow_rounded
                                  : Icons.pause_rounded,
                              color: _orange,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _timerPaused ? 'Resume' : 'Pause',
                              style: const TextStyle(
                                  color: _orange,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _resetTimer,
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: const Icon(Icons.refresh_rounded,
                          color: AppTheme.textSecondary, size: 22),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              GestureDetector(
                onTap: _resetTimer,
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: const Center(
                    child: Text('Cancel Timer',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 14)),
                  ),
                ),
              ),
            ]

            // ── IDLE STATE ────────────────────────────────────────────────
            else ...[
              const Center(
                child: Text('SET TIMER DURATION', style: AppTheme.labelText),
              ),
              const SizedBox(height: 16),

              Center(
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _DrumPicker(
                          controller: _hourCtrl,
                          itemCount: 24,
                          label: 'HH',
                          selectedValue: _selectedHours,
                          onChanged: (v) =>
                              setState(() => _selectedHours = v),
                        ),
                      ),
                      const _DrumSeparator(),
                      Expanded(
                        child: _DrumPicker(
                          controller: _minuteCtrl,
                          itemCount: 60,
                          label: 'MM',
                          selectedValue: _selectedMinutes,
                          onChanged: (v) =>
                              setState(() => _selectedMinutes = v),
                        ),
                      ),
                      const _DrumSeparator(),
                      Expanded(
                        child: _DrumPicker(
                          controller: _secondCtrl,
                          itemCount: 60,
                          label: 'SS',
                          selectedValue: _selectedSeconds,
                          onChanged: (v) =>
                              setState(() => _selectedSeconds = v),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text('QUICK PRESETS', style: AppTheme.labelText),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _PresetChip(label: '30s',    h: 0, m: 0,  s: 30, selH: _selectedHours, selM: _selectedMinutes, selS: _selectedSeconds, onTap: _applyPreset),
                  _PresetChip(label: '1 min',  h: 0, m: 1,  s: 0,  selH: _selectedHours, selM: _selectedMinutes, selS: _selectedSeconds, onTap: _applyPreset),
                  _PresetChip(label: '5 min',  h: 0, m: 5,  s: 0,  selH: _selectedHours, selM: _selectedMinutes, selS: _selectedSeconds, onTap: _applyPreset),
                  _PresetChip(label: '10 min', h: 0, m: 10, s: 0,  selH: _selectedHours, selM: _selectedMinutes, selS: _selectedSeconds, onTap: _applyPreset),
                  _PresetChip(label: '15 min', h: 0, m: 15, s: 0,  selH: _selectedHours, selM: _selectedMinutes, selS: _selectedSeconds, onTap: _applyPreset),
                  _PresetChip(label: '30 min', h: 0, m: 30, s: 0,  selH: _selectedHours, selM: _selectedMinutes, selS: _selectedSeconds, onTap: _applyPreset),
                  _PresetChip(label: '1 hour', h: 1, m: 0,  s: 0,  selH: _selectedHours, selM: _selectedMinutes, selS: _selectedSeconds, onTap: _applyPreset),
                ],
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: AppTheme.accentBlue, size: 15),
                        SizedBox(width: 8),
                        Text('How it works',
                            style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _StepRow(num: '1', text: 'Set your timer duration above'),
                    _StepRow(num: '2', text: 'Tap START — countdown begins'),
                    _StepRow(
                        num: '3',
                        text: 'If you\'re safe, tap Cancel before it hits 0'),
                    _StepRow(
                        num: '4',
                        text:
                            'If timer reaches 0, SOS auto-sends to ${widget.contacts.isEmpty ? 'your contacts' : '${widget.contacts.length} contacts'}'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              GestureDetector(
                onTap: _startTimer,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color:
                        _totalSelected == 0 ? AppTheme.surfaceLight : _orange,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _totalSelected == 0
                        ? null
                        : [
                            BoxShadow(
                              color: _orange.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            )
                          ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow_rounded,
                          color: _totalSelected == 0
                              ? AppTheme.textHint
                              : AppTheme.background,
                          size: 26),
                      const SizedBox(width: 8),
                      Text(
                        'START Safety Timer',
                        style: TextStyle(
                          color: _totalSelected == 0
                              ? AppTheme.textHint
                              : AppTheme.background,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Drum Picker ───────────────────────────────────────────────────────────────
class _DrumPicker extends StatelessWidget {
  final FixedExtentScrollController controller;
  final int itemCount;
  final String label;
  final int selectedValue;
  final void Function(int) onChanged;

  static const _orange = Color(0xFFFFAB40);

  const _DrumPicker({
    required this.controller,
    required this.itemCount,
    required this.label,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppTheme.textHint,
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        SizedBox(
          height: 158,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 42,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: _orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _orange.withOpacity(0.22)),
                ),
              ),
              ListWheelScrollView.useDelegate(
                controller: controller,
                itemExtent: 42,
                physics: const FixedExtentScrollPhysics(),
                perspective: 0.003,
                diameterRatio: 1.5,
                onSelectedItemChanged: onChanged,
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: itemCount,
                  builder: (context, index) {
                    final isSelected = index == selectedValue;
                    return Center(
                      child: Text(
                        index.toString().padLeft(2, '0'),
                        style: TextStyle(
                          color: isSelected ? _orange : AppTheme.textHint,
                          fontSize: isSelected ? 26 : 18,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w400,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DrumSeparator extends StatelessWidget {
  const _DrumSeparator();
  static const _orange = Color(0xFFFFAB40);

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Text(':',
          style: TextStyle(
              color: _orange, fontSize: 30, fontWeight: FontWeight.w800)),
    );
  }
}

// ── Preset Chip ───────────────────────────────────────────────────────────────
class _PresetChip extends StatelessWidget {
  final String label;
  final int h, m, s;
  final int selH, selM, selS;
  final void Function(int, int, int) onTap;

  static const _orange = Color(0xFFFFAB40);

  const _PresetChip({
    required this.label,
    required this.h,
    required this.m,
    required this.s,
    required this.selH,
    required this.selM,
    required this.selS,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selH == h && selM == m && selS == s;
    return GestureDetector(
      onTap: () => onTap(h, m, s),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _orange.withOpacity(0.12) : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _orange : AppTheme.borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? _orange : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ── Step Row ──────────────────────────────────────────────────────────────────
class _StepRow extends StatelessWidget {
  final String num;
  final String text;
  const _StepRow({required this.num, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.accentBlue.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(num,
                  style: const TextStyle(
                      color: AppTheme.accentBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }
}