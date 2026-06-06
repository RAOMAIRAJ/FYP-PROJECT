import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qanoon_buddy/data/auth_provider.dart';
import 'package:qanoon_buddy/core/api_service.dart';
import 'package:qanoon_buddy/core/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qanoon_buddy/presentation/widgets/hover_button.dart';
import 'package:go_router/go_router.dart';

class RiskAnalyzerScreen extends ConsumerStatefulWidget {
  const RiskAnalyzerScreen({super.key});

  @override
  ConsumerState<RiskAnalyzerScreen> createState() => _RiskAnalyzerScreenState();
}

class _RiskAnalyzerScreenState extends ConsumerState<RiskAnalyzerScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  Future<void> _analyze() async {
    if (_controller.text.isEmpty) return;
    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final apiService = ApiService();
      final res = await apiService.analyzeRisk(_controller.text, ref.read(authProvider).token ?? '');
      if (mounted) {
        setState(() {
          _result = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Color _getRiskColor(String level) {
    switch (level.toLowerCase()) {
      case 'low': return AppTheme.completed;
      case 'medium': return AppTheme.warning;
      case 'high': return AppTheme.error;
      default: return AppTheme.textGrey;
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
      body: Column(
        children: [
          // ── Gradient Header ──
          Container(
            width: double.infinity,
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
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
                    const Text('Legal Risk Analyzer',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ).animate().slideY(begin: -0.1).fade(),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            const Text(
              'Describe your situation in detail. Our AI will analyze the legal risks and consequences in Pakistan.',
              style: TextStyle(fontSize: 15, color: textGrey, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 6,
              style: const TextStyle(fontSize: 14, color: textDark),
              decoration: InputDecoration(
                hintText: 'e.g., I bought a car and the seller refuses to transfer the papers...',
                filled: true,
                fillColor: Colors.white,
                hintStyle: const TextStyle(color: textGrey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),
            HoverButton(
              onTap: _isLoading ? null : _analyze,
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [primary, AppTheme.navyLight]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: Center(
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Analyze Risk', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_result != null) ...[
              const Text('Analysis Result', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textDark)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _getRiskColor(_result!['risk_level'] ?? '').withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _getRiskColor(_result!['risk_level'] ?? '')),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_rounded, color: _getRiskColor(_result!['risk_level'] ?? '')),
                        const SizedBox(width: 8),
                        Text(
                          'Risk Level: ${_result!['risk_level']}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getRiskColor(_result!['risk_level'] ?? ''),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Legal Consequences:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    ...(_result!['legal_consequences'] as List<dynamic>).map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontSize: 18)),
                          Expanded(child: Text(c.toString(), style: const TextStyle(fontSize: 15, height: 1.4))),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
              if (_result!['risk_level'] == 'High' || _result!['risk_level'] == 'Medium') ...[
                const SizedBox(height: 24),
                HoverButton(
                  onTap: () => context.push('/lawyer-match'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppTheme.error, AppTheme.error.withOpacity(0.8)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: AppTheme.error.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 8))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.gavel_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('High Risk Detected', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              SizedBox(height: 4),
                              Text('Match with a specialized lawyer immediately.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
                      ],
                    ),
                  ).animate().scale(delay: 400.ms, duration: 600.ms, curve: Curves.easeOutBack),
                ),
              ]
            ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
