import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qanoon_buddy/core/theme.dart';
import 'package:qanoon_buddy/core/api_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CitizenAppDashboard extends StatefulWidget {
  const CitizenAppDashboard({super.key});

  @override
  State<CitizenAppDashboard> createState() => _CitizenAppDashboardState();
}

class _CitizenAppDashboardState extends State<CitizenAppDashboard> {
  final ApiService apiService = ApiService();
  bool _isLoadingRadar = true;
  int _trafficCount = 0;
  int _powerCount = 0;
  int _crimeCount = 0;
  int _otherCount = 0;
  
  String _selectedArea = 'All';
  final List<String> _radarAreas = [
    'All',
    'Gulshan-e-Iqbal',
    'Clifton & DHA',
    'Gulistan-e-Johar',
    'North Nazimabad',
    'Saddar & Lyari',
    'Federal B. Area',
    'Korangi & Landhi',
    'Malir & Shah Faisal',
    'Orangi & SITE',
    'North Karachi & Surjani',
    'Scheme 33 & University Road',
    'Bahria & Super Highway',
    'Kemari & Port Area',
    'Shah Faisal & Airport',
    'Garden & Bahadurabad',
  ];

  @override
  void initState() {
    super.initState();
    _fetchRadarData();
  }

  Future<void> _fetchRadarData() async {
    setState(() => _isLoadingRadar = true);
    try {
      final incidents = await apiService.fetchLiveIncidents(area: _selectedArea == 'All' ? null : _selectedArea);
      int traffic = 0;
      int power = 0;
      int crime = 0;
      int other = 0;

      for (var inc in incidents) {
        final type = (inc['incident_type'] ?? '').toString().toLowerCase();
        if (type.contains('traffic') || type.contains('road') || type.contains('accident')) {
          traffic++;
        } else if (type.contains('power') || type.contains('electricity') || type.contains('water') || type.contains('fire')) {
          power++;
        } else if (type.contains('crime') || type.contains('robbery') || type.contains('snatching') || type.contains('shooting')) {
          crime++;
        } else {
          other++;
        }
      }

      if (mounted) {
        setState(() {
          _trafficCount = traffic;
          _powerCount = power;
          _crimeCount = crime;
          _otherCount = other;
          _isLoadingRadar = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRadar = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB), // Slightly cooler off-white
      appBar: AppBar(
        title: const Text(
          'Karachi Citizen App',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppTheme.navyDeep,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppTheme.navyDeep),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radar Summary Dark Container
            GestureDetector(
              onTap: () => context.push('/karachi-live-map'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF151923), Color(0xFF1E2433)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF151923).withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 40), // Balance for centering text
                        const Expanded(
                          child: Text(
                            "Stay updated, har waqt rakhein.\nBe safe.",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        // Area Selector Dropdown
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.location_on_rounded, color: Colors.white70, size: 20),
                          tooltip: 'Select Area',
                          color: const Color(0xFF1E2433),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          onSelected: (String area) {
                            setState(() {
                              _selectedArea = area;
                            });
                            _fetchRadarData();
                          },
                          itemBuilder: (BuildContext context) {
                            return _radarAreas.map((String area) {
                              return PopupMenuItem<String>(
                                value: area,
                                child: Text(
                                  area,
                                  style: TextStyle(
                                    color: _selectedArea == area ? AppTheme.goldPremium : Colors.white,
                                    fontWeight: _selectedArea == area ? FontWeight.w800 : FontWeight.normal,
                                  ),
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),
                    const SizedBox(height: 12),
                    const Text(
                      "🙏",
                      style: TextStyle(fontSize: 24),
                    )
                        .animate(onPlay: (controller) => controller.repeat(reverse: true))
                        .scaleXY(begin: 1.0, end: 1.15, duration: 1000.ms, curve: Curves.easeInOut),
                    const SizedBox(height: 24),
                    if (_isLoadingRadar)
                      const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 32), child: CircularProgressIndicator(color: AppTheme.goldPremium)))
                          .animate()
                          .fadeIn()
                    else
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 2.2, // Tweak this for height
                        children: [
                          _buildStatCard('Traffic', _trafficCount.toString(), Icons.directions_car_rounded, Colors.orangeAccent)
                              .animate()
                              .fadeIn(delay: 100.ms)
                              .slideX(begin: -0.1),
                          _buildStatCard('Power', _powerCount.toString(), Icons.bolt_rounded, Colors.amber)
                              .animate()
                              .fadeIn(delay: 150.ms)
                              .slideX(begin: 0.1),
                          _buildStatCard('Crime', _crimeCount.toString(), Icons.warning_rounded, Colors.redAccent)
                              .animate()
                              .fadeIn(delay: 200.ms)
                              .slideX(begin: -0.1),
                          _buildStatCard('Other', _otherCount.toString(), Icons.info_outline_rounded, Colors.lightBlue)
                              .animate()
                              .fadeIn(delay: 250.ms)
                              .slideX(begin: 0.1),
                        ],
                      ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 600.ms).scaleXY(begin: 0.95, end: 1.0, curve: Curves.easeOutBack),
            
            const SizedBox(height: 28),
            
            // Red Banner for CPLC Recovery
            GestureDetector(
              onTap: () => context.push('/cplc-recovery'),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.error.withValues(alpha: 0.9), AppTheme.error],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(color: AppTheme.error.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 12))],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                            child: const Text('EMERGENCY ACTION', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                          ),
                          const SizedBox(height: 16),
                          const Text('🚨 JUST GOT ROBBED?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5)),
                          const SizedBox(height: 8),
                          Text('Tap here to instantly block SIMs, PTA IMEI, and auto-generate CPLC complaints.', 
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w600, height: 1.5)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))]),
                      child: const Icon(Icons.arrow_forward_rounded, color: AppTheme.error, size: 28)
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .slideX(begin: 0, end: 0.2, duration: 800.ms, curve: Curves.easeInOut),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
            
            const SizedBox(height: 32),
            
            // Essential Services Header
            const Text(
              'Essential Services',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.navyDeep,
                letterSpacing: -0.5,
              ),
            ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.05, end: 0),
            
            const SizedBox(height: 20),
            
            // Cards Grid
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildServiceCard(
                      context,
                      title: 'Live Map',
                      subtitle: 'Real-time updates',
                      icon: Icons.map_outlined,
                      iconColor: Colors.orange,
                      route: '/karachi-live-map',
                      delay: 450,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildServiceCard(
                      context,
                      title: 'Safe Route',
                      subtitle: 'AI navigation',
                      icon: Icons.route_rounded,
                      iconColor: Colors.teal,
                      route: '/ai-route-advisor',
                      delay: 550,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildServiceCard(
                      context,
                      title: 'Citizen Portal',
                      subtitle: 'Govt services',
                      icon: Icons.room_service_rounded,
                      iconColor: Colors.lightBlue,
                      route: '/citizen-services',
                      delay: 650,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildServiceCard(
                      context,
                      title: 'Smart Govt',
                      subtitle: 'Crowd tracker',
                      icon: Icons.account_balance_rounded,
                      iconColor: Colors.indigo,
                      route: '/smart-govt-office',
                      delay: 750,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF202431),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String route,
    required int delay,
  }) {
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(24),
      splashColor: iconColor.withValues(alpha: 0.1),
      highlightColor: iconColor.withValues(alpha: 0.05),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.navyDeep.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: AppTheme.navyDeep.withValues(alpha: 0.03),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [iconColor.withValues(alpha: 0.8), iconColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, size: 34, color: Colors.white),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppTheme.navyDeep,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay.ms, duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
  }
}
