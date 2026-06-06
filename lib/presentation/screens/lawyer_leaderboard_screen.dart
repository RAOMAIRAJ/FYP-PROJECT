import 'package:flutter/material.dart';
import 'package:qanoon_buddy/core/theme.dart';
import 'package:qanoon_buddy/core/api_service.dart';
import 'package:qanoon_buddy/presentation/screens/booking_screen.dart';
import 'package:qanoon_buddy/presentation/widgets/hover_button.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';

class LawyerLeaderboardScreen extends StatefulWidget {
  const LawyerLeaderboardScreen({super.key});

  @override
  State<LawyerLeaderboardScreen> createState() => _LawyerLeaderboardScreenState();
}

class _LawyerLeaderboardScreenState extends State<LawyerLeaderboardScreen> {
  static const Color primary  = AppTheme.navyDeep;
  static const Color accent   = AppTheme.goldPremium;
  static const Color bg       = AppTheme.surface;
  static const Color textDark = AppTheme.textDark;
  static const Color textGrey = AppTheme.textGrey;
  static const Color border   = AppTheme.border;

  List<dynamic> _lawyers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    if (mounted) setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final data = await apiService.getLawyersFiltered(sortBy: 'cases');
      if (mounted) {
        setState(() {
          _lawyers = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _showReviewsModal(dynamic lawyer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LawyerReviewsModal(lawyerId: lawyer['id'].toString(), lawyerName: lawyer['name'] ?? 'Lawyer'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: _isLoading 
        ? _buildLoadingState() 
        : _errorMessage != null
          ? _buildErrorState()
          : RefreshIndicator(
              onRefresh: _fetchLeaderboard,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── Fancy Header & Podium ──
                  SliverToBoxAdapter(child: _buildHeaderPodium()),

                  // ── Section Title ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                      child: Row(
                        children: [
                          Container(width: 4, height: 20, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 12),
                          const Text('Comprehensive Ranking', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textDark)),
                        ],
                      ),
                    ),
                  ),

                  // ── Rank List ──
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          try {
                            final l = _lawyers[index];
                            if (l == null) return const SizedBox.shrink();
                            return _buildLawyerCard(l, index + 1)
                              .animate()
                              .fadeIn(delay: (index * 50).ms)
                              .slideX(begin: 0.05);
                          } catch (e) {
                            return ListTile(title: Text('Data Error: $e'), subtitle: const Text('Please refresh'));
                          }
                        },
                        childCount: _lawyers.length,
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            ),
    );
  }

  Widget _buildErrorState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppTheme.error, size: 64),
          const SizedBox(height: 16),
          const Text('Connection Link Broken', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 8),
          Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: textGrey)),
          const SizedBox(height: 32),
          SizedBox(
            width: 200,
            child: ElevatedButton(
              onPressed: _fetchLeaderboard,
              style: ElevatedButton.styleFrom(backgroundColor: accent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Retry Connection', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildHeaderPodium() {
    return Container(
      decoration: const BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // AppBar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  HoverButton(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40, 
                      decoration: BoxDecoration(
                        color: AppTheme.glassWhite.withOpacity(0.1), 
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.glassBorder),
                      ), 
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                  const Expanded(child: Center(child: Text('Lawyer Leaderboard', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5)))),
                  const SizedBox(width: 40),
                ],
              ),
            ),
    
            const SizedBox(height: 30),
            
            // Podium
            if (_lawyers.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Silver (#2)
                    if (_lawyers.length > 1 && _lawyers[1] != null) 
                      Expanded(
                        flex: 3,
                        child: _PodiumItem(lawyer: _lawyers[1], rank: 2, height: 120, color: const Color(0xFF94A3B8)).animate().scale(delay: 200.ms, duration: 600.ms, curve: Curves.easeOutBack)
                      ),
                    const SizedBox(width: 8),
                    // Gold (#1)
                    if (_lawyers.isNotEmpty && _lawyers[0] != null)
                      Expanded(
                        flex: 4,
                        child: _PodiumItem(lawyer: _lawyers[0], rank: 1, height: 160, color: accent).animate().scale(duration: 800.ms, curve: Curves.elasticOut)
                      ),
                    const SizedBox(width: 8),
                    // Bronze (#3)
                    if (_lawyers.length > 2 && _lawyers[2] != null) 
                      Expanded(
                        flex: 3,
                        child: _PodiumItem(lawyer: _lawyers[2], rank: 3, height: 100, color: const Color(0xFFB45309)).animate().scale(delay: 400.ms, duration: 600.ms, curve: Curves.easeOutBack)
                      ),
                  ],
                ),
              ),
            ] else 
              const SizedBox(height: 200, child: Center(child: Text('No rankings available', style: TextStyle(color: Colors.white54)))),
    
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLawyerCard(dynamic l, int rank) {
    if (l == null) return const SizedBox.shrink();
    final rating = double.tryParse(l['avg_rating']?.toString() ?? '0') ?? 0.0;
    
    final isFirst = rank == 1;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isFirst ? accent.withOpacity(0.6) : border, width: isFirst ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: isFirst ? accent.withOpacity(0.15) : AppTheme.navyDeep.withOpacity(0.06), 
            blurRadius: isFirst ? 30 : 20, 
            spreadRadius: isFirst ? 4 : 0, 
            offset: const Offset(0, 10)
          )
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (isFirst)
             Positioned(
               right: -20, top: -20,
               child: Icon(Icons.star_rounded, size: 120, color: accent.withOpacity(0.05))
                 .animate(onPlay: (c) => c.repeat()).rotate(duration: 15.seconds),
             ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Rank + Icon
                    Container(
                      width: 54, height: 54, 
                      decoration: BoxDecoration(
                        color: isFirst ? accent.withOpacity(0.15) : AppTheme.surface, 
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isFirst ? accent.withOpacity(0.3) : border),
                        boxShadow: isFirst ? [BoxShadow(color: accent.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))] : [],
                      ),
                      child: Center(
                        child: Text('#$rank', style: TextStyle(fontWeight: FontWeight.w900, color: isFirst ? accent : textDark, fontSize: 18))
                               .animate(onPlay: isFirst ? (c) => c.repeat(reverse: true) : null).scaleXY(end: 1.1, duration: 1.seconds),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(child: Text(l['name']?.toString() ?? 'Lawyer', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: textDark, letterSpacing: -0.5), overflow: TextOverflow.ellipsis)),
                              if (isFirst) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.verified_rounded, color: accent, size: 16)
                                  .animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2.seconds),
                              ],
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.goldPremium.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(l['tier'] ?? 'Bronze', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.goldPremium)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(l['specialization']?.toString() ?? 'Legal Professional', style: const TextStyle(color: textGrey, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _StatItem(label: 'Cases', value: '${l['total_consultations'] ?? 0}'),
                    const SizedBox(width: 16),
                    _StatItem(label: 'Badges', value: '${l['badges_count'] ?? 0}'),
                    const SizedBox(width: 16),
                    _StatItem(label: 'Rating', value: '${rating.toStringAsFixed(1)} ⭐', isGold: true),
                  ],
                ),
              ),
              const Divider(height: 1, color: border, indent: 24, endIndent: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: HoverButton(
                        onTap: () => _showReviewsModal(l),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white, 
                            borderRadius: BorderRadius.circular(16), 
                            border: Border.all(color: border)
                          ),
                          child: const Center(child: Text('Check Reviews', style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 14))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: HoverButton(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScreen(lawyer: l))),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [primary, AppTheme.navyLight]), 
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                          ),
                          child: const Center(child: Text('Book Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5))),
                        ),
                      ),
                    ),
                  ],
                ).animate().fade(delay: 200.ms).slideY(begin: 0.2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Container(width: 120, height: 120, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))),
    const SizedBox(height: 24),
    const Text('Tallying Legal Brilliance...', style: TextStyle(color: primary, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5))
      .animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
  ]));
}

class _PodiumItem extends StatelessWidget {
  final dynamic lawyer;
  final int rank;
  final double height;
  final Color color;

  const _PodiumItem({required this.lawyer, required this.rank, required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (rank == 1) 
            const Text('👑', style: TextStyle(fontSize: 36))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .slideY(begin: -0.2, end: 0.1, duration: 2.seconds, curve: Curves.easeInOut)
              .shimmer(duration: 2.seconds),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle, 
              border: Border.all(color: color.withOpacity(0.8), width: rank == 1 ? 3 : 2),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.4), blurRadius: 15, spreadRadius: rank == 1 ? 2 : 0)
              ],
            ),
            child: CircleAvatar(radius: rank == 1 ? 34 : 26, backgroundColor: Colors.white.withOpacity(0.15), child: const Icon(Icons.person, color: Colors.white70)),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).slideY(begin: 0, end: -0.05, duration: (1.5 + (rank * 0.2)).seconds, curve: Curves.easeInOut),
          const SizedBox(height: 12),
          Text(lawyer['name']?.toString().split(' ').first ?? 'Lawyer', 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5), 
            overflow: TextOverflow.ellipsis).animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 12),
          Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withOpacity(0.4)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              border: Border.all(color: color.withOpacity(0.6), width: 1.5),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, -3))
              ],
            ),
            child: Center(
              child: Text('$rank', style: TextStyle(color: rank == 1 ? Colors.white : Colors.white70, fontSize: 28, fontWeight: FontWeight.w900))
                      .animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 3.seconds),
            ),
          ).animate().scaleY(alignment: Alignment.bottomCenter, duration: 800.ms, curve: Curves.easeOutBack),
        ],
      );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final bool isGold;
  const _StatItem({required this.label, required this.value, this.isGold = false});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, color: AppTheme.textGrey, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isGold ? AppTheme.goldPremium : AppTheme.textDark)),
    ],
  );
}

// ── Reviews Modal ──────────────────────────────────────────

class _LawyerReviewsModal extends StatefulWidget {
  final String lawyerId, lawyerName;
  const _LawyerReviewsModal({required this.lawyerId, required this.lawyerName});
  @override
  State<_LawyerReviewsModal> createState() => _LawyerReviewsModalState();
}

class _LawyerReviewsModalState extends State<_LawyerReviewsModal> {
  List<dynamic> _reviews = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _skip = 0;
  final int _limit = 10;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_hasMore || _loadingMore) return;
    if (_reviews.isNotEmpty) {
      setState(() => _loadingMore = true);
    } else {
      setState(() => _loading = true);
    }

    try {
      final data = await apiService.getLawyerReviews(widget.lawyerId, skip: _skip, limit: _limit);
      if (mounted) {
        setState(() {
          _reviews.addAll(data);
          _loading = false;
          _loadingMore = false;
          _hasMore = data.length == _limit;
          if (_hasMore) _skip += _limit;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32), topRight: Radius.circular(32))),
      child: Column(
        children: [
          Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: AppTheme.border.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('${widget.lawyerName}\'s Reviews',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w900)),
                      Text('Client feedback and performance history',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ])),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close)),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (_reviews.isEmpty)
                    ? const Center(
                        child: Text('No reviews found for this lawyer',
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: _reviews.length + (_hasMore ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i == _reviews.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: _loadingMore
                                  ? const Center(child: CircularProgressIndicator())
                                  : TextButton(
                                      onPressed: _load,
                                      child: const Text('Load More Reviews',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.goldPremium))),
                            );
                          }
                          return _ReviewCard(review: _reviews[i]);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final dynamic review;
  const _ReviewCard({required this.review});
  @override
  Widget build(BuildContext context) {
    final rating = (review['rating'] ?? 0).toDouble();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(review['user_name'] ?? 'Verified Client', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              Row(children: List.generate(5, (s) => Icon(Icons.star_rounded, size: 14, color: s < rating ? AppTheme.goldPremium : AppTheme.border))),
            ],
          ),
          const SizedBox(height: 8),
          Text(review['review_text'] ?? review['comment'] ?? '', style: const TextStyle(height: 1.4, color: AppTheme.textGrey)),
        ],
      ),
    );
  }
}
