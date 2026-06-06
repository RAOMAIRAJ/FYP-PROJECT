import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qanoon_buddy/core/api_service.dart';
import 'package:qanoon_buddy/core/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qanoon_buddy/presentation/widgets/hover_button.dart';

class AiComplaintGeneratorScreen extends StatefulWidget {
  const AiComplaintGeneratorScreen({super.key});

  @override
  State<AiComplaintGeneratorScreen> createState() => _AiComplaintGeneratorScreenState();
}

class _AiComplaintGeneratorScreenState extends State<AiComplaintGeneratorScreen> {
  final TextEditingController _detailsController = TextEditingController();
  String _selectedType = 'Police';
  String _selectedLanguage = 'English';
  
  bool _isLoading = false;
  String? _generatedComplaint;

  final List<String> _complaintTypes = [
    'Police', 'Cybercrime (FIA)', 'K-Electric', 'KMC / Water Board',
    'Landlord Dispute', 'Harassment', 'Fraud', 'Consumer Court', 'Bank'
  ];

  Future<void> _generate() async {
    if (_detailsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter issue details')));
      return;
    }

    setState(() {
      _isLoading = true;
      _generatedComplaint = null;
    });

    try {
      final res = await apiService.generateComplaint(
        type: _selectedType,
        language: _selectedLanguage,
        details: _detailsController.text,
      );
      setState(() {
        _generatedComplaint = res['complaint_text'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate: $e')));
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
        title: const Text('AI Complaint Generator', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'KARACHI/SINDH COMPLAINT SYSTEM',
              style: TextStyle(color: AppTheme.navyDeep, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2),
            ).animate().fadeIn().slideY(begin: 0.2),
            const SizedBox(height: 8),
            const Text(
              'Automatically draft a legally sound, highly formal complaint tailored for local authorities.',
              style: TextStyle(color: AppTheme.textGrey, fontSize: 13, fontWeight: FontWeight.w600, height: 1.5),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
            
            const SizedBox(height: 30),

            // Form
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
                  const Text('Complaint Target Authority', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.border)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: _complaintTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setState(() => _selectedType = v!),
                  ),
                  const SizedBox(height: 20),

                  const Text('Language', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedLanguage,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.border)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: ['English', 'Urdu'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setState(() => _selectedLanguage = v!),
                  ),
                  const SizedBox(height: 20),

                  const Text('Issue Details (What happened?)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _detailsController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'E.g., Two men snatched my phone at Tariq Road...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.border)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _generate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.navyDeep,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('GENERATE COMPLAINT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

            if (_generatedComplaint != null) ...[
              const SizedBox(height: 30),
              const Text('Generated Draft', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.navyDeep)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.navyDeep.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.goldPremium.withOpacity(0.3)),
                ),
                child: SelectableText(
                  _generatedComplaint!,
                  style: const TextStyle(height: 1.6, fontSize: 14, color: AppTheme.textDark),
                ),
              ).animate().fadeIn().slideY(begin: 0.1),
              const SizedBox(height: 16),
              HoverButton(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _generatedComplaint!));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard!')));
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.copy, size: 18, color: AppTheme.navyDeep),
                      SizedBox(width: 8),
                      Text('Copy to Clipboard', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navyDeep)),
                    ],
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
