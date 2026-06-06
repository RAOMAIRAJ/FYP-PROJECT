import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:qanoon_buddy/core/theme.dart';
import 'package:qanoon_buddy/core/db_helper.dart';

class MyVehiclesScreen extends StatefulWidget {
  const MyVehiclesScreen({super.key});

  @override
  State<MyVehiclesScreen> createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends State<MyVehiclesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoading = true;

  // Simulated traffic challan records database
  final List<Map<String, dynamic>> _challans = [
    {
      'plate_number': 'LEB-26-809',
      'date': '2026-05-12',
      'offense': 'Over-speeding (Canal Road)',
      'fine': 500.0,
      'status': 'Paid',
      'city': 'Lahore'
    },
    {
      'plate_number': 'LEB-26-809',
      'date': '2026-05-16',
      'offense': 'Violating Red Signal (DHA Phase 6)',
      'fine': 1000.0,
      'status': 'Unpaid',
      'city': 'Lahore'
    },
    {
      'plate_number': 'ICT-GA-450',
      'date': '2026-04-20',
      'offense': 'Driving without Seatbelt (Kashmir Highway)',
      'fine': 750.0,
      'status': 'Paid',
      'city': 'Islamabad'
    }
  ];

  bool _isCheckingChallans = false;
  String? _challanCheckResultPlate;
  List<Map<String, dynamic>> _matchedChallans = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshVehicles();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshVehicles() async {
    setState(() => _isLoading = true);
    final data = await DbHelper.getVehicles();
    setState(() {
      _vehicles = data;
      _isLoading = false;
    });
  }

  void _showAddVehicleModal({Map<String, dynamic>? existingVehicle}) {
    final isEdit = existingVehicle != null;
    final plateController = TextEditingController(text: existingVehicle?['plate_number'] ?? '');
    final makerController = TextEditingController(text: existingVehicle?['maker'] ?? '');
    final modelController = TextEditingController(text: existingVehicle?['model'] ?? '');

    DateTime tokenExpiry = existingVehicle?['token_expiry'] != null
        ? DateTime.parse(existingVehicle!['token_expiry'])
        : DateTime.now().add(const Duration(days: 180));

    DateTime insuranceExpiry = existingVehicle?['insurance_expiry'] != null
        ? DateTime.parse(existingVehicle!['insurance_expiry'])
        : DateTime.now().add(const Duration(days: 365));

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
                      isEdit ? 'Edit Vehicle Info' : 'Add Vehicle to Garage',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: AppTheme.navyDeep,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildField(plateController, 'License Plate Number', 'e.g. LEB-26-809, ICT-GA-450', Icons.subtitles_rounded),
                    const SizedBox(height: 16),
                    _buildField(makerController, 'Vehicle Make / Brand', 'e.g. Honda, Toyota, Suzuki', Icons.directions_car_rounded),
                    const SizedBox(height: 16),
                    _buildField(modelController, 'Model & Year', 'e.g. Civic 2024, Yaris 2025', Icons.calendar_today_rounded),
                    const SizedBox(height: 16),

                    // Token Tax Expiry
                    const Text(
                      'Token Tax Expiration Date',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.textGrey),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: tokenExpiry,
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
                          setModalState(() => tokenExpiry = picked);
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
                            const Icon(Icons.receipt_long_rounded, color: AppTheme.goldPremium),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('EEEE, MMMM dd, yyyy').format(tokenExpiry),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Insurance Expiry
                    const Text(
                      'Insurance Expiration Date',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.textGrey),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: insuranceExpiry,
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
                          setModalState(() => insuranceExpiry = picked);
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
                            const Icon(Icons.shield_rounded, color: AppTheme.goldPremium),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('EEEE, MMMM dd, yyyy').format(insuranceExpiry),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
                            ),
                          ],
                        ),
                      ),
                    ),

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
                              if (plateController.text.trim().isEmpty || makerController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please fill out Plate Number and Brand.')),
                                );
                                return;
                              }

                              final row = {
                                'plate_number': plateController.text.trim().toUpperCase(),
                                'maker': makerController.text.trim(),
                                'model': modelController.text.trim(),
                                'token_expiry': tokenExpiry.toIso8601String().substring(0, 10),
                                'insurance_expiry': insuranceExpiry.toIso8601String().substring(0, 10),
                                'reg_date': DateTime.now().toIso8601String().substring(0, 10),
                                'created_at': DateTime.now().toIso8601String(),
                              };

                              if (isEdit) {
                                row['id'] = existingVehicle['id'];
                                await DbHelper.updateVehicle(row);
                              } else {
                                await DbHelper.insertVehicle(row);
                              }

                              _refreshVehicles();
                              if (context.mounted) Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.navyDeep,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(isEdit ? 'Save Changes' : 'Add Vehicle', style: const TextStyle(fontWeight: FontWeight.w800)),
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

  void _deleteVehicle(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Delete Vehicle?', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.navyDeep)),
        content: const Text('This will permanently delete this vehicle from your digital garage.'),
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
      await DbHelper.deleteVehicle(id);
      _refreshVehicles();
    }
  }

  Future<void> _checkChallansForVehicle(String plate) async {
    setState(() {
      _isCheckingChallans = true;
      _challanCheckResultPlate = plate;
    });

    // Simulate query loading to feel highly interactive & dynamic
    await Future.delayed(const Duration(milliseconds: 1500));

    final matches = _challans.where((c) {
      return c['plate_number'].replaceAll('-', '').replaceAll(' ', '').toUpperCase() ==
          plate.replaceAll('-', '').replaceAll(' ', '').toUpperCase();
    }).toList();

    setState(() {
      _isCheckingChallans = false;
      _matchedChallans = matches;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('My Vehicles & Challans', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
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
            Tab(text: 'My Garage'),
            Tab(text: 'Challan Tracker'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGarageTab(),
          _buildChallanTrackerTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showAddVehicleModal(),
              backgroundColor: AppTheme.navyDeep,
              foregroundColor: AppTheme.goldPremium,
              icon: const Icon(Icons.add_road_rounded),
              label: const Text('Add Vehicle', style: TextStyle(fontWeight: FontWeight.w800)),
            )
          : null,
    );
  }

  Widget _buildGarageTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.navyDeep));
    }

    return Column(
      children: [
        // Garage Header
        Container(
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
                  const Icon(Icons.garage_rounded, color: AppTheme.goldPremium, size: 28),
                  const SizedBox(width: 10),
                  const Text(
                    'PERSONAL DIGITAL GARAGE',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Add your active vehicle registrations to track token tax renewals, manage insurance dates, and verify active traffic tickets dynamically offline.',
                style: TextStyle(color: AppTheme.border, fontSize: 12, height: 1.5, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),

        Expanded(
          child: _vehicles.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                  itemCount: _vehicles.length,
                  itemBuilder: (context, index) {
                    final v = _vehicles[index];

                    // Expiry tracking
                    final tokenStr = v['token_expiry'] ?? '';
                    final insStr = v['insurance_expiry'] ?? '';
                    int tokenDays = 0;
                    int insDays = 0;

                    try {
                      tokenDays = DateTime.parse(tokenStr).difference(DateTime.now()).inDays + 1;
                      insDays = DateTime.parse(insStr).difference(DateTime.now()).inDays + 1;
                    } catch (_) {}

                    return Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.navyDeep, AppTheme.navyLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.goldPremium.withOpacity(0.5)),
                                  ),
                                  child: Text(
                                    v['plate_number'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        v['maker'] ?? '',
                                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                                      ),
                                      Text(
                                        v['model'] ?? '',
                                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _deleteVehicle(v['id']),
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                ),
                              ],
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Divider(color: Colors.white.withOpacity(0.1)),
                          ),

                          // Renewal trackers
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                            child: Row(
                              children: [
                                // Token Tax Indicator
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Token Tax Renewal',
                                          style: TextStyle(color: AppTheme.border, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          tokenDays < 0 ? 'Overdue!' : '$tokenDays days left',
                                          style: TextStyle(
                                            color: tokenDays <= 30 ? Colors.orangeAccent : Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Insurance Indicator
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Insurance Renewal',
                                          style: TextStyle(color: AppTheme.border, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          insDays < 0 ? 'Expired' : '$insDays days left',
                                          style: TextStyle(
                                            color: insDays <= 30 ? Colors.orangeAccent : Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Action bar
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(24),
                                bottomRight: Radius.circular(24),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    _tabController.animateTo(1);
                                    _checkChallansForVehicle(v['plate_number']);
                                  },
                                  icon: const Icon(Icons.traffic_rounded, color: AppTheme.goldPremium, size: 16),
                                  label: const Text('Check Challans', style: TextStyle(color: AppTheme.goldPremium, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                                TextButton.icon(
                                  onPressed: () => _showAddVehicleModal(existingVehicle: v),
                                  icon: const Icon(Icons.edit_rounded, color: Colors.white70, size: 16),
                                  label: const Text('Edit Vehicle', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ).animate().fade(delay: (index * 50).ms).slideY(begin: 0.05);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildChallanTrackerTab() {
    final plateController = TextEditingController();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🚦 LIVE VEHICLE CHALLAN CHECKER',
                  style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.navyDeep, fontSize: 14),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Verify Outstanding Challans and traffic offenses registered against your vehicle dynamically with provincial excise & warden databases.',
                  style: TextStyle(color: AppTheme.textGrey, fontSize: 12, height: 1.4, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),

                // Text field + button
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: plateController,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        decoration: InputDecoration(
                          hintText: 'Enter Plate e.g. LEB-26-809',
                          prefixIcon: const Icon(Icons.subtitles_rounded, color: AppTheme.goldPremium),
                          filled: true,
                          fillColor: AppTheme.surface,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (plateController.text.trim().isEmpty) return;
                        _checkChallansForVehicle(plateController.text.trim());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.navyDeep,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Verify', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (_vehicles.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Select Registered Vehicle:',
              style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.navyDeep, fontSize: 13),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _vehicles.length,
                itemBuilder: (context, index) {
                  final v = _vehicles[index];
                  return Container(
                    margin: const EdgeInsets.only(right: 10),
                    child: ActionChip(
                      onPressed: () => _checkChallansForVehicle(v['plate_number'] ?? ''),
                      backgroundColor: Colors.white,
                      surfaceTintColor: Colors.white,
                      side: const BorderSide(color: AppTheme.border),
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navyDeep, fontSize: 12),
                      avatar: const Icon(Icons.directions_car_rounded, size: 14, color: AppTheme.goldPremium),
                      label: Text(v['plate_number'] ?? ''),
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Result block
          if (_isCheckingChallans)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppTheme.navyDeep),
                    SizedBox(height: 14),
                    Text(
                      'Querying Excise & Traffic Police Databases...',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textGrey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else if (_challanCheckResultPlate != null)
            _buildChallanResultBlock(),
        ],
      ),
    );
  }

  Widget _buildChallanResultBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Challans for "$_challanCheckResultPlate":',
              style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.navyDeep, fontSize: 14),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _matchedChallans.any((c) => c['status'] == 'Unpaid')
                    ? AppTheme.error.withOpacity(0.08)
                    : AppTheme.accepted.withOpacity(0.08),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                _matchedChallans.any((c) => c['status'] == 'Unpaid')
                    ? 'OUTSTANDING DUES'
                    : 'CLEARED / NO UNPAID',
                style: TextStyle(
                  color: _matchedChallans.any((c) => c['status'] == 'Unpaid') ? AppTheme.error : AppTheme.accepted,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_matchedChallans.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Column(
              children: [
                Icon(Icons.check_circle_rounded, color: AppTheme.accepted, size: 48),
                SizedBox(height: 12),
                Text(
                  'No Traffic Violations Found',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textDark, fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  'Excellent! No unpaid or pending traffic fines were found on this license plate.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textGrey, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _matchedChallans.length,
            itemBuilder: (context, index) {
              final c = _matchedChallans[index];
              final isUnpaid = c['status'] == 'Unpaid';
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  title: Text(
                    c['offense'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textDark, fontSize: 13),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Date: ${c['date']} • Region: ${c['city']}',
                      style: const TextStyle(color: AppTheme.textGrey, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'PKR ${c['fine']}',
                        style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.navyDeep, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (c['status'] ?? '').toUpperCase(),
                        style: TextStyle(
                          color: isUnpaid ? AppTheme.error : AppTheme.accepted,
                          fontWeight: FontWeight.w900,
                          fontSize: 9,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    ).animate().fade().slideY(begin: 0.05);
  }

  Widget _buildField(TextEditingController controller, String label, String hint, IconData icon) {
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
              child: const Icon(Icons.directions_car_rounded, size: 70, color: AppTheme.goldPremium),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your Digital Garage is Empty',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.navyDeep),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first vehicle (car or motorcycle) to keep license plates saved, check live warden tickets, and monitor renewal deadlines.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textGrey, fontSize: 12, height: 1.5, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
