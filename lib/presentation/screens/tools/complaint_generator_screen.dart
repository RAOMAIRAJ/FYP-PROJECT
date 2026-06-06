import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qanoon_buddy/core/api_service.dart';
import 'package:qanoon_buddy/data/auth_provider.dart';
import 'package:qanoon_buddy/core/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qanoon_buddy/presentation/widgets/hover_button.dart';

class ComplaintGeneratorScreen extends ConsumerStatefulWidget {
  const ComplaintGeneratorScreen({super.key});

  @override
  ConsumerState<ComplaintGeneratorScreen> createState() => _ComplaintGeneratorScreenState();
}

class _ComplaintGeneratorScreenState extends ConsumerState<ComplaintGeneratorScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  String? _result;
  String _selectedCategory = 'Police';
  bool _isUrdu = false;

  final List<String> _categories = [
    'Police',
    'Cybercrime',
    'Landlord',
    'Harassment',
    'Fraud',
    'Banks',
    'Consumer Court'
  ];

  Future<void> _generate() async {
    final token = ref.read(authProvider).token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to use this feature.')));
      return;
    }

    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter incident details.')));
      return;
    }
    
    // Unfocus keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final language = _isUrdu ? 'Urdu' : 'English';
      final res = await apiService.generateComplaint(
        type: _selectedCategory,
        language: language,
        details: _controller.text,
      );
      
      if (mounted) {
        setState(() {
          _result = res['complaint_text'];
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

  void _copyToClipboard() {
    if (_result != null) {
      Clipboard.setData(ClipboardData(text: _result!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complaint copied to clipboard!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
          SliverAppBar(
            backgroundColor: primary,
            expandedHeight: 140,
            floating: false,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
              title: const Text('AI Complaint Generator', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, AppTheme.navyLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                   child: Icon(Icons.contact_page_rounded, color: Colors.white.withOpacity(0.1), size: 100),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('AI COMPLAINT DRAFTER', style: TextStyle(color: primary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 12),
                  const Text(
                    'Select the appropriate authority and describe your issue. Our AI will draft a formal, ready-to-submit complaint.',
                    style: TextStyle(fontSize: 13, color: textGrey, height: 1.5, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 32),
                  
                  const Text('COMPLAINT CATEGORY', style: TextStyle(fontWeight: FontWeight.w900, color: textDark, fontSize: 11, letterSpacing: 1.0)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: border),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: primary),
                        style: const TextStyle(fontWeight: FontWeight.w800, color: textDark, fontSize: 15),
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCategory = val);
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  const Text('LANGUAGE', style: TextStyle(fontWeight: FontWeight.w900, color: textDark, fontSize: 11, letterSpacing: 1.0)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: HoverButton(
                          onTap: () => setState(() => _isUrdu = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: !_isUrdu ? primary : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: !_isUrdu ? primary : border),
                              boxShadow: !_isUrdu ? [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))] : [],
                            ),
                            child: Center(child: Text('ENGLISH', style: TextStyle(color: !_isUrdu ? Colors.white : textGrey, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.0))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: HoverButton(
                          onTap: () => setState(() => _isUrdu = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: _isUrdu ? primary : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _isUrdu ? primary : border),
                              boxShadow: _isUrdu ? [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))] : [],
                            ),
                            child: Center(child: Text('URDU / ROMAN', style: TextStyle(color: _isUrdu ? Colors.white : textGrey, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.0))),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  const Text('INCIDENT DETAILS', style: TextStyle(fontWeight: FontWeight.w900, color: textDark, fontSize: 11, letterSpacing: 1.0)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: border),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))]
                    ),
                    child: TextField(
                      controller: _controller,
                      maxLines: 6,
                      style: const TextStyle(fontSize: 15, color: textDark, fontWeight: FontWeight.w600, height: 1.5),
                      decoration: InputDecoration(
                        hintText: 'e.g., "Mera bank account se unauthorized transaction hui hai..."',
                        hintStyle: TextStyle(color: textGrey.withOpacity(0.6), fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(24),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  HoverButton(
                    onTap: _isLoading ? null : _generate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [primary, AppTheme.navyLight]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))],
                      ),
                      child: Center(
                        child: _isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.auto_awesome, color: accent, size: 20),
                                SizedBox(width: 8),
                                Text('GENERATE COMPLAINT', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                              ],
                            ),
                      ),
                    ),
                  ),
                  
                  if (_result != null) ...[
                    const SizedBox(height: 40),
                    const Divider(color: border),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('OFFICIAL DRAFT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: primary, letterSpacing: 1.5)),
                        HoverButton(
                          onTap: _copyToClipboard,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                            child: const Row(
                              children: [
                                Icon(Icons.copy_rounded, color: accent, size: 16),
                                SizedBox(width: 8),
                                Text('COPY', style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.0)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: border),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 16, offset: const Offset(0, 8))],
                      ),
                      child: MarkdownBody(
                        data: _result!,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(fontSize: 14, height: 1.6, color: textDark, fontWeight: FontWeight.w500),
                          h1: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: primary, letterSpacing: -0.5),
                          h2: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: primary, letterSpacing: -0.5),
                          strong: const TextStyle(fontWeight: FontWeight.w800, color: textDark),
                        ),
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
