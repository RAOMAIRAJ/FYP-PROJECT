import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qanoon_buddy/core/api_service.dart';
import 'package:qanoon_buddy/data/auth_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qanoon_buddy/presentation/widgets/hover_button.dart';
import 'package:qanoon_buddy/core/theme.dart';
import 'package:qanoon_buddy/core/db_helper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qanoon_buddy/presentation/screens/support/my_tickets_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qanoon_buddy/presentation/screens/lawyer/ai_client_summary_screen.dart';
import 'package:qanoon_buddy/presentation/screens/lawyer/legal_marketplace_screen.dart';
import 'package:qanoon_buddy/presentation/screens/lawyer/lawyer_referral_screen.dart';
import 'package:qanoon_buddy/presentation/screens/lawyer/ai_case_assistant_screen.dart';


class LawyerDashboardScreen extends ConsumerStatefulWidget {
  const LawyerDashboardScreen({super.key});

  @override
  ConsumerState<LawyerDashboardScreen> createState() =>
      _LawyerDashboardScreenState();
}

class _LawyerDashboardScreenState
    extends ConsumerState<LawyerDashboardScreen>
    with SingleTickerProviderStateMixin {
  static const Color primary  = AppTheme.navyDeep;
  static const Color accent   = AppTheme.goldPremium;
  static const Color bg       = AppTheme.surface;
  static const Color textDark = AppTheme.textDark;
  static const Color textGrey = AppTheme.textGrey;
  static const Color border   = AppTheme.border;

  late TabController _tabController;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _stats;
  List<dynamic> _consultations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _fetchAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAll({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) setState(() => _isLoading = true);
    try {
      final token = ref.read(authProvider).token!;
      final results = await Future.wait([
        apiService.getLawyerProfile(token),
        apiService.getLawyerStats(token),
        apiService.getLawyerConsultations(token),
      ]);
      if (mounted) {
        setState(() {
          _profile       = results[0] as Map<String, dynamic>;
          _stats         = results[1] as Map<String, dynamic>;
          _consultations = results[2] as List<dynamic>;
          _isLoading     = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Dashboard Sync Failed: $e'),
          backgroundColor: AppTheme.error,
        ));
      }
    }
  }

  Future<void> _accept(String id) async {
    try {
      final token = ref.read(authProvider).token!;
      await apiService.acceptConsultation(id, token);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Consultation accepted!'), backgroundColor: AppTheme.completed));
      _fetchAll(silent: true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    }
  }

  Future<void> _complete(String id) async {
    _showCompleteDialog(id);
  }

  void _showSupportTicketBottomSheet(BuildContext context, String userEmail, String userName, String defaultType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => _SupportTicketSheet(userEmail: userEmail, userName: userName, defaultType: defaultType),
    );
  }

  void _joinMeeting(String consultationId, String clientName) async {
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
        final displayName = Uri.encodeComponent("Adv. ${user['full_name']}");
        final url = Uri.parse("$serverUrl/$roomName#config.prejoinPageEnabled=false&config.prejoinConfig.enabled=false&config.lobbyModeEnabled=false&config.lobby.enabled=false&config.enableLobby=false&config.requireDisplayName=false&config.disableLobby=true&config.startWithAudioMuted=true&config.startWithVideoMuted=false&userInfo.displayName=$displayName");
        try {
          await launchUrl(url, mode: LaunchMode.platformDefault);
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('⚠️ Could not launch meeting: $e')));
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
          displayName: "Adv. ${user['full_name']}",
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

  Future<void> _startSession(String id) async {
    try {
      final token = ref.read(authProvider).token!;
      await apiService.startSession(id, token);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🟢 Session started!'), backgroundColor: AppTheme.completed));
      _fetchAll(silent: true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
    }
  }

  void _showCompleteDialog(String id) {
    final notesCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.description_outlined, color: AppTheme.completed, size: 48),
              const SizedBox(height: 16),
              const Text('Complete Session', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
              const SizedBox(height: 8),
              const Text('Write a consultation report as evidence', style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: TextField(
                  controller: notesCtrl,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textDark),
                  decoration: const InputDecoration(
                    hintText: 'e.g., Discussed family custody rights. Advised client on Khula procedure...',
                    hintStyle: TextStyle(color: AppTheme.textGrey, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (notesCtrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx);
                    try {
                      final token = ref.read(authProvider).token!;
                      await apiService.completeSessionWithNotes(
                        consultationId: id,
                        token: token,
                        lawyerNotes: notesCtrl.text.trim(),
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ Session completed with report!'), backgroundColor: AppTheme.completed));
                        Future.delayed(const Duration(milliseconds: 1500), () {
                          if (mounted) {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                contentPadding: const EdgeInsets.all(32),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 80, height: 80,
                                      decoration: BoxDecoration(
                                        color: AppTheme.goldPremium.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(child: Icon(Icons.account_balance_wallet_rounded, color: AppTheme.goldPremium, size: 40)),
                                    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                                    const SizedBox(height: 24),
                                    const Text('PAYOUT INITIATED', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textDark, letterSpacing: 1)),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Escrow funds have been successfully transferred to your configured EasyPaisa account.\n(FYP Simulation)',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: AppTheme.textGrey, fontSize: 13, height: 1.5, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.goldPremium,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: const Text('DISMISS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        });
                      }
                      _fetchAll();
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.completed,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  ),
                  child: const FittedBox(
                    child: Text('Complete & Submit Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStrategySheet(String querySummary) {
    final token = ref.read(authProvider).token ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _StrategySheet(querySummary: querySummary, token: token),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pending'    : return AppTheme.pending;
      case 'accepted'   : return AppTheme.accepted;
      case 'in_progress': return AppTheme.inProgress;
      case 'completed'  : return AppTheme.completed;
      case 'cancelled'  : return AppTheme.cancelled;
      default           : return textGrey;
    }
  }

  Color _statusBg(String s) {
    switch (s) {
      case 'pending'    : return AppTheme.pending.withOpacity(0.1);
      case 'accepted'   : return AppTheme.accepted.withOpacity(0.1);
      case 'in_progress': return AppTheme.inProgress.withOpacity(0.1);
      case 'completed'  : return AppTheme.completed.withOpacity(0.1);
      case 'cancelled'  : return AppTheme.cancelled.withOpacity(0.1);
      default           : return bg;
    }
  }

  String _formatDate(String d) {
    try {
      final dt = DateTime.parse(d).toLocal();
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
    } catch (_) { return d; }
  }

  @override
  Widget build(BuildContext context) {
    final int completedCount = _stats?['completed_consultations'] ?? 0;
    final double totalIncome = double.tryParse(_stats?['total_earned']?.toString() ?? '0') ?? 0.0;
    final double escrowIncome = double.tryParse(_stats?['escrow_balance']?.toString() ?? '0') ?? 0.0;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [

          // ── Header ──
          Container(
            color: primary,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Lawyer Dashboard',
                                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                              Text(
                                _profile?['full_name'] ?? 'Loading...',
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _fetchAll,
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Stats row
                  if (_stats != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                      child: Row(
                        children: [
                          _StatBox(
                            label: 'Total',
                            value: '${_stats!['total_consultations'] ?? 0}',
                            color: Colors.white,
                          ),
                          const SizedBox(width: 10),
                          _StatBox(
                            label: 'Pending',
                            value: '${_stats!['pending_consultations'] ?? 0}',
                            color: const Color(0xFFFBBF24),
                            highlight: (_stats!['pending_consultations'] ?? 0) > 0,
                          ),
                          const SizedBox(width: 10),
                          _StatBox(
                            label: 'Completed',
                            value: '${_stats!['completed_consultations'] ?? 0}',
                            color: const Color(0xFF4ADE80),
                            highlight: (_stats!['completed_consultations'] ?? 0) > 0,
                          ),
                          const SizedBox(width: 10),
                          _StatBox(
                            label: 'Rating',
                            value: '${(_stats!['avg_rating'] ?? 0.0).toStringAsFixed(1)}⭐',
                            color: const Color(0xFFF3C04D),
                            highlight: (_stats!['avg_rating'] ?? 0.0) >= 4.0,
                          ),
                        ],
                      ),
                    ),

                  // Tabs
                  const SizedBox(height: 4), // Add a bit of space above tabs
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    indicatorWeight: 2,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white38,
                    labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    unselectedLabelStyle: const TextStyle(fontSize: 13),
                    labelPadding: const EdgeInsets.only(bottom: 4, left: 16, right: 16), // Restored horizontal padding
                    isScrollable: true,
                    tabs: const [
                      Tab(text: 'Requests'),
                      Tab(text: 'Schedule'),
                      Tab(text: 'Tools'),
                      Tab(text: 'Profile'),
                      Tab(text: 'Stats'),
                    ],
                  ),
                  const SizedBox(height: 2), // Add a tiny bit of space below tabs
                ],
              ),
            ),
          ),

          // ── Content ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primary))
                : TabBarView(
                    controller: _tabController,
                    children: [

                      // ── Requests Tab ──
                      _consultations.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 72, height: 72,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Center(child: Text('📋', style: TextStyle(fontSize: 32))),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('No requests yet',
                                      style: TextStyle(color: AppTheme.textDark, fontSize: 17, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 6),
                                  const Text('Bookings will appear here',
                                      style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                              itemCount: _consultations.length,
                              itemBuilder: (_, i) {
                                final c      = _consultations[i];
                                final status = c['status'] ?? 'pending';
                                final sColor = _statusColor(status);
                                final sBg    = _statusBg(status);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppTheme.border),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Client info
                                            Row(
                                              children: [
                                                Container(
                                                  width: 42, height: 42,
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFFEFF6FF),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      (c['user_name'] ?? 'U')[0].toUpperCase(),
                                                      style: const TextStyle(
                                                        color: accent,
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 17,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        c['user_name'] ?? 'Client',
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.w700,
                                                          fontSize: 14,
                                                          color: AppTheme.textDark,
                                                        ),
                                                      ),
                                                      Text(
                                                        _formatDate(c['created_at'] ?? ''),
                                                        style: const TextStyle(color: AppTheme.textGrey, fontSize: 11),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                  decoration: BoxDecoration(
                                                    color: sBg,
                                                    borderRadius: BorderRadius.circular(20),
                                                    border: Border.all(color: sColor.withOpacity(0.3)),
                                                  ),
                                                  child: Text(
                                                    status.toString().replaceAll('_', ' ').toUpperCase(),
                                                    style: TextStyle(color: sColor, fontSize: 10, fontWeight: FontWeight.w700),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 12),

                                            // Query
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: bg,
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: AppTheme.border),
                                              ),
                                              child: Text(
                                                c['query_summary'] ?? '',
                                                style: const TextStyle(color: AppTheme.textDark, fontSize: 13, height: 1.4),
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),

                                            const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                _Chip(
                                                  icon: Icons.category_outlined,
                                                  label: (c['category'] ?? 'general').toString().replaceAll('_', ' '),
                                                ),
                                                const SizedBox(width: 8),
                                                _Chip(
                                                  icon: (c['meeting_type'] ?? 'online') == 'online'
                                                      ? Icons.videocam_outlined
                                                      : Icons.business_outlined,
                                                  label: (c['meeting_type'] ?? 'online') == 'online'
                                                      ? 'Online'
                                                      : 'In Person',
                                                ),
                                                const Spacer(),
                                                IconButton(
                                                  icon: const Icon(Icons.auto_awesome, color: AppTheme.goldPremium),
                                                  tooltip: 'AI Summary',
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) => AIClientSummaryScreen(
                                                          consultationId: c['id'].toString(),
                                                          clientName: c['user_name'] ?? 'Client',
                                                          querySummary: c['query_summary'] ?? '',
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Action buttons
                                      if (status == 'pending' || status == 'accepted')
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                          child: Row(
                                            children: [
                                              if (status == 'pending')
                                                Expanded(
                                                  child: GestureDetector(
                                                    onTap: () => _accept(c['id']),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(vertical: 11),
                                                      decoration: BoxDecoration(
                                                        color: accent,
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: const Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Icon(Icons.check, color: Colors.white, size: 15),
                                                          SizedBox(width: 6),
                                                          Text('Accept', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              if (status == 'accepted') ...[
                                                Expanded(
                                                  child: GestureDetector(
                                                    onTap: () => _complete(c['id']),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(vertical: 11),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF16A34A),
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: const Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Icon(Icons.task_alt_rounded, color: Colors.white, size: 15),
                                                          SizedBox(width: 6),
                                                          Text('Mark Complete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),

                      // ── Schedule Tab ──
                      const _ScheduleTabContent(),

                      // ── Profile Tab ──
                      _profile == null
                          ? const Center(child: CircularProgressIndicator(color: primary))
                          : SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                              child: Column(
                                children: [
                                  // Premium Header
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [AppTheme.navyDeep, Color(0xFF1E293B)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(color: AppTheme.navyDeep.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 88, height: 88,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: AppTheme.goldPremium, width: 3),
                                          ),
                                          child: const Center(child: Text('👨‍⚖️', style: TextStyle(fontSize: 40))),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          _profile!['full_name'] ?? '',
                                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          (_profile!['specialization'] ?? '').toString().replaceAll('_', ' ').toUpperCase(),
                                          style: const TextStyle(color: AppTheme.goldPremium, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                                        ),
                                        const SizedBox(height: 16),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: _profile!['verification_status'] == 'approved'
                                                ? const Color(0xFF16A34A).withOpacity(0.2)
                                                : const Color(0xFFD97706).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: _profile!['verification_status'] == 'approved'
                                                  ? const Color(0xFF16A34A)
                                                  : const Color(0xFFD97706),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _profile!['verification_status'] == 'approved' ? Icons.verified_rounded : Icons.pending_actions_rounded,
                                                color: _profile!['verification_status'] == 'approved' ? const Color(0xFF4ADE80) : const Color(0xFFFBBF24),
                                                size: 16,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                _profile!['verification_status'] == 'approved' ? 'Verified Lawyer' : 'Pending Approval',
                                                style: TextStyle(
                                                  color: _profile!['verification_status'] == 'approved' ? const Color(0xFF4ADE80) : const Color(0xFFFBBF24),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Quick Stats Row
                                  Row(
                                    children: [
                                      Expanded(child: _ProfileStatCard(icon: Icons.payments_rounded, label: 'Fee', value: 'Rs ${_profile!['consultation_fee']}', color: const Color(0xFF16A34A))),
                                      const SizedBox(width: 12),
                                      Expanded(child: _ProfileStatCard(icon: Icons.work_history_rounded, label: 'Experience', value: '${_profile!['years_experience']} yrs', color: const Color(0xFF3B82F6))),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Detail Cards
                                  _ProfileDetailCard(icon: Icons.email_rounded, label: 'Email Address', value: _profile!['email'] ?? ''),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(child: _ProfileDetailCard(icon: Icons.location_city_rounded, label: 'City', value: _profile!['city'] ?? '')),
                                      const SizedBox(width: 12),
                                      Expanded(child: _ProfileDetailCard(icon: Icons.badge_rounded, label: 'Bar Council', value: _profile!['bar_council_number'] ?? '')),
                                    ],
                                  ),

                                  if (_profile!['bio'] != null && (_profile!['bio'] as String).isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.border)),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: const [
                                              Icon(Icons.person_pin_rounded, color: AppTheme.textDark, size: 20),
                                              SizedBox(width: 8),
                                              Text('About Me', style: TextStyle(color: AppTheme.textDark, fontSize: 16, fontWeight: FontWeight.w800)),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(_profile!['bio'] ?? '', style: const TextStyle(color: AppTheme.textGrey, fontSize: 14, height: 1.6)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 24),
                                  const _PayoutSettingsCard(),
                                ],
                              ),
                            ),

                      // ── Stats Tab ──
                      SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Overview', style: TextStyle(color: AppTheme.navyDeep, fontSize: 18, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 16),
                            GridView.count(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              childAspectRatio: 1.1,
                              children: [
                                _GridStat(
                                  icon: Icons.calendar_today_rounded,
                                  label: 'Total',
                                  value: '${_stats?['total_consultations'] ?? 0}',
                                  color: accent,
                                  bg: const Color(0xFFEFF6FF),
                                ),
                                _GridStat(
                                  icon: Icons.hourglass_empty_rounded,
                                  label: 'Pending',
                                  value: '${_stats?['pending_consultations'] ?? 0}',
                                  color: const Color(0xFFD97706),
                                  bg: const Color(0xFFFFFBEB),
                                ),
                                _GridStat(
                                  icon: Icons.task_alt_rounded,
                                  label: 'Completed',
                                  value: '$completedCount',
                                  color: const Color(0xFF16A34A),
                                  bg: const Color(0xFFF0FDF4),
                                ),
                                _GridStat(
                                  icon: Icons.star_rounded,
                                  label: 'Rating',
                                  value: '${(_stats?['avg_rating'] ?? 0.0).toStringAsFixed(1)}',
                                  color: const Color(0xFFD97706),
                                  bg: const Color(0xFFFFFBEB),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            const Text('Earnings', style: TextStyle(color: AppTheme.navyDeep, fontSize: 18, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 16),
                            _IncomeCard(
                              title: 'Total Income',
                              amount: 'Rs ${totalIncome.toStringAsFixed(0)}',
                              subtitle: 'Based on $completedCount completed sessions',
                              icon: Icons.account_balance_wallet_rounded,
                              gradient: const LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF22C55E)]),
                            ),
                            const SizedBox(height: 12),
                            _IncomeCard(
                              title: 'Escrow Income',
                              amount: 'Rs ${escrowIncome.toStringAsFixed(0)}',
                              subtitle: 'Available for withdrawal via EasyPaisa',
                              icon: Icons.security_rounded,
                              gradient: const LinearGradient(colors: [AppTheme.goldPremium, Color(0xFFF59E0B)]),
                            ),
                            const SizedBox(height: 32),
                            const Text('Recent Payments (Escrow)', style: TextStyle(color: AppTheme.navyDeep, fontSize: 18, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 16),
                            if (_consultations.where((c) => c['status'] == 'completed').isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: const Center(
                                  child: Text('No completed payments yet.', style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                                ),
                              )
                            else
                              ..._consultations.where((c) => c['status'] == 'completed').map((c) => Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppTheme.border),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: const BoxDecoration(color: Color(0xFFF0FDF4), shape: BoxShape.circle),
                                      child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Payment from ${c['user_name'] ?? 'Client'}', style: const TextStyle(color: AppTheme.textDark, fontSize: 14, fontWeight: FontWeight.w700)),
                                          const SizedBox(height: 4),
                                          Text(_formatDate(c['created_at'] ?? ''), style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('Rs ${c['fee'] ?? _profile?['consultation_fee'] ?? 0}', style: const TextStyle(color: AppTheme.navyDeep, fontSize: 15, fontWeight: FontWeight.w900)),
                                        const SizedBox(height: 4),
                                        const Text('Escrow', style: TextStyle(color: AppTheme.goldPremium, fontSize: 11, fontWeight: FontWeight.w800)),
                                      ],
                                    ),
                                  ],
                                ),
                              )).toList(),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Stat Box ──────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool highlight;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: highlight ? color.withOpacity(0.15) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: highlight ? color.withOpacity(0.3) : Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: highlight ? [
            BoxShadow(color: color.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))
          ] : [],
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(color: highlight ? color : Colors.white, fontSize: 18, fontWeight: FontWeight.w900, height: 1.1)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label.toUpperCase(),
                  style: TextStyle(color: highlight ? color.withOpacity(0.8) : Colors.white60, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ),
          ],
        ),
      ).animate().scaleXY(begin: 0.9, duration: 400.ms, curve: Curves.easeOutBack),
    );
  }
}

// ── Chip ──────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.navyDeep),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                color: AppTheme.navyDeep,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}

// ── Profile Cards ──────────────────────────────────────────────

class _ProfileStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ProfileStatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: AppTheme.navyDeep, fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ProfileDetailCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileDetailCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.navyDeep.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppTheme.navyDeep, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: AppTheme.textDark, fontSize: 13, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Card ─────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final List<Widget> items;
  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(children: items),
    );
  }
}

// ── Info Row ──────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.textGrey),
              const SizedBox(width: 12),
              Text(label,
                  style: const TextStyle(color: AppTheme.textGrey, fontSize: 12, fontWeight: FontWeight.w500)),
              const Spacer(),
              Flexible(
                child: Text(value,
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: AppTheme.textDark, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: AppTheme.border),
      ],
    );
  }
}

// ── Big Stat ──────────────────────────────────────────────────

class _BigStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bg;

  const _BigStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label,
                style: const TextStyle(color: AppTheme.textGrey, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          Text(value,
              style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// ── Grid Stat ─────────────────────────────────────────────────

class _GridStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bg;

  const _GridStat({required this.icon, required this.label, required this.value, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const Spacer(),
          Text(value, style: const TextStyle(color: AppTheme.navyDeep, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    ).animate().scaleXY(begin: 0.9, duration: 400.ms, curve: Curves.easeOutBack);
  }
}

// ── Income Card ───────────────────────────────────────────────

class _IncomeCard extends StatelessWidget {
  final String title;
  final String amount;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;

  const _IncomeCard({required this.title, required this.amount, required this.subtitle, required this.icon, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.8), size: 24),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          Text(amount, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1))
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .shimmer(duration: 2.seconds, color: Colors.white.withOpacity(0.5)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    ).animate().slideY(begin: 0.05, duration: 400.ms, curve: Curves.easeOut);
  }
}

// ── Payout Settings Card ──────────────────────────────────────

class _PayoutSettingsCard extends StatefulWidget {
  const _PayoutSettingsCard();

  @override
  State<_PayoutSettingsCard> createState() => _PayoutSettingsCardState();
}

class _PayoutSettingsCardState extends State<_PayoutSettingsCard> {
  final _ctrl = TextEditingController();
  String _savedValue = '';
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _load();
    _ctrl.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString('easypaisa_number') ?? '';
    if (mounted) {
      setState(() {
        _ctrl.text = val;
        _savedValue = val;
      });
    }
  }

  Future<void> _save() async {
    final cleanVal = _ctrl.text.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('easypaisa_number', cleanVal);
    if (mounted) {
      setState(() {
        _savedValue = cleanVal;
        _saved = true;
      });
    }
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _saved = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onTextChanged);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textVal = _ctrl.text.trim();
    final isSavedValue = textVal.isNotEmpty && textVal == _savedValue;
    final isEmpty = textVal.isEmpty;

    Color btnColor;
    String btnText;
    VoidCallback? onBtnPressed;

    if (_saved) {
      btnColor = AppTheme.completed;
      btnText = '✅ Saved Successfully!';
      onBtnPressed = null;
    } else if (isEmpty) {
      btnColor = Colors.grey.shade400;
      btnText = 'Enter Payout Number';
      onBtnPressed = null;
    } else if (isSavedValue) {
      btnColor = AppTheme.completed.withOpacity(0.9);
      btnText = '✅ Active Payout Account';
      onBtnPressed = null;
    } else {
      btnColor = AppTheme.goldPremium;
      btnText = _savedValue.isEmpty ? 'Save Payout Number' : 'Update Payout Number';
      onBtnPressed = _save;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded, color: AppTheme.goldPremium, size: 20),
              SizedBox(width: 8),
              Text('Payout Settings',
                  style: TextStyle(color: AppTheme.textDark, fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('EasyPaisa number for receiving consultation fees',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '03XX-XXXXXXX',
              prefixIcon: const Icon(Icons.phone_android_rounded, size: 18),
              suffixIcon: isSavedValue
                  ? const Icon(Icons.check_circle_rounded, color: AppTheme.completed, size: 20)
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onBtnPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: btnColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                disabledBackgroundColor: btnColor,
                elevation: onBtnPressed == null ? 0 : 2,
              ),
              child: Text(
                btnText,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Schedule Tab ──────────────────────────────────────────────

class _ScheduleTabContent extends ConsumerStatefulWidget {
  const _ScheduleTabContent();
  @override
  ConsumerState<_ScheduleTabContent> createState() => _ScheduleTabContentState();
}

class _ScheduleTabContentState extends ConsumerState<_ScheduleTabContent> {
  bool _isLoading = false;
  List<dynamic> _slots = [];
  final List<String> dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  void initState() {
    super.initState();
    _fetchSlots();
  }

  Future<void> _fetchSlots() async {
    setState(() => _isLoading = true);
    try {
      final token = ref.read(authProvider).token!;
      final res = await apiService.getMyAvailability(token);
      if (mounted) setState(() { _slots = res; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSlot(String id) async {
    try {
      final token = ref.read(authProvider).token!;
      await apiService.deleteAvailabilitySlot(id, token);
      _fetchSlots();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Slot deleted'), backgroundColor: Color(0xFF16A34A)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  void _showAddSlotDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Slot'),
        content: const Text('Slot management is under development. Please check back later.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ],
      ),
    );
  }

  String formatDate(String d) {
    try {
      final dt = DateTime.parse(d).toLocal();
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
    } catch (_) { return d; }
  }

  String _formatTime(String t) {
    try {
      final parts = t.split(':');
      final h = int.parse(parts[0]);
      final m = parts[1];
      final ampm = h >= 12 ? 'PM' : 'AM';
      final h12 = h % 12 == 0 ? 12 : h % 12;
      return '$h12:$m $ampm';
    } catch (_) { return t; }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Weekly Schedule',
                              style: TextStyle(color: AppTheme.navyDeep, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                          const SizedBox(height: 6),
                          const Text('Manage 30-min consultation slots',
                              style: TextStyle(color: AppTheme.goldPremium, fontSize: 13, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    HoverButton(
                      onTap: _showAddSlotDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppTheme.navyDeep, AppTheme.navyLight]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: AppTheme.navyDeep.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                        ),
                        child: const Row(children: [
                          Icon(Icons.add_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('Add Slot', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                        ]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                if (_slots.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.border),
                      boxShadow: [BoxShadow(color: AppTheme.navyDeep.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 8))],
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.calendar_month_outlined, size: 64, color: AppTheme.textGrey),
                        SizedBox(height: 20),
                        Text('No availability set',
                            style: TextStyle(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.w900)),
                        SizedBox(height: 8),
                        Text('Add time slots so clients can book consultations',
                            style: TextStyle(color: AppTheme.textGrey, fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )
                else
                  ...List.generate(7, (day) {
                    final daySlots = _slots.where((s) => s['day_of_week'] == day).toList();
                    if (daySlots.isEmpty) return const SizedBox.shrink();
                    daySlots.sort((a, b) => (a['start_time'] ?? '').compareTo(b['start_time'] ?? ''));

                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: AppTheme.navyDeep.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 8))],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0, top: 24, bottom: 24, width: 4,
                            child: Container(decoration: BoxDecoration(color: AppTheme.goldPremium, borderRadius: BorderRadius.circular(2))),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(24).copyWith(left: 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: AppTheme.goldPremium.withOpacity(0.1), shape: BoxShape.circle),
                                      child: const Icon(Icons.calendar_today_rounded, color: AppTheme.goldPremium, size: 16),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(dayNames[day],
                                        style: const TextStyle(color: AppTheme.navyDeep, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.3)),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: daySlots.map((slot) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.goldPremium.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppTheme.goldPremium.withOpacity(0.2)),
                                    ),
                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                      const Icon(Icons.schedule_rounded, color: AppTheme.goldPremium, size: 14),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${_formatTime(slot['start_time'] ?? '')} to ${_formatTime(slot['end_time'] ?? '')}',
                                        style: const TextStyle(color: AppTheme.navyDeep, fontSize: 13, fontWeight: FontWeight.w800),
                                      ),
                                      const SizedBox(width: 12),
                                      HoverButton(
                                        onTap: () => _deleteSlot(slot['id']),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.1), shape: BoxShape.circle),
                                          child: const Icon(Icons.close_rounded, color: AppTheme.error, size: 14),
                                        ),
                                      ),
                                    ]),
                                  )).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fade().slideY(begin: 0.1);
                  }),
                const SizedBox(height: 100),
              ],
            ),
          );
  }
}

// ── AI Strategy Sheet ─────────────────────────────────────────

class _StrategySheet extends StatefulWidget {
  final String querySummary;
  final String token;
  const _StrategySheet({required this.querySummary, required this.token});

  @override
  State<_StrategySheet> createState() => _StrategySheetState();
}

class _StrategySheetState extends State<_StrategySheet> {
  bool _isLoading = true;
  Map<String, dynamic>? _strategy;

  @override
  void initState() {
    super.initState();
    _fetchStrategy();
  }

  Future<void> _fetchStrategy() async {
    try {
      final res = await apiService.generateCaseStrategy(widget.querySummary, widget.token);
      if (mounted) setState(() { _strategy = res; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate strategy: $e'), backgroundColor: AppTheme.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.navyDeep))
            : ListView(
                controller: controller,
                children: [
                  Center(
                    child: Container(width: 48, height: 5,
                        decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(10))),
                  ),
                  const SizedBox(height: 24),
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: AppTheme.goldPremium, size: 28),
                      SizedBox(width: 12),
                      Text('AI Case Strategy',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.navyDeep)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Generated instantly based on Pakistani Law',
                      style: TextStyle(color: AppTheme.textGrey, fontSize: 13)),
                  const SizedBox(height: 24),
                  const Text('RECOMMENDED STRATEGY',
                      style: TextStyle(color: AppTheme.navyDeep, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(_strategy?['strategy'] ?? '',
                        style: const TextStyle(color: AppTheme.textDark, fontSize: 14, height: 1.6)),
                  ),
                  const SizedBox(height: 24),
                  const Text('RELEVANT LAWS & SECTIONS',
                      style: TextStyle(color: AppTheme.navyDeep, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  ...(_strategy?['laws'] as List<dynamic>? ?? []).map((law) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.goldPremium.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.goldPremium.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.gavel_rounded, color: AppTheme.goldPremium, size: 16),
                      const SizedBox(width: 12),
                      Expanded(child: Text(law.toString(),
                          style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w700))),
                    ]),
                  )),
                  const SizedBox(height: 24),
                  const Text('PREPARATION ADVICE',
                      style: TextStyle(color: AppTheme.navyDeep, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  ...(_strategy?['advice'] as List<dynamic>? ?? []).map((advice) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.check_circle, color: AppTheme.accepted, size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text(advice.toString(),
                          style: const TextStyle(color: AppTheme.textDark, fontSize: 14, height: 1.5))),
                    ]),
                  )),
                ],
              ),
      ),
    );
  }
}

// ── Support Ticket Sheet ──────────────────────────────────────

class _SupportTicketSheet extends ConsumerStatefulWidget {
  final String userEmail;
  final String userName;
  final String defaultType;

  const _SupportTicketSheet({
    required this.userEmail,
    required this.userName,
    required this.defaultType,
  });

  @override
  ConsumerState<_SupportTicketSheet> createState() => _SupportTicketSheetState();
}

class _SupportTicketSheetState extends ConsumerState<_SupportTicketSheet> {
  late String selectedType;
  String selectedCategory = 'Fraud';
  final subjectCtrl = TextEditingController();
  final messageCtrl = TextEditingController();
  final lawyerNameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedType = widget.defaultType;
  }

  @override
  void dispose() {
    subjectCtrl.dispose();
    messageCtrl.dispose();
    lawyerNameCtrl.dispose();
    super.dispose();
  }

  Widget _buildTypeOption(String type, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.goldPremium.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? AppTheme.goldPremium : AppTheme.border, width: 1.5),
          ),
          child: Center(
            child: Text(
              type.toUpperCase(),
              style: TextStyle(
                color: isSelected ? AppTheme.navyDeep : AppTheme.textGrey,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isComplaint = selectedType == 'Complaint';

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48, height: 5,
                decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(isComplaint ? Icons.report_problem_rounded : Icons.support_agent_rounded,
                    color: AppTheme.goldPremium, size: 24),
                const SizedBox(width: 8),
                Text(
                  isComplaint ? 'FILE A COMPLAINT' : 'SUBMIT SUPPORT TICKET',
                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.navyDeep, fontSize: 14, letterSpacing: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Describe your issue below. Our regulatory department will audit your request within 24 hours.',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 20),
            const Text('Ticket Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textDark)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildTypeOption('Question', selectedType == 'Question', () => setState(() => selectedType = 'Question')),
                const SizedBox(width: 12),
                _buildTypeOption('Complaint', selectedType == 'Complaint', () => setState(() => selectedType = 'Complaint')),
              ],
            ),
            const SizedBox(height: 20),

            if (isComplaint) ...[
              const Text('Complaint Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textDark)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'Fraud', child: Text('Financial Fraud')),
                      DropdownMenuItem(value: 'Fake Lawyer', child: Text('Duplicate / Fake Lawyer Profile')),
                      DropdownMenuItem(value: 'App Issue', child: Text('App crash / Payment failure')),
                      DropdownMenuItem(value: 'Abuse', child: Text('Abusive or Unprofessional conduct')),
                    ],
                    onChanged: (v) => setState(() => selectedCategory = v!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: lawyerNameCtrl,
                decoration: const InputDecoration(
                  hintText: 'Enter Lawyer Name / ID if applicable...',
                  labelText: 'Reported Subject Name',
                ),
              ),
              const SizedBox(height: 16),
            ],

            TextField(
              controller: subjectCtrl,
              decoration: const InputDecoration(
                hintText: 'Enter a short summary of your issue...',
                labelText: 'Subject',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Type your message/inquiry in detail...',
                labelText: 'Detailed Explanation',
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navyDeep,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                minimumSize: const Size(double.infinity, 54),
              ),
              onPressed: () async {
                if (subjectCtrl.text.isEmpty || messageCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill out the subject and message fields.'), backgroundColor: AppTheme.error));
                  return;
                }

                final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
                final dateStr = "${months[DateTime.now().month - 1]} ${DateTime.now().day}, ${DateTime.now().year}";
                final token = ref.read(authProvider).token;

                if (token == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error: Not authenticated!')));
                  return;
                }

                try {
                  if (isComplaint) {
                    await apiService.submitComplaint(
                      token: token,
                      category: selectedCategory,
                      reportedLawyer: lawyerNameCtrl.text.isNotEmpty ? lawyerNameCtrl.text : 'N/A',
                      description: messageCtrl.text,
                      date: dateStr,
                    );
                  } else {
                    await apiService.submitTicket(
                      token: token,
                      ticketType: selectedType,
                      subject: subjectCtrl.text,
                      message: messageCtrl.text,
                      date: dateStr,
                    );
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 10),
                            Expanded(child: Text(isComplaint
                                ? 'Complaint dispatched for investigation!'
                                : 'Support ticket submitted successfully!')),
                          ],
                        ),
                        backgroundColor: AppTheme.completed,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Submission failed: $e'), backgroundColor: AppTheme.error));
                  }
                }
              },
              child: Text(
                isComplaint ? 'Submit Complaint' : 'Submit Ticket',
                style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}