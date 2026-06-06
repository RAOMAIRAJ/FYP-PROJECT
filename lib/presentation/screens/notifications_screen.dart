import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qanoon_buddy/core/api_service.dart';
import 'package:qanoon_buddy/data/auth_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qanoon_buddy/presentation/widgets/hover_button.dart';
import 'package:qanoon_buddy/core/theme.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  static const Color primary  = AppTheme.navyDeep;
  static const Color accent   = AppTheme.goldPremium;
  static const Color bg       = AppTheme.surface;
  static const Color textDark = AppTheme.textDark;
  static const Color textGrey = AppTheme.textGrey;
  static const Color border   = AppTheme.border;

  List<dynamic> _notifications = [];
  bool   _isLoading = true;
  bool   _isLoadingMore = false;
  bool   _hasMore = true;
  int    _skip = 0;
  final int _limit = 20;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch({bool refresh = false}) async {
    if (refresh) {
      setState(() { _isLoading = true; _error = null; _skip = 0; _notifications = []; _hasMore = true; });
    } else {
      if (!_hasMore || _isLoadingMore) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final token = ref.read(authProvider).token!;
      final data  = await apiService.getNotifications(token, skip: _skip, limit: _limit);
      if (mounted) {
        setState(() {
          if (refresh) {
            _notifications = data;
          } else {
            _notifications.addAll(data);
          }
          _isLoading = false;
          _isLoadingMore = false;
          _hasMore = data.length == _limit;
          if (_hasMore) _skip += _limit;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _isLoadingMore = false; _error = e.toString(); });
    }
  }

  Future<void> _markAllRead() async {
    try {
      final token = ref.read(authProvider).token!;
      await apiService.markAllRead(token);
      _fetch(refresh: true);
    } catch (_) {}
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'new_booking': return Icons.history_edu_rounded;
      case 'accepted'   : return Icons.verified_rounded;
      case 'completed'  : return Icons.task_alt_rounded;
      case 'cancelled'  : return Icons.cancel_outlined;
      case 'review'     : return Icons.star_rounded;
      default           : return Icons.notifications_active_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'new_booking': return accent;
      case 'accepted'   : return AppTheme.completed;
      case 'completed'  : return AppTheme.completed;
      case 'cancelled'  : return AppTheme.error;
      case 'review'     : return AppTheme.warning;
      default           : return accent;
    }
  }

  Color _typeBg(String type) {
    switch (type) {
      case 'new_booking': return accent.withOpacity(0.1);
      case 'accepted'   : return AppTheme.completed.withOpacity(0.1);
      case 'completed'  : return AppTheme.completed.withOpacity(0.1);
      case 'cancelled'  : return AppTheme.error.withOpacity(0.1);
      case 'review'     : return AppTheme.warning.withOpacity(0.1);
      default           : return accent.withOpacity(0.1);
    }
  }

  String _formatDate(String d) {
    try {
      final dt  = DateTime.parse(d).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1)  return 'JUST NOW';
      if (diff.inMinutes < 60) return '${diff.inMinutes}M AGO';
      if (diff.inHours < 24)   return '${diff.inHours}H AGO';
      if (diff.inDays < 7)     return '${diff.inDays}D AGO';
      const m = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
      return '${dt.day} ${m[dt.month - 1]}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => n['is_read'] == false).length;

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // ── Elite Notifications Header ──
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Row(
                  children: [
                    _topBtn(Icons.chevron_left_rounded, () => Navigator.pop(context)),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: const Text('COMMUNICATIONS', 
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                          ),
                          if (unread > 0)
                            Text('$unread UNREAD PROTOCOLS', 
                              style: TextStyle(color: accent.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)
                            )
                          else
                            const Text('PROTOCOL ARCHIVE', 
                              style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)
                            ),
                        ],
                      ),
                    ),
                    if (unread > 0)
                      _topBtn(Icons.done_all_rounded, _markAllRead),
                    const SizedBox(width: 12),
                    _topBtn(Icons.refresh_rounded, () => _fetch(refresh: true)),
                  ],
                ),
              ),
            ),
          ).animate().fade().slideY(begin: -0.1),

          // ── Notification Stream ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: accent))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                            const SizedBox(height: 16),
                            Text('SYNC ERROR\n$_error', 
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: textGrey, fontSize: 12, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 24),
                            HoverButton(
                              onTap: () => _fetch(refresh: true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(12)),
                                child: const Text('RETRY SYNC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _notifications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 100, height: 100,
                                  decoration: BoxDecoration(color: accent.withOpacity(0.05), shape: BoxShape.circle),
                                  child: const Center(child: Icon(Icons.notifications_none_rounded, color: accent, size: 40)),
                                ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                                const SizedBox(height: 24),
                                const Text('PROTOCOL CLEAR', style: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
                                const SizedBox(height: 8),
                                const Text('ALL SYSTEMS ARE MONITORING NORMALLY', style: TextStyle(color: textGrey, fontSize: 11, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _notifications.length + (_hasMore ? 1 : 0),
                            itemBuilder: (_, i) {
                              if (i == _notifications.length) {
                                return _buildLoadMore();
                              }
                              final n      = _notifications[i];
                              final type   = n['type'] ?? 'general';
                              final isRead = n['is_read'] ?? false;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: isRead ? border : accent.withOpacity(0.3)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isRead ? Colors.black.withOpacity(0.02) : accent.withOpacity(0.05),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Stack(
                                    children: [
                                      if (!isRead)
                                        Positioned(
                                          left: 0, top: 0, bottom: 0,
                                          child: Container(width: 4, color: accent),
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 52, height: 52,
                                              decoration: BoxDecoration(color: _typeBg(type), borderRadius: BorderRadius.circular(16)),
                                              child: Icon(_typeIcon(type), color: _typeColor(type), size: 24),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          n['title'] ?? 'SYSTEM UPDATE',
                                                          style: TextStyle(
                                                            color: textDark, 
                                                            fontSize: 15, 
                                                            fontWeight: FontWeight.w900,
                                                            letterSpacing: -0.2,
                                                          ),
                                                        ),
                                                      ),
                                                      Text(
                                                        _formatDate(n['created_at'] ?? ''),
                                                        style: const TextStyle(color: textGrey, fontSize: 9, fontWeight: FontWeight.w900),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    n['body'] ?? 'No additional details provided.',
                                                    style: TextStyle(
                                                      color: isRead ? textGrey : textDark.withOpacity(0.7), 
                                                      fontSize: 13, 
                                                      height: 1.5,
                                                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ).animate().fade(delay: (i * 30).ms).slideX(begin: 0.05);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _topBtn(IconData icon, VoidCallback onTap) {
    return HoverButton(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: AppTheme.glassWhite.withOpacity(0.12), 
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildLoadMore() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: _isLoadingMore
          ? const Center(child: CircularProgressIndicator(color: accent))
          : Center(
              child: HoverButton(
                onTap: () => _fetch(refresh: false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: border),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: const Text('LOAD MORE NOTIFICATIONS', 
                    style: TextStyle(color: primary, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                ),
              ),
            ),
    );
  }
}