import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qanoon_buddy/core/api_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qanoon_buddy/presentation/widgets/hover_button.dart';
import 'package:qanoon_buddy/core/theme.dart';

class LegalNewsScreen extends ConsumerStatefulWidget {
  const LegalNewsScreen({super.key});

  @override
  ConsumerState<LegalNewsScreen> createState() => _LegalNewsScreenState();
}

class _LegalNewsScreenState extends ConsumerState<LegalNewsScreen> {
  static const Color primary   = AppTheme.navyDeep;
  static const Color accent    = AppTheme.goldPremium;
  static const Color bg        = AppTheme.surface;
  static const Color textDark  = AppTheme.textDark;
  static const Color textGrey  = AppTheme.textGrey;
  static const Color border    = AppTheme.border;

  List<dynamic> _news = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _skip = 0;
  final int _limit = 10;
  String _language = 'en'; // 'en' or 'ur'
  String _newsType = 'all'; // Default to 'all'
  String _karachiTopic = 'All';
  final List<String> _karachiTopics = ['All', 'Snatching', 'Load Shedding', 'Water Crisis', 'Traffic', 'Weather'];

  @override
  void initState() {
    super.initState();
    _fetchNews(refresh: true);
  }

  Future<void> _fetchNews({bool refresh = false}) async {
    if (refresh) {
      setState(() { 
        _isLoading = true; 
        _skip = 0; 
        _hasMore = true; 
        _news = []; 
      });
    } else {
      if (!_hasMore || _isLoadingMore) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      List<dynamic> data = [];
      if (_newsType == 'all') {
        final legalData = await apiService.getNews(skip: _skip, limit: _limit, type: 'legal');
        final karachiData = await apiService.getNews(skip: _skip, limit: _limit, type: 'karachi');
        data = [...legalData, ...karachiData];
      } else {
        final topic = _karachiTopic == 'All' ? null : _karachiTopic;
        data = await apiService.getNews(skip: _skip, limit: _limit, type: _newsType, topic: topic);
      }
      
      if (mounted) {
        setState(() {
          if (refresh) {
            _news = data;
          } else {
            _news.addAll(data);
          }
          
          _news.sort((a, b) {
            try {
              final dateA = DateTime.parse(a['created_at']);
              final dateB = DateTime.parse(b['created_at']);
              return dateB.compareTo(dateA);
            } catch (_) { return 0; }
          });

          _isLoading = false;
          _isLoadingMore = false;
          // For 'all' we fetch limit from both, so we might get up to limit * 2 items.
          _hasMore = _newsType == 'all' ? (data.length >= _limit) : (data.length == _limit);
          if (_hasMore) _skip += _limit;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // ── Elite News Header ──
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _topBtn(Icons.chevron_left_rounded, () => Navigator.pop(context)),
                        const SizedBox(width: 20),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('LEGAL GAZETTE', 
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                              Text('SUPREME COURT INTELLIGENCE', 
                                style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                            ],
                          ),
                        ),
                        _topBtn(Icons.refresh_rounded, () => _fetchNews(refresh: true)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Type Toggle
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.navyDeep.withOpacity(0.6), 
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          _typeBtn('all', 'ALL'),
                          _typeBtn('legal', 'LEGAL'),
                          _typeBtn('karachi', 'KARACHI'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Topic Chips (if Karachi)
                    if (_newsType == 'karachi') ...[
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
                                  _fetchNews(refresh: true);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isActive ? accent : AppTheme.glassWhite.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isActive ? accent : AppTheme.glassBorder),
                                ),
                                child: Center(
                                  child: Text(t, style: TextStyle(
                                    color: isActive ? AppTheme.navyDeep : Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  )),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Language Toggle
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.navyDeep.withOpacity(0.6), 
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          _langBtn('en', 'ENGLISH'),
                          _langBtn('ur', 'اردو - URDU'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().slideY(begin: -0.1).fade(),

          // ── News List ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: accent))
                : _news.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _news.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (i == _news.length) {
                            return _buildLoadMore();
                          }
                          return _buildNewsCard(_news[i], i);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _langBtn(String code, String label) {
    bool active = _language == code;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _language = code),
        child: AnimatedContainer(
          duration: 250.ms,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active ? [BoxShadow(color: accent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? AppTheme.navyDeep : Colors.white54,
              fontSize: 11,
              fontWeight: active ? FontWeight.w900 : FontWeight.w600,
              letterSpacing: code == 'ur' ? 0 : 1,
              fontFamily: code == 'ur' ? 'Jameel Noori Nastaleeq' : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeBtn(String code, String label) {
    bool active = _newsType == code;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_newsType != code) {
            setState(() => _newsType = code);
            _fetchNews(refresh: true);
          }
        },
        child: AnimatedContainer(
          duration: 250.ms,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active ? [BoxShadow(color: accent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? AppTheme.navyDeep : Colors.white54,
              fontSize: 11,
              fontWeight: active ? FontWeight.w900 : FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewsCard(dynamic news, int index) {
    final title   = _language == 'en' ? news['title_en'] : news['title_ur'];
    final summary = _language == 'en' ? news['summary_en'] : news['summary_ur'];
    final isUrdu  = _language == 'ur';
    final TextDirection dir = isUrdu ? TextDirection.rtl : TextDirection.ltr;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Directionality(
        textDirection: dir,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Category tag & Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.goldPremium.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.goldPremium.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded, color: AppTheme.goldPremium, size: 14),
                      const SizedBox(width: 4),
                      Text((news['category'] ?? 'GENERAL UPDATE').toUpperCase(),
                          style: const TextStyle(color: AppTheme.goldPremium, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    ],
                  ),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true)).fade(begin: 1.0, end: 0.5, duration: 800.ms),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: textGrey, size: 14),
                    const SizedBox(width: 4),
                    Text(_formatDate(news['created_at']),
                        style: const TextStyle(color: textGrey, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Headline
            Text(title ?? '',
                style: TextStyle(
                  color: textDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  height: 1.3,
                  letterSpacing: isUrdu ? 0 : -0.3,
                  fontFamily: isUrdu ? 'Jameel Noori Nastaleeq' : null,
                )),
            const SizedBox(height: 12),
            
            // Summary
            if (summary != null && summary.toString().isNotEmpty)
              Text(summary,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textGrey,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 1.5,
                    fontFamily: isUrdu ? 'Jameel Noori Nastaleeq' : null,
                  )),
                  
            const SizedBox(height: 24),
            
            // Action button
            if (news['source_url'] != null)
              HoverButton(
                onTap: () => launchUrl(Uri.parse(news['source_url'])),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('READ FULL ARTICLE',
                        style: TextStyle(color: AppTheme.navyDeep, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                    const SizedBox(width: 8),
                    Icon(isUrdu ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded, color: AppTheme.navyDeep, size: 16),
                  ],
                ),
              ),
          ],
        ),
      ),
    ).animate().fade(delay: (index * 50).ms).slideY(begin: 0.1);
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: accent.withOpacity(0.05), shape: BoxShape.circle),
            child: const Icon(Icons.newspaper_rounded, color: accent, size: 64),
          ),
          const SizedBox(height: 24),
          const Text('NO NEWS RECORDED', style: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 8),
          const Text('THE GAZETTE IS CURRENTLY CLEAR', style: TextStyle(color: textGrey, fontSize: 11, fontWeight: FontWeight.w800)),
        ],
      ),
    ).animate().scale();
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
    } catch (_) { return iso; }
  }

  Widget _topBtn(IconData icon, VoidCallback onTap) {
    return HoverButton(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: AppTheme.glassWhite.withOpacity(0.2), 
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildLoadMore() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: _isLoadingMore
          ? const Center(child: CircularProgressIndicator(color: accent))
          : Center(
              child: HoverButton(
                onTap: _fetchNews,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: border),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: const Text('LOAD MORE GAZETTE', 
                    style: TextStyle(color: AppTheme.navyDeep, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                ),
              ),
            ),
    );
  }
}
