import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qanoon_buddy/core/theme.dart';

class EmergencyHelplinesScreen extends StatelessWidget {
  const EmergencyHelplinesScreen({super.key});

  // Pakistani emergency helplines
  static const List<Map<String, dynamic>> _emergencies = [
    {
      'title': 'Police Emergency',
      'number': '15',
      'category': 'Security',
      'icon': Icons.local_police_rounded,
      'description': 'Direct connection to local police stations for immediate protection.',
      'color': AppTheme.error,
    },
    {
      'title': 'Rescue & Ambulance',
      'number': '1122',
      'category': 'Medical',
      'icon': Icons.medical_services_rounded,
      'description': 'Rescue 1122 ambulance and emergency management service.',
      'color': Colors.orange,
    },
    {
      'title': 'FIA Cyber Crime',
      'number': '9911',
      'category': 'Cyber Security',
      'icon': Icons.security_rounded,
      'description': 'Report online harassment, financial fraud, and cyber threats.',
      'color': AppTheme.navyDeep,
    },
    {
      'title': 'Child Protection',
      'number': '1121',
      'category': 'Human Rights',
      'icon': Icons.child_care_rounded,
      'description': 'Helpline for children in distress or facing abuse and neglect.',
      'color': AppTheme.inProgress,
    },
    {
      'title': 'Human Rights Helpline',
      'number': '1099',
      'category': 'Human Rights',
      'icon': Icons.gavel_rounded,
      'description': 'Ministry of Human Rights helpline for legal aid and complaints.',
      'color': AppTheme.accepted,
    },
    {
      'title': 'NADRA Support',
      'number': '1777',
      'category': 'Identity Support',
      'icon': Icons.badge_rounded,
      'description': 'Contact NADRA for identity card queries and verification issues.',
      'color': AppTheme.completed,
    },
  ];

  Future<void> _makeCall(BuildContext context, String number) async {
    final Uri url = Uri(scheme: 'tel', path: number);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch dialer for $number')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching dialer: $e')),
        );
      }
    }
  }

  Future<void> _launchWhatsApp(BuildContext context, String phone, String message) async {
    final url = Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(message)}");
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch WhatsApp. Make sure it is installed.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching WhatsApp: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text(
          'Emergency Helplines',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.navyDeep, AppTheme.navyLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Description
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.navyDeep.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: const Row(
                children: [
                  Text('🚨', style: TextStyle(fontSize: 32)),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Instant Helpline Access',
                          style: TextStyle(
                            color: AppTheme.textDark,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'No internet required for calls. Connect directly with national support agencies and legal protection authorities.',
                          style: TextStyle(
                            color: AppTheme.textGrey,
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fade().slideY(begin: 0.1),

            const SizedBox(height: 28),

            const Text(
              'National Crisis Lines',
              style: TextStyle(
                color: AppTheme.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ).animate().fade(delay: 100.ms),

            const SizedBox(height: 16),

            // Emergency list
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _emergencies.length,
              itemBuilder: (context, index) {
                final item = _emergencies[index];
                final color = item['color'] as Color;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.01),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _makeCall(context, item['number']!),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      key: ValueKey(item['title']),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: color.withOpacity(0.15)),
                            ),
                            child: Icon(item['icon'] as IconData, color: color, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      item['category']!,
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'DIAL ${item['number']}',
                                      style: const TextStyle(
                                        color: AppTheme.textGrey,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['title']!,
                                  style: const TextStyle(
                                    color: AppTheme.textDark,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['description']!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppTheme.textGrey,
                                    fontSize: 11,
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.phone_enabled_rounded,
                            color: color,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fade(delay: (200 + index * 50).ms).slideX(begin: 0.05);
              },
            ),

            const SizedBox(height: 16),

            // Free Legal Aid Society (WhatsApp Integration)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.navyDeep, AppTheme.navyLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.navyDeep.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Text('⚖️', style: TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Free Legal Aid Desk',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'LAS Pakistan Helpline',
                              style: TextStyle(
                                color: AppTheme.goldPremium,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Direct chat with Legal Aid Society representatives. Get free, confidential initial consults regarding custody, labor issues, land disputes, and criminal charges.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _makeCall(context, '+922135630012'),
                          icon: const Icon(Icons.phone_rounded, color: Colors.white),
                          label: const Text('Call Office'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withOpacity(0.3)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _launchWhatsApp(
                            context,
                            '+923001234567', // Placeholder official helpline WhatsApp
                            'Assalam-o-Alaikum, Qanoon Buddy User requesting legal assistance support.',
                          ),
                          icon: const Icon(Icons.chat_rounded, color: Colors.white),
                          label: const Text('WhatsApp'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fade(delay: 500.ms).slideY(begin: 0.1),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
