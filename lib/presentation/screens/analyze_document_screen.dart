import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:qanoon_buddy/core/api_service.dart';
import 'package:qanoon_buddy/presentation/widgets/hover_button.dart';
import 'package:qanoon_buddy/core/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qanoon_buddy/data/auth_provider.dart';

class AnalyzeDocumentScreen extends ConsumerStatefulWidget {
  const AnalyzeDocumentScreen({super.key});

  @override
  ConsumerState<AnalyzeDocumentScreen> createState() => _AnalyzeDocumentScreenState();
}

class _AnalyzeDocumentScreenState extends ConsumerState<AnalyzeDocumentScreen> {
  static const Color primary = AppTheme.navyDeep;
  static const Color accent = AppTheme.goldPremium;
  static const Color bg = AppTheme.surface;
  static const Color textDark = AppTheme.textDark;
  static const Color textGrey = AppTheme.textGrey;
  static const Color border = AppTheme.border;

  bool _isAnalyzing = false;
  String? _selectedFileName;
  Map<String, dynamic>? _analysisResult;

  Future<void> _pickAndAnalyze() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _selectedFileName = result.files.single.name;
          _isAnalyzing = true;
          _analysisResult = null;
        });

        final analysis = await apiService.analyzeDocument(result.files.single.bytes!, result.files.single.name, ref.read(authProvider).token ?? '');
        
        setState(() {
          _analysisResult = analysis;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error analyzing document: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // ── Gradient Header ──
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, Color(0xFF1E293B)],
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
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text('AI Document Analyzer',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ).animate().slideY(begin: -0.1).fade(),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            // Upload button
            HoverButton(
              onTap: _isAnalyzing ? null : _pickAndAnalyze,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: accent.withOpacity(0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Icon(_isAnalyzing ? Icons.hourglass_top : Icons.upload_file, size: 48, color: accent),
                    const SizedBox(height: 12),
                    Text(
                      _isAnalyzing 
                        ? 'Analyzing "$_selectedFileName"...' 
                        : (_selectedFileName ?? 'Upload Legal Document (PDF)'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primary),
                      textAlign: TextAlign.center,
                    ),
                    if (!_isAnalyzing && _selectedFileName == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Tap to browse files. Supports PDFs up to 10MB.',
                          style: TextStyle(color: textGrey, fontSize: 13),
                        ),
                      )
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Result area
            Expanded(
              child: _isAnalyzing
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: accent),
                        SizedBox(height: 16),
                        Text('Reading clauses & highlighting risks...', style: TextStyle(color: textGrey)),
                      ],
                    ),
                  )
                : _analysisResult != null
                  ? DefaultTabController(
                      length: 3,
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                            child: const TabBar(
                              labelColor: primary,
                              unselectedLabelColor: textGrey,
                              indicatorColor: accent,
                              indicatorWeight: 3,
                              tabs: [
                                Tab(icon: Icon(Icons.description), text: 'Summary'),
                                Tab(icon: Icon(Icons.flag), text: 'Red Flags'),
                                Tab(icon: Icon(Icons.vpn_key), text: 'Key Clauses'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: TabBarView(
                              children: [
                                // Tab 1: Summary
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
                                  child: SingleChildScrollView(
                                    child: Text(_analysisResult!['summary']?.toString() ?? 'No summary available.', style: const TextStyle(fontSize: 15, height: 1.5, color: textDark)),
                                  ),
                                ),
                                // Tab 2: Red Flags
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.error.withOpacity(0.3))),
                                  child: ListView(
                                    children: (_analysisResult!['red_flags'] as List<dynamic>? ?? []).map((flag) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        const Icon(Icons.warning, color: AppTheme.error, size: 20),
                                        const SizedBox(width: 12),
                                        Expanded(child: Text(flag.toString(), style: const TextStyle(fontSize: 14, height: 1.5, color: textDark))),
                                      ]),
                                    )).toList(),
                                  ),
                                ),
                                // Tab 3: Key Clauses
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
                                  child: ListView(
                                    children: (_analysisResult!['key_clauses'] as List<dynamic>? ?? []).map((clause) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        const Icon(Icons.check_circle, color: accent, size: 20),
                                        const SizedBox(width: 12),
                                        Expanded(child: Text(clause.toString(), style: const TextStyle(fontSize: 14, height: 1.5, color: textDark))),
                                      ]),
                                    )).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : const Center(
                      child: Text(
                        'Upload a legal document to get a concise summary and risk analysis.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textGrey, fontSize: 14),
                      ),
                    ),
            ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
