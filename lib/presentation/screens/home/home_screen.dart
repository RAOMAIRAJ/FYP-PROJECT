import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qanoon_buddy/data/auth_provider.dart';
import 'package:qanoon_buddy/presentation/screens/chat_screen.dart';
import 'package:qanoon_buddy/presentation/screens/lawyers_screen.dart';
import 'package:qanoon_buddy/presentation/screens/consultations_screen.dart';
import 'package:qanoon_buddy/presentation/screens/profile_screen.dart';
import 'package:qanoon_buddy/presentation/screens/home/user_home_tab.dart';
import 'package:qanoon_buddy/presentation/screens/home/lawyer_home_tab.dart';
import 'package:qanoon_buddy/presentation/screens/peer_contacts_screen.dart';
import 'package:qanoon_buddy/presentation/screens/support/ai_support_bot_screen.dart';
import 'package:qanoon_buddy/core/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  static const Color accent    = AppTheme.goldPremium;
  static const Color textGrey  = AppTheme.textGrey;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final role = auth.user?['role'] ?? 'user';
    final isLawyer = role == 'lawyer';

    // Decide which body to show
    Widget body;
    if (_currentIndex == 0) {
      body = isLawyer ? const LawyerHomeTab() : const UserHomeTab();
    } else {
      // Temporary fallback while switching tabs (handled by navigator pushing, but keeping state here if we ever convert to IndexedStack)
      body = isLawyer ? const LawyerHomeTab() : const UserHomeTab();
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      extendBody: true,
      body: body,
      floatingActionButton: GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AiSupportBotScreen()));
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.navyDeep,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppTheme.navyDeep.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.support_agent_rounded, color: Colors.white, size: 28),
          ),
        ).animate(onPlay: (controller) => controller.repeat(reverse: true))
         .scaleXY(end: 1.08, duration: 1.2.seconds, curve: Curves.easeInOut)
         .shimmer(duration: 2.seconds, color: Colors.white.withOpacity(0.3)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 10))
                  ]
                ),
                child: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: (i) {
                    setState(() => _currentIndex = i);
                    if (i == 0) return;

                    if (isLawyer) {
                      if (i == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()));
                      if (i == 2) Navigator.push(context, MaterialPageRoute(builder: (_) => const ConsultationsScreen()));
                      if (i == 3) Navigator.push(context, MaterialPageRoute(builder: (_) => const PeerContactsScreen()));
                      if (i == 4) Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                    } else {
                      if (i == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()));
                      if (i == 2) Navigator.push(context, MaterialPageRoute(builder: (_) => const ConsultationsScreen()));
                      if (i == 3) Navigator.push(context, MaterialPageRoute(builder: (_) => const LawyersScreen()));
                      if (i == 4) Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                    }
                    setState(() => _currentIndex = 0);
                  },
                  backgroundColor: Colors.transparent,
                  selectedItemColor: accent,
                  unselectedItemColor: textGrey.withOpacity(0.8),
                  type: BottomNavigationBarType.fixed,
                  elevation: 0,
                  showSelectedLabels: false,
                  showUnselectedLabels: false,
                  items: isLawyer
                      ? const [
                          BottomNavigationBarItem(icon: Icon(Icons.home_rounded, size: 28), label: 'Home'),
                          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded, size: 28), label: 'AI'),
                          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded, size: 28), label: 'Meetings'),
                          BottomNavigationBarItem(icon: Icon(Icons.forum_rounded, size: 28), label: 'Msg'),
                          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded, size: 28), label: 'Profile'),
                        ]
                      : const [
                          BottomNavigationBarItem(icon: Icon(Icons.home_rounded, size: 28), label: 'Home'),
                          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded, size: 28), label: 'AI'),
                          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded, size: 28), label: 'Meetings'),
                          BottomNavigationBarItem(icon: Icon(Icons.gavel_rounded, size: 28), label: 'Lawyers'),
                          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded, size: 28), label: 'Profile'),
                        ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}