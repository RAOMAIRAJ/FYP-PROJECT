import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qanoon_buddy/core/api_service.dart';
import 'package:qanoon_buddy/data/auth_provider.dart';
import 'package:qanoon_buddy/presentation/screens/booking_screen.dart';
import 'package:qanoon_buddy/presentation/screens/peer_chat_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qanoon_buddy/presentation/widgets/hover_button.dart';
import 'package:qanoon_buddy/core/theme.dart';

class LawyersScreen extends ConsumerStatefulWidget {
  const LawyersScreen({super.key});

  @override
  ConsumerState<LawyersScreen> createState() => _LawyersScreenState();
}

class _LawyersScreenState extends ConsumerState<LawyersScreen> {
  static const Color primary  = AppTheme.navyDeep;
  static const Color accent   = AppTheme.goldPremium;
  static const Color bg       = AppTheme.surface;
  static const Color textDark = AppTheme.textDark;
  static const Color textGrey = AppTheme.textGrey;
  static const Color border   = AppTheme.border;

  List<dynamic> _lawyers       = [];
  bool          _isLoading     = true;
  bool          _isLoadingMore = false;
  bool          _hasMore       = true;
  int           _page          = 1;
  String?       _error;

  String _selectedSpec = 'all';
  String _selectedCity = 'all';

  final List<Map<String, String>> _specs = [
    {'value': 'all',                  'label': '🏛 ALL CATEGORIES'},
    {'value': 'family_law',           'label': '👪 FAMILY LAW'},
    {'value': 'tax_law',              'label': '💰 TAX & CORPORATE'},
    {'value': 'criminal_law',         'label': '⚖ CRIMINAL DEFENSE'},
    {'value': 'property_law',         'label': '🏢 PROPERTY & REAL ESTATE'},
    {'value': 'cybercrime_law',       'label': '💻 CYBERCRIME & TECH'},
    {'value': 'civil_law',            'label': '📜 CIVIL LITIGATION'},
  ];

  final List<Map<String, String>> _cities = [
    {'value': 'all',        'label': 'ALL CITIES'},
    {'value': 'karachi',    'label': 'KARACHI'},
    {'value': 'lahore',     'label': 'LAHORE'},
    {'value': 'islamabad',  'label': 'ISLAMABAD'},
    {'value': 'rawalpindi', 'label': 'RAWALPINDI'},
    {'value': 'faisalabad', 'label': 'FAISALABAD'},
    {'value': 'multan',     'label': 'MULTAN'},
    {'value': 'peshawar',   'label': 'PESHAWAR'},
    {'value': 'quetta',     'label': 'QUETTA'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchLawyers(refresh: true);
  }

  Future<void> _fetchLawyers({bool refresh = false}) async {
    if (refresh) {
      setState(() { _isLoading = true; _error = null; _page = 1; _hasMore = true; _lawyers = []; });
    } else {
      if (!_hasMore || _isLoadingMore) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final data = await apiService.getLawyersFiltered(
        specialization: _selectedSpec == 'all' ? null : _selectedSpec,
        city          : _selectedCity == 'all' ? null : _selectedCity,
        page          : _page,
        limit         : 10,
      );
      
      if (mounted) {
        setState(() { 
          if (refresh) {
            _lawyers = data;
          } else {
            _lawyers.addAll(data);
          }
          _isLoading = false;
          _isLoadingMore = false;
          _hasMore = data.length == 10;
          if (_hasMore) _page++;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; _isLoadingMore = false; _error = 'PROTOCOL SYNC FAILED.'; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // ── Elite Selection Header ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, AppTheme.navyLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Row(
                      children: [
                        _topBtn(Icons.chevron_left_rounded, () => Navigator.pop(context)),
                        const SizedBox(width: 20),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('EXECUTIVE COUNSEL', 
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                              Text('VERIFIED LEGAL PRACTITIONERS', 
                                style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                            ],
                          ),
                        ),
                        _topBtn(Icons.sync_rounded, () => _fetchLawyers(refresh: true), isSync: true),
                      ],
                    ),
                  ),

                  // Spec Filters
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: _specs.map((s) {
                        final selected = _selectedSpec == s['value'];
                        return HoverButton(
                          onTap: () {
                            setState(() => _selectedSpec = s['value']!);
                            _fetchLawyers();
                          },
                          child: AnimatedContainer(
                            duration: 200.ms,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: selected ? accent : Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: selected ? accent : Colors.white.withOpacity(0.12)),
                              boxShadow: selected ? [BoxShadow(color: accent.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))] : [],
                            ),
                            child: Text(s['label']!,
                                style: TextStyle(
                                  color: selected ? primary : Colors.white.withOpacity(0.6),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                )),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // City Filter
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: Row(
                      children: [
                        const Icon(Icons.location_searching_rounded, color: accent, size: 16),
                        const SizedBox(width: 12),
                        Theme(
                          data: Theme.of(context).copyWith(canvasColor: AppTheme.navyLight),
                          child: DropdownButton<String>(
                            value: _selectedCity,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: accent, size: 20),
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                            items: _cities.map((c) => DropdownMenuItem(value: c['value'], child: Text(c['label']!))).toList(),
                            onChanged: (v) {
                              setState(() => _selectedCity = v!);
                              _fetchLawyers();
                            },
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(30)),
                          child: Text('${_lawyers.length} MATCHES', 
                            style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fade().slideY(begin: -0.1),

          // ── Counsel Registry ──
          Expanded(
            child: _isLoading
                ? _buildShimmer()
                : _error != null
                    ? _buildError()
                    : _lawyers.isEmpty
                        ? _buildEmpty()
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _lawyers.length + (_hasMore ? 1 : 0),
                            itemBuilder: (_, i) {
                              if (i == _lawyers.length) {
                                return _buildLoadMore();
                              }
                              return _buildLawyerCard(_lawyers[i], i);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildLawyerCard(dynamic l, int i) {
    final rating = (l['avg_rating'] ?? 0).toDouble();
    final isOnline = l['available_online'] ?? false;
    final spec = (l['specialization'] ?? 'General').toString().replaceAll('_', ' ').toUpperCase();

    return HoverButton(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScreen(lawyer: l))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: border),
          boxShadow: [BoxShadow(color: primary.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 12))],
        ),
        child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 68, height: 68,
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.04),
                        shape: BoxShape.circle,
                        border: Border.all(color: primary.withOpacity(0.08), width: 1),
                      ),
                      child: const Center(child: Icon(Icons.gavel_rounded, size: 32, color: primary)),
                    ),
                    if (isOnline)
                      Positioned(
                        bottom: 2, right: 2,
                        child: Container(
                          width: 16, height: 16,
                          decoration: BoxDecoration(
                            color: AppTheme.completed,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 1.5.seconds, color: Colors.white),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(l['name'] ?? 'LEGAL PRACTITIONER',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textDark, letterSpacing: -0.3)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: accent.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded, color: accent, size: 12),
                                SizedBox(width: 4),
                                Text('ELITE', style: TextStyle(color: accent, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(spec, style: const TextStyle(color: textGrey, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _miniStat(Icons.star_rounded, '$rating', accent),
                          _miniStat(Icons.location_on_rounded, l['city'] ?? 'PAK', textGrey),
                          _miniStat(Icons.work_history_rounded, '${l['years_experience'] ?? 0}Y EXP', textGrey),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
              border: const Border(top: BorderSide(color: border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('RETAINER FEE', style: TextStyle(color: textGrey, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      Text('Rs ${l['consultation_fee']}', style: const TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 18), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                _actionIcon(Icons.chat_bubble_rounded, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PeerChatScreen(peerId: l['user_id'].toString(), peerName: l['name'] ?? 'Lawyer', peerRole: 'lawyer')));
                }),
                const SizedBox(width: 12),
                HoverButton(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScreen(lawyer: l))),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [primary, AppTheme.navyLight]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                    ),
                    child: const Text('BOOK NOW', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )).animate().fade(delay: (i * 30).ms).slideX(begin: 0.05);
  }

  Widget _miniStat(IconData icon, String label, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: color, size: 14),
      const SizedBox(width: 4),
      Text(label.toUpperCase(), style: TextStyle(color: textGrey, fontSize: 10, fontWeight: FontWeight.w800)),
    ],
  );

  Widget _actionIcon(IconData icon, VoidCallback onTap) => HoverButton(
    onTap: onTap,
    child: Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        color: primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withOpacity(0.1)),
      ),
      child: Icon(icon, color: primary, size: 20),
    ),
  );

  Widget _topBtn(IconData icon, VoidCallback onTap, {bool isSync = false}) {
    Widget iconWidget = Icon(icon, color: Colors.white, size: 20);
    if (isSync) {
      iconWidget = iconWidget.animate(onPlay: (c) => c.repeat(reverse: true)).rotate(duration: 2.seconds, curve: Curves.linear);
    }
    return HoverButton(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12), 
          borderRadius: BorderRadius.circular(12),
        ),
        child: iconWidget,
      ),
    );
  }

  Widget _buildShimmer() => ListView.builder(
    padding: const EdgeInsets.all(20),
    itemCount: 4,
    itemBuilder: (_, __) => Shimmer.fromColors(
      baseColor: Colors.grey[100]!,
      highlightColor: Colors.white,
      child: Container(
        height: 160,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
      ),
    ),
  );

  Widget _buildError() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 48),
        const SizedBox(height: 16),
        Text(_error!, style: const TextStyle(color: textGrey, fontWeight: FontWeight.w900, fontSize: 12)),
      ],
    ),
  );

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.search_off_rounded, color: textGrey, size: 48),
        const SizedBox(height: 16),
        const Text('NO COUNSEL MATCHES', style: TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
        const SizedBox(height: 8),
        const Text('ADJUST FILTERS FOR PROTOCOL SEARCH', style: TextStyle(color: textGrey, fontSize: 11, fontWeight: FontWeight.w700)),
      ],
    ),
  );

  Widget _buildLoadMore() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: _isLoadingMore
          ? const Center(child: CircularProgressIndicator(color: primary))
          : Center(
              child: HoverButton(
                onTap: _fetchLawyers,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: border),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: const Text('LOAD MORE COUNSEL', 
                    style: TextStyle(color: primary, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                ),
              ),
            ),
    );
  }
}