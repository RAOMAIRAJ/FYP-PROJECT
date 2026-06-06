import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qanoon_buddy/data/auth_provider.dart';
import 'package:qanoon_buddy/core/api_service.dart';
import 'package:qanoon_buddy/core/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qanoon_buddy/presentation/widgets/hover_button.dart';

class BailCalculatorScreen extends ConsumerStatefulWidget {
  const BailCalculatorScreen({super.key});

  @override
  ConsumerState<BailCalculatorScreen> createState() => _BailCalculatorScreenState();
}

class _BailCalculatorScreenState extends ConsumerState<BailCalculatorScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  Future<void> _calculate() async {
    if (_controller.text.isEmpty) return;
    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final res = await apiService.calculateBail(_controller.text, ref.read(authProvider).token ?? '');
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
                    const Text('Bail Calculator',
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
              'Enter the offense description or Pakistan Penal Code (PPC) section to find out if it is generally bailable.',
              style: TextStyle(fontSize: 15, color: textGrey, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              style: const TextStyle(fontSize: 14, color: textDark),
              decoration: InputDecoration(
                hintText: 'e.g., PPC 302 or "Theft of mobile phone"',
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
              onTap: _isLoading ? null : _calculate,
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
                    : const Text('Check Bail Eligibility', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_result != null) ...[
              const Text('Eligibility Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textDark)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _result!['is_bailable'] ? AppTheme.completed.withOpacity(0.1) : AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _result!['is_bailable'] ? AppTheme.completed : AppTheme.error),
                ),
                child: Column(
                  children: [
                    Icon(
                      _result!['is_bailable'] ? Icons.check_circle_outline : Icons.cancel_outlined,
                      size: 64,
                      color: _result!['is_bailable'] ? AppTheme.completed : AppTheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _result!['is_bailable'] ? 'Bailable Offense' : 'Non-Bailable Offense',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _result!['is_bailable'] ? AppTheme.completed : AppTheme.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _result!['explanation'] ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, height: 1.5, color: textDark),
                    ),
                    if (_result!['max_punishment'] != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                        child: Row(
                          children: [
                            const Icon(Icons.gavel, color: primary),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('Maximum Punishment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textGrey)),
                              const SizedBox(height: 4),
                              Text(_result!['max_punishment'], style: const TextStyle(fontWeight: FontWeight.w700, color: textDark)),
                            ])),
                          ],
                        ),
                      ),
                    ],
                    if (_result!['bail_type'] != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                        child: Row(
                          children: [
                            const Icon(Icons.description, color: accent),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('Required Bail Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textGrey)),
                              const SizedBox(height: 4),
                              Text(_result!['bail_type'], style: const TextStyle(fontWeight: FontWeight.w700, color: textDark)),
                            ])),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text(
                      '*This is AI-generated advice and does not replace professional legal counsel.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: textGrey, fontStyle: FontStyle.italic),
                    )
                  ],
                ),
              ),
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
