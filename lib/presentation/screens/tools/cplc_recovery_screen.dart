import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qanoon_buddy/data/auth_provider.dart';
import 'package:flutter/services.dart';
import 'package:qanoon_buddy/core/api_service.dart';
import 'package:qanoon_buddy/core/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qanoon_buddy/presentation/widgets/hover_button.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class CplcRecoveryScreen extends ConsumerStatefulWidget {
  const CplcRecoveryScreen({super.key});

  @override
  ConsumerState<CplcRecoveryScreen> createState() => _CplcRecoveryScreenState();
}

class _CplcRecoveryScreenState extends ConsumerState<CplcRecoveryScreen> {
  final _textController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  bool _isListening = false;
  bool _isLoading = false;
  String? _result;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    await _speech.initialize();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => debugPrint('onStatus: $val'),
        onError: (val) => debugPrint('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _textController.text = val.recognizedWords;
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _makeCall(String number) async {
    final Uri url = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch dialer')));
    }
  }

  Future<void> _generateComplaint() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please describe the incident first.')));
      return;
    }
    
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final res = await apiService.generateCplcComplaint(_textController.text, ref.read(authProvider).token ?? '');
      if (mounted) {
        setState(() {
          _result = res['complaint_draft'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
      }
    }
  }

  Future<void> _generatePdf() async {
    if (_result == null) return;
    
    final pdf = pw.Document();
    
    // Load Poppins font via printing package
    final fontRegular = await PdfGoogleFonts.poppinsRegular();
    final fontBold = await PdfGoogleFonts.poppinsBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 2),
            ),
            padding: const pw.EdgeInsets.all(30),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'OFFICIAL COMPLAINT (CPLC & POLICE)',
                    style: pw.TextStyle(font: fontBold, fontSize: 18, decoration: pw.TextDecoration.underline),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Date: ${DateFormat('dd MMMM yyyy').format(DateTime.now())}',
                  style: pw.TextStyle(font: fontRegular, fontSize: 12),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  _result!,
                  style: pw.TextStyle(font: fontRegular, fontSize: 12, lineSpacing: 5),
                ),
                pw.Spacer(),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'Signature / Thumb Impression\n___________________________',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(font: fontRegular, fontSize: 12),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Divider(thickness: 1, color: PdfColors.grey300),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    'Generated securely by Qanoon Buddy App',
                    style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.grey600),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'CPLC_Complaint_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppTheme.error,
            expandedHeight: 140,
            floating: false,
            pinned: true,
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
              title: const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🚨', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 8),
                  Text('JUST GOT ROBBED?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.error.withOpacity(0.8), AppTheme.error],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                   child: Icon(Icons.warning_amber_rounded, color: Colors.white.withOpacity(0.15), size: 100),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('IMMEDIATE ACTIONS', style: TextStyle(color: AppTheme.navyDeep, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  _buildEmergencyCard(Icons.sim_card_alert_rounded, '1. Block SIM', 'Call your telecom operator immediately to prevent misuse.', '111', AppTheme.goldPremium),
                  const SizedBox(height: 16),
                  _buildEmergencyCard(Icons.phonelink_erase_rounded, '2. Block IMEI (PTA)', 'Call PTA toll-free to permanently block the stolen device.', '0800-25625', AppTheme.navyDeep),
                  const SizedBox(height: 16),
                  _buildEmergencyCard(Icons.local_police_rounded, '3. Madadgar 15', 'Report the incident to the police emergency helpline immediately.', '15', AppTheme.error),
                  
                  const SizedBox(height: 40),
                  const Divider(color: AppTheme.border),
                  const SizedBox(height: 32),

                  const Text('AUTO-GENERATE CPLC COMPLAINT', style: TextStyle(color: AppTheme.navyDeep, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 12),
                  const Text(
                    'No need to type. Tap the microphone and speak exactly what happened in Roman Urdu or English.',
                    style: TextStyle(color: AppTheme.textGrey, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),

                  // Input Area
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: _isListening ? AppTheme.error.withOpacity(0.5) : AppTheme.border, width: _isListening ? 2 : 1),
                      boxShadow: [
                        BoxShadow(color: AppTheme.navyDeep.withOpacity(0.05), blurRadius: 24, offset: const Offset(0, 12)),
                        if (_isListening) BoxShadow(color: AppTheme.error.withOpacity(0.15), blurRadius: 24, spreadRadius: 8)
                      ]
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _textController,
                          maxLines: 5,
                          style: const TextStyle(fontSize: 16, color: AppTheme.textDark, fontWeight: FontWeight.w600, height: 1.4),
                          decoration: InputDecoration(
                            hintText: 'e.g., "Mera phone Gulshan mein snatch ho gaya..."',
                            hintStyle: TextStyle(color: AppTheme.textGrey.withOpacity(0.6), fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(24),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                            border: const Border(top: BorderSide(color: AppTheme.border)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: HoverButton(
                                  onTap: _listen,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      color: _isListening ? AppTheme.error : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: _isListening ? AppTheme.error : AppTheme.border),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(_isListening ? Icons.mic : Icons.mic_none_rounded, color: _isListening ? Colors.white : AppTheme.error, size: 20),
                                        const SizedBox(width: 8),
                                        Text(_isListening ? 'LISTENING...' : 'VOICE TYPE', 
                                          style: TextStyle(color: _isListening ? Colors.white : AppTheme.error, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.0)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: HoverButton(
                                  onTap: _isLoading ? null : _generateComplaint,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [AppTheme.navyDeep, AppTheme.navyLight]),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [BoxShadow(color: AppTheme.navyDeep.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                                    ),
                                    child: Center(
                                      child: _isLoading 
                                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : const Text('GENERATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.0)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_result != null) ...[
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.completed.withOpacity(0.3), width: 2),
                        boxShadow: [BoxShadow(color: AppTheme.completed.withOpacity(0.1), blurRadius: 20, spreadRadius: 5)],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: AppTheme.completed.withOpacity(0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.check_circle_rounded, color: AppTheme.completed, size: 48),
                          ),
                          const SizedBox(height: 20),
                          const Text('Complaint Drafted!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.navyDeep, letterSpacing: -0.5)),
                          const SizedBox(height: 8),
                          const Text('Your official application is ready to be printed or shared with the CPLC via WhatsApp.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textGrey, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 24),
                          HoverButton(
                            onTap: _generatePdf,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [AppTheme.navyDeep, AppTheme.navyLight]),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: AppTheme.navyDeep.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text('VIEW & SHARE PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.0)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard(IconData icon, String title, String subtitle, String number, Color color) {
    return HoverButton(
      onTap: () => _makeCall(number),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.08), color.withOpacity(0.01)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: color == AppTheme.navyDeep ? AppTheme.navyDeep : AppTheme.textDark, letterSpacing: -0.3)),
                  const SizedBox(height: 6),
                  Text(subtitle, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12, height: 1.5, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color, 
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
              ),
              child: const Icon(Icons.call_rounded, color: Colors.white, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}
