import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:qanoon_buddy/core/theme.dart';

class CitizenServicesHubScreen extends StatelessWidget {
  const CitizenServicesHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = [
      {
        'title': 'Legal Procedure Guides',
        'desc': 'Interactive flows for vehicle transfer, inheritance, property registration & more.',
        'icon': Icons.menu_book_rounded,
        'route': '/citizen-services/procedures',
        'color': const Color(0xFF1E3A8A),
      },
      {
        'title': 'Stamp Duty Calculator',
        'desc': 'Calculate property stamp duty rates across major urban centers.',
        'icon': Icons.calculate_rounded,
        'route': '/citizen-services/stamp-duty',
        'color': const Color(0xFF0F766E),
      },
      {
        'title': 'Court Fee Calculator',
        'desc': 'Determine exact judicial court fee margins for civilian disputes.',
        'icon': Icons.balance_rounded,
        'route': '/citizen-services/court-fees',
        'color': const Color(0xFFB45309),
      },
      {
        'title': 'Excise & Challan Portal',
        'desc': 'Safely check license plates and traffic ticket statuses online.',
        'icon': Icons.receipt_long_rounded,
        'route': '/citizen-services/challan',
        'color': const Color(0xFF4338CA),
      },
    ];

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text(
          'Citizen Services Hub',
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.navyDeep, Color(0xFF132247)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.navyDeep.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PUBLIC UTILITY PORTAL',
                    style: TextStyle(
                      color: AppTheme.goldPremium,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Legal Utilities & Procedures',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Browse verified Pakistani legal templates, calculate state taxation duties, and run registration checks instantly without artificial intelligence processing.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ).animate().fade().slideY(begin: 0.05, duration: 300.ms),

            const SizedBox(height: 28),

            const Text(
              'CHOOSE A UTILITY',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: AppTheme.navyDeep,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),

            // Services ListView
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: services.length,
              itemBuilder: (context, index) {
                final item = services[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () => context.push(item['route'] as String),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (item['color'] as Color).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              item['icon'] as IconData,
                              color: item['color'] as Color,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['desc'] as String,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textGrey,
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: AppTheme.textGrey.withOpacity(0.5),
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fade(delay: (index * 80).ms).slideX(begin: 0.05, delay: (index * 80).ms);
              },
            ),
          ],
        ),
      ),
    );
  }
}
