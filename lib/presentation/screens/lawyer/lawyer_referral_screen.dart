import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api_service.dart';

class LawyerReferralScreen extends StatefulWidget {
  const LawyerReferralScreen({Key? key}) : super(key: key);

  @override
  State<LawyerReferralScreen> createState() => _LawyerReferralScreenState();
}

class _LawyerReferralScreenState extends State<LawyerReferralScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _network = [];
  List<dynamic> _sentReferrals = [];
  List<dynamic> _receivedReferrals = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      if (token == null) throw Exception("Unauthorized");

      final network = await _apiService.getNetworkLawyers(token);
      final sent = await _apiService.getSentReferrals(token);
      final received = await _apiService.getReceivedReferrals(token);

      setState(() {
        _network = network;
        _sentReferrals = sent;
        _receivedReferrals = received;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load referral data: $e')),
        );
      }
    }
  }

  Future<void> _respondToReferral(String referralId, String status) async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      await _apiService.respondToReferral(referralId, status == "accepted", token!);
      _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lawyer Network & Referrals'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'My Network'),
              Tab(text: 'Received'),
              Tab(text: 'Sent'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _network.isEmpty
                      ? const Center(child: Text("No lawyers in your network yet."))
                      : ListView.builder(
                          itemCount: _network.length,
                          itemBuilder: (context, index) {
                            final lawyer = _network[index];
                            return ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.person)),
                              title: Text(lawyer['full_name'] ?? 'Lawyer'),
                              subtitle: Text(lawyer['specialization'] ?? 'General'),
                              trailing: IconButton(
                                icon: const Icon(Icons.send),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Send Referral feature coming soon!")));
                                },
                              ),
                            );
                          },
                        ),
                  _receivedReferrals.isEmpty
                      ? const Center(child: Text("No received referrals."))
                      : ListView.builder(
                          itemCount: _receivedReferrals.length,
                          itemBuilder: (context, index) {
                            final ref = _receivedReferrals[index];
                            return Card(
                              margin: const EdgeInsets.all(8),
                              child: ListTile(
                                title: Text('From: ${ref['from_lawyer_name'] ?? 'Unknown'}'),
                                subtitle: Text('Case: ${ref['case_description'] ?? 'No description'}'),
                                trailing: ref['status'] == 'pending'
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                              icon: const Icon(Icons.check, color: Colors.green),
                                              onPressed: () => _respondToReferral(ref['id'], "accepted")),
                                          IconButton(
                                              icon: const Icon(Icons.close, color: Colors.red),
                                              onPressed: () => _respondToReferral(ref['id'], "declined")),
                                        ],
                                      )
                                    : Text(ref['status']),
                              ),
                            );
                          },
                        ),
                  _sentReferrals.isEmpty
                      ? const Center(child: Text("No sent referrals."))
                      : ListView.builder(
                          itemCount: _sentReferrals.length,
                          itemBuilder: (context, index) {
                            final ref = _sentReferrals[index];
                            return Card(
                              margin: const EdgeInsets.all(8),
                              child: ListTile(
                                title: Text('To: ${ref['to_lawyer_name'] ?? 'Unknown'}'),
                                subtitle: Text('Status: ${ref['status']}'),
                              ),
                            );
                          },
                        ),
                ],
              ),
      ),
    );
  }
}
