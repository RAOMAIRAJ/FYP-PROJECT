import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qanoon_buddy/core/api_service.dart';
import 'package:qanoon_buddy/data/auth_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'peer_chat_screen.dart';
import 'package:qanoon_buddy/presentation/widgets/hover_button.dart';
import 'package:qanoon_buddy/core/theme.dart';

class PeerContactsScreen extends ConsumerStatefulWidget {
  const PeerContactsScreen({super.key});

  @override
  ConsumerState<PeerContactsScreen> createState() => _PeerContactsScreenState();
}

class _PeerContactsScreenState extends ConsumerState<PeerContactsScreen> {
  static const Color primary = AppTheme.navyDeep;
  static const Color accent = AppTheme.goldPremium;
  static const Color bg = AppTheme.surface;
  static const Color textDark = AppTheme.textDark;
  static const Color border = AppTheme.border;

  List<dynamic> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    setState(() => _isLoading = true);
    try {
      final token = ref.read(authProvider).token;
      if (token == null) return;
      final data = await apiService.getPeerChatContacts(token);
      if (mounted) setState(() => _contacts = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading contacts: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // ── Header ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, AppTheme.navyLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    HoverButton(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.glassWhite.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.glassBorder),
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text('Messages', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    HoverButton(
                      onTap: _fetchContacts,
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.glassWhite.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.glassBorder),
                        ),
                        child: const Icon(Icons.refresh, color: Colors.white, size: 20).animate(onPlay: (c) => c.repeat(reverse: true)).rotate(duration: 2.seconds, curve: Curves.linear),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fade().slideY(begin: -0.1),

          // ── Body ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primary))
                : _contacts.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: _contacts.length,
                        itemBuilder: (context, index) {
                          final contact = _contacts[index];
                          final name = contact['full_name'] ?? 'Unknown';
                          final role = contact['role'] ?? 'user';
                          
                          return HoverButton(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => PeerChatScreen(peerId: contact['id'], peerName: name, peerRole: role)),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: border),
                                boxShadow: [
                                  BoxShadow(color: primary.withOpacity(0.06), blurRadius: 20, spreadRadius: 2, offset: const Offset(0, 8)),
                                ]
                              ),
                              child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: role == 'lawyer' ? AppTheme.accepted.withOpacity(0.1) : AppTheme.completed.withOpacity(0.1),
                                        child: Text(
                                          name[0].toUpperCase(),
                                          style: TextStyle(
                                            color: role == 'lawyer' ? accent : AppTheme.completed,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: textDark)),
                                            const SizedBox(height: 2),
                                            Text(role.toString().toUpperCase(), style: TextStyle(
                                              color: role == 'lawyer' ? accent : AppTheme.completed,
                                              fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5
                                            )),
                                          ],
                                        ),
                                      ),
                                      if ((contact['unread_count'] ?? 0) > 0)
                                        Container(
                                          margin: const EdgeInsets.only(right: 12),
                                          padding: const EdgeInsets.all(8),
                                          decoration: const BoxDecoration(
                                            color: Colors.redAccent,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            contact['unread_count'].toString(),
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      const Icon(Icons.chevron_right, color: AppTheme.border, size: 24)
                                        .animate(onPlay: (c) => c.repeat(reverse: true))
                                        .slideX(begin: 0, end: 0.2, duration: 1.seconds, curve: Curves.easeInOut),
                                    ],
                                  ),
                                ),
                            ),
                          ).animate().fade(delay: (index * 50).ms).slideX(begin: 0.05);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 8))]
            ),
            child: const Icon(Icons.chat_bubble_outline, size: 40, color: AppTheme.textGrey),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 24),
          const Text('No messages yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 8),
          const Text('Your conversations will appear here.', style: TextStyle(color: AppTheme.textGrey)),
        ],
      ),
    );
  }
}
