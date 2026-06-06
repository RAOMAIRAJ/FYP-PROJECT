import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:qanoon_buddy/core/theme.dart';
import 'package:qanoon_buddy/core/db_helper.dart';

class DigitalLegalWalletScreen extends StatefulWidget {
  const DigitalLegalWalletScreen({super.key});

  @override
  State<DigitalLegalWalletScreen> createState() => _DigitalLegalWalletScreenState();
}

class _DigitalLegalWalletScreenState extends State<DigitalLegalWalletScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _docs = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // Standard Mock templates for download center
  final List<Map<String, String>> _mockDownloads = [
    {
      'title': 'Residential Lease Agreement Draft.pdf',
      'type': 'Rent Agreement',
      'date': 'May 15, 2026',
      'size': '145 KB'
    },
    {
      'title': 'General Power of Attorney (POA).pdf',
      'type': 'Power of Attorney',
      'date': 'May 12, 2026',
      'size': '192 KB'
    },
    {
      'title': 'Stolen Bike FIR Complaint Draft.pdf',
      'type': 'FIR Draft',
      'date': 'May 10, 2026',
      'size': '88 KB'
    },
    {
      'title': 'Formal Legal Notice to Tenant.pdf',
      'type': 'Legal Notice',
      'date': 'May 08, 2026',
      'size': '112 KB'
    }
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshDocs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshDocs() async {
    setState(() => _isLoading = true);
    final data = await DbHelper.getWalletDocs();
    setState(() {
      _docs = data;
      _isLoading = false;
    });
  }

  void _showAddDocModal({Map<String, dynamic>? existingDoc}) {
    final isEdit = existingDoc != null;
    final titleController = TextEditingController(text: existingDoc?['title'] ?? '');
    final docNumberController = TextEditingController(text: existingDoc?['doc_number'] ?? '');
    final notesController = TextEditingController(text: existingDoc?['notes'] ?? '');

    String selectedType = existingDoc?['type'] ?? 'CNIC';
    DateTime selectedExpiry = existingDoc?['expiry_date'] != null
        ? DateTime.parse(existingDoc!['expiry_date'])
        : DateTime.now().add(const Duration(days: 365));

    final docTypes = [
      'CNIC',
      'Driving License',
      'Vehicle papers',
      'Passport',
      'Property Deed',
      'Affidavit',
      'Contract'
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppTheme.border,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isEdit ? 'Edit Document Parameters' : 'Secure New Document',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: AppTheme.navyDeep,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Dropdown for type
                    const Text(
                      'Document Category',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.textGrey),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedType,
                          isExpanded: true,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 14),
                          items: docTypes.map((String t) {
                            return DropdownMenuItem<String>(value: t, child: Text(t));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedType = val);
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    _buildField(titleController, 'Friendly Title / Alias', 'e.g. My Primary CNIC, Personal Passport', Icons.title),
                    const SizedBox(height: 16),
                    _buildField(docNumberController, 'Document / License Number', 'e.g. 35201-XXXXXXX-X', Icons.badge_outlined),
                    const SizedBox(height: 16),

                    // Expiry selector
                    const Text(
                      'Expiration / Renewal Date',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.textGrey),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedExpiry,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 7300)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppTheme.navyDeep,
                                  onPrimary: Colors.white,
                                  onSurface: AppTheme.textDark,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setModalState(() => selectedExpiry = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, color: AppTheme.goldPremium),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('EEEE, MMMM dd, yyyy').format(selectedExpiry),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    _buildField(notesController, 'Secret Notes / Key Info (Optional)', 'Any additional details...', Icons.notes, maxLines: 2),

                    const SizedBox(height: 28),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.navyDeep,
                              side: const BorderSide(color: AppTheme.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (titleController.text.trim().isEmpty || docNumberController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please fill out Alias and Document Number.')),
                                );
                                return;
                              }

                              final row = {
                                'title': titleController.text.trim(),
                                'type': selectedType,
                                'doc_number': docNumberController.text.trim(),
                                'expiry_date': selectedExpiry.toIso8601String().substring(0, 10),
                                'notes': notesController.text.trim(),
                                'file_path_mock': 'mock_doc_file_${selectedType.toLowerCase().replaceAll(' ', '_')}.pdf',
                                'created_at': DateTime.now().toIso8601String(),
                              };

                              if (isEdit) {
                                row['id'] = existingDoc['id'];
                                await DbHelper.updateWalletDoc(row);
                              } else {
                                await DbHelper.insertWalletDoc(row);
                              }

                              _refreshDocs();
                              if (context.mounted) Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.navyDeep,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(isEdit ? 'Save Changes' : 'Secure Document', style: const TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _deleteDoc(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Remove Document File?', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.navyDeep)),
        content: const Text('This will permanently delete this document parameters from your offline wallet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textGrey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Remove', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DbHelper.deleteWalletDoc(id);
      _refreshDocs();
    }
  }

  void _showQrDialog(Map<String, dynamic> doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.navyDeep,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'SECURE QR SHARING',
              style: TextStyle(color: AppTheme.goldPremium, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
            const SizedBox(height: 8),
            Text(
              doc['title'] ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              'No: ${doc['doc_number']}',
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // High Tech Mock QR Design
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: CustomPaint(
                size: const Size(200, 200),
                painter: QrPainter(),
              ),
            ),

            const SizedBox(height: 24),
            Text(
              'Let authorities or lawyers scan this QR code to securely parse your offline document parameters.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, height: 1.5, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldPremium,
                foregroundColor: AppTheme.navyDeep,
                minimumSize: const Size(140, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Digital Legal Wallet', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.navyDeep, AppTheme.navyLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.goldPremium,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          indicatorColor: AppTheme.goldPremium,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'My Wallet'),
            Tab(text: 'Downloads'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWalletTab(),
          _buildDownloadsTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showAddDocModal(),
              backgroundColor: AppTheme.navyDeep,
              foregroundColor: AppTheme.goldPremium,
              icon: const Icon(Icons.add_moderator_rounded),
              label: const Text('Add Document', style: TextStyle(fontWeight: FontWeight.w800)),
            )
          : null,
    );
  }

  Widget _buildWalletTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.navyDeep));
    }

    final filteredDocs = _docs.where((doc) {
      final t = (doc['title'] ?? '').toLowerCase();
      final n = (doc['doc_number'] ?? '').toLowerCase();
      final cat = (doc['type'] ?? '').toLowerCase();
      return t.contains(_searchQuery.toLowerCase()) ||
          n.contains(_searchQuery.toLowerCase()) ||
          cat.contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        // Search & Reminder summary banner
        _buildWalletHeaderBanner(),

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'Search stored legal credentials...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.goldPremium),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
            ),
          ),
        ),

        Expanded(
          child: filteredDocs.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final expiryDateStr = doc['expiry_date'] ?? '';
                    int daysLeft = 0;
                    String statusText = 'Valid';
                    Color indicatorColor = AppTheme.accepted;

                    try {
                      final expiry = DateTime.parse(expiryDateStr);
                      daysLeft = expiry.difference(DateTime.now()).inDays + 1;
                      if (daysLeft < 0) {
                        statusText = 'EXPIRED';
                        indicatorColor = AppTheme.error;
                      } else if (daysLeft <= 30) {
                        statusText = 'EXPIRING SOON';
                        indicatorColor = AppTheme.warning;
                      }
                    } catch (_) {}

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppTheme.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.01),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: indicatorColor.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getDocIcon(doc['type'] ?? ''),
                                color: indicatorColor,
                                size: 24,
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    doc['title'] ?? '',
                                    style: const TextStyle(
                                      color: AppTheme.textDark,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: indicatorColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      color: indicatorColor,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${doc['type']} • No: ${doc['doc_number']}',
                                    style: const TextStyle(color: AppTheme.textGrey, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.timer_outlined, size: 14, color: AppTheme.textGrey),
                                      const SizedBox(width: 4),
                                      Text(
                                        daysLeft < 0
                                            ? 'Expired ${daysLeft.abs()} days ago'
                                            : 'Expires in $daysLeft days (${DateFormat('MMM dd, yyyy').format(DateTime.parse(expiryDateStr))})',
                                        style: TextStyle(
                                          color: daysLeft <= 30 ? AppTheme.warning : AppTheme.textGrey,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (doc['notes'] != null && doc['notes'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  doc['notes'],
                                  style: const TextStyle(color: AppTheme.textGrey, fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),

                          // Actions
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                IconButton(
                                  onPressed: () => _showQrDialog(doc),
                                  icon: const Icon(Icons.qr_code_2_rounded, color: AppTheme.goldPremium),
                                  tooltip: 'Share QR Code',
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    Share.share(
                                      'Qanoon Buddy Secure Share:\n\n'
                                      'Document Type: ${doc['type']}\n'
                                      'Title: ${doc['title']}\n'
                                      'Number: ${doc['doc_number']}\n'
                                      'Expiry Date: ${doc['expiry_date']}\n'
                                      'Notes: ${doc['notes'] ?? 'None'}',
                                    );
                                  },
                                  icon: const Icon(Icons.share_rounded, size: 16, color: AppTheme.navyDeep),
                                  label: const Text('Share Params', style: TextStyle(color: AppTheme.navyDeep, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                                TextButton.icon(
                                  onPressed: () => _showAddDocModal(existingDoc: doc),
                                  icon: const Icon(Icons.edit_rounded, size: 16, color: AppTheme.textGrey),
                                  label: const Text('Edit', style: TextStyle(color: AppTheme.textGrey, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                                IconButton(
                                  onPressed: () => _deleteDoc(doc['id']),
                                  icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
                                  tooltip: 'Delete',
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ).animate().fade(delay: (index * 40).ms).slideY(begin: 0.05);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildWalletHeaderBanner() {
    int expiredCount = 0;
    int urgentCount = 0;

    for (var doc in _docs) {
      try {
        final expiry = DateTime.parse(doc['expiry_date']);
        final days = expiry.difference(DateTime.now()).inDays + 1;
        if (days < 0) {
          expiredCount++;
        } else if (days <= 30) {
          urgentCount++;
        }
      } catch (_) {}
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.navyDeep,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_rounded, color: AppTheme.goldPremium, size: 28),
              const SizedBox(width: 10),
              const Text(
                'OFFLINE LEGAL COMPANION',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Keep your sensitive CNIC, License, Passports, and Contracts details encrypted safely in your device storage with real-time expiration warnings.',
            style: TextStyle(color: AppTheme.border, fontSize: 12, height: 1.5, fontWeight: FontWeight.w500),
          ),
          if (expiredCount > 0 || urgentCount > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.goldPremium.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppTheme.goldPremium, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You have ${expiredCount > 0 ? "$expiredCount EXPIRED" : ""} ${expiredCount > 0 && urgentCount > 0 ? "and " : ""}${urgentCount > 0 ? "$urgentCount upcoming expiration" : ""} files requiring renewal attention.',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _downloadDocument(BuildContext context, Map<String, String> item) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: AppTheme.goldPremium, strokeWidth: 2.5),
              ),
              SizedBox(width: 16),
              Text('Assembling verified PDF draft... Please wait.', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          duration: Duration(milliseconds: 1000),
          backgroundColor: AppTheme.navyDeep,
        ),
      );

      final pdfDoc = pw.Document();
      pdfDoc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context pContext) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(32),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('QANOON BUDDY', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0A1128'))),
                          pw.Text('Your Premium Legal Companion', style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('#64748B'))),
                        ],
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#FBF7E7'),
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Text('CERTIFIED DRAFT', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#D4AF37'))),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Divider(thickness: 1.5, color: PdfColor.fromHex('#E2E8F0')),
                  pw.SizedBox(height: 24),
                  pw.Text(item['title'] ?? 'Legal Document', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F172A'))),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    children: [
                      pw.Text('Category: ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#64748B'))),
                      pw.Text(item['type'] ?? '', style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#0F172A'))),
                      pw.Text('  •  Created: ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#64748B'))),
                      pw.Text(item['date'] ?? '', style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#0F172A'))),
                      pw.Text('  •  Size: ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#64748B'))),
                      pw.Text(item['size'] ?? '', style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#0F172A'))),
                    ],
                  ),
                  pw.SizedBox(height: 32),
                  pw.Text('OFFICIAL LEGAL MEMORANDUM & CLAUSES', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0A1128'))),
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'This document constitutes a certified legal draft generated automatically through Qanoon Buddy\'s proprietary smart engines. '
                    'It is compiled in accordance with standard civil guidelines of Sindh & Pakistani jurisprudence.\n\n'
                    'WHEREAS the parties hereby acknowledge that they have read and fully understood all conditions, terms, and agreements '
                    'presented in the main consultation body and agree to the following sections:\n\n'
                    '1. MANDATORY REGISTRATION:\n'
                    'This draft is ready for presentation to an authorized Oath Commissioner, Notary Public, or Sub-Registrar within the Sindh jurisdiction.\n\n'
                    '2. WITNESS ATTESTATION:\n'
                    'All signatures, passport details, and thumbprints must be affixed in the presence of two separate, non-related adult witnesses '
                    'as required by the Registration Act of Pakistan.\n\n'
                    '3. LEGAL COMPLIANCE:\n'
                    'Both parties warrant that all declarations, claims, and background details entered into this document builder are accurate, '
                    'true, and legally binding under penalty of perjury.',
                    style: pw.TextStyle(fontSize: 10, height: 1.6, color: PdfColor.fromHex('#334155')),
                  ),
                  pw.Spacer(),
                  pw.Divider(thickness: 1, color: PdfColor.fromHex('#E2E8F0')),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Generated via Qanoon Buddy Verified Draft Portal', style: pw.TextStyle(fontSize: 7, color: PdfColor.fromHex('#94A3B8'))),
                      pw.Text('Page 1 of 1', style: pw.TextStyle(fontSize: 7, color: PdfColor.fromHex('#94A3B8'))),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );

      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          downloadsDir = await getExternalStorageDirectory();
        }
      } else {
        downloadsDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      }

      final filePath = '${downloadsDir!.path}/${item['title']}';
      final file = File(filePath);
      await file.writeAsBytes(await pdfDoc.save());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to Downloads: ${item['title']}'),
            backgroundColor: AppTheme.completed,
            action: SnackBarAction(
              label: 'SHARE',
              textColor: Colors.white,
              onPressed: () {
                Share.shareXFiles([XFile(filePath)], text: 'Here is your certified Qanoon Buddy legal draft: ${item['title']}');
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating document: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Widget _buildDownloadsTab() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          color: AppTheme.navyDeep,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🏛️ UNIFIED DOWNLOAD CENTER',
                style: TextStyle(color: AppTheme.goldPremium, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
              ),
              SizedBox(height: 8),
              Text(
                'Access every legal document draft, application, or complaint generated within Qanoon Buddy. Keep them archived for immediate printing or sharing.',
                style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _mockDownloads.length,
            itemBuilder: (context, index) {
              final item = _mockDownloads[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.navyDeep.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 28),
                  ),
                  title: Text(
                    item['title'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textDark, fontSize: 14),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      '${item['type']} • Created: ${item['date']} • Size: ${item['size']}',
                      style: const TextStyle(color: AppTheme.textGrey, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          Share.share('Qanoon Buddy Document Draft: ${item['title']}');
                        },
                        icon: const Icon(Icons.share_rounded, color: AppTheme.navyDeep, size: 20),
                        tooltip: 'Share',
                      ),
                      IconButton(
                        onPressed: () => _downloadDocument(context, item),
                        icon: const Icon(Icons.download_for_offline_rounded, color: AppTheme.goldPremium, size: 22),
                        tooltip: 'Download',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getDocIcon(String type) {
    switch (type) {
      case 'CNIC':
        return Icons.contact_mail_rounded;
      case 'Driving License':
        return Icons.time_to_leave_rounded;
      case 'Vehicle papers':
        return Icons.receipt_long_rounded;
      case 'Passport':
        return Icons.flight_takeoff_rounded;
      case 'Property Deed':
        return Icons.villa_rounded;
      case 'Affidavit':
        return Icons.edit_note_rounded;
      default:
        return Icons.description_rounded;
    }
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.navyDeep.withOpacity(0.04),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wallet_rounded, size: 70, color: AppTheme.goldPremium),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Stored Credentials',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.navyDeep),
            ),
            const SizedBox(height: 8),
            const Text(
              'Safeguard essential documents offline and get notified about renewals (CNIC, driving license, passport, property agreements).',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textGrey, fontSize: 12, height: 1.5, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// Beautiful Pixelated High-Tech Custom QR Painter
class QrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.navyDeep
      ..style = PaintingStyle.fill;

    final double block = size.width / 15;

    // Corner 1
    canvas.drawRect(Rect.fromLTWH(0, 0, block * 4, block * 4), paint);
    canvas.drawRect(Rect.fromLTWH(block, block, block * 2, block * 2), Paint()..color = Colors.white);

    // Corner 2
    canvas.drawRect(Rect.fromLTWH(size.width - block * 4, 0, block * 4, block * 4), paint);
    canvas.drawRect(Rect.fromLTWH(size.width - block * 3, block, block * 2, block * 2), Paint()..color = Colors.white);

    // Corner 3
    canvas.drawRect(Rect.fromLTWH(0, size.height - block * 4, block * 4, block * 4), paint);
    canvas.drawRect(Rect.fromLTWH(block, size.height - block * 3, block * 2, block * 2), Paint()..color = Colors.white);

    // Dynamic High Tech Pixelated Inner Blocks
    final double halfX = size.width / 2;
    final double halfY = size.height / 2;
    canvas.drawRect(Rect.fromLTWH(halfX - block, halfY - block, block * 2, block * 2), paint);
    canvas.drawRect(Rect.fromLTWH(halfX + block * 2, halfY - block * 3, block, block * 2), paint);
    canvas.drawRect(Rect.fromLTWH(halfX - block * 3, halfY + block * 2, block * 2, block), paint);
    canvas.drawRect(Rect.fromLTWH(block * 5, block * 5, block * 2, block * 2), paint);
    canvas.drawRect(Rect.fromLTWH(size.width - block * 6, size.height - block * 6, block * 2, block * 2), paint);
    canvas.drawRect(Rect.fromLTWH(block * 6, size.height - block * 8, block, block * 3), paint);
    canvas.drawRect(Rect.fromLTWH(size.width - block * 8, block * 6, block * 3, block), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
