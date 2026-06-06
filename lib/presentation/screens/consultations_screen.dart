import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qanoon_buddy/core/api_service.dart';
import 'package:qanoon_buddy/data/auth_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qanoon_buddy/presentation/screens/booking_screen.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qanoon_buddy/presentation/widgets/hover_button.dart';
import 'package:qanoon_buddy/core/theme.dart';
import 'package:permission_handler/permission_handler.dart';

class ConsultationsScreen extends ConsumerStatefulWidget {
  const ConsultationsScreen({super.key});

  @override
  ConsumerState<ConsultationsScreen> createState() =>
      _ConsultationsScreenState();
}

class _ConsultationsScreenState extends ConsumerState<ConsultationsScreen> {
  static const Color primary  = AppTheme.navyDeep;
  static const Color accent   = AppTheme.goldPremium;
  static const Color bg       = AppTheme.surface;
  static const Color textDark = AppTheme.textDark;
  static const Color textGrey = AppTheme.textGrey;
  static const Color border   = AppTheme.border;

  List<dynamic> _consultations = [];
  bool   _isLoading     = true;
  bool   _isLoadingMore = false;
  bool   _hasMore       = true;
  int    _skip          = 0;
  final int _limit      = 10;
  String? _error;
  final Set<String> _locallyReviewed = {};

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch({bool refresh = false}) async {
    if (refresh) {
      setState(() { 
        _isLoading = true; 
        _error = null; 
        _skip = 0; 
        _hasMore = true; 
        _consultations = []; 
      });
    } else {
      if (!_hasMore || _isLoadingMore) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final token = ref.read(authProvider).token;
      if (token == null) throw Exception('Not logged in');
      
      final isLawyer = ref.read(authProvider).user?['role'] == 'lawyer';
      
      final data = isLawyer 
          ? await apiService.getLawyerConsultations(token, skip: _skip, limit: _limit)
          : await apiService.getMyConsultations(token, skip: _skip, limit: _limit);

      if (mounted) {
        setState(() { 
          if (refresh) {
            _consultations = data;
          } else {
            _consultations.addAll(data);
          }
          _isLoading = false; 
          _isLoadingMore = false;
          _hasMore = data.length == _limit;
          if (_hasMore) _skip += _limit;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { 
          _isLoading = false; 
          _isLoadingMore = false;
          _error = e.toString(); 
        });
      }
    }
  }

  void _joinMeeting(String consultationId, String lawyerName) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final cleanId = consultationId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    final roomName = "qanoonbuddy$cleanId";
    const serverUrl = "https://meet.ffmuc.net";

    if (!kIsWeb) {
      await [Permission.camera, Permission.microphone].request();
    }

    try {
      if (kIsWeb) {
        final name = Uri.encodeComponent(user['full_name'] ?? "Client");
        final url = Uri.parse("$serverUrl/$roomName#config.prejoinPageEnabled=false&config.prejoinConfig.enabled=false&config.lobbyModeEnabled=false&config.lobby.enabled=false&config.enableLobby=false&config.requireDisplayName=false&config.disableLobby=true&config.startWithAudioMuted=true&config.startWithVideoMuted=false&userInfo.displayName=$name");
        try {
          await launchUrl(url, mode: LaunchMode.platformDefault);
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Could not launch meeting: $e')));
        }
        return;
      }

      final jitsiMeet = JitsiMeet();
      final options = JitsiMeetConferenceOptions(
        serverURL: serverUrl,
        room: roomName,
        configOverrides: {
          "startWithAudioMuted": true,
          "startWithVideoMuted": false,
          "subject": "Qanoon Buddy Legal Session",
          "prejoinPageEnabled": false,
          "lobbyModeEnabled": false,
          "enableLobby": false,
          "requireDisplayName": false,
          "disableLobby": true,
          "disableModeratorIndicator": true,
          "enableNoAudioDetection": true,
          "disableSafeRoomWarning": true,
          "p2p.enabled": false,
          "stereo": false,
          "resolution": 720,
        },
        featureFlags: {
          "unsaferoomwarning.enabled": false,
          "prejoinPageEnabled": false,
          "prejoinpage.enabled": false,
          "lobbyModeEnabled": false,
          "lobby-mode.enabled": false,
          "meetingNameEnabled": true,
          "inviteEnabled": false,
          "meeting-password-button.enabled": false,
          "security-options.enabled": false,
          "welcomepage.enabled": false,
          "toolbox.enabled": true,
        },
        userInfo: JitsiMeetUserInfo(
          displayName: user['full_name'],
        ),
      );

      jitsiMeet.join(options);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('⚠️ Video Call Error: $e'),
          backgroundColor: AppTheme.error,
        ));
      }
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pending'    : return AppTheme.pending;
      case 'accepted'   : return AppTheme.goldPremium;
      case 'in_progress': return AppTheme.inProgress;
      case 'completed'  : return AppTheme.completed;
      case 'cancelled'  : return AppTheme.cancelled;
      default           : return textGrey;
    }
  }

  Color _statusBg(String s) {
    switch (s) {
      case 'pending'    : return AppTheme.pending.withOpacity(0.1);
      case 'accepted'   : return AppTheme.goldPremium.withOpacity(0.1);
      case 'in_progress': return AppTheme.inProgress.withOpacity(0.1);
      case 'completed'  : return AppTheme.completed.withOpacity(0.1);
      case 'cancelled'  : return AppTheme.cancelled.withOpacity(0.1);
      default           : return AppTheme.surface;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'pending'    : return Icons.hourglass_empty_rounded;
      case 'accepted'   : return Icons.verified_rounded;
      case 'in_progress': return Icons.play_circle_outline_rounded;
      case 'completed'  : return Icons.task_alt_rounded;
      case 'cancelled'  : return Icons.cancel_outlined;
      default           : return Icons.help_outline;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'pending'    : return 'PENDING REVIEW';
      case 'accepted'   : return 'CONFIRMED';
      case 'in_progress': return 'IN SESSION';
      case 'completed'  : return 'COMPLETED';
      case 'cancelled'  : return 'TERMINATED';
      default           : return s.toUpperCase();
    }
  }

  void _showCancelDialog(BuildContext context, String consultationId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: AppTheme.cancelled.withOpacity(0.1), shape: BoxShape.circle),
              child: const Center(child: Icon(Icons.cancel_outlined, color: AppTheme.cancelled, size: 40)),
            ),
            const SizedBox(height: 24),
            const Text('Cancel Consultation?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textDark)),
            const SizedBox(height: 12),
            const Text(
              'Are you sure you want to cancel this consultation? This action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textGrey, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Keep', style: TextStyle(color: textDark, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: HoverButton(
                    onTap: () {
                      Navigator.pop(context);
                      _cancel(consultationId);
                    },
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.cancelled,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text('Cancel Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate().fade().scale(curve: Curves.easeOutBack),
    );
  }

  void _showReviewDialog(BuildContext context, String consultationId, String? lawyerId) {
    int _selectedRating = 5;
    final _reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(24),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(color: AppTheme.pending.withOpacity(0.1), shape: BoxShape.circle),
                child: const Center(child: Icon(Icons.star_rounded, color: AppTheme.pending, size: 40)),
              ),
              const SizedBox(height: 24),
              const Text('Leave a Review', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textDark)),
              const SizedBox(height: 8),
              const Text('How was your experience?', style: TextStyle(color: textGrey, fontSize: 14)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return HoverButton(
                    onTap: () => setS(() => _selectedRating = i + 1),
                    child: Icon(
                      Icons.star_rounded,
                      color: i < _selectedRating ? AppTheme.pending : const Color(0xFFE2E8F0),
                      size: 40,
                    ),
                  ).animate().scale(delay: (i * 100).ms, curve: Curves.easeOutBack);
                }),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                ),
                child: TextField(
                  controller: _reviewController,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 14, color: textDark),
                  decoration: const InputDecoration(
                    hintText: 'Share your experience...',
                    hintStyle: const TextStyle(color: textGrey, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(20),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: textDark, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: HoverButton(
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _submitReview(
                          consultationId,
                          _selectedRating,
                          _reviewController.text.trim().isEmpty ? null : _reviewController.text.trim(),
                        );
                      },
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text('Submit Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13), textAlign: TextAlign.center),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fade().scale(curve: Curves.easeOutBack),
      ),
    );
  }

  Future<void> _submitReview(String consultationId, int rating, String? reviewText) async {
    try {
      final token = ref.read(authProvider).token!;
      await apiService.submitReview(consultationId: consultationId, rating: rating, token: token, reviewText: reviewText);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Review submitted!'), backgroundColor: AppTheme.completed));
        setState(() { _locallyReviewed.add(consultationId); });
      }
      _fetch();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    }
  }

  String _formatDate(String d) {
    try {
      final dt = DateTime.parse(d).toLocal();
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) { return d; }
  }

  Future<void> _cancel(String consultationId) async {
    try {
      final token = ref.read(authProvider).token!;
      await apiService.cancelConsultation(consultationId, token);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Consultation cancelled.'), backgroundColor: AppTheme.cancelled));
      _fetch();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    }
  }

  String _formatDateTime(String? dt) {
    if (dt == null) return '';
    try {
      final parsed = DateTime.parse(dt).toLocal();
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      final hour = parsed.hour > 12 ? parsed.hour - 12 : parsed.hour;
      final ampm = parsed.hour >= 12 ? 'PM' : 'AM';
      final min = parsed.minute.toString().padLeft(2, '0');
      return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year} at $hour:$min $ampm PKT';
    } catch (_) { return dt; }
  }

  void _showRescheduleDialog(BuildContext context, String consultationId) {
    DateTime? newDate;
    TimeOfDay? newTime;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(28),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_month_rounded, color: accent, size: 48),
              const SizedBox(height: 16),
              const Text('Reschedule', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textDark)),
              const SizedBox(height: 8),
              const Text('Pick a new date and time', style: TextStyle(color: textGrey, fontSize: 14)),
              const SizedBox(height: 24),
              HoverButton(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 60)),
                  );
                  if (picked != null) setS(() => newDate = picked);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                  child: Text(
                    newDate != null ? '${newDate!.day}/${newDate!.month}/${newDate!.year}' : 'Select Date',
                    style: TextStyle(color: newDate != null ? textDark : textGrey, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              HoverButton(
                onTap: () async {
                  final picked = await showTimePicker(context: ctx, initialTime: const TimeOfDay(hour: 10, minute: 0));
                  if (picked != null) setS(() => newTime = picked);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                  child: Text(
                    newTime != null ? '${newTime!.hour}:${newTime!.minute.toString().padLeft(2, '0')}' : 'Select Time',
                    style: TextStyle(color: newTime != null ? textDark : textGrey, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: textDark, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (newDate == null || newTime == null) return;
                        Navigator.pop(ctx);
                        final dt = DateTime(newDate!.year, newDate!.month, newDate!.day, newTime!.hour, newTime!.minute);
                        final iso = '${dt.toIso8601String()}+05:00';
                        try {
                          final token = ref.read(authProvider).token!;
                          await apiService.rescheduleConsultation(consultationId: consultationId, newScheduledAt: iso, token: token);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Rescheduled!'), backgroundColor: AppTheme.completed));
                          _fetch();
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Reschedule', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, AppTheme.navyLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    _topBtn(Icons.chevron_left_rounded, () => Navigator.pop(context)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('LEGAL SESSIONS',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(
                            ref.read(authProvider).user?['role'] == 'lawyer'
                                ? 'MANAGING CLIENT CASELOAD'
                                : 'MONITORING APPOINTMENT STATUS',
                            style: TextStyle(
                                color: accent.withOpacity(0.8),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                    _topBtn(Icons.refresh_rounded, () => _fetch(refresh: true)),
                  ],
                ),
              ),
            ),
          ).animate().slideY(begin: -0.1).fade(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: accent))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 48),
                            const SizedBox(height: 16),
                            Text('RETRIEVAL ERROR\n$_error', textAlign: TextAlign.center, style: const TextStyle(color: textGrey, fontSize: 12, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 24),
                            HoverButton(
                              onTap: _fetch,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(12)),
                                child: const Text('RETRY SYNC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _consultations.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 100, height: 100,
                                  decoration: BoxDecoration(color: accent.withOpacity(0.05), shape: BoxShape.circle),
                                  child: const Center(child: Icon(Icons.history_edu_rounded, color: accent, size: 40)),
                                ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                                const SizedBox(height: 24),
                                const Text('NO SESSIONS FOUND', style: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 8),
                                const Text('BEGIN YOUR LEGAL JOURNEY BY BOOKING A COUNSEL',
                                    style: TextStyle(color: textGrey, fontSize: 12, fontWeight: FontWeight.w500),
                                    textAlign: TextAlign.center),
                                const SizedBox(height: 32),
                                HoverButton(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [primary, AppTheme.navyLight]),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                            color: primary.withOpacity(0.3),
                                            blurRadius: 15,
                                            offset: const Offset(0, 8))
                                      ],
                                    ),
                                    child: const Text('FIND COUNSEL',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                                  ),
                                ).animate().fade().slideY(begin: 0.1),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _consultations.length + (_hasMore ? 1 : 0),
                            itemBuilder: (_, i) {
                              if (i == _consultations.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8, bottom: 40),
                                  child: _isLoadingMore
                                      ? const Center(child: CircularProgressIndicator(color: accent))
                                      : HoverButton(
                                          onTap: () => _fetch(),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: border),
                                            ),
                                            child: const Center(
                                              child: Text('LOAD MORE SESSIONS',
                                                  style: TextStyle(color: textGrey, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                                            ),
                                          ),
                                        ),
                                );
                              }
                              final c = _consultations[i];
                              final status = c['status'] ?? 'pending';
                              final sColor = _statusColor(status);
                              final sBg = _statusBg(status);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 20),
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: border),
                                  boxShadow: [
                                    BoxShadow(
                                        color: primary.withOpacity(0.06),
                                        blurRadius: 24,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 12))
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header: Status Badge & Date
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: sBg,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: sColor.withOpacity(0.2)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(_statusIcon(status), color: sColor, size: 14),
                                              const SizedBox(width: 6),
                                              Text(_statusLabel(status),
                                                style: TextStyle(
                                                  color: sColor,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            const Icon(Icons.history_rounded, color: textGrey, size: 14),
                                            const SizedBox(width: 4),
                                            Text(_formatDate(c['created_at'] ?? ''),
                                                style: const TextStyle(color: textGrey, fontSize: 12, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    // Title
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(c['query_summary'] ?? 'LEGAL CONSULTATION',
                                              style: const TextStyle(
                                                  color: textDark,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 18,
                                                  height: 1.3,
                                                  letterSpacing: -0.3)),
                                        ),
                                        if (c['escrow_status'] == 'held') ...[
                                          const SizedBox(width: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                            decoration: BoxDecoration(color: accent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                            child: Row(
                                              children: const [
                                                Icon(Icons.shield_rounded, color: accent, size: 12),
                                                SizedBox(width: 4),
                                                Text('ESCROW', style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w800)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                            
                                    const SizedBox(height: 20),
                                    
                                    // Appointment Box
                                    if (c['scheduled_at'] != null) ...[
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: border),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(12),
                                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
                                              ),
                                              child: const Icon(Icons.calendar_month_rounded, color: accent, size: 24),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('APPOINTMENT',
                                                    style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
                                                  const SizedBox(height: 4),
                                                  Text(_formatDateTime(c['scheduled_at']),
                                                    style: const TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.w800)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                    
                                    // Divider
                                    Divider(height: 1, color: border.withOpacity(0.5)),
                                    const SizedBox(height: 16),
                                    
                                    // Footer
                                    Row(
                                      children: [
                                        // Category Pill
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                                          child: Text((c['category'] ?? 'general').toString().replaceAll('_', ' ').toUpperCase(),
                                            style: const TextStyle(color: textDark, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                                        ),
                                        const SizedBox(width: 8),
                                        // Meeting Type
                                        Row(
                                          children: [
                                            Icon((c['meeting_type'] ?? 'online') == 'online' ? Icons.videocam_rounded : Icons.business_rounded, color: textGrey, size: 16),
                                            const SizedBox(width: 4),
                                            Text((c['meeting_type'] ?? 'online') == 'online' ? 'VIRTUAL' : 'CHAMBER',
                                              style: const TextStyle(color: textGrey, fontSize: 11, fontWeight: FontWeight.w800)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    
                                    // Video Session button
                                    if ((status == 'accepted' || status == 'in_progress') && (c['meeting_type'] ?? 'online') == 'online')
                                      Padding(
                                        padding: const EdgeInsets.only(top: 20),
                                        child: HoverButton(
                                          onTap: () => _joinMeeting(c['id'], c['lawyer_name'] ?? 'Lawyer'),
                                          child: Container(
                                            width: double.infinity,
                                            height: 52,
                                            decoration: BoxDecoration(
                                              color: accent,
                                              borderRadius: BorderRadius.circular(16),
                                              boxShadow: [BoxShadow(color: accent.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                                            ),
                                            child: const Center(
                                              child: Text('JOIN VIDEO SESSION',
                                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    
                                    // Actions row
                                    if (status == 'pending' || status == 'accepted' || (status == 'completed' && c['is_reviewed'] != true && !_locallyReviewed.contains(c['id']) && ref.read(authProvider).user?['role'] != 'lawyer'))
                                      Padding(
                                        padding: const EdgeInsets.only(top: 20),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            if (status == 'pending' || status == 'accepted')
                                              _actionBtn('SCHEDULE', accent.withOpacity(0.1), accent, () => _showRescheduleDialog(context, c['id'])),
                                            if (status == 'pending') const SizedBox(width: 10),
                                            if (status == 'pending')
                                              _actionBtn('CANCEL', AppTheme.cancelled.withOpacity(0.1), AppTheme.cancelled, () => _showCancelDialog(context, c['id'])),
                                            if (status == 'completed' && c['is_reviewed'] != true && !_locallyReviewed.contains(c['id']) && ref.read(authProvider).user?['role'] != 'lawyer')
                                              HoverButton(
                                                onTap: () => _showReviewDialog(context, c['id'], c['lawyer_id']),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                  decoration: BoxDecoration(
                                                    color: accent.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(color: accent),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: const [
                                                      Icon(Icons.star, color: accent, size: 14),
                                                      SizedBox(width: 6),
                                                      Text('RATE COUNSEL', style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ).animate().fade(delay: (i * 60).ms).slideY(begin: 0.08);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _tag(IconData icon, String text, {bool isAccent = false}) {
    return Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: isAccent ? accent : textGrey, size: 12), const SizedBox(width: 6), Text(text.toUpperCase(), style: TextStyle(color: isAccent ? accent : textGrey, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5))]);
  }

  Widget _topBtn(IconData icon, VoidCallback onTap) {
    return HoverButton(
        onTap: onTap,
        child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1))),
            child: Icon(icon, color: Colors.white, size: 20)));
  }

  Widget _actionBtn(String label, Color bg, Color text, VoidCallback onTap, {IconData? icon}) {
    return HoverButton(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: text.withOpacity(0.2))), child: Row(mainAxisSize: MainAxisSize.min, children: [if (icon != null) ...[Icon(icon, color: text, size: 14), const SizedBox(width: 6)], Text(label, style: TextStyle(color: text, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5))])));
  }
}