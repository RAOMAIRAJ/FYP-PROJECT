import 'package:flutter/material.dart';

class SmartCaseTimelineScreen extends StatefulWidget {
  const SmartCaseTimelineScreen({Key? key}) : super(key: key);

  @override
  State<SmartCaseTimelineScreen> createState() => _SmartCaseTimelineScreenState();
}

class _SmartCaseTimelineScreenState extends State<SmartCaseTimelineScreen> {
  final List<Map<String, dynamic>> _events = [
    {'title': 'Initial Consultation', 'date': '2026-05-01', 'type': 'Meeting', 'completed': true},
    {'title': 'Filing Petition', 'date': '2026-05-15', 'type': 'Filing', 'completed': true},
    {'title': 'First Hearing', 'date': '2026-06-10', 'type': 'Hearing', 'completed': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Case Timeline')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: const Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(child: Text('AI Suggestion: Prepare witness statements before First Hearing.')),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _events.length,
              itemBuilder: (context, index) {
                final event = _events[index];
                return ListTile(
                  leading: Icon(
                    event['completed'] ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: event['completed'] ? Colors.green : Colors.grey,
                  ),
                  title: Text(event['title']),
                  subtitle: Text('${event['type']} - ${event['date']}'),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show add event bottom sheet
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
