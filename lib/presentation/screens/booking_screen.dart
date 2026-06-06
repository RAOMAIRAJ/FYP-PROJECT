import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qanoon_buddy/core/api_service.dart';
import 'package:qanoon_buddy/data/auth_provider.dart';
import 'package:qanoon_buddy/presentation/screens/payment_screen.dart';
import 'package:qanoon_buddy/presentation/screens/consultations_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qanoon_buddy/presentation/widgets/hover_button.dart';
import 'package:qanoon_buddy/core/theme.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> lawyer;
  const BookingScreen({super.key, required this.lawyer});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final _queryController = TextEditingController();
  final _notesController = TextEditingController();
  String  _meetingType    = 'online';
  String  _category       = 'general';
  bool    _isLoading      = false;
  String? _consultationId;

  // ── Scheduling ──
  DateTime? _selectedDate;
  Map<String, dynamic>? _selectedSlot;
  List<dynamic> _availableSlots = [];
  bool _loadingSlots = false;

  static const Color primary  = AppTheme.navyDeep;
  static const Color accent   = AppTheme.goldPremium;
  static const Color bg       = AppTheme.surface;
  static const Color textDark = AppTheme.textDark;
  static const Color textGrey = AppTheme.textGrey;
  static const Color border   = AppTheme.border;

  final List<Map<String, String>> _categories = [
    {'value': 'family_law', 'label': '🏛 FAMILY'},
    {'value': 'tax_law',    'label': '💰 TAX'},
    {'value': 'general',    'label': '⚖ GENERAL'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchAvailability();
  }

  @override
  void dispose() {
    _queryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchAvailability() async {
    setState(() => _loadingSlots = true);
    try {
      final lawyerId = widget.lawyer['lawyer_id']?.toString() ?? widget.lawyer['id']?.toString() ?? '';
      final slots = await apiService.getLawyerAvailability(lawyerId);
      if (mounted) setState(() { _availableSlots = slots; _loadingSlots = false; });
    } catch (e) {
      if (mounted) setState(() => _loadingSlots = false);
    }
  }

  List<dynamic> _slotsForDate(DateTime date) {
    final dayOfWeek = date.weekday - 1;
    return _availableSlots.where((s) => s['day_of_week'] == dayOfWeek).toList();
  }

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: primary,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: textDark,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: primary, textStyle: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _selectedSlot = null;
      });
    }
  }

  String _buildScheduledAt() {
    if (_selectedDate == null || _selectedSlot == null) return '';
    final parts = (_selectedSlot!['start_time'] as String).split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final dt = DateTime(
      _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
      hour, minute,
    );
    return '${dt.toIso8601String()}+05:00';
  }

  void _book() async {
    if (_queryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your legal issue'), backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = ref.read(authProvider).token;
      if (token == null) throw Exception('Not logged in');

      final scheduledAt = _buildScheduledAt();

      final result = await apiService.bookConsultation(
        lawyerId    : (widget.lawyer['lawyer_id'] ?? widget.lawyer['id']).toString(),
        querySummary: _queryController.text.trim(),
        category    : _category,
        meetingType : _meetingType,
        token       : token,
        notes       : _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        scheduledAt : scheduledAt.isEmpty ? null : scheduledAt,
      );

      _consultationId = result['consultation_id'];
      setState(() => _isLoading = false);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => PopScope(
            canPop: false,
            child: AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              contentPadding: const EdgeInsets.all(32),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(color: accent.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Center(child: Icon(Icons.verified_rounded, color: accent, size: 50)),
                  ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 32),
                  const Text('BOOKING REQUESTED', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textDark, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  Text(
                    scheduledAt.isNotEmpty
                      ? 'Session pending for ${_selectedDate!.day}/${_selectedDate!.month} at ${_selectedSlot!['start_time']}.\nComplete your vault escrow to confirm.'
                      : 'Finalize your consultation with ${widget.lawyer['name']} by completing the security payment.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: textGrey, fontSize: 13, height: 1.6, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 32),
                  HoverButton(
                    onTap: () {
                      Navigator.pop(dialogContext);
                      Navigator.pushReplacement(context, MaterialPageRoute(
                        builder: (_) => PaymentScreen(
                          consultationId: _consultationId!,
                          amount: (widget.lawyer['consultation_fee'] ?? 0).toDouble(),
                          lawyerName: widget.lawyer['name'] ?? '',
                        ),
                      ));
                    },
                    child: Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [primary, AppTheme.navyDeep]),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                      ),
                      child: const Center(
                        child: Text('SECURE WITH ESCROW', 
                          style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () async { 
                      try {
                        await apiService.cancelConsultation(_consultationId!, token);
                      } catch (e) {
                        debugPrint('Failed to cancel consultation: $e');
                      }
                      if (context.mounted) {
                        Navigator.pop(dialogContext); 
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ConsultationsScreen())); 
                      }
                    },
                    child: const Text('CANCEL REQUEST',
                      style: TextStyle(color: AppTheme.error, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  ),
                ],
              ).animate().fade(),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final errorStr = e.toString();
        final isBooked = errorStr.contains('409') || errorStr.toLowerCase().contains('booked');
        
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            contentPadding: const EdgeInsets.all(32),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Center(child: Icon(Icons.event_busy_rounded, color: AppTheme.error, size: 40)),
                ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 24),
                Text(isBooked ? 'TIME SLOT UNAVAILABLE' : 'BOOKING ERROR', 
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textDark, letterSpacing: 1), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(
                  isBooked 
                    ? 'This specific time slot has already been booked by another client. Please select a different available timeline.'
                    : 'An unexpected security error occurred while processing your booking.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: textGrey, fontSize: 13, height: 1.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 32),
                HoverButton(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: primary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: const Center(
                      child: Text('UNDERSTOOD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
                    ),
                  ),
                ),
              ],
            ).animate().fade(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lawyer = widget.lawyer;
    final rating = (lawyer['avg_rating'] ?? 0).toDouble();

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // ── Elite Booking Header ──
          Container(
            padding: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: primary,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
              boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    _topBtn(Icons.arrow_back_rounded, () => Navigator.pop(context)),
                    const SizedBox(width: 20),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SECURE COUNSEL', 
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                          SizedBox(height: 4),
                          Text('ELITE LEGAL PROTOCOL', 
                            style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().slideY(begin: -0.2).fade(duration: 400.ms),

          // ── Scrollable Form ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Premium Lawyer Card ──
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: border),
                      boxShadow: [BoxShadow(color: primary.withOpacity(0.06), blurRadius: 30, offset: const Offset(0, 15))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: accent.withOpacity(0.3), width: 2),
                          ),
                          child: Center(
                            child: const Icon(Icons.gavel_rounded, size: 32, color: accent)
                              .animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(end: 1.1, duration: 2.seconds),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(lawyer['name'] ?? 'LEGAL COUNSEL',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textDark, letterSpacing: -0.5)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: primary.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                                child: Text(
                                  (lawyer['specialization'] ?? 'General').toString().toUpperCase().replaceAll('_', ' '),
                                  style: const TextStyle(color: primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: accent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.star_rounded, color: accent, size: 14),
                                        const SizedBox(width: 4),
                                        Text('$rating', style: const TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w900)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: textGrey.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.payments_outlined, color: textGrey, size: 14),
                                        const SizedBox(width: 4),
                                        Text('₨${lawyer['consultation_fee']}', style: const TextStyle(color: textGrey, fontSize: 12, fontWeight: FontWeight.w800)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fade(duration: 500.ms).slideY(begin: 0.1),

                  const SizedBox(height: 32),

                  // ── Protocol Sections ──
                  _sectionLabel('SESSION PROTOCOL'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _MeetingCard(
                        value: 'online', current: _meetingType, emoji: '📹', title: 'VIRTUAL', sub: 'SECURE LINK',
                        onTap: () => setState(() => _meetingType = 'online'),
                      )),
                      const SizedBox(width: 16),
                      Expanded(child: _MeetingCard(
                        value: 'in_person', current: _meetingType, emoji: '🏢', title: 'CHAMBER', sub: 'OFFICE VISIT',
                        onTap: () => setState(() => _meetingType = 'in_person'),
                      )),
                    ],
                  ).animate().fade(delay: 100.ms),

                  const SizedBox(height: 32),

                  _sectionLabel('LEGAL CATEGORY'),
                  const SizedBox(height: 16),
                  Row(
                    children: _categories.map((c) {
                      final selected = _category == c['value'];
                      return Expanded(
                        child: HoverButton(
                          onTap: () => setState(() => _category = c['value']!),
                          child: AnimatedContainer(
                            duration: 300.ms,
                            margin: EdgeInsets.only(right: c != _categories.last ? 12 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: selected ? accent.withOpacity(0.15) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: selected ? accent : border, width: selected ? 2 : 1),
                              boxShadow: selected ? [BoxShadow(color: accent.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))] : [],
                            ),
                            child: Text(c['label']!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: selected ? AppTheme.navyDeep : textGrey,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                )),
                          ),
                        ),
                      );
                    }).toList(),
                  ).animate().fade(delay: 200.ms),

                  const SizedBox(height: 32),

                  _sectionLabel('TIMELINE'),
                  const SizedBox(height: 16),
                  HoverButton(
                    onTap: _pickDate,
                    child: AnimatedContainer(
                      duration: 300.ms,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _selectedDate != null ? accent.withOpacity(0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: _selectedDate != null ? accent : border, width: _selectedDate != null ? 2 : 1),
                        boxShadow: _selectedDate != null ? [BoxShadow(color: accent.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))] : [],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _selectedDate != null ? accent.withOpacity(0.2) : primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(Icons.calendar_month_rounded, color: _selectedDate != null ? accent : primary, size: 26),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedDate != null ? 'SCHEDULED DATE' : 'SELECT PREFERRED DATE',
                                  style: TextStyle(color: _selectedDate != null ? accent : textGrey, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedDate != null
                                    ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                    : 'Choose a timeline for your session',
                                  style: TextStyle(
                                    color: textDark,
                                    fontSize: _selectedDate != null ? 20 : 13,
                                    fontWeight: _selectedDate != null ? FontWeight.w900 : FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: _selectedDate != null ? accent : textGrey, size: 24),
                        ],
                      ),
                    ),
                  ).animate().fade(delay: 300.ms),

                  if (_selectedDate != null) ...[
                    const SizedBox(height: 20),
                    if (_loadingSlots)
                      const Center(child: CircularProgressIndicator(color: accent))
                    else if (_slotsForDate(_selectedDate!).isEmpty)
                      _infoCard('NO AVAILABILITY', 'The counsel has not listed slots for this date.').animate().fade()
                    else
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _slotsForDate(_selectedDate!).map((slot) {
                          final isSelected = _selectedSlot?['id'] == slot['id'];
                          return HoverButton(
                            onTap: () => setState(() => _selectedSlot = slot),
                            child: AnimatedContainer(
                              duration: 300.ms,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              decoration: BoxDecoration(
                                color: isSelected ? primary : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isSelected ? primary : border),
                                boxShadow: isSelected ? [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 6))] : [],
                              ),
                              child: Text(
                                slot['display']?.toString().split(' ').skip(1).join(' ') ?? '${slot['start_time']} - ${slot['end_time']}',
                                style: TextStyle(
                                  color: isSelected ? accent : textDark,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ).animate().fade().slideY(),
                  ],

                  const SizedBox(height: 32),

                  _sectionLabel('CASE BRIEF'),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: border),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                    ),
                    child: TextField(
                      controller: _queryController,
                      maxLines: 5,
                      style: const TextStyle(fontSize: 15, color: textDark, fontWeight: FontWeight.w700),
                      decoration: const InputDecoration(
                        hintText: 'Enter specific details of your legal issue for the counsel to review...',
                        hintStyle: TextStyle(color: AppTheme.textGrey, fontSize: 14, fontWeight: FontWeight.w600),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(24),
                      ),
                    ),
                  ).animate().fade(delay: 400.ms),

                  const SizedBox(height: 48),

                  // ── Final Action ──
                  HoverButton(
                    onTap: _isLoading ? null : _book,
                    child: Container(
                      width: double.infinity,
                      height: 68,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [accent, AppTheme.goldPremium]),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: accent.withOpacity(0.4), blurRadius: 24, offset: const Offset(0, 12))],
                      ),
                      child: Center(
                        child: _isLoading
                            ? const CircularProgressIndicator(color: primary)
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.lock_outline_rounded, color: primary, size: 22),
                                  SizedBox(width: 12),
                                  Text('INITIALIZE SECURE BOOKING',
                                      style: TextStyle(color: primary, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                                ],
                              ),
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2.seconds, color: Colors.white.withOpacity(0.4)),
                  ).animate().fade(delay: 500.ms).slideY(begin: 0.2),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text, 
    style: const TextStyle(color: textGrey, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5));

  Widget _infoCard(String title, String sub) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.error.withOpacity(0.1))),
    child: Row(
      children: [
        const Icon(Icons.info_outline_rounded, color: AppTheme.error, size: 24),
        const SizedBox(width: 16),
        Expanded(child: Text('$title: $sub', style: const TextStyle(color: AppTheme.error, fontSize: 13, fontWeight: FontWeight.w800))),
      ],
    ),
  );

  Widget _topBtn(IconData icon, VoidCallback onTap) {
    return HoverButton(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1), 
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  final String value, current, emoji, title, sub;
  final VoidCallback onTap;
  const _MeetingCard({required this.value, required this.current, required this.emoji, required this.title, required this.sub, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    return HoverButton(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 300.ms,
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: selected ? AppTheme.navyDeep : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: selected ? AppTheme.navyDeep : AppTheme.border, width: selected ? 2 : 1),
          boxShadow: selected ? [BoxShadow(color: AppTheme.navyDeep.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected ? Colors.white.withOpacity(0.1) : AppTheme.navyDeep.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 28))
                .animate(target: selected ? 1 : 0).scaleXY(end: 1.2, duration: 200.ms, curve: Curves.easeOutBack),
            ),
            const SizedBox(height: 24),
            Text(title, style: TextStyle(color: selected ? AppTheme.goldPremium : AppTheme.textDark, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Text(sub, style: TextStyle(color: selected ? Colors.white70 : AppTheme.textGrey, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}