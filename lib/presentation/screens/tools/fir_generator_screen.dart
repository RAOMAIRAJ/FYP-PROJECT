import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qanoon_buddy/data/auth_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:qanoon_buddy/core/api_service.dart';
import 'package:qanoon_buddy/core/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qanoon_buddy/presentation/widgets/hover_button.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class FirGeneratorScreen extends ConsumerStatefulWidget {
  const FirGeneratorScreen({super.key});

  @override
  ConsumerState<FirGeneratorScreen> createState() => _FirGeneratorScreenState();
}

class _FirGeneratorScreenState extends ConsumerState<FirGeneratorScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  String? _result;

  Future<void> _generate() async {
    if (_controller.text.isEmpty) return;
    
    // Unfocus keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final res = await apiService.generateFir(_controller.text, ref.read(authProvider).token ?? '');
      if (mounted) {
        setState(() {
          _result = res['fir_draft'];
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
          content: Text('FIR Draft copied to clipboard!'),
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

  Future<void> _generatePdf() async {
    if (_result == null) return;
    
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.poppinsRegular();
    final fontBold = await PdfGoogleFonts.poppinsBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 2)),
            padding: const pw.EdgeInsets.all(30),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(child: pw.Text('FIRST INFORMATION REPORT (FIR) DRAFT', style: pw.TextStyle(font: fontBold, fontSize: 16, decoration: pw.TextDecoration.underline))),
                pw.SizedBox(height: 20),
                pw.Text('Date: ${DateFormat('dd MMMM yyyy').format(DateTime.now())}', style: pw.TextStyle(font: fontRegular, fontSize: 12)),
                pw.SizedBox(height: 20),
                pw.Text(_result!, style: pw.TextStyle(font: fontRegular, fontSize: 12, lineSpacing: 5)),
                pw.Spacer(),
                pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('Signature / Thumb Impression\n___________________________', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: fontRegular, fontSize: 12))),
                pw.SizedBox(height: 20),
                pw.Divider(thickness: 1, color: PdfColors.grey300),
                pw.SizedBox(height: 10),
                pw.Center(child: pw.Text('Drafted securely by Qanoon Buddy App', style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.grey600))),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'FIR_Draft_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
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
                    const Text('FIR Draft Generator',
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
              'Provide details about the incident (Who, What, When, Where). Our AI will format it into a formal FIR draft according to Pakistani police standards.',
              style: TextStyle(fontSize: 15, color: textGrey, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 6,
              style: const TextStyle(fontSize: 14, color: textDark),
              decoration: InputDecoration(
                hintText: 'e.g., Yesterday at 5 PM on Main Boulevard, two men on a motorcycle snatched my bag...',
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
              onTap: _isLoading ? null : _generate,
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
                    : const Text('Generate FIR Draft', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_result != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Generated FIR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textDark)),
                  IconButton(
                    icon: const Icon(Icons.copy_all, color: accent),
                    onPressed: _copyToClipboard,
                    tooltip: 'Copy all text',
                  )
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: MarkdownBody(
                  data: _result!,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(fontSize: 14, height: 1.6, color: textDark),
                    h1: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primary),
                    h2: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: primary),
                    strong: const TextStyle(fontWeight: FontWeight.bold, color: textDark),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _generatePdf,
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                  label: const Text('GENERATE OFFICIAL PDF', style: TextStyle(fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.navyDeep,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
