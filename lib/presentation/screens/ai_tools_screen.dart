import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qanoon_buddy/presentation/screens/tools/risk_analyzer_screen.dart';
import 'package:qanoon_buddy/presentation/screens/tools/fir_generator_screen.dart';
import 'package:qanoon_buddy/presentation/screens/tools/bail_calculator_screen.dart';
import 'package:qanoon_buddy/presentation/screens/analyze_document_screen.dart';
import 'package:qanoon_buddy/presentation/screens/tools/lawyer_match_screen.dart';
import 'package:qanoon_buddy/presentation/widgets/hover_button.dart';
import 'package:qanoon_buddy/core/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AiToolsScreen extends StatelessWidget {
  const AiToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('🏗️ BUILDING AiToolsScreen');
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          // ── Elite Tools Header ──
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.navyDeep, Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _topBtn(context, Icons.chevron_left_rounded, () => context.pop()),
                          const SizedBox(width: 16),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('CORE INTELLIGENCE', 
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                              Text('ADVANCED LEGAL PROTOCOLS', 
                                style: TextStyle(color: AppTheme.goldPremium, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'EMPOWER YOUR LEGAL JOURNEY',
                        style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, height: 1.1),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Leverage Pakistan\'s most advanced AI systems to analyze risks, calculate bail, and automate documentation.',
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, height: 1.6, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildListDelegate([
                _AiGridCard(
                  title: 'CONTRACT ANALYZER',
                  description: 'Upload documents to instantly extract clauses.',
                  icon: Icons.document_scanner_rounded,
                  accentColor: Colors.blueAccent,
                  onTap: () => context.push('/analyze-document'),
                  index: 0,
                ),
                _AiGridCard(
                  title: 'FIR DRAFT GENERATOR',
                  description: 'Draft formal First Information Reports instantly.',
                  icon: Icons.edit_document,
                  accentColor: Colors.indigo,
                  onTap: () => context.push('/fir-generator'),
                  index: 1,
                ),
                _AiGridCard(
                  title: 'RISK ANALYZER',
                  description: 'AI assessment of potential legal risks.',
                  icon: Icons.security_rounded,
                  accentColor: Colors.orange,
                  onTap: () => context.push('/risk-analyzer'),
                  index: 2,
                ),
                _AiGridCard(
                  title: 'BAIL CALCULATOR',
                  description: 'Verify bail eligibility with jurisprudence.',
                  icon: Icons.gavel_rounded,
                  accentColor: Colors.teal,
                  onTap: () => context.push('/bail-calculator'),
                  index: 3,
                ),
                _AiGridCard(
                  title: 'LAWYER MATCH AI',
                  description: 'Find optimal counsel based on your case.',
                  icon: Icons.person_search_rounded,
                  accentColor: AppTheme.goldPremium,
                  onTap: () => context.push('/lawyer-match'),
                  index: 4,
                ),
                _AiGridCard(
                  title: 'COMPLAINT GENERATOR',
                  description: 'Generate formal police/fraud complaints.',
                  icon: Icons.contact_page_rounded,
                  accentColor: Colors.redAccent,
                  onTap: () => context.push('/complaint-generator'),
                  index: 5,
                ),
                _AiGridCard(
                  title: 'DEPARTMENT GUIDE AI',
                  description: 'Let AI guide you to the correct department.',
                  icon: Icons.account_balance_rounded,
                  accentColor: Colors.purple,
                  onTap: () => context.push('/department-guide'),
                  index: 6,
                ),
              ]),
            ),
          ),
          
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  Widget _topBtn(BuildContext context, IconData icon, VoidCallback onTap) {
    return HoverButton(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12), 
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _AiGridCard extends StatelessWidget {
  final String title, description;
  final IconData icon;
  final VoidCallback onTap;
  final Color accentColor;
  final int index;

  const _AiGridCard({required this.title, required this.description, required this.icon, required this.onTap, required this.accentColor, required this.index});

  @override
  Widget build(BuildContext context) {
    return HoverButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: accentColor.withOpacity(0.2), width: 1.5),
          boxShadow: [BoxShadow(color: AppTheme.navyDeep.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 12))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(child: Icon(icon, size: 24, color: accentColor)),
            ),
            const Spacer(),
            Text(title, style: const TextStyle(color: AppTheme.navyDeep, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: -0.2)),
            const SizedBox(height: 6),
            Expanded(
              flex: 2,
              child: Text(description, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textGrey, fontSize: 10, fontWeight: FontWeight.w600, height: 1.4)),
            ),
          ],
        ),
      ),
    ).animate().fade(delay: (index * 50).ms).slideY(begin: 0.1);
  }
}
