import 'package:flutter/material.dart';
import 'package:qanoon_buddy/core/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qanoon_buddy/presentation/widgets/hover_button.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qanoon_buddy/core/api_service.dart';

class AiRouteAdvisorScreen extends StatefulWidget {
  const AiRouteAdvisorScreen({super.key});

  @override
  State<AiRouteAdvisorScreen> createState() => _AiRouteAdvisorScreenState();
}

class _AiRouteAdvisorScreenState extends State<AiRouteAdvisorScreen> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  bool _isAnalyzing = false;
  bool _showResult = false;
  String _highRiskReport = '';
  String _safeRouteReport = '';

  void _analyzeRoute() async {
    if (_fromController.text.isEmpty || _toController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter both locations.')));
      return;
    }
    
    FocusScope.of(context).unfocus();
    setState(() {
      _isAnalyzing = true;
      _showResult = false;
    });

    try {
      final token = await const FlutterSecureStorage().read(key: 'auth_token');
      final result = await apiService.getAiRouteAdvice(_fromController.text.trim(), _toController.text.trim(), token ?? '');
      if (mounted) {
        setState(() {
          int count = result['active_incidents_count'] ?? 0;
          _highRiskReport = count > 0 
              ? 'Warning: There are currently $count active incidents reported on Karachi Radar. Please read the AI advice carefully.' 
              : 'No major active incidents reported right now.';
          _safeRouteReport = result['safe_route_advice'] ?? 'Proceed on main arteries.';
          _isAnalyzing = false;
          _showResult = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error analyzing route: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.navyDeep,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.pop()),
        title: const Text('AI Route Risk Advisor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Enter your planned route. Our AI will analyze community reports and historical data to identify potential risks like snatching hotspots, protests, or blocked roads.', style: TextStyle(color: AppTheme.textGrey, height: 1.5)),
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _fromController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.my_location, color: Colors.blue),
                      hintText: 'Current Location (e.g., Gulshan)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      filled: true, fillColor: AppTheme.surface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _toController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.location_on, color: Colors.red),
                      hintText: 'Destination (e.g., Clifton)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      filled: true, fillColor: AppTheme.surface,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            HoverButton(
              onTap: _isAnalyzing ? null : _analyzeRoute,
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.navyDeep, AppTheme.navyLight]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: AppTheme.navyDeep.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Center(
                  child: _isAnalyzing 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Analyze Route Safety', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),

            if (_showResult) ...[
              const SizedBox(height: 32),
              const Text('Intelligence Report', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textDark)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('High Risk Detected', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('• $_highRiskReport', style: const TextStyle(color: Colors.red, height: 1.5)),
                  ],
                ),
              ).animate().fade().slideY(begin: 0.2),
              
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('AI Suggested Safe Route', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('$_safeRouteReport', style: const TextStyle(color: Colors.green, height: 1.5)),
                  ],
                ),
              ).animate().fade(delay: 200.ms).slideY(begin: 0.2),
            ],
          ],
        ),
      ),
    );
  }
}
