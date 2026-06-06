import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qanoon_buddy/data/auth_provider.dart';
import 'package:qanoon_buddy/presentation/screens/consultations_screen.dart';
import 'package:qanoon_buddy/presentation/screens/admin_screen.dart';
import 'package:qanoon_buddy/presentation/screens/lawyer_dashboard_screen.dart';
import 'package:qanoon_buddy/presentation/screens/notifications_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qanoon_buddy/presentation/widgets/hover_button.dart';
import 'package:qanoon_buddy/core/theme.dart';
import 'package:qanoon_buddy/core/db_helper.dart';
import 'package:qanoon_buddy/core/api_service.dart';
import 'package:qanoon_buddy/presentation/screens/support/my_tickets_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const Color primary  = AppTheme.navyDeep;
  static const Color accent   = AppTheme.goldPremium;
  static const Color bg       = AppTheme.surface;
  static const Color textDark = AppTheme.textDark;
  static const Color textGrey = AppTheme.textGrey;
  static const Color border   = AppTheme.border;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    final name  = user?['full_name'] ?? 'User';
    final email = user?['email']     ?? '';
    final city  = user?['city']      ?? 'Not set';
    final role  = user?['role']      ?? 'user';

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          // ── Elite Profile Header ──
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary, AppTheme.navyLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -100,
                    left: -100,
                    child: Container(
                      width: 300, height: 300,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withOpacity(0.05)),
                    ),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _topBtn(Icons.chevron_left_rounded, () => Navigator.pop(context)),
                              const Spacer(),
                              const Text('PERSONAL VAULT', 
                                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2)),
                              const Spacer(),
                              _topBtn(Icons.edit_note_rounded, () {}),
                            ],
                          ),
                          const SizedBox(height: 40),
                          Container(
                            width: 110, height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(colors: [accent, AppTheme.goldMuted]),
                              boxShadow: [BoxShadow(color: accent.withOpacity(0.3), blurRadius: 20, spreadRadius: 5)],
                            ),
                            padding: const EdgeInsets.all(3),
                            child: Container(
                              decoration: const BoxDecoration(color: AppTheme.navyDeep, shape: BoxShape.circle),
                              child: Center(
                                child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', 
                                  style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900)),
                              ),
                            ),
                          ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                          const SizedBox(height: 24),
                          Text(name, 
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                          const SizedBox(height: 6),
                          Text(email.toUpperCase(), 
                            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.1), 
                              borderRadius: BorderRadius.circular(30), 
                              border: Border.all(color: accent.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(role == 'lawyer' ? Icons.verified_user_rounded : Icons.person_rounded, color: accent, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  role == 'lawyer' ? 'VERIFIED COUNSEL' : role == 'admin' ? 'SYSTEM ADMIN' : 'ELITE MEMBER',
                                  style: const TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
                                ),
                              ],
                            ),
                          ).animate().fade(delay: 300.ms).slideY(begin: 0.2),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Profile Body ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('ACCOUNT SECURITY').animate().fade().slideX(begin: 0.1),
                  const SizedBox(height: 16),
                  _Card(children: [
                    _InfoRow(icon: Icons.person_outline_rounded, label: 'Full Name', value: name),
                    _InfoRow(icon: Icons.alternate_email_rounded, label: 'Electronic Mail', value: email),
                    _InfoRow(icon: Icons.location_on_outlined, label: 'Jurisdiction', value: city),
                    _InfoRow(icon: Icons.badge_outlined, label: 'Membership', value: role.toUpperCase(), isLast: true),
                  ]).animate().fade().slideY(begin: 0.1),

                  const SizedBox(height: 32),

                  _sectionLabel('RADAR ALERTS & NOTIFICATIONS').animate().fade().slideX(begin: 0.1, delay: 50.ms),
                  const SizedBox(height: 16),
                  _Card(children: [
                    _MenuRow(
                      icon: Icons.radar_rounded, 
                      label: 'Target Area: ${user?['radar_alert_area'] ?? 'Not set'}', 
                      isLast: true, 
                      onTap: () => _showAreaSelectorSheet(context, ref, user?['radar_alert_area'])
                    ),
                  ]).animate().fade().slideY(begin: 0.1, delay: 50.ms),

                  const SizedBox(height: 32),

                  if (role == 'lawyer') ...[
                    _sectionLabel('COUNSELOR DASHBOARD').animate().fade().slideX(begin: 0.1, delay: 100.ms),
                    const SizedBox(height: 16),
                    HoverButton(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LawyerDashboardScreen())),
                      child: Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [primary, AppTheme.navyLight]),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                        ),
                        child: const Center(
                          child: Text('ENTER LAWYER PORTAL', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                        ),
                      ),
                    ).animate().fade().slideY(begin: 0.1, delay: 100.ms),
                    const SizedBox(height: 32),
                  ],

                  _sectionLabel('ACTIVITY & RECORDS').animate().fade().slideX(begin: 0.1, delay: 150.ms),
                  const SizedBox(height: 16),
                  _Card(children: [
                    _MenuRow(icon: Icons.history_edu_rounded, label: 'Legal Consultations', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConsultationsScreen()))),
                    _MenuRow(icon: Icons.forum_outlined, label: 'AI Interaction History', onTap: () {}),
                    _MenuRow(icon: Icons.stars_rounded, label: 'Professional Reviews', isLast: true, onTap: () {}),
                  ]).animate().fade().slideY(begin: 0.1, delay: 150.ms),

                  const SizedBox(height: 32),

                  _sectionLabel('HELP & SUPPORT').animate().fade().slideX(begin: 0.1, delay: 220.ms),
                  const SizedBox(height: 16),
                  _Card(children: [
                    _MenuRow(
                      icon: Icons.support_agent_rounded,
                      label: 'Submit Support Ticket',
                      onTap: () => _showSupportTicketBottomSheet(context, email, name, 'Question'),
                    ),
                    _MenuRow(
                      icon: Icons.history_rounded,
                      label: 'My Support History',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyTicketsScreen())),
                    ),
                    _MenuRow(
                      icon: Icons.report_problem_rounded,
                      label: 'File a Complaint / Report Abuse',
                      isLast: true,
                      onTap: () => _showSupportTicketBottomSheet(context, email, name, 'Complaint'),
                    ),
                  ]).animate().fade().slideY(begin: 0.1, delay: 220.ms),

                  const SizedBox(height: 48),

                  if (role == 'admin') ...[
                    HoverButton(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen())),
                      child: Container(
                        width: double.infinity,
                        height: 60,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.inProgress.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppTheme.inProgress.withOpacity(0.3)),
                        ),
                        child: const Center(
                          child: Text('SYSTEM ADMINISTRATION', style: TextStyle(color: AppTheme.inProgress, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ),
                      ),
                    ).animate().fade().slideY(begin: 0.1, delay: 250.ms),
                    HoverButton(
                      onTap: () => context.push('/radar-admin'),
                      child: Container(
                        width: double.infinity,
                        height: 60,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                        ),
                        child: const Center(
                          child: Text('KARACHI RADAR ADMIN', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ),
                      ),
                    ).animate().fade().slideY(begin: 0.1, delay: 280.ms),
                  ],

                  HoverButton(
                    onTap: () async {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) context.go('/login');
                    },
                    child: Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.error.withOpacity(0.2)),
                      ),
                      child: const Center(
                        child: Text('TERMINATE SESSION', style: TextStyle(color: AppTheme.error, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      ),
                    ),
                  ).animate().fade().slideY(begin: 0.1, delay: 300.ms)
                   .animate(onPlay: (c) => c.repeat(reverse: true))
                   .shimmer(duration: 2.seconds, color: AppTheme.error.withOpacity(0.2)),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSupportTicketBottomSheet(BuildContext context, String userEmail, String userName, String defaultType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => _SupportTicketSheet(userEmail: userEmail, userName: userName, defaultType: defaultType),
    );
  }

  void _showAreaSelectorSheet(BuildContext context, WidgetRef ref, String? currentArea) {
    final areas = [
      'Gulshan-e-Iqbal',
      'Clifton & DHA',
      'Gulistan-e-Johar',
      'North Nazimabad',
      'Saddar & Lyari',
      'Federal B. Area',
      'Korangi & Landhi'
    ];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Alert Area', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
              const SizedBox(height: 8),
              const Text('You will receive push notifications for high-severity incidents in this area.', style: TextStyle(color: textGrey, fontSize: 13)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: areas.length,
                  itemBuilder: (context, index) {
                    final area = areas[index];
                    final isSelected = area == currentArea;
                    return ListTile(
                      title: Text(area, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: primary) : null,
                      onTap: () async {
                        Navigator.pop(context);
                        final success = await ref.read(authProvider.notifier).updateRadarArea(area);
                        if (success && ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Alert area updated successfully.')));
                        } else if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Failed to update alert area.')));
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await ref.read(authProvider.notifier).updateRadarArea(null);
                },
                child: const Text('Disable Area Alerts', style: TextStyle(color: AppTheme.error)),
              )
            ],
          ),
        );
      }
    );
  }

  Widget _buildTypeOption(BuildContext context, String type, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? accent.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? accent : border, width: 1.5),
          ),
          child: Center(
            child: Text(
              type.toUpperCase(),
              style: TextStyle(
                color: isSelected ? primary : textGrey,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4, left: 4),
        child: Text(text, style: const TextStyle(color: AppTheme.textGrey, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
      );

  Widget _topBtn(IconData icon, VoidCallback onTap) {
    return HoverButton(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: AppTheme.glassWhite.withOpacity(0.2), 
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool isLast;

  const _InfoRow({required this.icon, required this.label, required this.value, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(border: isLast ? null : const Border(bottom: BorderSide(color: AppTheme.border))),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: AppTheme.goldPremium.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: AppTheme.goldPremium, size: 20),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: AppTheme.textDark, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLast;

  const _MenuRow({required this.icon, required this.label, required this.onTap, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return HoverButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(border: isLast ? null : const Border(bottom: BorderSide(color: AppTheme.border))),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: AppTheme.navyDeep.withOpacity(0.05), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: AppTheme.navyDeep, size: 20),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(label, style: const TextStyle(color: AppTheme.textDark, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textGrey, size: 22)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .slideX(begin: 0, end: 0.2, duration: 1.seconds, curve: Curves.easeInOut),
          ],
        ),
      ),
    );
  }
}

class _SupportTicketSheet extends ConsumerStatefulWidget {
  final String userEmail;
  final String userName;
  final String defaultType;

  const _SupportTicketSheet({
    required this.userEmail,
    required this.userName,
    required this.defaultType,
  });

  @override
  ConsumerState<_SupportTicketSheet> createState() => _SupportTicketSheetState();
}

class _SupportTicketSheetState extends ConsumerState<_SupportTicketSheet> {
  late String selectedType;
  String selectedCategory = 'Fraud';
  final subjectCtrl = TextEditingController();
  final messageCtrl = TextEditingController();
  final lawyerNameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedType = widget.defaultType;
  }

  @override
  void dispose() {
    subjectCtrl.dispose();
    messageCtrl.dispose();
    lawyerNameCtrl.dispose();
    super.dispose();
  }

  Widget _buildTypeOption(String type, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? ProfileScreen.accent.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? ProfileScreen.accent : ProfileScreen.border, width: 1.5),
          ),
          child: Center(
            child: Text(
              type.toUpperCase(),
              style: TextStyle(
                color: isSelected ? ProfileScreen.primary : ProfileScreen.textGrey,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isComplaint = selectedType == 'Complaint';

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48, height: 5,
                decoration: BoxDecoration(color: ProfileScreen.border, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(isComplaint ? Icons.report_problem_rounded : Icons.support_agent_rounded, color: ProfileScreen.accent, size: 24),
                const SizedBox(width: 8),
                Text(
                  isComplaint ? 'FILE A COMPLAINT' : 'SUBMIT SUPPORT TICKET',
                  style: const TextStyle(fontWeight: FontWeight.w900, color: ProfileScreen.primary, fontSize: 14, letterSpacing: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Describe your issue below. Our regulatory department will audit your request within 24 hours.',
              style: TextStyle(color: ProfileScreen.textGrey, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 20),
            
            // Type selector
            const Text('Ticket Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: ProfileScreen.textDark)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildTypeOption('Question', selectedType == 'Question', () => setState(() => selectedType = 'Question')),
                const SizedBox(width: 12),
                _buildTypeOption('Complaint', selectedType == 'Complaint', () => setState(() => selectedType = 'Complaint')),
              ],
            ),
            const SizedBox(height: 20),

            if (isComplaint) ...[
              const Text('Complaint Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: ProfileScreen.textDark)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: ProfileScreen.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ProfileScreen.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'Fraud', child: Text('Financial Fraud')),
                      DropdownMenuItem(value: 'Fake Lawyer', child: Text('Duplicate / Fake Lawyer Profile')),
                      DropdownMenuItem(value: 'App Issue', child: Text('App crash / Payment failure')),
                      DropdownMenuItem(value: 'Abuse', child: Text('Abusive or Unprofessional conduct')),
                    ],
                    onChanged: (v) => setState(() => selectedCategory = v!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: lawyerNameCtrl,
                decoration: const InputDecoration(
                  hintText: 'Enter Lawyer Name / ID if applicable...',
                  labelText: 'Reported Subject Name',
                ),
              ),
              const SizedBox(height: 16),
            ],

            TextField(
              controller: subjectCtrl,
              decoration: const InputDecoration(
                hintText: 'Enter a short summary of your issue...',
                labelText: 'Subject',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Type your message/inquiry in detail...',
                labelText: 'Detailed Explanation',
              ),
            ),
            const SizedBox(height: 24),
            
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ProfileScreen.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                minimumSize: const Size(double.infinity, 54),
              ),
              onPressed: () async {
                if (subjectCtrl.text.isEmpty || messageCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill out the subject and message fields.'), backgroundColor: AppTheme.error)
                  );
                  return;
                }

                final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                final dateStr = "${months[DateTime.now().month - 1]} ${DateTime.now().day}, ${DateTime.now().year}";
                final token = ref.read(authProvider).token;

                if (token == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Not authenticated!')));
                  return;
                }

                try {
                  if (isComplaint) {
                    await apiService.submitComplaint(
                      token: token,
                      category: selectedCategory,
                      reportedLawyer: lawyerNameCtrl.text.isNotEmpty ? lawyerNameCtrl.text : 'N/A',
                      description: messageCtrl.text,
                      date: dateStr,
                    );
                  } else {
                    await apiService.submitTicket(
                      token: token,
                      ticketType: selectedType,
                      subject: subjectCtrl.text,
                      message: messageCtrl.text,
                      date: dateStr,
                    );
                  }
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 10),
                            Expanded(child: Text(isComplaint ? 'Complaint dispatched for investigation!' : 'Support ticket submitted successfully!')),
                          ],
                        ),
                        backgroundColor: AppTheme.completed,
                      )
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission failed: $e'), backgroundColor: AppTheme.error));
                  }
                }
              },
              child: Text(
                isComplaint ? 'Submit Complaint' : 'Submit Ticket',
                style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}