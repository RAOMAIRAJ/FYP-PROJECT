import 'package:flutter/material.dart';
import 'package:qanoon_buddy/core/api_service.dart';
import 'package:qanoon_buddy/presentation/screens/booking_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qanoon_buddy/presentation/widgets/hover_button.dart';
import 'package:qanoon_buddy/core/theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const Color primary  = AppTheme.navyDeep;
  static const Color accent   = AppTheme.goldPremium;
  static const Color bg       = AppTheme.surface;
  static const Color textDark = AppTheme.textDark;
  static const Color textGrey = AppTheme.textGrey;
  static const Color border   = AppTheme.border;

  final _controller = TextEditingController();
  List<dynamic> _results    = [];
  bool  _isLoading          = false;
  bool  _isLoadingMore      = false;
  bool  _hasMore           = false;
  int   _skip               = 0;
  final int _limit          = 10;
  bool  _hasSearched        = false;
  String? _error;

  final List<String> _suggestions = [
    '👨‍👩‍👧 Family Law', '💰 Tax Law', '🏢 Corporate', '🏠 Property', '📄 Contract', '⚖ Criminal',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String q, {bool refresh = true}) async {
    final query = q.trim();
    if (query.isEmpty) {
      if (mounted) setState(() { _results = []; _hasSearched = false; });
      return;
    }

    if (refresh) {
      if (mounted) setState(() { _isLoading = true; _error = null; _hasSearched = true; _skip = 0; _results = []; _hasMore = false; });
    } else {
      if (!_hasMore || _isLoadingMore) return;
      if (mounted) setState(() => _isLoadingMore = true);
    }

    try {
      final data = await apiService.searchLawyers(query, skip: _skip, limit: _limit);
      if (mounted) {
        setState(() {
          if (refresh) {
            _results = data;
          } else {
            _results.addAll(data);
          }
          _isLoading = false;
          _isLoadingMore = false;
          _hasMore = data.length == _limit;
          if (_hasMore) _skip += _limit;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _isLoadingMore = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // ── Header ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, AppTheme.navyDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        HoverButton(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ELITE SEARCH', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
                            Text('FIND VERIFIED LEGAL COUNSEL', style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        style: const TextStyle(color: textDark, fontSize: 15, fontWeight: FontWeight.w600),
                        onChanged: (v) {
                          if (v.isEmpty) {
                            setState(() { _results = []; _hasSearched = false; });
                          }
                        },
                        onSubmitted: _search,
                        decoration: InputDecoration(
                          hintText: 'e.g. Hamza, Family Law, Karachi...',
                          hintStyle: const TextStyle(color: textGrey, fontSize: 14),
                          prefixIcon: const Icon(Icons.search_rounded, color: accent, size: 22),
                          suffixIcon: _controller.text.isNotEmpty
                              ? HoverButton(
                                  onTap: () {
                                    _controller.clear();
                                    setState(() { _results = []; _hasSearched = false; });
                                  },
                                  child: const Icon(Icons.close_rounded, color: textGrey, size: 20),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                      ),
                    ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
                  ],
                ),
              ),
            ),
          ).animate().slideY(begin: -0.2).fade(),

          // ── Body ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primary))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('⚠️', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 16),
                            Text(_error!, style: const TextStyle(color: textGrey)),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () => _search(_controller.text),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              child: const Text('Try Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      )
                    : !_hasSearched
                        ? SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Popular Searches', style: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: _suggestions.map((s) {
                                    return HoverButton(
                                      onTap: () {
                                        _controller.text = s.split(' ').skip(1).join(' ');
                                        _search(_controller.text);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(24),
                                          border: Border.all(color: border),
                                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
                                        ),
                                        child: Text(s, style: const TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.w700)),
                                      ),
                                    ).animate().fade().scale(delay: 100.ms, curve: Curves.easeOutBack);
                                  }).toList(),
                                ),
                                const SizedBox(height: 40),
                                const Text('Search Tips', style: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 16),
                                _Tip(icon: Icons.person_search_outlined, text: 'Search by lawyer name e.g. "Hamza"').animate().fade().slideX(begin: 0.1, delay: 100.ms),
                                _Tip(icon: Icons.gavel_rounded, text: 'Search by specialty e.g. "Family Law"').animate().fade().slideX(begin: 0.1, delay: 150.ms),
                                _Tip(icon: Icons.location_on_outlined, text: 'Search by city e.g. "Karachi"').animate().fade().slideX(begin: 0.1, delay: 200.ms),
                                _Tip(icon: Icons.verified_user_outlined, text: 'All results show verified lawyers only').animate().fade().slideX(begin: 0.1, delay: 250.ms),
                              ],
                            ),
                          )
                        : _results.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 80, height: 80,
                                      decoration: BoxDecoration(color: primary.withOpacity(0.05), shape: BoxShape.circle),
                                      child: const Center(child: Text('🔍', style: TextStyle(fontSize: 36))),
                                    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                                    const SizedBox(height: 20),
                                    const Text('No lawyers found', style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 8),
                                    Text('No results for "${_controller.text}"', style: const TextStyle(color: textGrey, fontSize: 14)),
                                    const SizedBox(height: 8),
                                    const Text('Try a different name, city or specialty', style: TextStyle(color: textGrey, fontSize: 13)),
                                  ],
                                ),
                              )
                            : Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                                    child: Row(
                                      children: [
                                        Text(
                                          "${_results.length} lawyer${_results.length != 1 ? 's' : ''} found",
                                          style: const TextStyle(color: textGrey, fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                        const Spacer(),
                                        HoverButton(
                                          onTap: () {
                                            _controller.clear();
                                            setState(() { _results = []; _hasSearched = false; });
                                          },
                                          child: const Text('Clear Search', style: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.w800)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: ListView.builder(
                                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                                      itemCount: _results.length + (_hasMore ? 1 : 0),
                                      itemBuilder: (_, i) {
                                        if (i == _results.length) {
                                          return _buildLoadMore();
                                        }
                                        final l      = _results[i];
                                        final rating = (l['avg_rating'] ?? 0).toDouble();
                                        final isOnline = l['available_online'] ?? false;

                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(24),
                                            border: Border.all(color: border),
                                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 6))],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(20),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Stack(
                                                      children: [
                                                        Container(
                                                          width: 56, height: 56,
                                                          decoration: BoxDecoration(color: primary.withOpacity(0.05), shape: BoxShape.circle, border: Border.all(color: accent.withOpacity(0.2), width: 2)),
                                                          child: const Center(child: Icon(Icons.gavel_rounded, size: 24, color: accent)),
                                                        ),
                                                        Positioned(
                                                          bottom: 2, right: 2,
                                                          child: Container(
                                                            width: 14, height: 14,
                                                            decoration: BoxDecoration(color: isOnline ? AppTheme.completed : textGrey, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(width: 16),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: Text(l['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: textDark)),
                                                              ),
                                                              Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                decoration: BoxDecoration(color: AppTheme.completed.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                                                child: const Row(
                                                                  children: [
                                                                    Icon(Icons.verified_rounded, color: AppTheme.completed, size: 12),
                                                                    SizedBox(width: 4),
                                                                    Text('Verified', style: TextStyle(color: AppTheme.completed, fontSize: 10, fontWeight: FontWeight.bold)),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            (l['specialization'] ?? '') == 'family_law' ? 'Family Law Specialist' : (l['specialization'] ?? '') == 'tax_law' ? 'Tax Law Specialist' : l['specialization'] ?? '',
                                                            style: const TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                                          ),
                                                          const SizedBox(height: 8),
                                                          Row(
                                                            children: [
                                                              const Icon(Icons.star_rounded, color: AppTheme.warning, size: 14),
                                                              const SizedBox(width: 4),
                                                              Text('$rating', style: const TextStyle(color: textGrey, fontSize: 12, fontWeight: FontWeight.bold)),
                                                              const SizedBox(width: 12),
                                                              const Icon(Icons.location_on_outlined, color: AppTheme.textGrey, size: 14),
                                                              const SizedBox(width: 4),
                                                              Text("${l['city'] ?? ''}", style: const TextStyle(color: AppTheme.textGrey, fontSize: 12, fontWeight: FontWeight.w600)),
                                                              const SizedBox(width: 12),
                                                              const Icon(Icons.work_outline, color: AppTheme.textGrey, size: 13),
                                                              const SizedBox(width: 4),
                                                              Text("${l['years_experience'] ?? 0} yrs", style: const TextStyle(color: AppTheme.textGrey, fontSize: 12, fontWeight: FontWeight.w600)),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (l['bio'] != null && (l['bio'] as String).isNotEmpty) ...[
                                                  const SizedBox(height: 16),
                                                  Container(
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
                                                    child: Text(
                                                      l['bio'],
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(color: textDark, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
                                                    ),
                                                  ),
                                                ],
                                                const SizedBox(height: 16),
                                                const Divider(height: 1, color: border),
                                                const SizedBox(height: 16),
                                                Row(
                                                  children: [
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        const Text('Consultation Fee', style: TextStyle(color: AppTheme.textGrey, fontSize: 11, fontWeight: FontWeight.bold)),
                                                        const SizedBox(height: 2),
                                                        Text('₨${l['consultation_fee']}', style: const TextStyle(color: textDark, fontWeight: FontWeight.w800, fontSize: 18)),
                                                      ],
                                                    ),
                                                    const Spacer(),
                                                    ElevatedButton(
                                                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScreen(lawyer: l))),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: primary,
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                                      ),
                                                      child: const Text('Book Now', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ).animate().fade(delay: (i * 50).ms).slideY(begin: 0.1);
                                      },
                                    ),
                                  ),
                                ],
                              ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMore() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: _isLoadingMore
          ? const Center(child: CircularProgressIndicator(color: primary))
          : Center(
              child: HoverButton(
                onTap: () => _search(_controller.text, refresh: false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: border),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: const Text('LOAD MORE RESULTS', 
                    style: TextStyle(color: primary, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                ),
              ),
            ),
    );
  }
}

// ── Tip ───────────────────────────────────────────────────────

class _Tip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Tip({required this.icon, required this.text});
  static const Color accent = AppTheme.navyLight;
  static const Color textGrey = AppTheme.textGrey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppTheme.navyLight.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: const TextStyle(color: AppTheme.textDark, fontSize: 14, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}