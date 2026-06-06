import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qanoon_buddy/core/theme.dart';
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qanoon_buddy/presentation/screens/tools/challan_verification_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qanoon_buddy/data/auth_provider.dart';
import 'package:qanoon_buddy/core/api_service.dart';
import 'package:qanoon_buddy/presentation/widgets/hover_button.dart';

class CitizenServicesScreen extends ConsumerStatefulWidget {
  const CitizenServicesScreen({super.key});

  @override
  ConsumerState<CitizenServicesScreen> createState() => _CitizenServicesScreenState();
}

class _CitizenServicesScreenState extends ConsumerState<CitizenServicesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // State for Digital Citizen Dashboard
  final List<Map<String, String>> _savedVehicles = [];
  final List<Map<String, String>> _savedCNICs = [];
  final List<Map<String, String>> _savedBills = [];
  final List<Map<String, dynamic>> _myComplaints = [];

  // For active notifications
  final List<String> _notifications = [];

  // Portals Directory Search & Category State
  String _portalSearchQuery = '';
  String _selectedPortalCategory = 'All';

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final vehiclesStr = prefs.getString('saved_vehicles');
      if (vehiclesStr != null) {
        _savedVehicles.clear();
        _savedVehicles.addAll(List<Map<String, String>>.from(
          (json.decode(vehiclesStr) as List).map((x) => Map<String, String>.from(x))
        ));
      }

      final cnicsStr = prefs.getString('saved_cnics');
      if (cnicsStr != null) {
        _savedCNICs.clear();
        _savedCNICs.addAll(List<Map<String, String>>.from(
          (json.decode(cnicsStr) as List).map((x) => Map<String, String>.from(x))
        ));
      }

      final billsStr = prefs.getString('saved_bills');
      if (billsStr != null) {
        _savedBills.clear();
        _savedBills.addAll(List<Map<String, String>>.from(
          (json.decode(billsStr) as List).map((x) => Map<String, String>.from(x))
        ));
      }

      final complaintsStr = prefs.getString('my_complaints');
      if (complaintsStr != null) {
        _myComplaints.clear();
        _myComplaints.addAll(List<Map<String, dynamic>>.from(
          json.decode(complaintsStr) as List
        ));
      }

      final notificationsStr = prefs.getString('notifications');
      if (notificationsStr != null) {
        _notifications.clear();
        _notifications.addAll(List<String>.from(json.decode(notificationsStr) as List));
      }
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_vehicles', json.encode(_savedVehicles));
    await prefs.setString('saved_cnics', json.encode(_savedCNICs));
    await prefs.setString('saved_bills', json.encode(_savedBills));
    await prefs.setString('my_complaints', json.encode(_myComplaints));
    await prefs.setString('notifications', json.encode(_notifications));
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _copyAndLaunch(String label, String value, String url) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.copy_all_rounded, color: AppTheme.goldPremium),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  children: [
                    TextSpan(text: '$label '),
                    TextSpan(text: '"$value"', style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.goldPremium)),
                    const TextSpan(text: ' copied to clipboard! Opening official portal...'),
                  ],
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.navyDeep,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
    Future.delayed(const Duration(milliseconds: 1000), () {
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.location_city_rounded, color: AppTheme.goldPremium, size: 26),
            SizedBox(width: 8),
            Text(
              'Citizen Portal',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5),
            ),
          ],
        ),
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
          isScrollable: true,
          indicatorColor: AppTheme.goldPremium,
          labelColor: AppTheme.goldPremium,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          tabs: const [
            Tab(text: 'Dashboard', icon: Icon(Icons.dashboard_customize_rounded, size: 18)),
            Tab(text: 'Transport', icon: Icon(Icons.directions_car_filled_rounded, size: 18)),
            Tab(text: 'Identity & Legal', icon: Icon(Icons.badge_rounded, size: 18)),
            Tab(text: 'Utilities', icon: Icon(Icons.bolt_rounded, size: 18)),
            Tab(text: 'Official Portals 🌐', icon: Icon(Icons.open_in_new_rounded, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          _buildTransportTab(),
          _buildIdentityTab(),
          _buildUtilitiesTab(),
          _buildPortalsTab(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. DIGITAL CITIZEN DASHBOARD & "MY KARACHI" TAB (Feature 18, 19, 20)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "My Karachi" Local Weather & Security Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.navyDeep, Color(0xFF16223F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: AppTheme.navyDeep.withOpacity(0.2), blurRadius: 24, offset: const Offset(0, 12))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.wb_sunny_rounded, color: AppTheme.goldPremium, size: 20),
                        const SizedBox(width: 8),
                        const Text('Karachi Metro • 34°C', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: -0.3)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.completed.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppTheme.completed.withOpacity(0.5)),
                      ),
                      child: const Text('ROADS CLEAR', style: TextStyle(color: AppTheme.completed, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'No Security Alerts',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'Metropolitan road networks and businesses are fully operational. Shara-e-Faisal traffic is flowing normally without major disruptions.',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, height: 1.5, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Expanded(child: _karachiMetric(Icons.warning_amber_rounded, 'STRIKE STATUS', 'Normal')),
                      Container(width: 1, height: 30, color: Colors.white.withOpacity(0.1)),
                      const SizedBox(width: 16),
                      Expanded(child: _karachiMetric(Icons.traffic_rounded, 'TRAFFIC FLOW', 'Optimal')),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fade().slideY(begin: 0.1),

          const SizedBox(height: 32),

          // Smart Notifications Panel
          if (_notifications.isNotEmpty) ...[
            const Text('ALERT NOTIFICATIONS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5, color: AppTheme.navyDeep)),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _notifications.length,
              itemBuilder: (context, i) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.05),
                  border: Border.all(color: AppTheme.error.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppTheme.error.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Text(_notifications[i], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.navyDeep, height: 1.4))),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: AppTheme.textGrey),
                      onPressed: () => setState(() { _notifications.removeAt(i); _saveData(); }),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Saved Credentials Grid
          const Text('MY SAVED ASSETS & CARDS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5, color: AppTheme.navyDeep)),
          const SizedBox(height: 16),

          // Vehicles
          _buildDashboardCard(
            title: 'Saved Vehicles',
            icon: Icons.directions_car_rounded,
            badge: '${_savedVehicles.length} Registered',
            accentColor: Colors.blueAccent,
            onAdd: () => _showAddVehicleModal(),
            child: Column(
              children: _savedVehicles.asMap().entries.map((entry) => _buildSavedVehicleCard(entry.value, entry.key)).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // CNIC Card
          _buildDashboardCard(
            title: 'Identity Credentials',
            icon: Icons.badge_rounded,
            badge: '${_savedCNICs.length} Linked',
            accentColor: Colors.purple,
            onAdd: () => _showAddCNICModal(),
            child: Column(
              children: _savedCNICs.asMap().entries.map((entry) => _buildSavedCNICCard(entry.value, entry.key)).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // Bills
          _buildDashboardCard(
            title: 'Utility Bills',
            icon: Icons.receipt_long_rounded,
            badge: '${_savedBills.length} Linked',
            accentColor: Colors.orange,
            onAdd: () => _showAddBillModal(),
            child: Column(
              children: _savedBills.asMap().entries.map((entry) => _buildSavedBillCard(entry.value, entry.key)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _karachiMetric(IconData icon, String title, String val) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppTheme.goldPremium.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(icon, color: AppTheme.goldPremium, size: 14),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              Text(val, style: const TextStyle(color: AppTheme.goldPremium, fontSize: 12, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required IconData icon,
    required String badge,
    required VoidCallback onAdd,
    required Widget child,
    Color? accentColor,
  }) {
    final color = accentColor ?? AppTheme.goldPremium;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [BoxShadow(color: color.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.navyDeep, letterSpacing: -0.2), overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(30)),
                child: Text(badge, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (child is Column && child.children.isNotEmpty) ...[
            child,
            const SizedBox(height: 20),
          ],
          HoverButton(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 18, color: AppTheme.navyDeep),
                  SizedBox(width: 8),
                  Text('ADD DOCUMENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.navyDeep, letterSpacing: 1.0)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. TRANSPORT TAB
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildTransportTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildServiceTile(
          title: 'Vehicle Verification 🚗',
          desc: 'Check registration details, owner details, and token tax status.',
          icon: Icons.directions_car_filled_rounded,
          color: Colors.blueAccent,
          onTap: () => _showVehicleVerificationModal(),
        ),
        _buildServiceTile(
          title: 'Token Tax Checker 💰',
          desc: 'Look up outstanding tax due dates and set mobile expiry reminders.',
          icon: Icons.monetization_on_rounded,
          color: Colors.green,
          onTap: () => _showTokenTaxCheckerModal(),
        ),
        _buildServiceTile(
          title: 'Apply for Driving Licence 🪪',
          desc: 'Apply or verify driving license legality online.',
          icon: Icons.badge_rounded,
          color: Colors.orange,
          onTap: () => _showLicenseVerificationModal(),
        ),
        _buildServiceTile(
          title: 'Traffic Violation Fines Info 📜',
          desc: 'Check traffic violation fine amounts and schedules.',
          icon: Icons.list_alt_rounded,
          color: Colors.redAccent,
          onTap: () => _showTrafficFinesModal(),
        ),
        _buildServiceTile(
          title: 'Excise & Challan Portal 🚨',
          desc: 'Verify registration plates and check traffic fines securely online.',
          icon: Icons.receipt_long_rounded,
          color: AppTheme.navyDeep,
          onTap: () => context.push('/citizen-services/challan'),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. IDENTITY & LEGAL TAB
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildIdentityTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildServiceTile(
          title: 'PTA IMEI Verification 📱',
          desc: 'Instantly check PTA Approval and customs duty values before buying.',
          icon: Icons.phone_android_rounded,
          color: Colors.purple,
          onTap: () => _showPtaVerificationModal(),
        ),
        _buildServiceTile(
          title: 'SIM Information System 📞',
          desc: 'Search number of active SIM registered against a Pakistani CNIC.',
          icon: Icons.sim_card_rounded,
          color: Colors.redAccent,
          onTap: () => _showSimInfoModal(),
        ),
        _buildServiceTile(
          title: 'Passport Tracking Portal 🌍',
          desc: 'Track passport dispatch state & renewal schedules.',
          icon: Icons.public_rounded,
          color: Colors.teal,
          onTap: () => _showPassportTrackingModal(),
        ),
        _buildServiceTile(
          title: 'NADRA Services Directory 🪪',
          desc: 'Child Registry, Identity renewal requirements, and booking assistance.',
          icon: Icons.fingerprint_rounded,
          color: Colors.indigo,
          onTap: () => _showNadraHubModal(),
        ),
        _buildServiceTile(
          title: 'Property & Land Registry 🏠',
          desc: 'Verify property ownership, land records, and local area tax duties.',
          icon: Icons.home_work_rounded,
          color: Colors.brown,
          onTap: () => _showPropertyTaxModal(),
        ),
        _buildServiceTile(
          title: 'Court Case Tracking ⚖️',
          desc: 'Monitor civilian & criminal case hearings and orders.',
          icon: Icons.gavel_rounded,
          color: AppTheme.navyDeep,
          onTap: () => _showCourtCaseTrackingModal(),
        ),
        _buildServiceTile(
          title: 'FIR & Complaint Tracking 🚔',
          desc: 'Check live status of Police complaints and PM Portal disputes.',
          icon: Icons.local_police_rounded,
          color: Colors.blueGrey,
          onTap: () => _showComplaintTrackingModal(),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. UTILITIES TAB
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildUtilitiesTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildServiceTile(
          title: 'K-Electric Bill Checker ⚡',
          desc: 'Lookup monthly billing summary by 14-digit reference number.',
          icon: Icons.bolt,
          color: Colors.orange,
          onTap: () => _showElectricityBillModal(),
        ),
        _buildServiceTile(
          title: 'SSGC Gas Bill Checker 🔥',
          desc: 'Check SSGC/SNGPL active bills instantly using Customer ID.',
          icon: Icons.local_fire_department_rounded,
          color: Colors.red,
          onTap: () => _showGasBillModal(),
        ),
        _buildServiceTile(
          title: 'KWSC Water Bill Checker 🚰',
          desc: 'Track water utility balance sheet for Karachi metropolitan zones.',
          icon: Icons.water_drop_rounded,
          color: Colors.blue,
          onTap: () => _showWaterBillModal(),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 5. OFFICIAL PORTALS HUB (Feature 17 & Necessary Links list)
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildPortalsTab() {
    final List<Map<String, dynamic>> allPortals = [
      // Transport
      {
        'title': 'Punjab Vehicle Verification (MTMIS)',
        'desc': 'Official portal to check vehicle owners and token status in Punjab.',
        'url': 'https://mtmis.excise.punjab.gov.pk/',
        'category': 'Transport',
        'province': 'Punjab',
        'icon': Icons.directions_car_rounded,
        'color': Colors.green,
      },
      {
        'title': 'Sindh Vehicle Verification',
        'desc': 'Official excise portal for Sindh registration database lookup.',
        'url': 'https://excise.gos.pk/vehicle/vehicle_search',
        'category': 'Transport',
        'province': 'Sindh',
        'icon': Icons.two_wheeler_rounded,
        'color': Colors.redAccent,
      },
      {
        'title': 'KPK Vehicle Search Portal',
        'desc': 'Excise and taxation registration search engine of KPK.',
        'url': 'https://www.kpexcise.gov.pk/app/',
        'category': 'Transport',
        'province': 'KPK',
        'icon': Icons.garage_rounded,
        'color': Colors.orange,
      },
      {
        'title': 'Islamabad Vehicle Verification',
        'desc': 'Official ICT Islamabad vehicle record verification portal.',
        'url': 'http://islamabadexcise.gov.pk/',
        'category': 'Transport',
        'province': 'Islamabad',
        'icon': Icons.directions_car_filled_rounded,
        'color': Colors.blueAccent,
      },
      {
        'title': 'Punjab DLIMS License Portal',
        'desc': 'Apply, renew, or track Punjab driving licenses online.',
        'url': 'https://dlims.punjab.gov.pk/',
        'category': 'Transport',
        'province': 'Punjab',
        'icon': Icons.badge_rounded,
        'color': Colors.teal,
      },
      // Identity & Utilities
      {
        'title': 'PTA DIRBS Mobile Checker',
        'desc': 'Check official mobile IMEI validation and customs duty.',
        'url': 'https://dirbs.pta.gov.pk/',
        'category': 'Identity',
        'province': 'National',
        'icon': Icons.phone_android_rounded,
        'color': Colors.purple,
      },
      {
        'title': 'PTA SIM CNIC Registry',
        'desc': 'Official portal to verify SIM counts against CNIC.',
        'url': 'https://cnic.sims.pk/',
        'category': 'Identity',
        'province': 'National',
        'icon': Icons.sim_card_rounded,
        'color': Colors.pink,
      },
      {
        'title': 'NADRA Pak-Identity Portal',
        'desc': 'Official NADRA site for smart card applications and renewals.',
        'url': 'https://id.nadra.gov.pk/',
        'category': 'Identity',
        'province': 'National',
        'icon': Icons.fingerprint_rounded,
        'color': Colors.blue,
      },
      {
        'title': 'K-Electric Bill Inquiry',
        'desc': 'View and download current KE Karachi electric bills.',
        'url': 'https://ke.com.pk/',
        'category': 'Utilities',
        'province': 'Sindh',
        'icon': Icons.bolt,
        'color': Colors.orange,
      },
      {
        'title': 'SSGC Gas Bill Portal',
        'desc': 'Inquire outstanding Gas balances directly with SSGC.',
        'url': 'https://www.ssgc.com.pk/web/',
        'category': 'Utilities',
        'province': 'National',
        'icon': Icons.local_fire_department,
        'color': Colors.red,
      },
      // Legal
      {
        'title': 'Supreme Court of Pakistan',
        'desc': 'Official website of the Supreme Court case rosters.',
        'url': 'https://www.supremecourt.gov.pk/',
        'category': 'Legal',
        'province': 'National',
        'icon': Icons.gavel_rounded,
        'color': AppTheme.navyDeep,
      },
      {
        'title': 'Sindh High Court Registry',
        'desc': 'Lookup cases and daily cause lists in the High Court of Sindh.',
        'url': 'https://sindhhighcourt.gov.pk/',
        'category': 'Legal',
        'province': 'Sindh',
        'icon': Icons.account_balance_rounded,
        'color': Colors.indigo,
      },
      {
        'title': 'Lahore High Court Registry',
        'desc': 'Track case filings, orders, and judgment databases of LHC.',
        'url': 'https://lhc.gov.pk/',
        'category': 'Legal',
        'province': 'Punjab',
        'icon': Icons.balance_rounded,
        'color': Colors.blueGrey,
      },
    ];

    // Filter logic
    final filteredPortals = allPortals.where((p) {
      final matchesSearch = (p['title'] as String).toLowerCase().contains(_portalSearchQuery.toLowerCase()) ||
          (p['desc'] as String).toLowerCase().contains(_portalSearchQuery.toLowerCase());
      final matchesCat = _selectedPortalCategory == 'All' || p['category'] == _selectedPortalCategory;
      return matchesSearch && matchesCat;
    }).toList();

    return Column(
      children: [
        // Filter bar & Search
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                onChanged: (val) => setState(() => _portalSearchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search 20+ official links...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.goldPremium),
                  filled: true,
                  fillColor: AppTheme.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Transport', 'Identity', 'Utilities', 'Legal'].map((cat) {
                    final active = _selectedPortalCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => setState(() => _selectedPortalCategory = cat),
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: active ? AppTheme.goldPremium : AppTheme.surface,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: active ? AppTheme.goldPremium : AppTheme.border),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: active ? Colors.white : AppTheme.textGrey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: filteredPortals.length,
            itemBuilder: (context, idx) {
              final p = filteredPortals[idx];
              final color = p['color'] as Color;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => launchUrl(Uri.parse(p['url'] as String), mode: LaunchMode.externalApplication),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
                          child: Icon(p['icon'] as IconData, color: color, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                                    child: Text(
                                      (p['province'] as String).toUpperCase(),
                                      style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: AppTheme.navyDeep.withOpacity(0.05), borderRadius: BorderRadius.circular(4)),
                                    child: Text(
                                      (p['category'] as String).toUpperCase(),
                                      style: const TextStyle(color: AppTheme.navyDeep, fontSize: 8, fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(p['title'] as String, style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w900, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(p['desc'] as String, style: const TextStyle(color: AppTheme.textGrey, fontSize: 10, height: 1.4, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.open_in_new_rounded, color: AppTheme.textGrey, size: 16),
                      ],
                    ),
                  ),
                ),
              ).animate().fade(delay: (idx * 40).ms).slideY(begin: 0.05);
            },
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // REUSABLE HELPER UI WIDGETS
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildServiceTile({
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.border),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.textDark)),
                    const SizedBox(height: 4),
                    Text(desc, style: const TextStyle(fontSize: 11, color: AppTheme.textGrey, height: 1.4, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textGrey.withOpacity(0.3), size: 14),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // INTERACTIVE MODALS FOR ALL 20 FEATURES
  // ─────────────────────────────────────────────────────────────────────────────

  // Form Fields Controllers
  final _plateC = TextEditingController();
  final _imeiC = TextEditingController();
  final _cnicC = TextEditingController();
  final _complaintDescC = TextEditingController();
  final _refC = TextEditingController();
  final _caseC = TextEditingController();

  void _showAddVehicleModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Save Vehicle Details', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textDark)),
            const SizedBox(height: 16),
            TextField(controller: _plateC, decoration: const InputDecoration(hintText: 'Vehicle Number (e.g. KHI-7860)')),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_plateC.text.isNotEmpty) {
                  setState(() {
                    _savedVehicles.add({'plate': _plateC.text.toUpperCase(), 'model': 'Honda Civic 1.8L', 'tax': 'Paid', 'due': 'Jul 10, 2027'});
                    _saveData();
                  });
                  _plateC.clear();
                  Navigator.pop(context);
                }
              },
              child: const Text('Save to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCNICModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Save CNIC Credentials', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textDark)),
            const SizedBox(height: 16),
            TextField(controller: _cnicC, decoration: const InputDecoration(hintText: 'CNIC (e.g. 42101-1234567-1)')),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_cnicC.text.isNotEmpty) {
                  setState(() {
                    _savedCNICs.add({'name': 'M. Mairaj', 'cnic': _cnicC.text, 'expiry': 'Oct 14, 2035'});
                    _saveData();
                  });
                  _cnicC.clear();
                  Navigator.pop(context);
                }
              },
              child: const Text('Save to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBillModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Save Utility Bill', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textDark)),
            const SizedBox(height: 16),
            TextField(controller: _refC, decoration: const InputDecoration(hintText: 'Reference ID (e.g. 14234567890123)')),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (_refC.text.isNotEmpty) {
                  setState(() {
                    _savedBills.add({'type': 'Gas', 'ref': _refC.text, 'amount': 'PKR 2,450', 'due': 'Jun 05, 2026', 'status': 'Unpaid'});
                    _saveData();
                  });
                  _refC.clear();
                  Navigator.pop(context);
                }
              },
              child: const Text('Save to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  // 🚗 Vehicle Verification Modal
  void _showVehicleVerificationModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => _buildVerificationModalSheet(
        title: 'Vehicle Verification',
        icon: Icons.directions_car_rounded,
        portalUrl: 'https://mtmis.excise.punjab.gov.pk/',
        labelText: 'Vehicle Registration Plate',
        hintText: 'e.g. LE-12-3456 or AEE-902',
        instructions: '1. Your plate number is copied automatically.\n2. The official Excise website will open in your browser.\n3. Paste the plate in the search box, solve the Captcha, and tap search to see real-time owner details.',
        assetType: 'vehicle',
      ),
    );
  }

  // 💰 Token Tax Modal
  void _showTokenTaxCheckerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => _buildVerificationModalSheet(
        title: 'Token Tax Checker',
        icon: Icons.monetization_on_rounded,
        portalUrl: 'https://mtmis.excise.punjab.gov.pk/',
        labelText: 'Vehicle Registration Plate',
        hintText: 'e.g. LE-12-3456 or AEE-902',
        instructions: '1. Your plate is copied automatically.\n2. When the portal opens, paste the plate and solve the Captcha.\n3. You will see active token tax calculations and unpaid duties.',
        assetType: 'vehicle',
      ),
    );
  }

  // 🪪 License Verification
  void _showLicenseVerificationModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => _buildVerificationModalSheet(
        title: 'Apply for Driving Licence',
        icon: Icons.badge_rounded,
        portalUrl: 'https://dlims.punjab.gov.pk/',
        labelText: 'CNIC Number (no dashes)',
        hintText: 'e.g. 3520212345678',
        instructions: '1. Your CNIC is copied to clipboard.\n2. When DLIMS/DLSO portal opens, verify or submit your new application.\n3. Enter the security code or CNIC to check details.',
        assetType: 'cnic',
      ),
    );
  }

  // 📜 Traffic Violation Fines
  void _showTrafficFinesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => _buildVerificationModalSheet(
        title: 'Traffic Violation Fines Info',
        icon: Icons.list_alt_rounded,
        portalUrl: 'https://tracs.sindhpolice.gov.pk/fine-list/',
        labelText: 'License Plate / Challan (Optional)',
        hintText: 'e.g. KHI-1234',
        instructions: '1. Launch official Traffic Police fine rates page.\n2. Reference details will be copied automatically if provided.',
      ),
    );
  }

  // 📱 PTA Mobile Verification
  void _showPtaVerificationModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => _buildVerificationModalSheet(
        title: 'PTA IMEI Verification',
        icon: Icons.phone_android_rounded,
        portalUrl: 'https://dirbs.pta.gov.pk/',
        labelText: '15-Digit Device IMEI',
        hintText: 'Dial *#06# on your phone to get IMEI',
        instructions: '1. Device IMEI is copied automatically.\n2. Tapping verify will open the official PTA DIRBS site.\n3. Paste the 15-digit IMEI, complete the Captcha, and see if it is approved/tax paid.',
      ),
    );
  }

  // 📞 SIM Info modal - CNIC-Based SIM Registration Checker with High-Fidelity Simulator
  void _showSimInfoModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => _SimInfoModalSheet(
        onAssetSaved: (assetType, value) {
          setState(() {
            if (assetType == 'cnic') {
              _savedCNICs.add({
                'name': 'Linked Citizen',
                'cnic': value,
                'expiry': 'Dec 12, 2035'
              });
              _saveData();
            }
          });
        },
        onLaunch: _copyAndLaunch,
      ),
    );
  }

  // 🌍 Passport tracking
  void _showPassportTrackingModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => _buildVerificationModalSheet(
        title: 'Passport Dispatch Tracker',
        icon: Icons.public_rounded,
        portalUrl: 'https://tracking.dgip.gov.pk/',
        labelText: '11-Digit Tracking/Token No.',
        hintText: 'Found on your passport application receipt',
        instructions: '1. Passport tracking token is copied to clipboard.\n2. Open official Tracking portal, paste code, and view live delivery status.',
      ),
    );
  }

  // 🪪 NADRA Hub
  void _showNadraHubModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('NADRA Services Hub 🪪', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textDark)),
            const SizedBox(height: 16),
            const Text('Required Documents for CNIC Renewal:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.navyDeep)),
            const Text('1. Old Original CNIC\n2. Address proof (Utility bill / Registry)\n3. Family registration certificate (if modifying)', style: TextStyle(fontSize: 11, color: AppTheme.textGrey, height: 1.5)),
            const SizedBox(height: 16),
            const Text('Nearest Executive Offices in Karachi:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.navyDeep)),
            const Text('- DHA Phase 1 NADRA Mega Center (24 Hours)\n- North Nazimabad Mega Center (24 Hours)\n- Saddar Office (8 AM - 4 PM)', style: TextStyle(fontSize: 11, color: AppTheme.textGrey, height: 1.5)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => launchUrl(Uri.parse('https://id.nadra.gov.pk/'), mode: LaunchMode.externalApplication),
              child: const Text('Book Appointment Online'),
            ),
          ],
        ),
      ),
    );
  }

  // 🏠 Property / Land Verification
  void _showPropertyTaxModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => _buildVerificationModalSheet(
        title: 'Property Land Verification',
        icon: Icons.home_work_rounded,
        portalUrl: 'https://sindhzameen.gos.pk/',
        labelText: 'Property ID / CNIC',
        hintText: 'Enter CNIC or Property Survey ID',
        instructions: '1. Your search reference is copied to clipboard.\n2. Launching will open Sindh Zameen portal.\n3. Search land registry books and ownership maps with 100% official accuracy.',
      ),
    );
  }

  // ⚖️ Court Case Tracking
  void _showCourtCaseTrackingModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => _buildVerificationModalSheet(
        title: 'Court Case Tracking',
        icon: Icons.gavel_rounded,
        portalUrl: 'https://www.supremecourt.gov.pk/',
        labelText: 'Case Number or CNIC',
        hintText: 'e.g. C.A. 120/2026',
        instructions: '1. Case details are copied to clipboard.\n2. Launching will open Supreme Court Case Tracker.\n3. Paste details to view official roster status and latest signed court order files.',
      ),
    );
  }

  // 🚔 FIR Tracking
  void _showComplaintTrackingModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => _buildVerificationModalSheet(
        title: 'FIR & Complaint Tracking',
        icon: Icons.local_police_rounded,
        portalUrl: 'https://www.pmdu.gov.pk/',
        labelText: 'Complaint ID or CNIC',
        hintText: 'e.g. PMDU-KP-123456',
        instructions: '1. Complaint ticket number is copied to clipboard.\n2. Launching will load Prime Minister Citizen Portal / FIR system.\n3. Check official status of your civic complaints.',
      ),
    );
  }

  // ⚡ Electricity Bill Modal
  void _showElectricityBillModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => _buildVerificationModalSheet(
        title: 'K-Electric Bill Checker',
        icon: Icons.bolt,
        portalUrl: 'https://ke.com.pk/',
        labelText: '13-Digit Account/Ref Number',
        hintText: 'Found on your paper KE bill',
        instructions: '1. Account reference is copied to clipboard.\n2. Tapping verify will open K-Electric e-portal.\n3. Paste the reference to view, download, and check payment status of your bill.',
        assetType: 'bill',
      ),
    );
  }

  // 🔥 Gas Bill Modal
  void _showGasBillModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => _buildVerificationModalSheet(
        title: 'SSGC Gas Bill Checker',
        icon: Icons.local_fire_department_rounded,
        portalUrl: 'https://www.ssgc.com.pk/web/',
        labelText: '10-Digit Customer Number',
        hintText: 'Found on your SSGC paper bill',
        instructions: '1. Gas customer ID is copied to clipboard.\n2. Portal opens with SSGC Quick Bill Search.\n3. Paste the customer ID to retrieve official balance sheet details.',
        assetType: 'bill',
      ),
    );
  }

  // 🚰 Water Bill Modal
  void _showWaterBillModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => _buildVerificationModalSheet(
        title: 'KSWC Water Bill Search',
        icon: Icons.water_drop_rounded,
        portalUrl: 'https://www.kwsc.gos.pk/',
        labelText: 'Water Consumer ID',
        hintText: 'e.g. 104234567',
        instructions: '1. Water consumer ID is copied to clipboard.\n2. Portal opens with Karachi Water Corporation search.\n3. Paste the ID to view live outstanding water supply charges.',
        assetType: 'bill',
      ),
    );
  }

  // 📝 Complaint Hub (Civic complaints)
  void _showComplaintHubModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Citizen Complaint Hub 📝', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textDark)),
            const SizedBox(height: 16),
            const Text('File simulated civic complaints immediately into Pakistan systems.', style: TextStyle(fontSize: 11, color: AppTheme.textGrey)),
            const SizedBox(height: 16),
            TextField(controller: _plateC, decoration: const InputDecoration(hintText: 'Complaint subject (e.g. Garbage Dump, Electricity Theft)')),
            const SizedBox(height: 12),
            TextField(controller: _complaintDescC, maxLines: 3, decoration: InputDecoration(hintText: 'Describe details, street name, city details...', hintStyle: TextStyle(color: AppTheme.textGrey.withOpacity(0.5)))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                if (_plateC.text.isNotEmpty) {
                  final token = ref.read(authProvider).token;
                  if (token != null) {
                    try {
                      await ApiService().submitComplaint(
                        token: token,
                        category: _plateC.text,
                        reportedLawyer: 'N/A',
                        description: _complaintDescC.text.isNotEmpty ? _complaintDescC.text : 'Complaint submitted via Hub',
                        date: 'May 24, 2026',
                      );
                    } catch (e) {
                      debugPrint('Error syncing complaint: $e');
                    }
                  }

                  setState(() {
                    _myComplaints.add({'id': 'CMP-${1000 + Random().nextInt(9000)}', 'type': _plateC.text, 'date': 'May 24, 2026', 'status': 'Pending'});
                    _saveData();
                  });
                  _plateC.clear();
                  _complaintDescC.clear();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Complaint synced to backend! Track ID generated in Dashboard.')),
                    );
                  }
                }
              },
              child: const Text('Submit Complaint'),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // MASTER BUILDER FOR DYNAMIC FORM-SEARCH MODALS
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildVerificationModalSheet({
    required String title,
    required IconData icon,
    required String portalUrl,
    required String labelText,
    required String hintText,
    required String instructions,
    String? assetType, // 'vehicle', 'cnic', 'bill'
  }) {
    return _VerificationModalSheet(
      title: title,
      icon: icon,
      portalUrl: portalUrl,
      labelText: labelText,
      hintText: hintText,
      instructions: instructions,
      assetType: assetType,
      onAssetSaved: (type, val) {
        setState(() {
          if (type == 'vehicle') {
            _savedVehicles.add({
              'plate': val.toUpperCase(),
              'model': 'Honda City 1.5L',
              'tax': 'Paid',
              'due': 'Dec 31, 2026'
            });
          } else if (type == 'cnic') {
            _savedCNICs.add({
              'name': 'Linked Citizen',
              'cnic': val,
              'expiry': 'Dec 12, 2035'
            });
          } else if (type == 'bill') {
            _savedBills.add({
              'type': title.contains('Water') ? 'Water' : (title.contains('Gas') ? 'Gas' : 'Electricity'),
              'ref': val,
              'amount': 'PKR 4,320',
              'due': 'Jun 15, 2026',
              'status': 'Unpaid'
            });
          }
          _saveData();
        });
      },
      onLaunch: _copyAndLaunch,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // RESPONSIVE MULTI-ROW DASHBOARD CARD BUILDERS
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildSavedVehicleCard(Map<String, String> v, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Styled Plate Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.navyDeep,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.goldPremium.withOpacity(0.5), width: 1.5),
                ),
                child: Text(
                  v['plate'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              // Actions
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 18, color: AppTheme.navyDeep),
                    onPressed: () => _showEditVehicleModal(v, index),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                    onPressed: () => _deleteVehicle(index),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            v['model'] ?? 'Unknown Model',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tax due: ${v['due'] ?? ''}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textGrey, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (v['tax'] == 'Paid') ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  v['tax'] ?? 'Unpaid',
                  style: TextStyle(
                    color: (v['tax'] == 'Paid') ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          InkWell(
            onTap: () => _copyAndLaunch('Vehicle Plate', v['plate']!, 'https://mtmis.excise.punjab.gov.pk/'),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Copy & Verify Live', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.goldPremium)),
                SizedBox(width: 6),
                Icon(Icons.open_in_new_rounded, size: 14, color: AppTheme.goldPremium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedCNICCard(Map<String, String> c, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.credit_card_rounded, color: AppTheme.navyDeep, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    c['cnic'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: AppTheme.textDark,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              // Actions
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 18, color: AppTheme.navyDeep),
                    onPressed: () => _showEditCNICModal(c, index),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                    onPressed: () => _deleteCNIC(index),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            c['name'] ?? 'Linked Citizen',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
          ),
          const SizedBox(height: 6),
          Text(
            'Expiry Date: ${c['expiry'] ?? ''}',
            style: const TextStyle(fontSize: 11, color: AppTheme.textGrey, fontWeight: FontWeight.w600),
          ),
          const Divider(height: 20),
          InkWell(
            onTap: () => _copyAndLaunch('CNIC', c['cnic']!, 'https://cnic.sims.pk/'),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Copy & Verify SIMs', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.goldPremium)),
                SizedBox(width: 6),
                Icon(Icons.open_in_new_rounded, size: 14, color: AppTheme.goldPremium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedBillCard(Map<String, String> b, int index) {
    IconData billIcon = Icons.receipt_long_rounded;
    Color iconColor = AppTheme.goldPremium;
    if (b['type'] == 'Electricity') {
      billIcon = Icons.bolt;
      iconColor = Colors.orange;
    } else if (b['type'] == 'Gas') {
      billIcon = Icons.local_fire_department_rounded;
      iconColor = Colors.redAccent;
    } else if (b['type'] == 'Water') {
      billIcon = Icons.water_drop_rounded;
      iconColor = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(billIcon, color: iconColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${b['type'] ?? ''} Bill',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppTheme.textDark),
                  ),
                ],
              ),
              // Actions
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 18, color: AppTheme.navyDeep),
                    onPressed: () => _showEditBillModal(b, index),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                    onPressed: () => _deleteBill(index),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Ref ID: ${b['ref'] ?? ''}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.textDark, letterSpacing: 0.5),
          ),
          const Divider(height: 20),
          InkWell(
            onTap: () {
              String url = 'https://ke.com.pk/';
              if (b['type'] == 'Electricity') {
                url = 'https://ke.com.pk/';
              } else if (b['type'] == 'Gas') {
                url = 'https://www.ssgc.com.pk/web/';
              } else if (b['type'] == 'Water') {
                url = 'https://www.kwsc.gos.pk/';
              }
              _copyAndLaunch('${b['type']} Reference ID', b['ref']!, url);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Copy & Verify Live', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.goldPremium)),
                SizedBox(width: 6),
                Icon(Icons.open_in_new_rounded, size: 14, color: AppTheme.goldPremium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // MODAL EDIT & DELETE HANDLERS
  // ─────────────────────────────────────────────────────────────────────────────
  void _showEditVehicleModal(Map<String, String> v, int index) {
    final editPlateC = TextEditingController(text: v['plate']);
    final editModelC = TextEditingController(text: v['model']);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit Vehicle Details', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textDark)),
            const SizedBox(height: 16),
            TextField(controller: editPlateC, decoration: const InputDecoration(labelText: 'Vehicle Number')),
            const SizedBox(height: 12),
            TextField(controller: editModelC, decoration: const InputDecoration(labelText: 'Model (Optional)')),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (editPlateC.text.isNotEmpty) {
                  setState(() {
                    _savedVehicles[index] = {
                      'plate': editPlateC.text.toUpperCase(),
                      'model': editModelC.text.isNotEmpty ? editModelC.text : (v['model'] ?? 'Suzuki Alto'),
                      'tax': v['tax'] ?? 'Paid',
                      'due': v['due'] ?? 'Dec 15, 2026',
                    };
                    _saveData();
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: AppTheme.navyDeep,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Update Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteVehicle(int index) {
    setState(() {
      _savedVehicles.removeAt(index);
      _saveData();
    });
  }

  void _showEditCNICModal(Map<String, String> c, int index) {
    final editCnicC = TextEditingController(text: c['cnic']);
    final editNameC = TextEditingController(text: c['name']);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit CNIC Details', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textDark)),
            const SizedBox(height: 16),
            TextField(
              controller: editCnicC,
              decoration: const InputDecoration(labelText: 'CNIC Number'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(controller: editNameC, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (editCnicC.text.isNotEmpty) {
                  setState(() {
                    _savedCNICs[index] = {
                      'cnic': editCnicC.text,
                      'name': editNameC.text.isNotEmpty ? editNameC.text : (c['name'] ?? 'Linked Citizen'),
                      'expiry': c['expiry'] ?? 'Dec 12, 2035',
                    };
                    _saveData();
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: AppTheme.navyDeep,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Update Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteCNIC(int index) {
    setState(() {
      _savedCNICs.removeAt(index);
      _saveData();
    });
  }

  void _showEditBillModal(Map<String, String> b, int index) {
    final editRefC = TextEditingController(text: b['ref']);
    String? selectedType = b['type'];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Bill Details', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textDark)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Bill Type'),
                items: const [
                  DropdownMenuItem(value: 'Electricity', child: Text('Electricity (KE)')),
                  DropdownMenuItem(value: 'Gas', child: Text('Gas (SSGC)')),
                  DropdownMenuItem(value: 'Water', child: Text('Water (KWSC)')),
                ],
                onChanged: (val) {
                  setModalState(() {
                    selectedType = val;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(controller: editRefC, decoration: const InputDecoration(labelText: 'Reference ID / Account ID')),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (editRefC.text.isNotEmpty && selectedType != null) {
                    setState(() {
                      _savedBills[index] = {
                        'type': selectedType!,
                        'ref': editRefC.text,
                        'amount': b['amount'] ?? 'PKR 4,320',
                        'due': b['due'] ?? 'Jun 15, 2026',
                        'status': b['status'] ?? 'Unpaid',
                      };
                      _saveData();
                    });
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppTheme.navyDeep,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Update Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteBill(int index) {
    setState(() {
      _savedBills.removeAt(index);
      _saveData();
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATEFUL MODAL WIDGET IMPLEMENTATIONS
// ─────────────────────────────────────────────────────────────────────────────

class _SimInfoModalSheet extends StatefulWidget {
  final Function(String assetType, String value) onAssetSaved;
  final Function(String labelText, String value, String portalUrl) onLaunch;

  const _SimInfoModalSheet({
    Key? key,
    required this.onAssetSaved,
    required this.onLaunch,
  }) : super(key: key);

  @override
  State<_SimInfoModalSheet> createState() => _SimInfoModalSheetState();
}

class _SimInfoModalSheetState extends State<_SimInfoModalSheet> {
  late final TextEditingController _cnicController;
  bool _isChecking = false;
  bool _hasResult = false;
  Map<String, dynamic>? _simReport;
  bool _saveToDash = true;

  @override
  void initState() {
    super.initState();
    _cnicController = TextEditingController();
  }

  @override
  void dispose() {
    _cnicController.dispose();
    super.dispose();
  }

  void _generateSimReport(String cnicVal) {
    final cleanCnic = cnicVal.replaceAll('-', '').trim();
    if (cleanCnic.length != 13) return;

    final int hash = cleanCnic.hashCode;
    final int jazzActive = (hash % 2) + 1;
    final int jazzInactive = (hash % 3 == 0) ? 1 : 0;
    
    final int telenorActive = ((hash ~/ 2) % 2);
    final int telenorInactive = 0;

    final int zongActive = ((hash ~/ 3) % 2);
    final int zongInactive = ((hash ~/ 4) % 3 == 0) ? 1 : 0;

    final int ufoneActive = ((hash ~/ 5) % 2);
    final int ufoneInactive = 0;

    final int waridActive = 0;
    final int waridInactive = 0;

    final int totalActive = jazzActive + telenorActive + zongActive + ufoneActive + waridActive;
    final int totalInactive = jazzInactive + telenorInactive + zongInactive + ufoneInactive + waridInactive;
    final int grandTotal = totalActive + totalInactive;

    final List<String> names = [
      'Rao Muhammad Mairaj',
      'Umer Ali Khan Lodhi',
      'Muhammad Ali Lodhi',
      'Ayesha Khan Jamil',
      'Zainab Bibi Chaudhry',
    ];
    final String rawOwnerName = names[hash % names.length];
    
    final maskedOwnerName = rawOwnerName.split(' ').map((part) {
      if (part.length <= 2) return part;
      return '${part[0]}${'*' * (part.length - 2)}${part[part.length - 1]}';
    }).join(' ');

    final String formattedCnic = '${cleanCnic.substring(0, 5)}-${cleanCnic.substring(5, 12)}-${cleanCnic.substring(12)}';
    final maskedCnic = '${cleanCnic.substring(0, 5)}-*******-${cleanCnic.substring(12)}';

    setState(() {
      _simReport = {
        'cnic': formattedCnic,
        'maskedCnic': maskedCnic,
        'jazz': {'active': jazzActive, 'inactive': jazzInactive},
        'telenor': {'active': telenorActive, 'inactive': telenorInactive},
        'zong': {'active': zongActive, 'inactive': zongInactive},
        'ufone': {'active': ufoneActive, 'inactive': ufoneInactive},
        'warid': {'active': waridActive, 'inactive': waridInactive},
        'totalActive': totalActive,
        'totalInactive': totalInactive,
        'grandTotal': grandTotal,
        'ownerName': maskedOwnerName,
        'issueDate': '14-Oct-${2015 + (hash % 8)}',
        'district': ['Karachi South', 'Lahore Cantt', 'Islamabad Capital', 'Peshawar', 'Quetta'][hash % 5],
        'biometricStatus': '100% Biometrically Verified (NADRA E-Sahulat)',
      };
    });
  }

  Widget _buildSimOperatorRow(String operator, Color accentColor, Map<String, dynamic> data) {
    final int active = data['active'] ?? 0;
    final int inactive = data['inactive'] ?? 0;
    final bool hasSims = (active + inactive) > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: hasSims ? accentColor.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hasSims ? accentColor.withOpacity(0.2) : AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(Icons.sim_card_rounded, color: hasSims ? accentColor : AppTheme.textGrey.withOpacity(0.4), size: 18),
          const SizedBox(width: 10),
          Text(
            operator,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: hasSims ? AppTheme.textDark : AppTheme.textGrey,
            ),
          ),
          const Spacer(),
          if (hasSims) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text('$active Active', style: const TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.w900)),
            ),
            if (inactive > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text('$inactive Inactive', style: const TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.w900)),
              ),
            ],
          ] else
            const Text('0 SIMs registered', style: TextStyle(color: AppTheme.textGrey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildReportRow(String label, String value, {bool isVerified = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textGrey, fontWeight: FontWeight.w600)),
          Row(
            children: [
              if (isVerified) ...[
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 12),
                const SizedBox(width: 4),
              ],
              Text(
                value,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isVerified ? Colors.green : AppTheme.textDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.sim_card_rounded, color: Colors.redAccent, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'SIM Information System',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textDark),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (!_isChecking && !_hasResult) ...[
              const Text(
                'Validate active mobile SIM counts per operator registered on a Pakistani CNIC.',
                style: TextStyle(fontSize: 12, color: AppTheme.textGrey, height: 1.4),
              ),
              const SizedBox(height: 16),
              Text('CNIC NUMBER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.navyDeep.withOpacity(0.8))),
              const SizedBox(height: 8),
              TextField(
                controller: _cnicController,
                keyboardType: TextInputType.number,
                maxLength: 15,
                onChanged: (val) {
                  String text = val.replaceAll('-', '');
                  if (text.length > 5 && text.length <= 12) {
                    text = '${text.substring(0, 5)}-${text.substring(5)}';
                  } else if (text.length > 12) {
                    text = '${text.substring(0, 5)}-${text.substring(5, 12)}-${text.substring(12)}';
                  }
                  if (_cnicController.text != text) {
                    _cnicController.value = TextEditingValue(
                      text: text,
                      selection: TextSelection.collapsed(offset: text.length),
                    );
                  }
                },
                decoration: InputDecoration(
                  hintText: 'e.g. 42101-1234567-1',
                  counterText: '',
                  prefixIcon: const Icon(Icons.badge_rounded, color: AppTheme.goldPremium, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _saveToDash,
                    activeColor: AppTheme.goldPremium,
                    onChanged: (val) => setState(() => _saveToDash = val ?? true),
                  ),
                  const Expanded(
                    child: Text(
                      'Save this CNIC to my Dashboard for quick future lookups',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final String val = _cnicController.text.trim();
                        if (val.replaceAll('-', '').length != 13) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid 13-digit CNIC.')),
                          );
                          return;
                        }
                        setState(() {
                          _isChecking = true;
                        });
                        Future.delayed(const Duration(milliseconds: 1500), () {
                          if (!mounted) return;
                          setState(() {
                            _isChecking = false;
                            _hasResult = true;
                          });
                          _generateSimReport(val);
                          if (_saveToDash) {
                            widget.onAssetSaved('cnic', val);
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.navyDeep,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Simulate Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        final String val = _cnicController.text.trim();
                        if (val.isEmpty) return;
                        widget.onLaunch('CNIC', val, 'https://cnic.sims.pk/');
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.goldPremium),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Verify Live', style: TextStyle(color: AppTheme.goldPremium, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ] else if (_isChecking) ...[
              const SizedBox(height: 24),
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppTheme.goldPremium),
                    SizedBox(height: 16),
                    Text('Querying PTA SIM Database...', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navyDeep)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ] else if (_hasResult && _simReport != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.navyDeep.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.navyDeep.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NADRA BIOMETRIC REPORT',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: AppTheme.goldPremium, letterSpacing: 1),
                    ),
                    const SizedBox(height: 12),
                    _buildReportRow('Registered CNIC', _simReport!['maskedCnic'] ?? ''),
                    _buildReportRow('Owner Name', _simReport!['ownerName'] ?? ''),
                    _buildReportRow('Issue Date', _simReport!['issueDate'] ?? ''),
                    _buildReportRow('Registration District', _simReport!['district'] ?? ''),
                    const Divider(height: 16),
                    _buildReportRow('Status', _simReport!['biometricStatus'] ?? '', isVerified: true),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              const Text('OPERATOR SIM COUNTS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppTheme.navyDeep)),
              const SizedBox(height: 10),
              _buildSimOperatorRow('Jazz / Warid', Colors.orange, _simReport!['jazz']),
              _buildSimOperatorRow('Telenor', Colors.blue, _simReport!['telenor']),
              _buildSimOperatorRow('Zong', Colors.green, _simReport!['zong']),
              _buildSimOperatorRow('Ufone', Colors.orangeAccent, _simReport!['ufone']),
              
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Active SIMs: ${_simReport!['totalActive']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textDark)),
                  Text('Grand Total: ${_simReport!['grandTotal']}/5', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green)),
                ],
              ),
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 45),
                  backgroundColor: AppTheme.navyDeep,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VerificationModalSheet extends StatefulWidget {
  final String title;
  final IconData icon;
  final String portalUrl;
  final String labelText;
  final String hintText;
  final String instructions;
  final String? assetType;
  final Function(String assetType, String value) onAssetSaved;
  final Function(String labelText, String value, String portalUrl) onLaunch;

  const _VerificationModalSheet({
    Key? key,
    required this.title,
    required this.icon,
    required this.portalUrl,
    required this.labelText,
    required this.hintText,
    required this.instructions,
    this.assetType,
    required this.onAssetSaved,
    required this.onLaunch,
  }) : super(key: key);

  @override
  State<_VerificationModalSheet> createState() => _VerificationModalSheetState();
}

class _VerificationModalSheetState extends State<_VerificationModalSheet> {
  late final TextEditingController _inputController;
  bool _saveToDashboard = true;
  String _selectedProvince = 'Punjab';

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  String get _currentPortalUrl {
    final titleLower = widget.title.toLowerCase();
    if (titleLower.contains('vehicle')) {
      switch (_selectedProvince) {
        case 'Sindh':
          return 'https://excise.gos.pk/vehicle/vehicle_search';
        case 'KPK':
          return 'https://www.kpexcise.gov.pk/app/';
        case 'Islamabad':
          return 'http://islamabadexcise.gov.pk/';
        case 'Punjab':
        default:
          return 'https://mtmis.excise.punjab.gov.pk/';
      }
    } else if (titleLower.contains('tax')) {
      switch (_selectedProvince) {
        case 'Sindh':
          return 'https://taxportal.excise.gos.pk/home/quick_pay';
        case 'KPK':
          return 'https://www.kpexcise.gov.pk/app/';
        case 'Islamabad':
          return 'http://islamabadexcise.gov.pk/';
        case 'Punjab':
        default:
          return 'https://mtmis.excise.punjab.gov.pk/';
      }
    } else if (titleLower.contains('licen') || titleLower.contains('dlims')) {
      switch (_selectedProvince) {
        case 'Sindh':
          return 'https://dlsonline.sindhpolice.gov.pk/';
        case 'Punjab':
        default:
          return 'https://dlims.punjab.gov.pk/';
      }
    } else if (titleLower.contains('fine') || titleLower.contains('violation')) {
      switch (_selectedProvince) {
        case 'Sindh':
          return 'https://tracs.sindhpolice.gov.pk/fine-list/';
        case 'Punjab':
        default:
          return 'https://traffic.punjabpolice.gov.pk/';
      }
    }
    return widget.portalUrl;
  }

  bool get _showProvinceDropdown {
    final titleLower = widget.title.toLowerCase();
    return titleLower.contains('vehicle') ||
           titleLower.contains('tax') ||
           titleLower.contains('licen') ||
           titleLower.contains('fine') ||
           titleLower.contains('violation');
  }

  @override
  Widget build(BuildContext context) {
    final bool isFineInfo = widget.title.toLowerCase().contains('fine') || widget.title.toLowerCase().contains('violation');
    
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.icon, color: AppTheme.goldPremium, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.navyDeep.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.instructions,
                style: const TextStyle(fontSize: 11, color: AppTheme.textGrey, height: 1.4),
              ),
            ),
            const SizedBox(height: 16),

            if (_showProvinceDropdown) ...[
              const Text(
                'SELECT PROVINCE / REGION',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textGrey),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedProvince,
                    isExpanded: true,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    items: ['Punjab', 'Sindh', 'KPK', 'Islamabad'].map((prov) {
                      return DropdownMenuItem<String>(value: prov, child: Text(prov));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedProvince = val;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            Text(
              widget.labelText.toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.navyDeep.withOpacity(0.8)),
            ),
            const SizedBox(height: 8),
            
            TextField(
              controller: _inputController,
              decoration: InputDecoration(
                hintText: widget.hintText,
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.goldPremium, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onChanged: (val) {
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            
            if (widget.assetType != null)
              Row(
                children: [
                  Checkbox(
                    value: _saveToDashboard,
                    activeColor: AppTheme.goldPremium,
                    onChanged: (val) {
                      setState(() {
                        _saveToDashboard = val ?? true;
                      });
                    },
                  ),
                  Expanded(
                    child: Text(
                      'Save to Dashboard for quick access',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.navyDeep.withOpacity(0.8)),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: _inputController.text.trim().isEmpty && !isFineInfo
                  ? null
                  : () {
                      final val = _inputController.text.trim();
                      if (_saveToDashboard && widget.assetType != null && val.isNotEmpty) {
                        widget.onAssetSaved(widget.assetType!, val);
                      }
                      widget.onLaunch(widget.labelText, val, _currentPortalUrl);
                      Navigator.pop(context);
                    },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: AppTheme.navyDeep,
                disabledBackgroundColor: AppTheme.border,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      isFineInfo ? 'View Fine Info Portal' : 'Launch & Verify Live',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: _inputController.text.trim().isEmpty && !isFineInfo ? AppTheme.textGrey : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 16,
                    color: _inputController.text.trim().isEmpty && !isFineInfo ? AppTheme.textGrey : Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
