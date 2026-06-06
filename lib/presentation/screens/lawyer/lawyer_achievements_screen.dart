import 'package:flutter/material.dart';

class LawyerAchievementsScreen extends StatelessWidget {
  const LawyerAchievementsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Achievements & Ranking')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.amber.shade100,
            child: Column(
              children: [
                const Icon(Icons.workspace_premium, size: 64, color: Colors.amber),
                const SizedBox(height: 8),
                const Text('GOLD TIER', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber)),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: 0.7, backgroundColor: Colors.amber.shade200, color: Colors.amber.shade800),
                const SizedBox(height: 8),
                const Text('350 / 600 Points to Platinum'),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                final isUnlocked = index < 2;
                return Card(
                  elevation: isUnlocked ? 4 : 1,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: isUnlocked ? Colors.amber : Colors.transparent, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.emoji_events,
                          size: 48,
                          color: isUnlocked ? Colors.amber : Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isUnlocked ? 'First Victory' : 'Legal Legend',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isUnlocked ? Colors.black : Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isUnlocked ? 'Completed 1 case' : 'Complete 100 cases',
                          style: TextStyle(
                            fontSize: 12,
                            color: isUnlocked ? Colors.black87 : Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
