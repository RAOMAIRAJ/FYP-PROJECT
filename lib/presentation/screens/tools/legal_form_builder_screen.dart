import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qanoon_buddy/data/auth_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:qanoon_buddy/core/theme.dart';
import 'package:qanoon_buddy/core/api_service.dart';

class LegalFormBuilderScreen extends ConsumerStatefulWidget {
  const LegalFormBuilderScreen({super.key});

  @override
  ConsumerState<LegalFormBuilderScreen> createState() => _LegalFormBuilderScreenState();
}

class _LegalFormBuilderScreenState extends ConsumerState<LegalFormBuilderScreen> {
  String _selectedTemplate = 'affidavit'; // 'affidavit' or 'rent'
  int _currentStep = 0;

  final _magicPromptController = TextEditingController();
  bool _isExtracting = false;

  // Affidavit Form Data
  final _affDeclarantName = TextEditingController();
  final _affDeclarantFather = TextEditingController();
  final _affDeclarantCnic = TextEditingController();
  final _affDeclarantAddress = TextEditingController();
  final _affStatement = TextEditingController();

  // Rent Agreement Form Data
  final _rentLandlordName = TextEditingController();
  final _rentLandlordCnic = TextEditingController();
  final _rentTenantName = TextEditingController();
  final _rentTenantCnic = TextEditingController();
  final _rentPropAddress = TextEditingController();
  final _rentAmount = TextEditingController();
  final _rentDeposit = TextEditingController();

  bool _isGenerating = false;

  @override
  void dispose() {
    _magicPromptController.dispose();
    _affDeclarantName.dispose();
    _affDeclarantFather.dispose();
    _affDeclarantCnic.dispose();
    _affDeclarantAddress.dispose();
    _affStatement.dispose();
    _rentLandlordName.dispose();
    _rentLandlordCnic.dispose();
    _rentTenantName.dispose();
    _rentTenantCnic.dispose();
    _rentPropAddress.dispose();
    _rentAmount.dispose();
    _rentDeposit.dispose();
    super.dispose();
  }

  Future<void> _generatePDFAndShare() async {
    setState(() => _isGenerating = true);

    try {
      final pdf = pw.Document();
      
      final fontRegular = await PdfGoogleFonts.poppinsRegular();
      final fontBold = await PdfGoogleFonts.poppinsBold();
      
      final pageTheme = pw.PageTheme(
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        buildBackground: (pw.Context context) {
          return pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(
              margin: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey600, width: 2)),
              child: pw.Container(
                margin: const pw.EdgeInsets.all(4),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey600, width: 0.5)),
                child: pw.Center(
                  child: pw.Transform.rotate(
                    angle: -0.6,
                    child: pw.Text(
                      'QANOON BUDDY LEGAL DRAFT',
                      style: pw.TextStyle(color: PdfColors.grey200, fontSize: 40, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );

      if (_selectedTemplate == 'affidavit') {
        pdf.addPage(
          pw.Page(
            pageTheme: pageTheme,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(
                    child: pw.Text(
                      'SOLE STATUTORY DECLARATION / AFFIDAVIT',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Center(child: pw.Container(height: 2, width: 200, color: PdfColors.indigo900)),
                  pw.SizedBox(height: 40),
                  pw.Text('I, the undersigned declarant, do hereby solemnly declare and state on oath as under:', style: const pw.TextStyle(fontSize: 12)),
                  pw.SizedBox(height: 20),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey400),
                    children: [
                      _pdfTableRow('Declarant Name', _affDeclarantName.text),
                      _pdfTableRow('Father Name', _affDeclarantFather.text),
                      _pdfTableRow('CNIC Number', _affDeclarantCnic.text),
                      _pdfTableRow('Resident Address', _affDeclarantAddress.text),
                    ],
                  ),
                  pw.SizedBox(height: 24),
                  pw.Text('SOLEMN STATEMENTS:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey500), color: PdfColors.grey50),
                    child: pw.Text(
                      _affStatement.text.isNotEmpty ? _affStatement.text : 'That all statements declared herein are completely true, correct and valid under Pakistani statutes.',
                      style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5),
                    ),
                  ),
                  pw.SizedBox(height: 40),
                  pw.Text('VERIFICATION ON OATH:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Verified at the place mentioned below, that the contents of this statutory affidavit are true and correct to the best of my knowledge and belief, and nothing has been concealed or misrepresented.',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700, lineSpacing: 1.3),
                  ),
                  pw.Spacer(),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Date: ____________________'),
                          pw.SizedBox(height: 12),
                          pw.Text('Place: ___________________'),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Container(width: 150, height: 1, color: PdfColors.black),
                          pw.SizedBox(height: 4),
                          pw.Text('Signature / Thumb Impression', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          pw.Text('(Deponent / Declarant)', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      } else {
        // Rent Agreement Template
        pdf.addPage(
          pw.Page(
            pageTheme: pageTheme,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(
                    child: pw.Text(
                      'RESIDENTIAL TENANCY / RENT AGREEMENT',
                      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Center(child: pw.Container(height: 2, width: 220, color: PdfColors.indigo900)),
                  pw.SizedBox(height: 40),
                  pw.Text('This Tenancy Agreement is entered into by and between the Landlord and the Tenant, details as under:', style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.3)),
                  pw.SizedBox(height: 20),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey400),
                    children: [
                      _pdfTableRow('Landlord Name', _rentLandlordName.text),
                      _pdfTableRow('Landlord CNIC', _rentLandlordCnic.text),
                      _pdfTableRow('Tenant Name', _rentTenantName.text),
                      _pdfTableRow('Tenant CNIC', _rentTenantCnic.text),
                      _pdfTableRow('Property Location', _rentPropAddress.text),
                      _pdfTableRow('Monthly Rent Amount', 'PKR ${_rentAmount.text}'),
                      _pdfTableRow('Security Deposit Paid', 'PKR ${_rentDeposit.text}'),
                    ],
                  ),
                  pw.SizedBox(height: 24),
                  pw.Text('STANDARD TERMS & COVENANTS:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 12),
                  pw.Bullet(text: 'The Tenant agrees to pay the agreed monthly rent by or before the 10th of every month.'),
                  pw.SizedBox(height: 6),
                  pw.Bullet(text: 'The Tenant shall use the premises strictly for residential purposes and shall not sublet it.'),
                  pw.SizedBox(height: 6),
                  pw.Bullet(text: 'The Tenant will be responsible for standard utilities, including electricity, water and gas bills.'),
                  pw.SizedBox(height: 6),
                  pw.Bullet(text: 'Either party must give 1-month written notice prior to terminating this lease agreement.'),
                  pw.SizedBox(height: 6),
                  pw.Bullet(text: 'Upon termination, the Landlord shall refund the security deposit in full, subject to clearing dues.'),
                  pw.Spacer(),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        children: [
                          pw.Container(width: 140, height: 1, color: PdfColors.black),
                          pw.SizedBox(height: 4),
                          pw.Text('Signature of Landlord', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Container(width: 140, height: 1, color: PdfColors.black),
                          pw.SizedBox(height: 4),
                          pw.Text('Signature of Tenant', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 30),
                  pw.Text('WITNESSES:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.SizedBox(height: 16),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('1. _______________________', style: const pw.TextStyle(fontSize: 10)),
                          pw.SizedBox(height: 4),
                          pw.Text('   Name & CNIC', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('2. _______________________', style: const pw.TextStyle(fontSize: 10)),
                          pw.SizedBox(height: 4),
                          pw.Text('   Name & CNIC', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      }

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/${_selectedTemplate}_document.pdf');
      await file.writeAsBytes(await pdf.save());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document generated successfully at ${file.path.split("/").last}')),
        );
      }

      // Share via share_plus
      final xFile = XFile(file.path);
      await Share.shareXFiles([xFile], text: 'Generated Legal Document from Qanoon Buddy');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e')),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  pw.TableRow _pdfTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(value.isNotEmpty ? value : 'N/A', style: const pw.TextStyle(fontSize: 10)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Legal Form Builder', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.navyDeep, AppTheme.navyLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepTapped: (step) => setState(() => _currentStep = step),
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() => _currentStep += 1);
          } else {
            _generatePDFAndShare();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          }
        },
        controlsBuilder: (context, details) {
          if (_currentStep == 1) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 28.0),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: details.onStepCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.navyDeep,
                        side: const BorderSide(color: AppTheme.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Previous', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.navyDeep,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isGenerating
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_currentStep == 2 ? 'Generate & Share' : 'Continue', style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          );
        },
        steps: [
          Step(
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.editing,
            title: const Text('Template', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Legal Document Template',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.navyDeep),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose a template to build. We will gather required info and render a verified draft PDF instantly.',
                  style: TextStyle(color: AppTheme.textGrey, fontSize: 12, height: 1.4, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),
                _templateCard(
                  code: 'affidavit',
                  title: 'Solemn Affidavit (General Statement)',
                  desc: 'Legal declaration under oath regarding facts, identity, or assertions.',
                  icon: Icons.gavel_rounded,
                ),
                const SizedBox(height: 16),
                _templateCard(
                  code: 'rent',
                  title: 'Residential Rent Agreement',
                  desc: 'Standard lease terms, tenant covenants, deposit details, and landlord obligations.',
                  icon: Icons.home_work_rounded,
                ),
              ],
            ),
          ),
          Step(
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : (_currentStep == 1 ? StepState.editing : StepState.indexed),
            title: const Text('Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            content: _buildMagicInputForm(),
          ),
          Step(
            isActive: _currentStep >= 2,
            state: _currentStep == 2 ? StepState.editing : StepState.indexed,
            title: const Text('Export', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            content: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.navyDeep.withOpacity(0.04),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, size: 72, color: AppTheme.goldPremium),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Document Ready for Generation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.navyDeep),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Verify all entered inputs. Once satisfied, click the button below to generate a professionally typeset, print-ready PDF and share it with your lawyer or printer.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textGrey, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _templateCard({required String code, required String title, required String desc, required IconData icon}) {
    final active = _selectedTemplate == code;
    return InkWell(
      onTap: () => setState(() => _selectedTemplate = code),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: active ? AppTheme.navyDeep.withOpacity(0.02) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppTheme.goldPremium : AppTheme.border, width: active ? 1.5 : 1.0),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: active ? AppTheme.goldPremium.withOpacity(0.12) : AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: active ? AppTheme.goldPremium : AppTheme.textGrey, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: const TextStyle(color: AppTheme.textGrey, fontSize: 11, height: 1.3, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            if (active)
              const Icon(Icons.check_circle_rounded, color: AppTheme.goldPremium)
            else
              const Icon(Icons.circle_outlined, color: AppTheme.border),
          ],
        ),
      ),
    );
  }

  Future<void> _extractWithAI() async {
    if (_magicPromptController.text.trim().isEmpty) return;
    
    setState(() => _isExtracting = true);
    try {
      final api = ApiService();
      final data = await api.generateMagicForm(token: ref.read(authProvider).token ?? '', 
        templateType: _selectedTemplate,
        description: _magicPromptController.text,
      );
      
      if (_selectedTemplate == 'rent') {
        _rentLandlordName.text = data['landlord_name'] ?? '';
        _rentLandlordCnic.text = data['landlord_cnic'] ?? '';
        _rentTenantName.text = data['tenant_name'] ?? '';
        _rentTenantCnic.text = data['tenant_cnic'] ?? '';
        _rentPropAddress.text = data['property_address'] ?? '';
        _rentAmount.text = data['monthly_rent'] ?? '';
        _rentDeposit.text = data['security_deposit'] ?? '';
      } else {
        _affDeclarantName.text = data['declarant_name'] ?? '';
        _affDeclarantFather.text = data['declarant_father'] ?? '';
        _affDeclarantCnic.text = data['declarant_cnic'] ?? '';
        _affDeclarantAddress.text = data['declarant_address'] ?? '';
        _affStatement.text = data['statement'] ?? '';
      }
      
      setState(() => _currentStep = 2);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI Extraction failed: $e')));
      }
    } finally {
      setState(() => _isExtracting = false);
    }
  }

  Widget _buildMagicInputForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI Magic Generator ✨',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.navyDeep),
        ),
        const SizedBox(height: 8),
        const Text(
          'Describe your agreement in plain English or Roman Urdu. Our AI will instantly extract the entities and structure the document for you.',
          style: TextStyle(color: AppTheme.textGrey, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _magicPromptController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: _selectedTemplate == 'rent' 
                ? "e.g. 'I am renting my DHA house to Ali Khan for 45k a month. My name is Umer Lodhi.'"
                : "e.g. 'I, Umer Lodhi, solemnly declare that I have lost my original Matric certificate.'",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.goldPremium)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isExtracting ? null : _extractWithAI,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.goldPremium,
              foregroundColor: AppTheme.navyDeep,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: _isExtracting ? const SizedBox.shrink() : const Icon(Icons.auto_awesome),
            label: _isExtracting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.navyDeep))
                : const Text('Generate with AI', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ),
      ],
    ).animate().fade().slideY(begin: 0.1);
  }

  Widget _buildAffidavitForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Declarant Information',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.navyDeep),
        ),
        const SizedBox(height: 16),
        _buildField(_affDeclarantName, 'Declarant Full Name', 'e.g. Rao Muhammad Mairaj', Icons.person),
        const SizedBox(height: 14),
        _buildField(_affDeclarantFather, 'Father\'s Name', 'e.g. Rao Muhammad Ali', Icons.people),
        const SizedBox(height: 14),
        _buildField(_affDeclarantCnic, 'CNIC Number', 'e.g. 35201-1234567-9', Icons.badge_rounded),
        const SizedBox(height: 14),
        _buildField(_affDeclarantAddress, 'Residential Address', 'e.g. Model Town, Lahore', Icons.home_rounded),
        const SizedBox(height: 20),
        const Text(
          'Affidavit Statement',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.navyDeep),
        ),
        const SizedBox(height: 14),
        _buildField(_affStatement, 'Oath / Facts Statement', 'Type the key assertions, facts or statements being verified under oath...', Icons.notes, maxLines: 4),
      ],
    ).animate().fade();
  }

  Widget _buildRentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Landlord Details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.navyDeep),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildField(_rentLandlordName, 'Full Name', 'e.g. Umer Lodhi', Icons.person)),
            const SizedBox(width: 12),
            Expanded(child: _buildField(_rentLandlordCnic, 'CNIC No', '35201-0000000-0', Icons.badge)),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Tenant Details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.navyDeep),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildField(_rentTenantName, 'Full Name', 'e.g. Ali Khan', Icons.person_outline)),
            const SizedBox(width: 12),
            Expanded(child: _buildField(_rentTenantCnic, 'CNIC No', '35201-1111111-1', Icons.badge_outlined)),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Property & Financials',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.navyDeep),
        ),
        const SizedBox(height: 16),
        _buildField(_rentPropAddress, 'Leased Property Address', 'e.g. Suite 4, Block H-3, Johar Town, Lahore', Icons.location_city_rounded),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildField(_rentAmount, 'Monthly Rent (PKR)', 'e.g. 45000', Icons.payments)),
            const SizedBox(width: 12),
            Expanded(child: _buildField(_rentDeposit, 'Security Deposit (PKR)', 'e.g. 90000', Icons.wallet)),
          ],
        ),
      ],
    ).animate().fade();
  }

  Widget _buildField(TextEditingController controller, String label, String hint, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.textGrey),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppTheme.textGrey.withOpacity(0.5)),
            prefixIcon: Icon(icon, color: AppTheme.goldPremium, size: 20),
            filled: true,
            fillColor: AppTheme.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
