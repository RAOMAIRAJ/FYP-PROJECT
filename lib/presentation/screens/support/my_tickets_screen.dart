import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qanoon_buddy/core/theme.dart';
import 'package:qanoon_buddy/core/api_service.dart';
import 'package:qanoon_buddy/data/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyTicketsScreen extends ConsumerStatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  ConsumerState<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends ConsumerState<MyTicketsScreen> {
  bool _isLoading = true;
  List<dynamic> _items = [];
  Map<String, int> _readCounts = {};

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    final token = ref.read(authProvider).token;
    if (token == null) return;
    try {
      final res = await apiService.getMyTickets(token);
      final List<dynamic> complaints = res['complaints'] ?? [];
      final List<dynamic> tickets = res['tickets'] ?? [];
      
      final all = [...complaints, ...tickets];
      final prefs = await SharedPreferences.getInstance();
      Map<String, int> counts = {};
      for (var item in all) {
        counts[item['id'].toString()] = prefs.getInt('ticket_read_${item['id']}') ?? 0;
      }
      
      setState(() {
        _items = all;
        _readCounts = counts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _openTicketChat(Map<String, dynamic> ticket) async {
    // Both Support Tickets and Complaints now support two-way chat!
    final prefs = await SharedPreferences.getInstance();
    int currentReplies = (ticket['replies'] as List?)?.length ?? 0;
    await prefs.setInt('ticket_read_${ticket['id']}', currentReplies);
    setState(() {
      _readCounts[ticket['id'].toString()] = currentReplies;
    });
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TicketChatSheet(ticket: ticket, onReplied: _fetchTickets),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('My Support History', style: TextStyle(color: AppTheme.navyDeep, fontWeight: FontWeight.w900, fontSize: 18)),
        iconTheme: const IconThemeData(color: AppTheme.navyDeep),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _items.isEmpty
            ? const Center(child: Text("You have no support history.", style: TextStyle(color: AppTheme.textGrey)))
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _items.length,
                itemBuilder: (context, i) {
                  final item = _items[i];
                  final isTicket = item['type'] == 'Support Ticket';
                  final status = item['status'] ?? 'Pending';
                  final isPending = status == 'Pending';
                  
                  int totalReplies = (item['replies'] as List?)?.length ?? 0;
                  int readReplies = _readCounts[item['id'].toString()] ?? totalReplies;
                  int unreadCount = totalReplies - readReplies;
                  if (unreadCount < 0) unreadCount = 0;

                  return GestureDetector(
                    onTap: () => _openTicketChat(item),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(isTicket ? Icons.confirmation_number : Icons.gavel, color: isTicket ? AppTheme.navyDeep : AppTheme.goldPremium, size: 20),
                              const SizedBox(width: 8),
                              Text(item['type'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.navyDeep)),
                              if (unreadCount > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                )
                              ],
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isPending ? Colors.amber.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20)
                                ),
                                child: Text(status.toUpperCase(), style: TextStyle(color: isPending ? Colors.amber.shade700 : Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(item['subject'] ?? item['category'] ?? 'Support Request', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark)),
                          const SizedBox(height: 4),
                          Text(item['message'] ?? item['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                          const SizedBox(height: 12),
                          Text(item['date'] ?? '', style: const TextStyle(color: AppTheme.textGrey, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}

class _TicketChatSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> ticket;
  final VoidCallback onReplied;
  const _TicketChatSheet({required this.ticket, required this.onReplied});

  @override
  ConsumerState<_TicketChatSheet> createState() => _TicketChatSheetState();
}

class _TicketChatSheetState extends ConsumerState<_TicketChatSheet> {
  final TextEditingController _replyCtrl = TextEditingController();
  bool _isSending = false;
  late List<dynamic> replies;

  @override
  void initState() {
    super.initState();
    replies = List.from(widget.ticket['replies'] ?? []);
  }

  Future<void> _sendReply() async {
    if (_replyCtrl.text.trim().isEmpty) return;
    setState(() => _isSending = true);
    
    final token = ref.read(authProvider).token;
    if (token != null) {
      try {
        final res = await apiService.replyMyTicket(widget.ticket['id'], token, _replyCtrl.text.trim());
        setState(() {
          replies = res['replies'] ?? [];
        });
        _replyCtrl.clear();
        widget.onReplied(); // Trigger reload behind the modal
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to reply: $e')));
      }
    }
    setState(() => _isSending = false);
  }

  Widget _buildInitialTicketMessage() {
    String rawMsg = (widget.ticket['message'] ?? widget.ticket['description'] ?? '').toString().trim();
    String subject = (widget.ticket['subject'] ?? widget.ticket['category'] ?? 'Support Request').toString().toUpperCase();

    if (rawMsg.toLowerCase().contains('chat transcript:')) {
      final textToParse = rawMsg.replaceFirst(RegExp(r'^.*chat transcript:?\s*', caseSensitive: false, dotAll: true), '');
      final matches = RegExp(r'(Support Bot:|User:)(.*?)(?=(Support Bot:|User:|$))', dotAll: true).allMatches(textToParse);
      if (matches.isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
                child: Text(subject, style: TextStyle(fontWeight: FontWeight.w900, color: Colors.orange.shade800, fontSize: 10, letterSpacing: 1)),
              ),
            ),
            ...matches.map((m) {
              final isBot = m.group(1) == 'Support Bot:';
              final text = m.group(2)?.trim() ?? '';
              if (text.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isBot) ...[
                      const CircleAvatar(radius: 12, backgroundColor: AppTheme.navyDeep, child: Icon(Icons.smart_toy_rounded, size: 12, color: AppTheme.goldPremium)),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isBot ? Colors.white : AppTheme.goldPremium.withOpacity(0.15),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isBot ? 4 : 16),
                            bottomRight: Radius.circular(isBot ? 16 : 4),
                          ),
                          border: Border.all(color: isBot ? AppTheme.border : AppTheme.goldPremium.withOpacity(0.3)),
                        ),
                        child: Text(text, style: TextStyle(fontSize: 13, color: AppTheme.textDark, height: 1.4, fontWeight: isBot ? FontWeight.w500 : FontWeight.w600)),
                      ),
                    ),
                    if (!isBot) ...[
                      const SizedBox(width: 8),
                      CircleAvatar(radius: 12, backgroundColor: Colors.grey.shade300, child: const Icon(Icons.person, size: 12, color: Colors.white)),
                    ],
                  ],
                ),
              );
            }).toList(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: AppTheme.border),
            ),
          ],
        );
      }
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 32),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
              child: Text(subject, style: TextStyle(fontWeight: FontWeight.w900, color: Colors.orange.shade800, fontSize: 10, letterSpacing: 1)),
            ),
            const SizedBox(height: 16),
            Text(rawMsg, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: AppTheme.textDark, height: 1.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC), // Slate 50
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            const SizedBox(height: 12),
            Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 16),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppTheme.navyDeep.withOpacity(0.1),
                    child: const Icon(Icons.support_agent_rounded, color: AppTheme.navyDeep, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Support Team',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppTheme.navyDeep),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: AppTheme.navyDeep.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                'TICKET #${widget.ticket['id'].toString().substring(0, 8)}',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 9, color: AppTheme.navyDeep, letterSpacing: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: AppTheme.border)),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.textDark, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppTheme.border),

            // Main Chat Area
            Expanded(
              child: Container(
                color: const Color(0xFFF8FAFC),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInitialTicketMessage(),
                      
                      // Chat Bubbles
                      ...replies.map((r) {
                        final isAdmin = r['sender'] == 'admin';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Row(
                            mainAxisAlignment: isAdmin ? MainAxisAlignment.start : MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (isAdmin) ...[
                                CircleAvatar(radius: 14, backgroundColor: AppTheme.goldPremium, child: const Icon(Icons.admin_panel_settings, size: 16, color: AppTheme.navyDeep)),
                                const SizedBox(width: 10),
                              ],
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: !isAdmin ? AppTheme.navyDeep : Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(24),
                                      topRight: const Radius.circular(24),
                                      bottomLeft: Radius.circular(!isAdmin ? 24 : 6),
                                      bottomRight: Radius.circular(!isAdmin ? 6 : 24),
                                    ),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
                                    ],
                                  ),
                                  child: Text(
                                    r['message'],
                                    style: TextStyle(
                                      color: !isAdmin ? Colors.white : AppTheme.textDark,
                                      fontSize: 15,
                                      height: 1.4,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              if (!isAdmin) ...[
                                const SizedBox(width: 10),
                                CircleAvatar(radius: 14, backgroundColor: Colors.grey.shade300, child: const Icon(Icons.person, size: 16, color: Colors.white)),
                              ],
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            // Sleek Composer Area
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, -4))],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9), // Slate 100
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: TextField(
                        controller: _replyCtrl,
                        maxLines: 5,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(fontSize: 15),
                        decoration: const InputDecoration(
                          hintText: 'Type your reply...',
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _isSending 
                  ? Container(
                      height: 52, width: 52,
                      decoration: const BoxDecoration(color: AppTheme.navyDeep, shape: BoxShape.circle),
                      child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))),
                    )
                  : InkWell(
                      onTap: _sendReply,
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        height: 52, width: 52,
                        decoration: const BoxDecoration(
                          color: AppTheme.navyDeep,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(child: Icon(Icons.send_rounded, color: Colors.white, size: 22)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
