import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:qanoon_buddy/core/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qanoon_buddy/core/api_service.dart';
import 'package:qanoon_buddy/data/auth_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class KarachiLiveMapScreen extends ConsumerStatefulWidget {
  const KarachiLiveMapScreen({super.key});

  @override
  ConsumerState<KarachiLiveMapScreen> createState() => _KarachiLiveMapScreenState();
}

class _KarachiLiveMapScreenState extends ConsumerState<KarachiLiveMapScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MapController _mapController = MapController();
  Timer? _refreshTimer;
  bool _isMapReady = false;
  
  String _selectedArea = 'All';
  String _summaryText = 'Loading AI Radar Summary...';
  bool _isLoadingSummary = true;
  bool _isLoadingIncidents = true;
  
  List<dynamic> _incidents = [];

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

  // Coordinates lookup for Karachi neighborhoods
  static const Map<String, LatLng> _areaCoordinates = {
    'Gulshan-e-Iqbal': LatLng(24.9180, 67.0971),
    'Clifton & DHA': LatLng(24.8052, 67.0543),
    'Gulistan-e-Johar': LatLng(24.9300, 67.1250),
    'North Nazimabad': LatLng(24.9372, 67.0343),
    'Saddar & Lyari': LatLng(24.8607, 67.0011),
    'Federal B. Area': LatLng(24.9284, 67.0681),
    'Korangi & Landhi': LatLng(24.8322, 67.1350),
    'Malir & Shah Faisal': LatLng(24.8900, 67.1900),
    'Orangi & SITE': LatLng(24.9550, 67.0150),
    'North Karachi & Surjani': LatLng(25.0100, 67.0500),
    'Scheme 33 & University Road': LatLng(24.9100, 67.1100),
    'Bahria & Super Highway': LatLng(25.0600, 67.1800),
    'Kemari & Port Area': LatLng(24.8450, 66.9850),
    'Shah Faisal & Airport': LatLng(24.8700, 67.1500),
    'Garden & Bahadurabad': LatLng(24.8750, 67.0500),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSavedAreaAndFetch();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (mounted) _fetchRadarData(isBackground: true);
    });
  }

  Future<void> _loadSavedAreaAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final savedArea = prefs.getString('radar_area');
    if (savedArea != null && mounted) {
      setState(() {
        _selectedArea = savedArea;
      });
    }
    _fetchRadarData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchRadarData({bool isBackground = false}) async {
    if (mounted && !isBackground) {
      setState(() {
        _isLoadingSummary = true;
        _isLoadingIncidents = true;
      });
    }
    
    try {
      final token = ref.read(authProvider).token;
      final incidents = await apiService.fetchLiveIncidents(area: _selectedArea, token: token);
      final summary = await apiService.fetchRadarSummary(_selectedArea);
      
      if (mounted) {
        setState(() {
          _incidents = incidents;
          _summaryText = summary;
          _isLoadingSummary = false;
          _isLoadingIncidents = false;
        });
      }

      // Move map to the center of the selected area if map controller is ready
      if (_isMapReady) {
        final center = _areaCoordinates[_selectedArea] ?? const LatLng(24.8607, 67.0011);
        _mapController.move(center, 13.5);
      }
    } catch (e) {
      debugPrint('Error fetching radar data: $e');
      if (mounted) {
        setState(() {
          _isLoadingSummary = false;
          _isLoadingIncidents = false;
        });
      }
    }
  }

  Future<void> _handleVote(String incidentId, String action) async {
    final token = ref.read(authProvider).token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to verify/vote on incidents'))
      );
      return;
    }

    // Optimistic UI Update
    final index = _incidents.indexWhere((i) => i['id'].toString() == incidentId);
    if (index != -1 && mounted) {
      setState(() {
        final currentVoteDir = _incidents[index]['user_vote_dir'] ?? 0;
        if (action == 'upvote') {
           if (currentVoteDir == 1) {
              _incidents[index]['user_vote_dir'] = 0;
              _incidents[index]['upvotes'] = (_incidents[index]['upvotes'] ?? 1) - 1;
           } else {
              if (currentVoteDir == -1) {
                _incidents[index]['downvotes'] = (_incidents[index]['downvotes'] ?? 1) - 1;
              }
              _incidents[index]['user_vote_dir'] = 1;
              _incidents[index]['upvotes'] = (_incidents[index]['upvotes'] ?? 0) + 1;
           }
        } else {
           if (currentVoteDir == -1) {
              _incidents[index]['user_vote_dir'] = 0;
              _incidents[index]['downvotes'] = (_incidents[index]['downvotes'] ?? 1) - 1;
           } else {
              if (currentVoteDir == 1) {
                _incidents[index]['upvotes'] = (_incidents[index]['upvotes'] ?? 1) - 1;
              }
              _incidents[index]['user_vote_dir'] = -1;
              _incidents[index]['downvotes'] = (_incidents[index]['downvotes'] ?? 0) + 1;
           }
        }
      });
    }

    try {
      final response = await apiService.voteIncident(
        incidentId: incidentId,
        action: action,
        token: token,
      );
      // Silent sync with server numbers
      if (mounted) {
        setState(() {
          final idx = _incidents.indexWhere((i) => i['id'].toString() == incidentId);
          if (idx != -1) {
            _incidents[idx]['upvotes'] = response['upvotes'];
            _incidents[idx]['downvotes'] = response['downvotes'];
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to vote: $e'))
      );
    }
  }

  final Map<String, List<String>> _subAreasMap = {
    'Gulshan-e-Iqbal': ['NIPA', 'Maskan', 'Disco Bakery'],
    'Gulistan-e-Johar': ['Johar Mor', 'Perfume Chowk'],
    'Clifton & DHA': ['Teen Talwar', 'Boat Basin'],
    'Saddar & Lyari': ['II Chundrigar Road', 'M.A. Jinnah Road'],
    'Scheme 33 & University Road': ['University Road'],
    'Shah Faisal & Airport': ['Shahrah-e-Faisal'],
    'Garden & Bahadurabad': ['Tariq Road', 'Shahra-e-Quaideen'],
    'Federal B. Area': ['Rashid Minhas Road'],
    'Kemari & Port Area': ['Hub River Road'],
  };

  void _showReportDialog() {
    final token = ref.read(authProvider).token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to report incidents'))
      );
      return;
    }

    String selectedType = 'roadblock';
    String reportArea = _selectedArea;
    String? reportSubArea;
    int reportSeverity = 3;
    final TextEditingController descController = TextEditingController();
    bool useLiveLocation = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E2235),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Report Live Incident', 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      dropdownColor: const Color(0xFF1E2235),
                      style: const TextStyle(color: Colors.white),
                      iconEnabledColor: Colors.white54,
                      items: const [
                        DropdownMenuItem(value: 'roadblock', child: Text('Roadblock', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'protest', child: Text('Protest', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'snatching', child: Text('Snatching / Robbery', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'crime', child: Text('Crime', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'shooting', child: Text('Shooting', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'power_outage', child: Text('Power Outage', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'water_issue', child: Text('Water Crisis', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'fire', child: Text('Fire', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'accident', child: Text('Accident', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'other_emergency', child: Text('Other Emergency', style: TextStyle(color: Colors.white))),
                      ],
                      onChanged: (v) => setDialogState(() => selectedType = v!),
                      decoration: InputDecoration(
                        labelText: 'Incident Type',
                        labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFF282D45),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.goldPremium, width: 1.2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: reportArea,
                      dropdownColor: const Color(0xFF1E2235),
                      style: const TextStyle(color: Colors.white),
                      iconEnabledColor: Colors.white54,
                      isExpanded: true,
                      items: _radarAreas.map((area) => DropdownMenuItem(
                        value: area,
                        child: Text(area, style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (v) {
                        setDialogState(() {
                          reportArea = v!;
                          reportSubArea = null;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Select Area',
                        labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFF282D45),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.goldPremium, width: 1.2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_subAreasMap.containsKey(reportArea)) ...[
                      DropdownButtonFormField<String>(
                        value: reportSubArea,
                        dropdownColor: const Color(0xFF1E2235),
                        style: const TextStyle(color: Colors.white),
                        iconEnabledColor: Colors.white54,
                        isExpanded: true,
                        hint: const Text('Select Sub-Area (Optional)', style: TextStyle(color: Colors.white60)),
                        items: _subAreasMap[reportArea]!.map((sa) => DropdownMenuItem(
                          value: sa,
                          child: Text(sa, style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis),
                        )).toList(),
                        onChanged: (v) => setDialogState(() => reportSubArea = v),
                        decoration: InputDecoration(
                          labelText: 'Sub-Area',
                          labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFF282D45),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.goldPremium, width: 1.2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    DropdownButtonFormField<int>(
                      value: reportSeverity,
                      dropdownColor: const Color(0xFF1E2235),
                      style: const TextStyle(color: Colors.white),
                      iconEnabledColor: Colors.white54,
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('1 - Minor', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 2, child: Text('2 - Noticeable', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 3, child: Text('3 - Moderate', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 4, child: Text('4 - Severe', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 5, child: Text('5 - Critical', style: TextStyle(color: Colors.white))),
                      ],
                      onChanged: (v) => setDialogState(() => reportSeverity = v!),
                      decoration: InputDecoration(
                        labelText: 'Severity',
                        labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFF282D45),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.goldPremium, width: 1.2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Details / Landmark',
                        labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
                        hintText: 'e.g. Protest at Nursery near Metro bus stop',
                        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFF282D45),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.goldPremium, width: 1.2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: useLiveLocation,
                          activeColor: AppTheme.goldPremium,
                          checkColor: Colors.black,
                          side: const BorderSide(color: Colors.white60),
                          onChanged: (v) => setDialogState(() => useLiveLocation = v ?? false),
                        ),
                        const Expanded(
                          child: Text('Use current GPS location coordinates', 
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx), 
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54))
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      LatLng defaultCoords = _areaCoordinates[reportArea] ?? const LatLng(24.8607, 67.0011);
                      double lat = defaultCoords.latitude;
                      double lng = defaultCoords.longitude;

                      if (useLiveLocation) {
                        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                        if (!serviceEnabled) {
                          throw Exception('Location services are disabled.');
                        }
                        LocationPermission permission = await Geolocator.checkPermission();
                        if (permission == LocationPermission.denied) {
                          permission = await Geolocator.requestPermission();
                          if (permission == LocationPermission.denied) {
                            throw Exception('Location permissions are denied');
                          }
                        }
                        if (permission == LocationPermission.deniedForever) {
                          throw Exception('Location permissions permanently denied.');
                        }
                        Position position = await Geolocator.getCurrentPosition();
                        lat = position.latitude;
                        lng = position.longitude;
                      }

                      await apiService.reportIncident(
                        type: selectedType,
                        description: descController.text,
                        area: reportArea,
                        subArea: reportSubArea,
                        severity: reportSeverity,
                        lat: lat,
                        lng: lng,
                        token: token,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Incident reported successfully!'))
                      );
                      
                      if (reportArea == _selectedArea) {
                        _fetchRadarData(); // Refresh current radar view
                      } else {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('radar_area', reportArea);
                        setState(() {
                          _selectedArea = reportArea;
                        });
                        _fetchRadarData();
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed: $e'))
                      );
                    }
                  },
                  child: const Text('Submit Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  List<Marker> _getMarkers() {
    return _incidents.map((incident) {
      final type = incident['incident_type'];
      IconData icon;
      Color color;
      
      if (type == 'snatching' || type == 'crime' || type == 'shooting') {
        icon = type == 'shooting' ? Icons.local_police_rounded : Icons.warning_rounded;
        color = Colors.redAccent;
      } else if (type == 'power_outage') {
        icon = Icons.bolt_rounded;
        color = Colors.amber;
      } else if (type == 'water_issue') {
        icon = Icons.water_drop_rounded;
        color = Colors.blueAccent;
      } else if (type == 'fire') {
        icon = Icons.local_fire_department_rounded;
        color = Colors.deepOrangeAccent;
      } else if (type == 'protest') {
        icon = Icons.campaign_rounded;
        color = Colors.amberAccent;
      } else if (type == 'accident') {
        icon = Icons.car_crash_rounded;
        color = Colors.orange;
      } else if (type == 'other_emergency') {
        icon = Icons.info_outline_rounded;
        color = Colors.lightBlue;
      } else {
        icon = Icons.block_rounded;
        color = Colors.orangeAccent;
      }

      final lat = incident['latitude'] ?? 24.8607;
      final lng = incident['longitude'] ?? 67.0011;

      return Marker(
        point: LatLng(lat, lng),
        width: 45,
        height: 45,
        child: GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF1E2235),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Row(
                  children: [
                    Icon(icon, color: color, size: 24),
                    const SizedBox(width: 8),
                    Text(type.toString().toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                content: Text(
                  incident['description'] ?? 'No description.', 
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: AppTheme.goldPremium))),
                ],
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final center = _areaCoordinates[_selectedArea] ?? const LatLng(24.8607, 67.0011);
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F111D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F111D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              backgroundColor: const Color(0xFF1E2235),
              builder: (ctx) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Select Neighborhood', 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                      const SizedBox(height: 16),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _radarAreas.length,
                          itemBuilder: (context, index) {
                            final area = _radarAreas[index];
                            final isSelected = area == _selectedArea;
                            return ListTile(
                              onTap: () async {
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setString('radar_area', area);
                                setState(() {
                                  _selectedArea = area;
                                });
                                _fetchRadarData();
                                if (context.mounted) Navigator.pop(ctx);
                              },
                              title: Text(area, 
                                style: TextStyle(
                                  color: isSelected ? AppTheme.goldPremium : Colors.white70,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.normal,
                                )),
                              trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.goldPremium) : null,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, color: AppTheme.goldPremium, size: 20),
              const SizedBox(width: 6),
              Text(_selectedArea, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
              const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white60, size: 20),
            ],
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.goldPremium,
          labelColor: AppTheme.goldPremium,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: '📋 Active Feeds'),
            Tab(text: '🗺️ Radar Map'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Prevent sliding tabs with map gestures
        children: [
          // ── Tab 1: Active Feeds ──
          RefreshIndicator(
            onRefresh: _fetchRadarData,
            color: AppTheme.goldPremium,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // AI Summary Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.goldPremium.withOpacity(0.35), width: 1.2),
                    boxShadow: [
                      BoxShadow(color: AppTheme.goldPremium.withOpacity(0.05), blurRadius: 10),
                    ],
                  ),
                  child: _isLoadingSummary
                      ? Shimmer.fromColors(
                          baseColor: Colors.white.withOpacity(0.05),
                          highlightColor: Colors.white.withOpacity(0.15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(height: 12, color: Colors.white, width: double.infinity),
                              const SizedBox(height: 6),
                              Container(height: 12, color: Colors.white, width: 220),
                            ],
                          ),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.auto_awesome, color: AppTheme.goldPremium, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('AI SURVIVAL FORECAST', 
                                    style: TextStyle(color: AppTheme.goldPremium, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                                  const SizedBox(height: 6),
                                  Text(
                                    _summaryText,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('CITIZEN REPORTS', 
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
                    Text('${_incidents.length} Active alerts', 
                      style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                
                if (_isLoadingIncidents)
                  Column(
                    children: List.generate(3, (index) => Shimmer.fromColors(
                      baseColor: Colors.white.withOpacity(0.05),
                      highlightColor: Colors.white.withOpacity(0.12),
                      child: Container(
                        height: 100,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      ),
                    )),
                  )
                else if (_incidents.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    alignment: Alignment.center,
                    child: const Column(
                      children: [
                        Icon(Icons.shield_outlined, color: Colors.white24, size: 48),
                        SizedBox(height: 12),
                        Text('All quiet here! No alerts reported in this area.', 
                          style: TextStyle(color: Colors.white38, fontSize: 13)),
                      ],
                    ),
                  )
                else ...[
                  if (_selectedArea != 'All') ...[
                    if (_incidents.any((i) => i['area'] == _selectedArea))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text('📍 $_selectedArea Reports', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ..._incidents.where((i) => i['area'] == _selectedArea).map((incident) => _buildIncidentCard(incident)),
                    
                    if (_incidents.any((i) => i['area'] != _selectedArea)) ...[
                      const Padding(
                        padding: EdgeInsets.only(top: 16, bottom: 12),
                        child: Text('🌐 Other Karachi News', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      ..._incidents.where((i) => i['area'] != _selectedArea).map((incident) => _buildIncidentCard(incident)),
                    ]
                  ] else ...[
                    ..._incidents.map((incident) => _buildIncidentCard(incident)),
                  ]
                ],
              ],
            ),
          ),

          // ── Tab 2: Radar Map View ──
          Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 13.5,
                  maxZoom: 18.0,
                  onMapReady: () {
                    _isMapReady = true;
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.qanoonbuddy.app',
                  ),
                  MarkerLayer(
                    markers: _getMarkers(),
                  ),
                ],
              ),
              
              // Map Overlay showing selected Area Status
              Positioned(
                top: 16, left: 16, right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2235).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.radar, color: AppTheme.goldPremium, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _isLoadingIncidents 
                            ? 'Syncing reports...' 
                            : 'Radar scanning $_selectedArea. ${_incidents.length} active reports detected.',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showReportDialog,
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.add_alert_rounded, color: Colors.white),
        label: const Text('Report Incident', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  String _formatRelativeTime(String isoString) {
    try {
      final utcString = isoString.endsWith('Z') ? isoString : '${isoString}Z';
      final dt = DateTime.parse(utcString).toLocal();
      final diff = DateTime.now().difference(dt);
      
      if (diff.isNegative) return 'Just now';
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} m ago';
      if (diff.inHours < 24) return '${diff.inHours} h ago';
      return '${diff.inDays} d ago';
    } catch (_) {
      return 'Just now';
    }
  }

  Map<String, String> _parseSourceAndDescription(String rawDesc) {
    if (rawDesc.startsWith('[') && rawDesc.contains(']')) {
      final closeBracketIdx = rawDesc.indexOf(']');
      final source = rawDesc.substring(1, closeBracketIdx);
      final cleanDesc = rawDesc.substring(closeBracketIdx + 1).trim();
      return {'source': source, 'description': cleanDesc};
    }
    return {'source': 'Citizen Report', 'description': rawDesc};
  }

  Widget _buildSourceBadge(String source) {
    Color badgeColor = Colors.white24;
    IconData icon = Icons.info_outline;

    if (source.contains('Google News')) {
      badgeColor = Colors.blueAccent;
      icon = Icons.newspaper_rounded;
    } else if (source.contains('Reddit')) {
      badgeColor = Colors.deepOrangeAccent;
      icon = Icons.forum_rounded;
    } else if (source.contains('Twitter') || source.contains('X')) {
      badgeColor = Colors.lightBlueAccent;
      icon = Icons.chat_bubble_outline_rounded;
    } else if (source.contains('Facebook')) {
      badgeColor = const Color(0xFF1877F2);
      icon = Icons.groups_rounded;
    } else if (source.contains('Instagram')) {
      badgeColor = Colors.pinkAccent;
      icon = Icons.camera_alt_rounded;
    } else if (source.contains('Citizen Report')) {
      badgeColor = Colors.greenAccent;
      icon = Icons.person_pin_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withOpacity(0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: badgeColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              source,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                color: badgeColor,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentCard(dynamic incident) {
    final type = incident['incident_type'];
    final rawDesc = incident['description'] ?? 'No Details';
    final parsed = _parseSourceAndDescription(rawDesc);
    final source = parsed['source']!;
    final desc = parsed['description']!;
    final subArea = incident['sub_area'];
    final severity = incident['severity'] ?? 1;
    final upvotes = incident['upvotes'] ?? 0;
    final downvotes = incident['downvotes'] ?? 0;
    
    IconData icon;
    Color color;
    if (type == 'snatching' || type == 'crime' || type == 'shooting') {
      icon = type == 'shooting' ? Icons.local_police_rounded : Icons.warning_rounded;
      color = Colors.redAccent;
    } else if (type == 'power_outage') {
      icon = Icons.bolt_rounded;
      color = Colors.amber;
    } else if (type == 'water_issue') {
      icon = Icons.water_drop_rounded;
      color = Colors.blueAccent;
    } else if (type == 'fire') {
      icon = Icons.local_fire_department_rounded;
      color = Colors.deepOrangeAccent;
    } else if (type == 'protest') {
      icon = Icons.campaign_rounded;
      color = Colors.amberAccent;
    } else if (type == 'accident') {
      icon = Icons.car_crash_rounded;
      color = Colors.orange;
    } else if (type == 'other_emergency') {
      icon = Icons.info_outline_rounded;
      color = Colors.lightBlue;
    } else {
      icon = Icons.block_rounded;
      color = Colors.orangeAccent;
    }
    
    final String timeStr = incident['created_at'] != null 
      ? _formatRelativeTime(incident['created_at'].toString())
      : 'Just now';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(type.toString().toUpperCase().replaceAll('_', ' '), 
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
                    Text(timeStr, style: const TextStyle(color: Colors.white30, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildSourceBadge(source),
                    if (subArea != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purpleAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
                        ),
                        child: Text(subArea, style: const TextStyle(color: Colors.purpleAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (index) => Icon(
                        index < severity ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: index < severity ? AppTheme.goldPremium : Colors.white24,
                        size: 12,
                      )),
                    )
                  ],
                ),
                const SizedBox(height: 8),
            Text(
              desc,
              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
            ),
            const SizedBox(height: 8),
                // Upvote / Downvote actions
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (incident['id'] != null) {
                          _handleVote(incident['id'].toString(), 'upvote');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: (incident['user_vote_dir'] == 1) 
                              ? Colors.greenAccent.withValues(alpha: 0.2) 
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: (incident['user_vote_dir'] == 1) 
                              ? Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)) 
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.thumb_up_rounded, color: (incident['user_vote_dir'] == 1) ? Colors.greenAccent : Colors.white54, size: 14),
                            const SizedBox(width: 6),
                            Text('$upvotes', style: TextStyle(color: (incident['user_vote_dir'] == 1) ? Colors.greenAccent : Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        if (incident['id'] != null) {
                          _handleVote(incident['id'].toString(), 'downvote');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: (incident['user_vote_dir'] == -1) 
                              ? Colors.redAccent.withValues(alpha: 0.2) 
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: (incident['user_vote_dir'] == -1) 
                              ? Border.all(color: Colors.redAccent.withValues(alpha: 0.5)) 
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.thumb_down_rounded, color: (incident['user_vote_dir'] == -1) ? Colors.redAccent : Colors.white54, size: 14),
                            const SizedBox(width: 6),
                            Text('$downvotes', style: TextStyle(color: (incident['user_vote_dir'] == -1) ? Colors.redAccent : Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text('Verify report', style: TextStyle(color: Colors.white30, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
