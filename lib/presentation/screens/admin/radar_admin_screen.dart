import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qanoon_buddy/core/api_service.dart';
import 'package:qanoon_buddy/data/auth_provider.dart';
import 'package:qanoon_buddy/core/theme.dart';
import 'package:intl/intl.dart';

class RadarAdminScreen extends ConsumerStatefulWidget {
  const RadarAdminScreen({super.key});

  @override
  ConsumerState<RadarAdminScreen> createState() => _RadarAdminScreenState();
}

class _RadarAdminScreenState extends ConsumerState<RadarAdminScreen> {
  List<dynamic> _incidents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchIncidents();
  }

  Future<void> _fetchIncidents() async {
    setState(() => _isLoading = true);
    try {
      final token = ref.read(authProvider).token!;
      final data = await apiService.getAllRadarIncidents(token);
      setState(() {
        _incidents = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _verifyIncident(String id) async {
    try {
      final token = ref.read(authProvider).token!;
      await apiService.verifyRadarIncident(id, token);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incident verified!'), backgroundColor: Colors.green));
      _fetchIncidents();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _deleteIncident(String id) async {
    try {
      final token = ref.read(authProvider).token!;
      await apiService.deleteRadarIncident(id, token);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incident deleted!')));
      _fetchIncidents();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Radar Admin Panel', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppTheme.navyDeep,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _incidents.isEmpty
              ? const Center(child: Text('No incidents found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _incidents.length,
                  itemBuilder: (context, index) {
                    final incident = _incidents[index];
                    final date = incident['created_at'] != null 
                        ? DateFormat.yMMMd().add_jm().format(DateTime.parse(incident['created_at']).toLocal())
                        : 'Unknown Date';
                    
                    final isVerified = incident['verified'] == true;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    incident['title'] ?? 'No Title',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                if (isVerified)
                                  const Icon(Icons.verified, color: Colors.green)
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Area: ${incident['area'] ?? 'Unknown Area'}', style: const TextStyle(color: AppTheme.navyDeep, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Date: $date', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 12),
                            Text(incident['summary'] ?? 'No Description provided.'),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (!isVerified)
                                  ElevatedButton.icon(
                                    onPressed: () => _verifyIncident(incident['id'].toString()),
                                    icon: const Icon(Icons.check),
                                    label: const Text('Verify'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteIncident(incident['id'].toString()),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
