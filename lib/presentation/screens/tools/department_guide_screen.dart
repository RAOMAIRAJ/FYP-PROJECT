import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qanoon_buddy/core/api_service.dart';
import 'package:qanoon_buddy/core/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qanoon_buddy/presentation/widgets/hover_button.dart';

class DepartmentGuideScreen extends StatefulWidget {
  const DepartmentGuideScreen({super.key});

  @override
  State<DepartmentGuideScreen> createState() => _DepartmentGuideScreenState();
}

class _DepartmentGuideScreenState extends State<DepartmentGuideScreen> {
  final TextEditingController _issueController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _guideData;

  Future<void> _getGuide() async {
    if (_issueController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please describe your issue')));
      return;
    }

    setState(() {
      _isLoading = true;
      _guideData = null;
    });

    try {
      final res = await apiService.getDepartmentGuide(_issueController.text);
      setState(() {
        _guideData = res;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.navyDeep,
        foregroundColor: Colors.white,
        title: const Text('Department Guide AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'WHERE SHOULD I GO?',
              style: TextStyle(color: AppTheme.navyDeep, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2),
            ).animate().fadeIn().slideY(begin: 0.2),
            const SizedBox(height: 8),
            const Text(
              'Describe your issue, and our AI will tell you exactly which Karachi/Sindh government department handles it and what to do.',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 13, fontWeight: FontWeight.w600, height: 1.5),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
            
            const SizedBox(height: 30),

            // Input Form
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your Issue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _issueController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'e.g., Someone created a fake Facebook account with my pictures...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.border)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _getGuide,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.goldPremium,
                        foregroundColor: AppTheme.navyDeep,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppTheme.navyDeep, strokeWidth: 2))
                          : const Text('FIND DEPARTMENT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

            if (_guideData != null) ...[
              const SizedBox(height: 30),
              
              _ResultCard(
                title: 'TARGET DEPARTMENT',
                icon: Icons.account_balance_rounded,
                content: _guideData!['department'] ?? 'Unknown',
                isPrimary: true,
              ).animate().fadeIn().slideY(begin: 0.1),

              const SizedBox(height: 16),
              
              _ResultCard(
                title: 'REQUIRED DOCUMENTS',
                icon: Icons.file_copy_rounded,
                content: _guideData!['documents'] ?? 'N/A',
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

              const SizedBox(height: 16),
              
              _ResultCard(
                title: 'PROCEDURE',
                icon: Icons.format_list_numbered_rounded,
                content: _guideData!['procedure'] ?? 'N/A',
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

              const SizedBox(height: 16),
              
              _ResultCard(
                title: 'LOCATION HINT',
                icon: Icons.map_rounded,
                content: _guideData!['location_hint'] ?? 'N/A',
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

              const SizedBox(height: 16),
              
              _ResultCard(
                title: 'EMERGENCY HELPLINE',
                icon: Icons.phone_in_talk_rounded,
                content: _guideData!['emergency_contacts'] ?? 'N/A',
                isAlert: true,
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
            ]
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final bool isPrimary;
  final bool isAlert;

  const _ResultCard({
    required this.title,
    required this.content,
    required this.icon,
    this.isPrimary = false,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.white;
    Color borderColor = AppTheme.border;
    Color titleColor = AppTheme.navyDeep;

    if (isPrimary) {
      bgColor = AppTheme.navyDeep.withOpacity(0.05);
      borderColor = AppTheme.goldPremium.withOpacity(0.5);
    } else if (isAlert) {
      bgColor = Colors.red.withOpacity(0.05);
      borderColor = Colors.red.withOpacity(0.2);
      titleColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: titleColor),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.0, color: titleColor)),
            ],
          ),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(height: 1.5, fontSize: 14, color: AppTheme.textDark, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
