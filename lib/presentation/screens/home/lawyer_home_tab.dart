import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qanoon_buddy/core/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:qanoon_buddy/data/auth_provider.dart';
import 'package:qanoon_buddy/presentation/screens/analyze_document_screen.dart';
import 'package:qanoon_buddy/presentation/screens/ai_tools_screen.dart';
import 'package:qanoon_buddy/presentation/screens/qna_forum_screen.dart';
import 'package:qanoon_buddy/presentation/screens/chat_screen.dart';
import 'package:qanoon_buddy/presentation/screens/notifications_screen.dart';
import 'package:qanoon_buddy/presentation/screens/peer_contacts_screen.dart';
import 'package:qanoon_buddy/presentation/screens/lawyer_dashboard_screen.dart';
import 'package:qanoon_buddy/presentation/screens/legal_news_screen.dart';
import 'package:qanoon_buddy/presentation/screens/lawyer/ai_case_assistant_screen.dart';
import 'package:qanoon_buddy/presentation/screens/lawyer/smart_case_timeline_screen.dart';
import 'package:qanoon_buddy/presentation/screens/lawyer/digital_legal_chamber_screen.dart';
import 'package:qanoon_buddy/presentation/screens/lawyer/lawyer_public_profile_screen.dart';
import 'package:qanoon_buddy/presentation/screens/lawyer/legal_marketplace_screen.dart';
import 'package:qanoon_buddy/presentation/screens/lawyer/lawyer_referral_screen.dart';
import 'package:qanoon_buddy/presentation/screens/lawyer/lawyer_achievements_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qanoon_buddy/presentation/widgets/hover_button.dart';
import 'package:qanoon_buddy/core/theme.dart';
import 'dart:ui' as ui;

class LawyerHomeTab extends ConsumerStatefulWidget {
  const LawyerHomeTab({super.key});

  @override
  ConsumerState<LawyerHomeTab> createState() => _LawyerHomeTabState();
}

class _LawyerHomeTabState extends ConsumerState<LawyerHomeTab> {
  static const Color primary   = AppTheme.navyDeep;
  static const Color accent    = AppTheme.goldPremium;
  static const Color textDark  = AppTheme.textDark;
  static const Color textGrey  = AppTheme.textGrey;
  static const Color border    = AppTheme.border;
  static const Color cardBg    = Colors.white;

  Map<String, dynamic>? _stats;
  List<dynamic> _consultations = [];
  List<dynamic> _news          = [];
  bool _isLoading = true;
  bool _isLoadingNews = true;
  String _newsType = 'all';
  String _karachiTopic = 'All';
  final List<String> _karachiTopics = ['All', 'Snatching', 'Load Shedding', 'Water Crisis', 'Traffic', 'Weather'];

  final List<String> _legalFacts = [
    "Reminder: Always verify the opposing counsel's Bar Council registration before negotiations.",
    "Did you know? Qanoon Buddy's AI Legal assistant is trained on Pakistan's Supreme Court judgments.",
    "Pro Tip: Use the 'Start Session' button to directly enter a secure, end-to-end encrypted video courtroom.",
    "Reminder: Escrow funds are automatically released upon session completion and submission of the legal report."
  ];
  late String _randomFact;

  @override
  void initState() {
    super.initState();
    _randomFact = _legalFacts[DateTime.now().millisecond % _legalFacts.length];
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    _fetchNews();
    try {
      final token = ref.read(authProvider).token;
      if (token == null) return;
      
      final results = await Future.wait([
        apiService.getLawyerStats(token),
        apiService.getLawyerConsultations(token),
      ]);
      
      final stats = results[0] as Map<String, dynamic>;
      final consults = results[1] as List<dynamic>;
      
      if (mounted) {
        setState(() {
          _stats         = stats;
          _consultations = consults.take(4).toList();
          _isLoading     = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _fetchNews() async {
    if (mounted) setState(() => _isLoadingNews = true);
    try {
      if (_newsType == 'all') {
        final legalData = await apiService.getNews(limit: 3, type: 'legal');
        final karachiData = await apiService.getNews(limit: 3, type: 'karachi');
        
        List<dynamic> combined = [...legalData, ...karachiData];
        combined.sort((a, b) {
          try {
            final dateA = DateTime.parse(a['created_at']);
            final dateB = DateTime.parse(b['created_at']);
            return dateB.compareTo(dateA);
          } catch (_) { return 0; }
        });
        
        if (mounted) {
          setState(() {
            _news = combined.take(3).toList();
            _isLoadingNews = false;
          });
        }
      } else {
        final topic = _karachiTopic == 'All' ? null : _karachiTopic;
        final data = await apiService.getNews(limit: 3, type: _newsType, topic: topic);
        if (mounted) {
          setState(() {
            _news = data;
            _isLoadingNews = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingNews = false);
    }
  }

  String _formatDate(String d) {
    try {
      final dt = DateTime.parse(d).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${m[dt.month - 1]}';
    } catch (_) { return ''; }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pending': return AppTheme.pending;
      case 'accepted': return AppTheme.accepted;
      case 'in_progress': return AppTheme.inProgress;
      case 'completed': return AppTheme.completed;
      case 'cancelled': return AppTheme.cancelled;
      default: return textGrey;
    }
  }

  Color _statusBg(String s) {
    switch (s) {
      case 'pending': return AppTheme.pending.withOpacity(0.1);
      case 'accepted': return AppTheme.accepted.withOpacity(0.1);
      case 'in_progress': return AppTheme.inProgress.withOpacity(0.1);
      case 'completed': return AppTheme.completed.withOpacity(0.1);
      case 'cancelled': return AppTheme.cancelled.withOpacity(0.1);
      default: return AppTheme.surface;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'pending': return Icons.hourglass_empty_rounded;
      case 'accepted': return Icons.verified_rounded;
      case 'in_progress': return Icons.play_circle_outline_rounded;
      case 'completed': return Icons.task_alt_rounded;
      case 'cancelled': return Icons.cancel_outlined;
      default: return Icons.help_outline;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'pending': return 'PENDING REVIEW';
      case 'accepted': return 'CONFIRMED';
      case 'in_progress': return 'IN SESSION';
      case 'completed': return 'COMPLETED';
      case 'cancelled': return 'TERMINATED';
      default: return s.toUpperCase();
    }
  }

  Widget _buildNewsTab(String type, String label, IconData icon) {
    final isActive = _newsType == type;
    return HoverButton(
      onTap: () {
        if (_newsType != type) {
          setState(() => _newsType = type);
          _fetchNews();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.navyDeep : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isActive ? null : Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.goldPremium, size: 16),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(
              color: isActive ? Colors.white : AppTheme.navyDeep,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _accept(String id) async {
    try {
      final token = ref.read(authProvider).token!;
      await apiService.acceptConsultation(id, token);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Case accepted!'), backgroundColor: AppTheme.completed));
      }
      _fetchData();
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final name = auth.user?['full_name'] ?? 'Counsel';
    final firstName = name.split(' ').first;

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: primary,
      child: CustomScrollView(
        slivers: [
          // ── Elite Glassmorphism App Bar ──
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.navyDeep, AppTheme.navyLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Stack(
                children: [
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.asset('assets/images/logo.png', width: 42, height: 42, fit: BoxFit.contain),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('Lawyer Portal',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      )),
                                ],
                              ),
                              Row(
                                children: [
                                  _topBtn(Icons.notifications_none_rounded, () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                                  }, isBell: true),
                                  const SizedBox(width: 10),
                                  _topBtn(Icons.dashboard_rounded, () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LawyerDashboardScreen()));
                                  }),
                                ],
                              ),
                            ],
                          ).animate().fade(duration: 600.ms).slideY(begin: -0.2),

                          const SizedBox(height: 32),

                          // Greeting
                          Text('LAWYER ACTIVE',
                              style: TextStyle(
                                color: accent.withOpacity(0.9),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              )).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2.seconds, color: Colors.white).animate().fade(delay: 200.ms).slideX(begin: -0.1),
                          const SizedBox(height: 6),
                          Text('Adv. $firstName',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              )).animate().fade(delay: 300.ms).slideX(begin: -0.1),

                          const SizedBox(height: 28),

                          // Elite Ask AI Bar
                          HoverButton(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen())),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: BackdropFilter(
                                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.auto_awesome_rounded, color: accent, size: 22),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text('Research a legal case with AI...',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.5),
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            )),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [accent, AppTheme.goldMuted],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(color: accent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                                          ],
                                        ),
                                        child: const Text('ASK AI',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                            )),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 3.seconds, color: Colors.white.withOpacity(0.08)).animate().fade(delay: 400.ms).slideY(begin: 0.2),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Quick Actions ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: SingleChildScrollView(
                clipBehavior: Clip.none, // Allow shadows to be fully visible
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _QuickAction(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'AI Legal',
                      gradient: AppTheme.gradPurple, // Purple to Indigo
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen())),
                    ),
                    const SizedBox(width: 18),
                    _QuickAction(
                      icon: Icons.newspaper_rounded,
                      label: 'Gazette',
                      gradient: AppTheme.gradBlueMid, // Blue
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalNewsScreen())),
                    ),
                    const SizedBox(width: 18),
                    _QuickAction(
                      icon: Icons.dashboard_rounded,
                      label: 'Dashboard',
                      gradient: AppTheme.gradAmber, // Amber to Orange
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LawyerDashboardScreen())),
                    ),
                    const SizedBox(width: 18),
                    _QuickAction(
                      icon: Icons.auto_awesome,
                      label: 'AI Tools',
                      gradient: AppTheme.gradCyan, // Cyan to Blue
                      onTap: () {
                        debugPrint('🚀 [LawyerHomeTab] AI Tools Clicked');
                        try {
                          context.push('/ai-tools');
                        } catch (e, stack) {
                          debugPrint('❌ [LawyerHomeTab] Navigation Error: $e');
                          debugPrint('Stacktrace: $stack');
                          // Fallback to Navigator if GoRouter fails
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AiToolsScreen()));
                        }
                      },
                    ),
                    const SizedBox(width: 18),
                    _QuickAction(
                      icon: Icons.forum_rounded,
                      label: 'Clients',
                      gradient: AppTheme.gradPink, // Pink to Rose
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PeerContactsScreen())),
                    ),
                    const SizedBox(width: 20),
                    _QuickAction(
                      icon: Icons.people_alt_rounded,
                      label: 'Community QA',
                      gradient: AppTheme.gradEmerald, // Emerald
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QnaForumScreen())),
                    ),
                    const SizedBox(width: 18),
                    _QuickAction(
                      icon: Icons.smart_toy_rounded,
                      label: 'AI Case Asst',
                      gradient: AppTheme.gradPurple,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AICaseAssistantScreen())),
                    ),
                    const SizedBox(width: 18),
                    _QuickAction(
                      icon: Icons.timeline_rounded,
                      label: 'Timeline',
                      gradient: AppTheme.gradBlueMid,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartCaseTimelineScreen())),
                    ),
                    const SizedBox(width: 18),
                    _QuickAction(
                      icon: Icons.business_rounded,
                      label: 'My Chamber',
                      gradient: AppTheme.gradAmber,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DigitalLegalChamberScreen())),
                    ),
                    const SizedBox(width: 18),
                    _QuickAction(
                      icon: Icons.public_rounded,
                      label: 'My Website',
                      gradient: AppTheme.gradCyan,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LawyerPublicProfileScreen())),
                    ),
                    const SizedBox(width: 18),
                    _QuickAction(
                      icon: Icons.store_rounded,
                      label: 'Marketplace',
                      gradient: AppTheme.gradPink,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalMarketplaceScreen())),
                    ),
                    const SizedBox(width: 18),
                    _QuickAction(
                      icon: Icons.handshake_rounded,
                      label: 'Referrals',
                      gradient: AppTheme.gradEmerald,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LawyerReferralScreen())),
                    ),
                    const SizedBox(width: 20),
                    _QuickAction(
                      icon: Icons.emoji_events_rounded,
                      label: 'Achievements',
                      gradient: AppTheme.gradPurple,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LawyerAchievementsScreen())),
                    ),
                  ].animate(interval: 40.ms, delay: 400.ms).fade(duration: 400.ms).slideX(begin: 0.2, curve: Curves.easeOutQuad),
                ),
              ),
            ),
          ),

          // ── Did You Know Banner ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.navyDeep, AppTheme.navyLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lightbulb_rounded, color: AppTheme.goldPremium, size: 28)
                          .animate(onPlay: (controller) => controller.repeat(reverse: true))
                          .scaleXY(end: 1.1, duration: 800.ms)
                          .slideY(begin: -0.1, end: 0.1, duration: 1.seconds, curve: Curves.easeInOut),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _randomFact,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fade(delay: 600.ms, duration: 600.ms).slideY(begin: 0.1),
            ),
          ),

          // ── Stats Overview ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('Performance Snapshot', 'Full Dashboard', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LawyerDashboardScreen()))),
                  const SizedBox(height: 14),
                  if (_isLoading)
                    Shimmer.fromColors(
                      baseColor: Colors.grey[200]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Total Earnings',
                            value: '₨${double.tryParse((_stats?['total_earned'] ?? 0).toString())?.toStringAsFixed(0) ?? '0'}',
                            icon: Icons.payments_rounded,
                            color: AppTheme.completed,
                            bg: AppTheme.completed.withOpacity(0.1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Completed',
                            value: '${_stats?['completed_consultations'] ?? 0}',
                            icon: Icons.task_alt_rounded,
                            color: AppTheme.completed,
                            bg: AppTheme.completed.withOpacity(0.1),
                          ),
                        ),
                      ].animate(interval: 100.ms, delay: 500.ms).fade(duration: 500.ms).scale(begin: const Offset(0.9, 0.9)),
                    ),
                ],
              ),
            ),
          ),

          // ── Legal Gazette Highlights ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('Legal Gazette', 'View All', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalNewsScreen()))),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildNewsTab('all', 'All News', Icons.newspaper_rounded),
                        const SizedBox(width: 12),
                        _buildNewsTab('legal', 'Legal News', Icons.balance_rounded),
                        const SizedBox(width: 12),
                        _buildNewsTab('karachi', 'Karachi News', Icons.location_city_rounded),
                      ],
                    ),
                  ),
                  if (_newsType == 'karachi') ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 32,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _karachiTopics.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final t = _karachiTopics[index];
                          final isActive = _karachiTopic == t;
                          return GestureDetector(
                            onTap: () {
                              if (_karachiTopic != t) {
                                setState(() => _karachiTopic = t);
                                _fetchNews();
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: isActive ? AppTheme.goldPremium : AppTheme.glassWhite.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isActive ? AppTheme.goldPremium : border),
                              ),
                              child: Center(
                                child: Text(t, style: TextStyle(
                                  color: isActive ? Colors.white : textDark,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                )),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (_isLoadingNews)
                    Column(
                      children: List.generate(3, (index) => Shimmer.fromColors(
                        baseColor: Colors.grey[200]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          height: 70,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        ),
                      )),
                    )
                  else if (_news.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.newspaper_outlined, color: textGrey, size: 32),
                          SizedBox(height: 12),
                          Text('No legal updates available yet.', style: TextStyle(color: textGrey, fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    )
                  else
                    ..._news.map((item) => HoverButton(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalNewsScreen())),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: border),
                          boxShadow: [
                            BoxShadow(color: AppTheme.navyDeep.withOpacity(0.08), blurRadius: 30, spreadRadius: 4, offset: const Offset(0, 15))
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                               left: 0, top: 24, bottom: 24, width: 4, 
                               child: Container(decoration: BoxDecoration(color: AppTheme.goldPremium, borderRadius: BorderRadius.circular(2)))
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16).copyWith(left: 20),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 60, height: 60,
                                    decoration: BoxDecoration(color: AppTheme.goldPremium.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                                    child: const Center(child: Icon(Icons.newspaper_rounded, color: AppTheme.goldPremium, size: 28)),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: AppTheme.goldPremium.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                                        child: Text((item['category'] ?? 'GENERAL').toUpperCase(), style: const TextStyle(color: AppTheme.goldPremium, fontSize: 9, fontWeight: FontWeight.w900)),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(item['title_en'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: AppTheme.navyDeep, fontWeight: FontWeight.w900, fontSize: 14, height: 1.2)),
                                      const SizedBox(height: 6),
                                      Text(item['summary_en'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: AppTheme.textGrey, fontWeight: FontWeight.w500, fontSize: 11, height: 1.4)),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today_rounded, color: AppTheme.goldPremium, size: 12),
                                          const SizedBox(width: 4),
                                          Text(_formatDate(item['created_at'] ?? ''), style: const TextStyle(color: AppTheme.textGrey, fontSize: 10, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ],
                                  )),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 24, left: 8),
                                    child: const Icon(Icons.chevron_right_rounded, color: AppTheme.navyDeep, size: 24)
                                        .animate(onPlay: (c) => c.repeat(reverse: true))
                                        .slideX(begin: 0, end: 0.3, duration: 1.seconds, curve: Curves.easeInOut),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fade().slideX(begin: 0.1),
                    )).toList(),
                ],
              ),
            ),
          ),

          // ── Growth & Tools ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('Growth & Tools', 'View All', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LawyerDashboardScreen())), subtitle: 'Expand your practice and use AI'),
                  const SizedBox(height: 16),
                  
                  // AI Case Assistant Card
                  HoverButton(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AICaseAssistantScreen())),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: AppTheme.gradPurple),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: AppTheme.navyDeep.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('AI Case Assistant', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                                const SizedBox(height: 4),
                                Text('Analyze case details and formulate strategies using AI.', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, height: 1.4)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ).animate().fade().slideY(begin: 0.1),

                  // Legal Marketplace Card
                  HoverButton(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalMarketplaceScreen())),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.border),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppTheme.goldPremium.withOpacity(0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.store_rounded, color: AppTheme.goldPremium, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Legal Marketplace', style: TextStyle(color: AppTheme.navyDeep, fontSize: 18, fontWeight: FontWeight.w900)),
                                const SizedBox(height: 4),
                                const Text('Offer fixed-fee legal services directly to clients.', style: TextStyle(color: AppTheme.textGrey, fontSize: 12, height: 1.4)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.navyDeep, size: 16),
                        ],
                      ),
                    ),
                  ).animate().fade().slideY(begin: 0.1),

                  // Referrals Card
                  HoverButton(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LawyerReferralScreen())),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.border),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.handshake_rounded, color: Color(0xFF10B981), size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Lawyer Referrals', style: TextStyle(color: AppTheme.navyDeep, fontSize: 18, fontWeight: FontWeight.w900)),
                                const SizedBox(height: 4),
                                const Text('Send and receive cases from other lawyers and earn commission.', style: TextStyle(color: AppTheme.textGrey, fontSize: 12, height: 1.4)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.navyDeep, size: 16),
                        ],
                      ),
                    ),
                  ).animate().fade().slideY(begin: 0.1),

                ],
              ),
            ),
          ),

          // ── Recent Requests ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader('Recent Requests', 'See All', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LawyerDashboardScreen())), subtitle: 'Track and manage your client requests'),
                  const SizedBox(height: 14),
                  if (_isLoading)
                    Column(
                      children: List.generate(2, (index) => Shimmer.fromColors(
                        baseColor: Colors.grey[200]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                          height: 75,
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                        ),
                      )),
                    )
                  else if (_consultations.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, color: textGrey, size: 32),
                          SizedBox(height: 8),
                          Text('No new requests right now.', style: TextStyle(color: textGrey, fontSize: 13)),
                        ],
                      ),
                    )
                  else
                    ..._consultations.map((c) {
                      final status = c['status'] ?? 'pending';
                      final sColor = _statusColor(status);
                      final sBg = _statusBg(status);
                      return HoverButton(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LawyerDashboardScreen())),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: border),
                            boxShadow: [
                              BoxShadow(color: AppTheme.navyDeep.withOpacity(0.08), blurRadius: 30, spreadRadius: 4, offset: const Offset(0, 15))
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 3,
                                height: 40,
                                margin: const EdgeInsets.only(top: 6),
                                decoration: BoxDecoration(
                                  color: sColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Container(
                                width: 52, height: 52,
                                decoration: BoxDecoration(
                                  color: sBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: sColor.withOpacity(0.2)),
                                  boxShadow: [
                                    BoxShadow(color: sColor.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
                                  ],
                                ),
                                child: Center(child: Icon(_statusIcon(status), color: sColor, size: 28)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(c['query_summary'] ?? 'Legal Discussion', 
                                            maxLines: 2, 
                                            overflow: TextOverflow.ellipsis, 
                                            style: const TextStyle(
                                              color: AppTheme.navyDeep, 
                                              fontWeight: FontWeight.w800, 
                                              fontSize: 14,
                                              height: 1.2,
                                            )
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: sColor.withOpacity(0.08), 
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: sColor.withOpacity(0.2)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                status == 'completed' ? Icons.check_circle : 
                                                status == 'pending' ? Icons.schedule : 
                                                status == 'cancelled' ? Icons.cancel : Icons.info, 
                                                color: sColor, size: 10
                                              ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(end: 1.2, duration: 800.ms),
                                              const SizedBox(width: 4),
                                              Text(
                                                _statusLabel(status),
                                                style: TextStyle(color: sColor, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                              ),
                                            ]
                                          )
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.person_outline, color: AppTheme.textGrey, size: 12),
                                        const SizedBox(width: 4),
                                        Text('Client: ', style: const TextStyle(color: AppTheme.textGrey, fontSize: 10, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today_outlined, color: AppTheme.textGrey, size: 12),
                                        const SizedBox(width: 6),
                                        Text(_formatDate(c['created_at'] ?? '').toUpperCase(), 
                                          style: const TextStyle(color: AppTheme.textGrey, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)
                                        ),
                                        if (c['escrow_status'] == 'held') ...[
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            child: Container(width: 1, height: 10, color: border),
                                          ),
                                          const Icon(Icons.shield_rounded, color: AppTheme.goldPremium, size: 12),
                                          const SizedBox(width: 4),
                                          const Text('ESCROW SECURED', style: TextStyle(color: AppTheme.goldPremium, fontSize: 9, fontWeight: FontWeight.w800)),
                                        ],
                                      ],
                                    ),
                                    if (status == 'pending') ...[
                                      const SizedBox(height: 12),
                                      HoverButton(
                                        onTap: () => _accept(c['id'].toString()),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(10)),
                                          child: const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.check, color: Colors.white, size: 16),
                                              SizedBox(width: 6),
                                              Text('Accept Brief', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Padding(
                                padding: const EdgeInsets.only(top: 24),
                                child: Icon(Icons.chevron_right_rounded, color: sColor, size: 24)
                                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                                    .slideX(begin: 0, end: 0.3, duration: 1.seconds, curve: Curves.easeInOut),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fade(duration: 500.ms).slideX(begin: -0.05);
                    }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBtn(IconData icon, VoidCallback onTap, {bool isBell = false}) {
    Widget iconWidget = Icon(icon, color: Colors.white, size: 20);
    if (isBell) {
      iconWidget = iconWidget.animate(onPlay: (c) => c.repeat(reverse: true)).rotate(begin: -0.08, end: 0.08, duration: 800.ms, curve: Curves.easeInOut);
    }
    return HoverButton(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08), 
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: iconWidget,
      ),
    );
  }

  Widget _sectionHeader(String title, String action, VoidCallback onActionTap, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title, 
          style: const TextStyle(color: AppTheme.navyDeep, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: AppTheme.textGrey, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: 10),
        HoverButton(
          onTap: onActionTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(action, style: const TextStyle(color: AppTheme.goldPremium, fontSize: 13, fontWeight: FontWeight.w800)),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_rounded, color: AppTheme.goldPremium, size: 16)
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .slideX(begin: 0, end: 0.2, duration: 1.seconds, curve: Curves.easeInOut),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return HoverButton(
      onTap: onTap,
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: gradient.last.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true)).slideY(begin: -0.06, end: 0.06, duration: 1200.ms, curve: Curves.easeInOut),
            const SizedBox(height: 12),
            Text(label, 
              textAlign: TextAlign.center, 
              maxLines: 2, 
              overflow: TextOverflow.visible, 
              style: const TextStyle(
                color: AppTheme.textDark, 
                fontSize: 11, 
                fontWeight: FontWeight.w800, 
                height: 1.1,
                letterSpacing: -0.2,
              )),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color, bg;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: value.length > 7 ? 19 : 23,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textGrey, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
