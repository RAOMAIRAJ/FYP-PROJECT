import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:qanoon_buddy/core/theme.dart';
import 'package:qanoon_buddy/core/db_helper.dart';

class CaseTrackerScreen extends StatefulWidget {
  const CaseTrackerScreen({super.key});

  @override
  State<CaseTrackerScreen> createState() => _CaseTrackerScreenState();
}

class _CaseTrackerScreenState extends State<CaseTrackerScreen> {
  List<Map<String, dynamic>> _cases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshCases();
  }

  Future<void> _refreshCases() async {
    setState(() => _isLoading = true);
    final data = await DbHelper.getCases();
    setState(() {
      _cases = data;
      _isLoading = false;
    });
  }

  void _showCaseForm({Map<String, dynamic>? existingCase}) {
    final isEdit = existingCase != null;

    final caseNumberController = TextEditingController(text: existingCase?['case_number'] ?? '');
    final titleController = TextEditingController(text: existingCase?['title'] ?? '');
    final courtController = TextEditingController(text: existingCase?['court_name'] ?? '');
    final judgeController = TextEditingController(text: existingCase?['judge_name'] ?? '');
    final notesController = TextEditingController(text: existingCase?['notes'] ?? '');

    String selectedStatus = existingCase?['status'] ?? 'Active';
    DateTime selectedDate = existingCase?['next_hearing_date'] != null
        ? DateTime.parse(existingCase!['next_hearing_date'])
        : DateTime.now().add(const Duration(days: 7));

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
                      isEdit ? 'Update Case Details' : 'Register New Case',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: AppTheme.navyDeep,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Inputs
                    _buildField(caseNumberController, 'Case / Suit Number', 'e.g. OS-122/2026', Icons.tag),
                    const SizedBox(height: 16),
                    _buildField(titleController, 'Case Title', 'e.g. Rao Ali vs State', Icons.title),
                    const SizedBox(height: 16),
                    _buildField(courtController, 'Court Name', 'e.g. High Court Lahore', Icons.account_balance),
                    const SizedBox(height: 16),
                    _buildField(judgeController, 'Judge Name (Optional)', 'e.g. Hon. Justice Malik', Icons.person),
                    const SizedBox(height: 16),

                    // Date selector
                    const Text(
                      'Next Hearing Date',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.textGrey),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 3650)),
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
                          setModalState(() => selectedDate = picked);
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
                              DateFormat('EEEE, MMMM dd, yyyy').format(selectedDate),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Status Dropdown
                    const Text(
                      'Case Status',
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
                          value: selectedStatus,
                          isExpanded: true,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 14),
                          items: ['Active', 'Decided', 'Adjourned', 'Pending'].map((String s) {
                            return DropdownMenuItem<String>(value: s, child: Text(s));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedStatus = val);
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    _buildField(notesController, 'Internal Case Notes', 'Add personal hearing details, tasks or summaries...', Icons.notes, maxLines: 3),

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
                              if (caseNumberController.text.trim().isEmpty || titleController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please fill out Case Number and Case Title.')),
                                );
                                return;
                              }

                              final row = {
                                'case_number': caseNumberController.text.trim(),
                                'title': titleController.text.trim(),
                                'court_name': courtController.text.trim(),
                                'judge_name': judgeController.text.trim(),
                                'status': selectedStatus,
                                'next_hearing_date': selectedDate.toIso8601String().substring(0, 10),
                                'notes': notesController.text.trim(),
                                'created_at': DateTime.now().toIso8601String(),
                              };

                              if (isEdit) {
                                row['id'] = existingCase['id'];
                                await DbHelper.updateCase(row);
                              } else {
                                await DbHelper.insertCase(row);
                              }

                              _refreshCases();
                              if (context.mounted) Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.navyDeep,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(isEdit ? 'Save Changes' : 'Register Case', style: const TextStyle(fontWeight: FontWeight.w800)),
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

  void _deleteCase(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Delete Case File?', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.navyDeep)),
        content: const Text('This will permanently delete this case tracking file. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textGrey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DbHelper.deleteCase(id);
      _refreshCases();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Case Tracker', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.navyDeep, AppTheme.navyLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => _showCaseForm(),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 26),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.navyDeep))
          : _cases.isEmpty
              ? _buildEmptyState()
              : _buildCaseList(),
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
              child: const Icon(Icons.folder_open_rounded, size: 80, color: AppTheme.goldPremium),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Cases Tracked Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.navyDeep),
            ),
            const SizedBox(height: 8),
            const Text(
              'Register your active litigation matters to maintain custom schedules, track upcoming hearings, and write notes securely offline.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textGrey, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => _showCaseForm(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Your First Case', style: TextStyle(fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    ).animate().fade().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildCaseList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _cases.length,
      itemBuilder: (context, index) {
        final c = _cases[index];
        final status = c['status'] ?? 'Active';

        Color sColor = AppTheme.accepted;
        if (status == 'Decided') sColor = AppTheme.completed;
        if (status == 'Adjourned') sColor = AppTheme.warning;
        if (status == 'Pending') sColor = AppTheme.textGrey;

        final nextHearingStr = c['next_hearing_date'] ?? '';
        String formattedDate = '';
        int daysLeft = 0;
        try {
          final parsedDate = DateTime.parse(nextHearingStr);
          formattedDate = DateFormat('MMM dd, yyyy').format(parsedDate);
          daysLeft = parsedDate.difference(DateTime.now()).inDays + 1;
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
          child: ExpansionTile(
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            shape: const RoundedRectangleBorder(side: BorderSide.none),
            collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c['case_number'] ?? '',
                        style: const TextStyle(
                          color: AppTheme.goldPremium,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        c['title'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: sColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(color: sColor, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_rounded, size: 14, color: AppTheme.textGrey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      c['court_name'] ?? 'General Court',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.textGrey, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(color: AppTheme.border),
                    const SizedBox(height: 12),

                    if (c['judge_name'] != null && c['judge_name'].toString().isNotEmpty) ...[
                      _detailRow(Icons.gavel_rounded, 'Presiding Judge', c['judge_name']),
                      const SizedBox(height: 10),
                    ],

                    _detailRow(
                      Icons.calendar_month_rounded,
                      'Next Hearing',
                      '$formattedDate (${daysLeft <= 0 ? "Today" : "$daysLeft days left"})',
                    ),
                    const SizedBox(height: 12),

                    if (c['notes'] != null && c['notes'].toString().isNotEmpty) ...[
                      const Text(
                        'Hearing Summary / Notes:',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.textDark),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Text(
                          c['notes'],
                          style: const TextStyle(color: AppTheme.textGrey, fontSize: 12, height: 1.4, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _deleteCase(c['id']),
                          icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error, size: 18),
                          label: const Text('Delete', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _showCaseForm(existingCase: c),
                          icon: const Icon(Icons.edit_rounded, size: 14),
                          label: const Text('Edit Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.navyDeep,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ).animate().fade(delay: (index * 50).ms).slideY(begin: 0.05);
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.goldPremium),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.textDark)),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: AppTheme.textGrey))),
      ],
    );
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

