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

      final network = await _apiService.getMyNetwork(token);
      final sent = await _apiService.getSentReferrals(token);
      final received = await _apiService.getIncomingReferrals(token);

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
      if (token == null) throw Exception("Unauthorized");
      await _apiService.respondToReferral(referralId, status == "accepted", token);
      _fetchData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _showSendReferralDialog(Map<String, dynamic> lawyer) async {
    final TextEditingController _descController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send Referral to ${lawyer['name'] ?? lawyer['full_name'] ?? 'Lawyer'}'),
        content: TextField(
          controller: _descController,
          decoration: const InputDecoration(labelText: 'Case Description'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_descController.text.isEmpty) return;
              Navigator.pop(context);
              try {
                const storage = FlutterSecureStorage();
                final token = await storage.read(key: 'auth_token');
                if (token == null) throw Exception("Unauthorized");
                await _apiService.sendReferral(
                  toLawyerId: lawyer['lawyer_id'],
                  caseDescription: _descController.text,
                  token: token,
                );
                _fetchData();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Referral sent successfully')));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
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
                              title: Text(lawyer['name'] ?? lawyer['full_name'] ?? 'Lawyer'),
                              subtitle: Text(lawyer['specialization'] ?? 'General'),
                              trailing: IconButton(
                                icon: const Icon(Icons.send),
                                onPressed: () => _showSendReferralDialog(lawyer),
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
                                subtitle: Text('Case: ${ref['referral']['case_description'] ?? 'No description'}'),
                                trailing: ref['referral']['status'] == 'pending'
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                              icon: const Icon(Icons.check, color: Colors.green),
                                              onPressed: () => _respondToReferral(ref['referral']['id'], "accepted")),
                                          IconButton(
                                              icon: const Icon(Icons.close, color: Colors.red),
                                              onPressed: () => _respondToReferral(ref['referral']['id'], "declined")),
                                        ],
                                      )
                                    : Text(ref['referral']['status']),
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
                                subtitle: Text('Status: ${ref['referral']['status']}'),
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
