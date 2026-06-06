import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api_service.dart';

class AIClientSummaryScreen extends StatefulWidget {
  final String consultationId;
  final String clientName;
  final String querySummary;

  const AIClientSummaryScreen({
    Key? key,
    required this.consultationId,
    required this.clientName,
    required this.querySummary,
  }) : super(key: key);

  @override
  State<AIClientSummaryScreen> createState() => _AIClientSummaryScreenState();
}

class _AIClientSummaryScreenState extends State<AIClientSummaryScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  void _fetchSummary() async {
    setState(() => _isLoading = true);
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      if (token == null) throw Exception("Unauthorized");

      final summary = await _apiService.getClientSummary(widget.consultationId, token);
      
      if (mounted) {
        setState(() {
          _summary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load summary: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Client Summary')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _summary == null
            ? const Center(child: Text("Could not generate AI summary."))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(widget.clientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Consultation ID: ${widget.consultationId.substring(0, 8)}...'),
                    ),
                    const Divider(),
                    Text('Query: ${widget.querySummary}', style: const TextStyle(fontStyle: FontStyle.italic)),
                    const SizedBox(height: 24),
                    
                    if (_summary!.containsKey('key_facts') && _summary!['key_facts'] is List)
                      Card(child: ListTile(title: const Text('Key Facts'), subtitle: Text((_summary!['key_facts'] as List).join('\\n• ')))),
                    if (_summary!.containsKey('legal_issues') && _summary!['legal_issues'] is List)
                      Card(child: ListTile(title: const Text('Legal Issues'), subtitle: Text((_summary!['legal_issues'] as List).join(', ')))),
                    if (_summary!.containsKey('urgency_level'))
                      Card(
                        color: Colors.orange.shade100,
                        child: ListTile(title: const Text('Urgency Level'), subtitle: Text(_summary!['urgency_level'].toString())),
                      ),
                    if (_summary!.containsKey('recommended_approach'))
                      Card(child: ListTile(title: const Text('Recommended Approach'), subtitle: Text(_summary!['recommended_approach'].toString()))),
                    if (_summary!.containsKey('communication_tips'))
                      Card(child: ListTile(title: const Text('Communication Tips'), subtitle: Text(_summary!['communication_tips'].toString()))),
                    
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(onPressed: () {}, child: const Text('Accept Case')),
                        OutlinedButton(onPressed: () {}, child: const Text('Request Info')),
                      ],
                    ),
                  ],
                ),
              ),
    );
  }
}
