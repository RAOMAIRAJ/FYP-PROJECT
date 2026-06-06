import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qanoon_buddy/data/auth_provider.dart';
import 'package:qanoon_buddy/core/api_service.dart';
import 'package:qanoon_buddy/presentation/screens/booking_screen.dart';
import 'package:qanoon_buddy/core/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qanoon_buddy/presentation/widgets/hover_button.dart';


class LawyerMatchScreen extends ConsumerStatefulWidget {
  const LawyerMatchScreen({super.key});

  @override
  ConsumerState<LawyerMatchScreen> createState() => _LawyerMatchScreenState();
}

class _LawyerMatchScreenState extends ConsumerState<LawyerMatchScreen> {
  final _controller = TextEditingController();
  bool _isMatching = false;
  bool _hasMatched = false;
  List<dynamic> _matchedLawyers = [];
  Map<String, dynamic>? _extractedFilters;

  Future<void> _findMatch() async {
    if (_controller.text.isEmpty) return;
    
    setState(() {
      _isMatching = true;
      _hasMatched = false;
    });

    try {
      // 1. Ask NLP to extract intent
      final filters = await apiService.matchLawyer(_controller.text, ref.read(authProvider).token ?? '');
      _extractedFilters = filters;

      // 2. Query normal backend with filters
      final lawyers = await apiService.getLawyersFiltered(
        specialization: filters['specialization'],
        city: filters['city'],
        maxBudget: filters['max_budget'],
      );

      if (mounted) {
        setState(() {
          _matchedLawyers = lawyers;
          _hasMatched = true;
          _isMatching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isMatching = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  static const Color primary = AppTheme.navyDeep;
  static const Color accent = AppTheme.goldPremium;
  static const Color bg = AppTheme.surface;
  static const Color textDark = AppTheme.textDark;
  static const Color textGrey = AppTheme.textGrey;
  static const Color border = AppTheme.border;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          HoverButton(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text('Lawyer Match AI',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Describe your legal issue, your city, and your budget (if any). The AI will find the perfect lawyers for you.',
                        style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                      ).animate().fade().slideX(begin: -0.05),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _controller,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'e.g., I need a family lawyer in Lahore for a divorce case under 5000 Rs',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.08),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: accent.withOpacity(0.5), width: 1.5)),
                          contentPadding: const EdgeInsets.all(20),
                        ),
                      ).animate().fade().slideY(begin: 0.1),
                      const SizedBox(height: 20),
                      HoverButton(
                        onTap: _isMatching ? null : _findMatch,
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: accent.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                          ),
                          child: Center(
                            child: _isMatching
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Find My Lawyer', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ).animate().fade().scale(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_hasMatched)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Extracted Filters', style: TextStyle(color: textGrey, fontWeight: FontWeight.w700, fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: [
                        if (_extractedFilters?['specialization'] != null)
                          Chip(label: Text('Spec: ${_extractedFilters!['specialization']}', style: const TextStyle(fontSize: 12))),
                        if (_extractedFilters?['city'] != null)
                          Chip(label: Text('City: ${_extractedFilters!['city']}', style: const TextStyle(fontSize: 12))),
                        if (_extractedFilters?['max_budget'] != null)
                          Chip(label: Text('Max Budget: ${_extractedFilters!['max_budget']}', style: const TextStyle(fontSize: 12))),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text('${_matchedLawyers.length} Matches Found', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textDark)),
                  ],
                ),
              ),
            ),
          if (_hasMatched && _matchedLawyers.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No lawyers match those exact criteria. Try broadening your search.')),
              ),
            ),
          if (_hasMatched)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final l = _matchedLawyers[index];
                  final spec = (l['specialization'] ?? '').toString().replaceAll('_', ' ');
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    leading: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: accent.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.gavel_rounded, size: 24, color: accent),
                    ),
                    title: Text(l['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, color: textDark)),
                    subtitle: Text('${spec.toUpperCase()} • ${l['city']} • ₨${l['consultation_fee']}', style: const TextStyle(color: textGrey, fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: textGrey),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScreen(lawyer: l))),
                  );
                },
                childCount: _matchedLawyers.length,
              ),
            ),
        ],
      ),
    );
  }
}
