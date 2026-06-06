import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qanoon_buddy/core/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:qanoon_buddy/data/auth_provider.dart';
import 'package:qanoon_buddy/presentation/screens/analyze_document_screen.dart';
import 'package:qanoon_buddy/presentation/screens/ai_tools_screen.dart';
import 'package:qanoon_buddy/presentation/screens/chat_screen.dart';
import 'package:qanoon_buddy/presentation/screens/lawyers_screen.dart';
import 'package:qanoon_buddy/presentation/screens/lawyer_leaderboard_screen.dart';
import 'package:qanoon_buddy/presentation/screens/notifications_screen.dart';
import 'package:qanoon_buddy/presentation/screens/peer_contacts_screen.dart';
import 'package:qanoon_buddy/presentation/screens/search_screen.dart';
import 'package:qanoon_buddy/presentation/screens/qna_forum_screen.dart';
import 'package:qanoon_buddy/presentation/screens/booking_screen.dart';
import 'package:qanoon_buddy/presentation/screens/consultations_screen.dart';
import 'package:qanoon_buddy/presentation/screens/legal_news_screen.dart';
import 'package:qanoon_buddy/presentation/screens/tools/lawyer_match_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qanoon_buddy/core/theme.dart';
import 'dart:ui' as ui;
import 'package:qanoon_buddy/presentation/widgets/hover_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserHomeTab extends ConsumerStatefulWidget {
  const UserHomeTab({super.key});

  @override
  ConsumerState<UserHomeTab> createState() => _UserHomeTabState();
}

class _UserHomeTabState extends ConsumerState<UserHomeTab> {
  static const Color primary   = AppTheme.navyDeep;
  static const Color accent    = AppTheme.goldPremium;
  static const Color textDark  = AppTheme.textDark;
  static const Color textGrey  = AppTheme.textGrey;
  static const Color border    = AppTheme.border;

  List<dynamic> _lawyers = [];
  List<dynamic> _consultations = [];
  List<dynamic> _news = [];
  bool _isLoadingLawyers = true;
  bool _isLoadingConsults = true;
  bool _isLoadingNews = true;
  String _newsType = 'legal';
  String _karachiTopic = 'All';

  final List<String> _karachiTopics = ['All', 'Snatching', 'Load Shedding', 'Water Crisis', 'Traffic', 'Weather'];

  String _selectedRadarArea = 'Gulshan-e-Iqbal';
  bool _isLoadingRadar = true;
  bool _isLoadingRadarSummary = true;
  List<dynamic> _radarIncidents = [];
  String _radarSummaryText = 'Loading AI Radar Summary...';
  
  final List<String> _radarAreas = [
    'Gulshan-e-Iqbal',
    'Clifton & DHA',
    'Gulistan-e-Johar',
    'North Nazimabad',
    'Saddar & Lyari',
    'Federal B. Area',
    'Korangi & Landhi',
  ];

  final List<String> _legalFacts = [
    "Did you know? Under the Dissolution of Muslim Marriages Act 1939, women in Pakistan have the right to seek Khula.",
    "Did you know? You have the right to remain silent during police interrogation under Article 13 of the Constitution.",
    "Did you know? Employers must give a 1-month notice before terminating a permanent employee under Labor Laws.",
    "Did you know? Consumer Courts in Pakistan protect you against defective products and faulty services."
  ];
  late String _randomFact;

  @override
  void initState() {
    super.initState();
    _randomFact = _legalFacts[Random().nextInt(_legalFacts.length)];
    _fetchData();
  }

  Future<void> _fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedArea = prefs.getString('radar_area');
    if (savedArea != null && mounted) {
      setState(() {
        _selectedRadarArea = savedArea;
      });
    }

    _fetchLawyers();
    _fetchConsultations();
    _fetchNews();
    _fetchRadarData();
  }

  Future<void> _fetchRadarData() async {
    if (mounted) {
      setState(() {
        _isLoadingRadar = true;
        _isLoadingRadarSummary = true;
      });
    }

    // Fetch incidents independently to unblock UI grid
    apiService.fetchLiveIncidents(area: _selectedRadarArea).then((incidents) {
      if (mounted) {
        setState(() {
          _radarIncidents = incidents;
          _isLoadingRadar = false;
        });
      }
    }).catchError((e) {
      debugPrint('Error fetching radar incidents: $e');
      if (mounted) setState(() => _isLoadingRadar = false);
    });

    // Fetch AI Summary in parallel (may take slightly longer)
    apiService.fetchRadarSummary(_selectedRadarArea).then((summary) {
      if (mounted) {
        setState(() {
          _radarSummaryText = summary;
          _isLoadingRadarSummary = false;
        });
      }
    }).catchError((e) {
      debugPrint('Error fetching radar summary: $e');
      if (mounted) {
        setState(() {
          _radarSummaryText = 'Could not load summary.';
          _isLoadingRadarSummary = false;
        });
      }
    });
  }

  Future<void> _fetchNews() async {
    if (mounted) setState(() => _isLoadingNews = true);
    try {
      final topic = _karachiTopic == 'All' ? null : _karachiTopic;
      final data = await apiService.getNews(limit: 3, type: _newsType, topic: topic);
      if (mounted) {
        setState(() {
          _news = data;
          _isLoadingNews = false;
        });
      }
    } catch (e) {
      debugPrint('Gazette Error: $e');
      if (mounted) setState(() => _isLoadingNews = false);
    }
  }

  Future<void> _fetchLawyers() async {
    try {
      final data = await apiService.getLawyers();
      if (mounted) {
        setState(() {
          // Reverse the list so newly registered lawyers appear first for the MVP demo,
          // and remove the take(5) limit so no lawyers are cut off.
          _lawyers = data.reversed.toList();
          _isLoadingLawyers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingLawyers = false);
    }
  }

  Future<void> _fetchConsultations() async {
    try {
      final token = ref.read(authProvider).token;
      if (token == null) return;
      
      final data = await apiService.getMyConsultations(token);
      if (mounted) {
        setState(() {
          // Just take the latest 3
             _consultations = data.take(3).toList();
          _isLoadingConsults = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingConsults = false);
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

  Widget _buildSleekRadarMetric(String title, int count, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(1,1), end: const Offset(1.1, 1.1), duration: 1.seconds, curve: Curves.easeInOut),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w700)),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: count.toDouble()),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Text('${value.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRadarCategoryDetails(String categoryName, List<dynamic> filteredIncidents) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: const Color(0xFF1E2235),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$categoryName Alerts in $_selectedRadarArea',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (filteredIncidents.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'All clear! No active $categoryName alerts today in $_selectedRadarArea.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredIncidents.length,
                    itemBuilder: (context, index) {
                      final inc = filteredIncidents[index];
                      final desc = inc['description'] ?? 'No details provided.';
                      
                      // Format relative time if possible
                      final createdStr = inc['created_at'] != null 
                          ? _formatRelativeTimeHome(inc['created_at'].toString())
                          : 'Just now';
                          
                      final upvotes = inc['upvotes'] ?? 0;
                      
                      // Parse bracketed source info
                      String source = 'Citizen Report';
                      String cleanDesc = desc;
                      if (desc.startsWith('[') && desc.contains(']')) {
                        final endIdx = desc.indexOf(']');
                        source = desc.substring(1, endIdx);
                        cleanDesc = desc.substring(endIdx + 1).trim();
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.06)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSourceBadgeHome(source),
                                Text(createdStr, style: const TextStyle(color: Colors.white30, fontSize: 10)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              cleanDesc,
                              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.thumb_up_rounded, color: Colors.greenAccent, size: 12),
                                const SizedBox(width: 4),
                                Text('$upvotes verification votes', style: const TextStyle(color: Colors.white30, fontSize: 10)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatRelativeTimeHome(String isoString) {
    try {
      final utcString = isoString.endsWith('Z') ? isoString : '${isoString}Z';
      final dt = DateTime.parse(utcString).toLocal();
      final diff = DateTime.now().difference(dt);
      
      if (diff.isNegative) return 'Just now';
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} m ago';
      if (diff.inHours < 24) return '${diff.inHours} h ago';
      return '${diff.inDays} d ago';
    } catch (_) {
      return 'Just now';
    }
  }

  Widget _buildSourceBadgeHome(String source) {
    Color badgeColor = Colors.white24;
    IconData icon = Icons.info_outline;

    if (source.contains('Google News')) {
      badgeColor = Colors.blueAccent;
      icon = Icons.newspaper_rounded;
    } else if (source.contains('Reddit')) {
      badgeColor = Colors.deepOrangeAccent;
      icon = Icons.forum_rounded;
    } else if (source.contains('Twitter') || source.contains('X')) {
      badgeColor = Colors.lightBlueAccent;
      icon = Icons.chat_bubble_outline_rounded;
    } else if (source.contains('Facebook')) {
      badgeColor = const Color(0xFF1877F2);
      icon = Icons.groups_rounded;
    } else if (source.contains('Instagram')) {
      badgeColor = Colors.pinkAccent;
      icon = Icons.camera_alt_rounded;
    } else if (source.contains('Citizen Report')) {
      badgeColor = Colors.greenAccent;
      icon = Icons.person_pin_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor.withOpacity(0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 8, color: badgeColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              source,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                color: badgeColor,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final name = auth.user?['full_name'] ?? 'there';
    final firstName = name.split(' ').first;

    return Container(
      color: const Color(0xFFF8FAFC), // Premium off-white background
      child: RefreshIndicator(
        onRefresh: _fetchData,
        color: primary,
        child: CustomScrollView(
          slivers: [
          // ── Elite Glassmorphism App Bar ──
          // ── Elite Glassmorphism App Bar ──
          // ── Elite Glassmorphism App Bar ──
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B0D17), Color(0xFF1A1C30)], // Richer, deeper navy
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF1A1C30).withOpacity(0.5), blurRadius: 30, offset: const Offset(0, 10))
                ],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(55)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
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
                              const Text('Qanoon Buddy',
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
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22)
                                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                                      .rotate(begin: -0.08, end: 0.08, duration: 800.ms, curve: Curves.easeInOut),
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.search_rounded, color: Colors.white, size: 22),
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ).animate().fade(duration: 600.ms).slideY(begin: -0.2),

                      const SizedBox(height: 36),

                      // Greeting
                      Text('WELCOME BACK',
                          style: TextStyle(
                            color: const Color(0xFFF3C04D), // Mustard yellow
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          )).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2.seconds, color: Colors.white).animate().fade(delay: 200.ms).slideX(begin: -0.1),
                      const SizedBox(height: 6),
                      Text('$firstName',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            height: 1,
                            letterSpacing: -1,
                          )).animate().fade(delay: 300.ms).slideX(begin: -0.1),

                      const SizedBox(height: 32),

                      // Elite Ask AI Bar
                      HoverButton(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen())),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [const Color(0xFF24263A), const Color(0xFF24263A).withOpacity(0.8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                            boxShadow: [
                              BoxShadow(color: AppTheme.goldPremium.withOpacity(0.15), blurRadius: 25, offset: const Offset(0, 10)),
                              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome_rounded, color: Color(0xFFF3C04D), size: 24),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text('How can I help you, $firstName?',
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
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3C04D), // Solid mustard yellow
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(color: const Color(0xFFF3C04D).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))
                                  ],
                                ),
                                child: const Text('ASK AI',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    )),
                              ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(begin: const Offset(1.0, 1.0), end: const Offset(1.05, 1.05), duration: 1.seconds, curve: Curves.easeInOut),
                            ],
                          ),
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 3.seconds, color: Colors.white.withOpacity(0.08)).animate().fade(delay: 400.ms).slideY(begin: 0.2),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Active Consultation Alert (New) ──
          if (_consultations.any((c) => c['status'] == 'accepted' || c['status'] == 'in_progress'))
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.navyDeep, AppTheme.navyLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.accepted.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.videocam_rounded, color: AppTheme.accepted, size: 24),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Lawyer Accepted!', 
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                                SizedBox(height: 2),
                                Text('A lawyer has joined your request. Join now!', 
                                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                             // Switch to the new Meetings tab (index 2)
                             // Actually, since this is in a tab, we need to communicate with HomeScreen
                             // Simple way: Navigate to ConsultationsScreen directly
                             Navigator.push(context, MaterialPageRoute(builder: (_) => const ConsultationsScreen()));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accepted,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Go to Meetings', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fade().slideY(begin: 0.2),
            ),

          // ── Karachi Citizen Mini-App CTA ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: GestureDetector(
                onTap: () => context.push('/citizen-mini-app'),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF131524), Color(0xFF1E2235)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.goldPremium.withOpacity(0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: AppTheme.goldPremium.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.goldPremium.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.rocket_launch_rounded, color: AppTheme.goldPremium, size: 28)
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .slideY(begin: -0.1, end: 0.1, duration: 1.seconds),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Open Karachi Citizen App', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                            SizedBox(height: 4),
                            Text('Live Radar, Services & Garage in one place', style: TextStyle(color: Colors.white60, fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 16),
                    ],
                  ),
                ),
              ).animate().fade().slideY(begin: 0.2),
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
                      icon: Icons.chat_rounded,
                      label: 'AI Chat',
                      gradient: AppTheme.gradPurple,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen())),
                    ),
                    const SizedBox(width: 20),
                    _QuickAction(
                      icon: Icons.account_balance_rounded,
                      label: 'Govt Offices',
                      gradient: AppTheme.gradBlue,
                      onTap: () => context.push('/smart-govt-office'),
                    ),
                    const SizedBox(width: 20),
                    _QuickAction(
                      icon: Icons.auto_awesome_rounded,
                      label: 'AI Tools',
                      gradient: AppTheme.gradCyan,
                      onTap: () {
                        debugPrint('🚀 [UserHomeTab] AI Tools Clicked');
                        try {
                          context.push('/ai-tools');
                        } catch (e, stack) {
                          debugPrint('❌ [UserHomeTab] Navigation Error: $e');
                          debugPrint('Stacktrace: $stack');
                          // Fallback to Navigator if GoRouter fails
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AiToolsScreen()));
                        }
                      },
                    ),
                    const SizedBox(width: 20),
                    _QuickAction(
                      icon: Icons.forum_rounded,
                      label: 'Messages',
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
                    const SizedBox(width: 20),
                    _QuickAction(
                      icon: Icons.psychology_rounded,
                      label: 'Lawyer Match',
                      gradient: AppTheme.gradAmber, // Amber to Orange
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LawyerMatchScreen())),
                    ),
                    const SizedBox(width: 20),
                    _QuickAction(
                      icon: Icons.support_agent_rounded,
                      label: 'Emergency Desk',
                      gradient: AppTheme.gradPink,
                      onTap: () => context.push('/emergency-helplines'),
                    ),
                    const SizedBox(width: 20),
                    _QuickAction(
                      icon: Icons.calendar_month_rounded,
                      label: 'Case Tracker',
                      gradient: AppTheme.gradBlue,
                      onTap: () => context.push('/case-tracker'),
                    ),
                    const SizedBox(width: 20),
                    _QuickAction(
                      icon: Icons.wallet_rounded,
                      label: 'Digital Wallet',
                      gradient: AppTheme.gradPurple,
                      onTap: () => context.push('/digital-wallet'),
                    ),
                    const SizedBox(width: 20),].animate(interval: 40.ms, delay: 400.ms).fade(duration: 400.ms).slideX(begin: 0.2, curve: Curves.easeOutQuad),
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
                  border: Border.all(color: AppTheme.goldPremium.withOpacity(0.2), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.goldPremium.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
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


          // ── Legal Gazette Section ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text('Legal Gazette', style: TextStyle(color: AppTheme.navyDeep, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalNewsScreen())),
                    child: Row(
                      children: [
                        const Text('View All', style: TextStyle(color: AppTheme.goldPremium, fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward, color: AppTheme.goldPremium, size: 16)
                            .animate(onPlay: (controller) => controller.repeat(reverse: true))
                            .slideX(begin: 0, end: 0.2, duration: 1.seconds, curve: Curves.easeInOut),
                      ],
                    ),
                  ).animate().fade(delay: 500.ms).slideX(begin: 0.1),
                  const SizedBox(height: 20),

                  // Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildNewsTab('all', 'All News', Icons.newspaper_rounded),
                        _buildNewsTab('legal', 'Legal News', Icons.balance_rounded),
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
                    ..._news.map((news) => HoverButton(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalNewsScreen())),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: AppTheme.navyDeep.withOpacity(0.08), blurRadius: 30, spreadRadius: 4, offset: const Offset(0, 15))
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Thin floating gold line
                              Container(
                                width: 3,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.goldPremium,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 14),
                              // Gold rounded rectangle with icon
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppTheme.goldPremium.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(color: AppTheme.goldPremium.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
                                  ],
                                ),
                                child: const Icon(Icons.newspaper_rounded, color: AppTheme.goldPremium, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Live News badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.goldPremium.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppTheme.goldPremium.withOpacity(0.3)),
                                    ),
                                    child: Text(news['category']?.toUpperCase() ?? 'LIVE NEWS', 
                                      style: const TextStyle(color: AppTheme.goldPremium, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                                  ).animate(onPlay: (controller) => controller.repeat(reverse: true)).fade(begin: 1.0, end: 0.5, duration: 800.ms),
                                  const SizedBox(height: 6),
                                  Text(news['title_en'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: textDark, fontWeight: FontWeight.w800, fontSize: 14, height: 1.2)),
                                  const SizedBox(height: 6),
                                  const Text('Source: Google News', style: TextStyle(color: textGrey, fontSize: 11, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, color: AppTheme.goldPremium, size: 12),
                                      const SizedBox(width: 6),
                                      Text(_formatDate(news['created_at']), style: const TextStyle(color: textGrey, fontSize: 11, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ],
                              )),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right_rounded, color: AppTheme.goldPremium, size: 24)
                                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                                  .slideX(begin: 0, end: 0.3, duration: 1.seconds, curve: Curves.easeInOut),
                            ],
                          ),
                        ),
                      )
                    ).toList().animate(interval: 100.ms).fade(duration: 500.ms).slideY(begin: 0.2, curve: Curves.easeOutBack),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recent Consultations', style: TextStyle(color: AppTheme.navyDeep, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const SizedBox(height: 6),
                  const Text('Track and manage your legal consultation requests', style: TextStyle(color: textGrey, fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConsultationsScreen())),
                    child: Row(
                      children: [
                        const Text('View All', style: TextStyle(color: AppTheme.goldPremium, fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward, color: AppTheme.goldPremium, size: 16)
                            .animate(onPlay: (controller) => controller.repeat(reverse: true))
                            .slideX(begin: 0, end: 0.2, duration: 1.seconds, curve: Curves.easeInOut),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_isLoadingConsults)
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
                          Text('No recent consultations.', style: TextStyle(color: textGrey, fontSize: 13)),
                        ],
                      ),
                    )
                  else
                    ..._consultations.map((c) {
                      final status = c['status'] ?? 'pending';
                      final sColor = _statusColor(status);
                      final sBg    = _statusBg(status);

                      return HoverButton(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConsultationsScreen())),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.navyDeep.withOpacity(0.08), 
                                blurRadius: 30, 
                                spreadRadius: 4,
                                offset: const Offset(0, 15)
                              )
                            ],
                          ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Thin floating gold line
                            Container(
                              width: 3,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppTheme.goldPremium,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Light gold rounded rectangle with checkmark
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.goldPremium.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(color: AppTheme.goldPremium.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
                                ],
                              ),
                              child: const Icon(Icons.check_circle_outline_rounded, color: AppTheme.goldPremium, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Status badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.goldPremium.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.goldPremium.withOpacity(0.3)),
                                  ),
                                  child: Text(status.toUpperCase(), 
                                    style: const TextStyle(color: AppTheme.goldPremium, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)
                                  ),
                                ).animate(onPlay: (controller) => controller.repeat(reverse: true)).fade(begin: 1.0, end: 0.5, duration: 800.ms),
                                const SizedBox(height: 8),
                                Text(c['query_summary'] ?? 'Legal Discussion', 
                                  maxLines: 1, 
                                  overflow: TextOverflow.ellipsis, 
                                  style: const TextStyle(
                                    color: textDark, 
                                    fontWeight: FontWeight.w800, 
                                    fontSize: 16,
                                  )
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, color: textGrey, size: 14),
                                    const SizedBox(width: 6),
                                    Text(_formatDate(c['created_at'] ?? '').toUpperCase(), 
                                      style: const TextStyle(color: textGrey, fontSize: 12, fontWeight: FontWeight.w600)
                                    ),
                                  ],
                                ),
                                // Escrow badge if it's the last one for exact match
                                if (c['escrow_secured'] == true || c['query_summary'] == 'I want to registered my self as a filer') ...[
                                  const SizedBox(height: 6),
                                  const Row(
                                    children: [
                                      Icon(Icons.security_rounded, color: AppTheme.goldPremium, size: 12),
                                      SizedBox(width: 4),
                                      Text('ESCROW SECURED', style: TextStyle(color: AppTheme.goldPremium, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                                    ],
                                  ),
                                ],
                              ],
                            )),
                              const SizedBox(width: 12),
                              const Icon(Icons.chevron_right_rounded, color: AppTheme.goldPremium, size: 24)
                                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                                  .slideX(begin: 0, end: 0.3, duration: 1.seconds, curve: Curves.easeInOut),
                            ],
                          ),
                        ),
                      );
                    }).toList().animate(interval: 100.ms).fade(duration: 500.ms).slideY(begin: 0.2, curve: Curves.easeOutBack),
                ],
              ),
            ),
          ),

          // ── Top Lawyers (Horizontal Scroll) ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Top Recommended Lawyers', style: TextStyle(color: AppTheme.navyDeep, fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LawyerLeaderboardScreen())),
                    child: Row(
                      children: [
                        const Text('Leaderboard', style: TextStyle(color: AppTheme.goldPremium, fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward, color: AppTheme.goldPremium, size: 16)
                            .animate(onPlay: (controller) => controller.repeat(reverse: true))
                            .slideX(begin: 0, end: 0.2, duration: 1.seconds, curve: Curves.easeInOut),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_isLoadingLawyers)
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 3,
                        itemBuilder: (_, __) => Container(
                          width: 300,
                          margin: const EdgeInsets.only(right: 18, bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: border),
                          ),
                          child: Shimmer.fromColors(
                            baseColor: Colors.grey[200]!,
                            highlightColor: Colors.grey[100]!,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Container(width: 85, height: 85, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
                                  const SizedBox(width: 16),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Container(width: double.infinity, height: 18, color: Colors.white), const SizedBox(height: 8), Container(width: 80, height: 14, color: Colors.white), const Spacer(), Container(width: 40, height: 14, color: Colors.white),
                                  ])),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (_lawyers.isEmpty)
                     const Text('No lawyers found.', style: TextStyle(color: textGrey))
                  else
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _lawyers.length,
                        itemBuilder: (context, index) {
                          final l = _lawyers[index];
                          final rating = (l['avg_rating'] ?? 0).toDouble();

                          return HoverButton(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScreen(lawyer: l))),
                            child: Container(
                              width: 300,
                              margin: const EdgeInsets.only(right: 18, bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: border),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.navyDeep.withOpacity(0.06),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Left: Beautiful Squircle Avatar
                                    Container(
                                      width: 85,
                                      height: 85,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF0B0D17), Color(0xFF1A1C30)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(color: AppTheme.navyDeep.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))
                                        ],
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.person_rounded, size: 48, color: AppTheme.goldPremium),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Right: Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  l['name'] ?? 'Lawyer Name',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 18,
                                                    color: AppTheme.navyDeep,
                                                    letterSpacing: -0.5,
                                                  ),
                                                ),
                                              ),
                                              // Elite badge
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.goldPremium.withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Icon(Icons.verified_rounded, color: AppTheme.goldPremium, size: 12),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            (l['specialization'] ?? 'FAMILY LAW').toString().replaceAll('_', ' ').toUpperCase(),
                                            style: const TextStyle(
                                              color: AppTheme.goldPremium,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const Spacer(),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(Icons.star_rounded, color: AppTheme.goldPremium, size: 16),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    rating.toStringAsFixed(1),
                                                    style: const TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.w900),
                                                  ),
                                                ],
                                              ),
                                              Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: AppTheme.navyDeep,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                                              ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scaleXY(end: 1.1, duration: 800.ms, curve: Curves.easeInOut),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ).animate().fade(duration: 500.ms).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                const SizedBox(height: 40), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _topBtn(IconData icon, VoidCallback onTap) {
    return HoverButton(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08), 
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _sectionHeader(String title, String action, VoidCallback onActionTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title, 
            style: const TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        HoverButton(
          onTap: onActionTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.navyDeep.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(action, 
              style: const TextStyle(color: AppTheme.navyDeep, fontSize: 12, fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }

  Widget _buildNewsTab(String id, String label, IconData icon) {
    // Treat 'all' as the default if _newsType is not set to legal or karachi, for UI purposes
    final isActive = (_newsType == id) || (id == 'all' && _newsType != 'legal' && _newsType != 'karachi');
    return GestureDetector(
      onTap: () {
        if (_newsType != id) {
          setState(() => _newsType = id);
          _fetchNews();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.navyDeep : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isActive ? AppTheme.navyDeep : border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.goldPremium, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(
              color: isActive ? Colors.white : textDark,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            )),
          ],
        ),
      ),
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
              )).animate().fade(delay: 300.ms).slideY(begin: 0.2),
          ],
        ),
      ).animate().scale(delay: 200.ms, curve: Curves.elasticOut, duration: 800.ms),
    );
  }
}

class _LawyerCardWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.7); // Start on left side, 70% down
    
    // Swoop down in middle, then up on right
    path.quadraticBezierTo(
        size.width * 0.45, size.height * 1.15, 
        size.width, size.height * 0.4);
        
    path.lineTo(size.width, 0);
    path.close();

    // Fill Navy
    canvas.drawPath(path, Paint()..color = AppTheme.navyDeep..style = PaintingStyle.fill);

    // Draw Gold Line only on the curved bottom edge
    final curvePath = Path();
    curvePath.moveTo(0, size.height * 0.7);
    curvePath.quadraticBezierTo(
        size.width * 0.45, size.height * 1.15, 
        size.width, size.height * 0.4);
        
    canvas.drawPath(curvePath, Paint()
      ..color = AppTheme.goldPremium
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
