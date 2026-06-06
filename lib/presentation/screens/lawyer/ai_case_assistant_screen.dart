import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api_service.dart';

class AICaseAssistantScreen extends StatefulWidget {
  const AICaseAssistantScreen({Key? key}) : super(key: key);

  @override
  State<AICaseAssistantScreen> createState() => _AICaseAssistantScreenState();
}

class _AICaseAssistantScreenState extends State<AICaseAssistantScreen> {
  final ApiService _apiService = ApiService();
  final _descController = TextEditingController();
  final _opponentController = TextEditingController();
  String _selectedCategory = 'Criminal';
  bool _isLoading = false;
  Map<String, dynamic>? _results;

  final List<String> _categories = [
    'Criminal', 'Civil', 'Family', 'Corporate', 'Cyber', 'Property'
  ];

  void _analyzeCase() async {
    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter case description')));
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'auth_token');
      if (token == null) throw Exception("Unauthorized");

      final results = await _apiService.analyzeCase(
        description: _descController.text.trim(),
        category: _selectedCategory,
        opponentDetails: _opponentController.text.trim(),
        token: token,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _results = results;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Analysis failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Case Assistant')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Case Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _opponentController,
              decoration: const InputDecoration(
                labelText: 'Opponent Details (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _analyzeCase,
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                : const Text('Analyze Case'),
            ),
            if (_results != null) ...[
              const SizedBox(height: 32),
              const Text('Analysis Results', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (_results!.containsKey('summary'))
                Card(child: ListTile(title: const Text('Summary'), subtitle: Text(_results!['summary'].toString()))),
              if (_results!.containsKey('strong_points') && _results!['strong_points'] is List)
                Card(child: ListTile(title: const Text('Strong Points'), subtitle: Text((_results!['strong_points'] as List).join('\\n• ')))),
              if (_results!.containsKey('weak_points') && _results!['weak_points'] is List)
                Card(child: ListTile(title: const Text('Weak Points'), subtitle: Text((_results!['weak_points'] as List).join('\\n• ')))),
              if (_results!.containsKey('relevant_case_laws') && _results!['relevant_case_laws'] is List)
                Card(child: ListTile(title: const Text('Relevant Case Laws'), subtitle: Text((_results!['relevant_case_laws'] as List).join(', ')))),
              if (_results!.containsKey('recommended_strategy'))
                Card(child: ListTile(title: const Text('Strategy'), subtitle: Text(_results!['recommended_strategy'].toString()))),
              if (_results!.containsKey('estimated_timeline'))
                Card(child: ListTile(title: const Text('Estimated Timeline'), subtitle: Text(_results!['estimated_timeline'].toString()))),
            ]
          ],
        ),
      ),
    );
  }
}
