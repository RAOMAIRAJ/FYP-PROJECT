import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qanoon_buddy/core/theme.dart';
import 'package:qanoon_buddy/core/api_service.dart';
import 'package:qanoon_buddy/data/auth_provider.dart';
import 'package:qanoon_buddy/presentation/widgets/hover_button.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class AiSupportBotScreen extends ConsumerStatefulWidget {
  const AiSupportBotScreen({super.key});

  @override
  ConsumerState<AiSupportBotScreen> createState() => _AiSupportBotScreenState();
}

class _AiSupportBotScreenState extends ConsumerState<AiSupportBotScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      "sender": "ai",
      "message": "Hello! I am your Support Assistant. I can help you with password resets, verifying your profile, payment disputes, or app issues. How can I assist you today?"
    }
  ];
  bool _isLoading = false;
  bool _escalated = false;

  Future<void> _sendMessage() async {
    if (_msgCtrl.text.trim().isEmpty) return;
    
    final userText = _msgCtrl.text.trim();
    setState(() {
      _messages.add({"sender": "user", "message": userText});
      _isLoading = true;
    });
    _msgCtrl.clear();

    try {
      final token = ref.read(authProvider).token;
      if (token == null) throw Exception("Not logged in");

      final historyForApi = _messages.take(_messages.length - 1).toList();
      final res = await apiService.chatWithSupportAi(historyForApi, userText);

      if (!mounted) return;

      bool suppressReply = false;
      String? actionFeedback;

      // Smart Actions Pre-processing
      if (res['action'] != null) {
        if (res['action'] == 'RESET_PASSWORD') {
          final user = ref.read(authProvider).user;
          final email = user?['email'];
          if (email != null && email.toString().isNotEmpty) {
            await apiService.forgotPassword(email);
            actionFeedback = "✅ I have sent a password reset link to your registered email address ($email). Please check your inbox and follow the instructions to reset your password.";
          } else {
            suppressReply = true;
            actionFeedback = "❌ I couldn't find an email associated with your account. You might have signed in with a phone number.";
          }
        }
        else if (res['action'] == 'FILE_TICKET' && res['action_data'] != null) {
          final data = res['action_data'];
          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          final dateStr = "${months[DateTime.now().month - 1]} ${DateTime.now().day}, ${DateTime.now().year}";
          
          await apiService.submitTicket(
            token: token,
            ticketType: data['type'] ?? 'Problem',
            subject: data['subject'] ?? 'Auto-Filed Issue',
            message: data['message'] ?? 'Filed by AI bot',
            date: dateStr,
          );
          actionFeedback = "✅ I've successfully filed this technical support ticket for you.";
        } 
        else if (res['action'] == 'FILE_COMPLAINT' && res['action_data'] != null) {
          final data = res['action_data'];
          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          final dateStr = "${months[DateTime.now().month - 1]} ${DateTime.now().day}, ${DateTime.now().year}";
          
          await apiService.submitComplaint(
            token: token,
            category: data['category'] ?? 'General',
            reportedLawyer: data['target_name'] ?? 'Unknown',
            description: "Against: ${data['target_name']}\n\n${data['message'] ?? 'Filed by AI bot'}",
            date: dateStr,
          );
          actionFeedback = "✅ I've successfully registered this complaint for you. Our team will investigate immediately.";
        }
        else if (res['action'] == 'ACCOUNT_SUMMARY') {
          final ticketsResponse = await apiService.getMyTickets(token);
          final tickets = List<Map<String, dynamic>>.from(ticketsResponse['data'] ?? []);
          final consultations = await apiService.getMyConsultations(token);
          
          String summary = "📊 **Here is your Account Summary:**\n\n";
          summary += "**Active Consultations:** ${consultations.length}\n";
          for (var c in consultations.take(2)) summary += "• ${c['status']} - ${c['date']} at ${c['time']}\n";
          
          summary += "\n**Active Support Tickets:** ${tickets.where((t) => t['status'] != 'closed').length}\n";
          for (var t in tickets.take(2)) summary += "• [${t['status'].toUpperCase()}] ${t['subject']}\n";
          
          actionFeedback = summary.trim();
        }
        else if (res['action'] == 'INITIATE_REFUND' && res['action_data'] != null) {
          final data = res['action_data'];
          await apiService.submitTicket(
            token: token,
            ticketType: 'Refund',
            subject: 'Automated Refund Request',
            message: data['reason'] ?? 'User requested a refund via Support AI.',
            date: DateTime.now().toString(),
          );
          actionFeedback = "✅ I have initiated the refund process for you. Our team will review your request and get back to you shortly.";
        }
        else if (res['action'] == 'NAVIGATE_SERVICE' && res['action_data'] != null) {
          final serviceType = res['action_data']['service_type'] ?? 'Citizen Services';
          actionFeedback = "I can redirect you to the $serviceType portal immediately! Please use the navigation menu or tap here to proceed.";
        }
        else if (res['action'] == 'CHECK_STATUS') {
          final ticketsResponse = await apiService.getMyTickets(token);
          final tickets = List<Map<String, dynamic>>.from(ticketsResponse['data'] ?? []);
          
          if (tickets.isEmpty) {
            actionFeedback = "You don't have any active support tickets.";
          } else {
            String summary = "Here are your recent tickets:\n\n";
            for (var t in tickets.take(3)) {
              summary += "• [${t['status'].toUpperCase()}] ${t['subject']}\n";
            }
            actionFeedback = summary.trim();
          }
        }
      }

      if (!mounted) return;

      setState(() {
        if (!suppressReply && res['reply'] != null) {
          _messages.add({"sender": "ai", "message": res['reply']});
        }
        if (actionFeedback != null) {
          _messages.add({"sender": "ai", "message": actionFeedback});
        }
        
        _isLoading = false;
        if (res['escalate'] == true) {
          _escalated = true;
        }
      });

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _messages.add({"sender": "ai", "message": "I'm having trouble connecting right now. Let me know if you want to escalate this to a human admin."});
      });
    }
  }

  Future<void> _escalateToAdmin() async {
    final token = ref.read(authProvider).token;
    if (token == null) return;
    
    // Auto-create a ticket based on chat history
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = "${months[DateTime.now().month - 1]} ${DateTime.now().day}, ${DateTime.now().year}";
    
    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      
      final historyStr = _messages.map((m) => "${m['sender'] == 'ai' ? 'Support Bot' : 'User'}: ${m['message']}").join('\n');
      
      await apiService.submitTicket(
        token: token,
        ticketType: 'Problem',
        subject: 'Escalated from Support Bot',
        message: 'Chat Transcript:\n$historyStr',
        date: dateStr,
      );
      
      if (!mounted) return;
      Navigator.pop(context); // close loader
      
      setState(() {
        _escalated = false;
        _messages.add({"sender": "ai", "message": "✅ I've escalated your issue to our Human Admin team! A support ticket has been created for you. You can track it in your Personal Vault > Support History."});
      });
    } catch (e) {
      Navigator.pop(context); // close loader
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to escalate: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.support_agent_rounded, color: AppTheme.navyDeep, size: 22),
            const SizedBox(width: 8),
            const Text('Support Bot', style: TextStyle(color: AppTheme.navyDeep, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
          ],
        ),
        iconTheme: const IconThemeData(color: AppTheme.navyDeep),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                
                if (msg["sender"] == "action_button") {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20, left: 16),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.open_in_new, color: Colors.white, size: 18),
                        label: Text(msg["message"] ?? 'Proceed', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.navyDeep,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          elevation: 8,
                          shadowColor: AppTheme.navyDeep.withOpacity(0.5),
                        ),
                        onPressed: () {
                          if (msg["route"] != null) {
                            context.push(msg["route"]!);
                          }
                        },
                      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
                    ),
                  );
                }

                final isUser = msg["sender"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                    child: Row(
                      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              gradient: isUser
                                  ? const LinearGradient(
                                      colors: [AppTheme.navyDeep, Color(0xFF1E293B)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: isUser ? null : Colors.white,
                              borderRadius: BorderRadius.circular(24).copyWith(
                                bottomRight: isUser ? const Radius.circular(6) : const Radius.circular(24),
                                bottomLeft: isUser ? const Radius.circular(24) : const Radius.circular(6),
                              ),
                              border: isUser ? null : Border.all(color: AppTheme.border.withOpacity(0.5)),
                              boxShadow: [
                                BoxShadow(
                                  color: isUser 
                                      ? AppTheme.navyDeep.withOpacity(0.25)
                                      : Colors.black.withOpacity(0.03),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                )
                              ],
                            ),
                            child: Text(
                              msg["message"]!,
                              style: TextStyle(
                                color: isUser ? Colors.white : AppTheme.navyDeep,
                                fontSize: 14.5,
                                height: 1.5,
                                fontWeight: isUser ? FontWeight.w500 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOutQuad).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
                );
              },
            ),
          ),
          
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),

          if (_escalated && !_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.person, color: Colors.white, size: 18),
                label: const Text('Escalate to Human Admin', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.goldPremium,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                ),
                onPressed: _escalateToAdmin,
              ).animate().shake(delay: 500.ms),
            ),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: InputDecoration(
                      hintText: 'Ask a legal question...',
                      hintStyle: TextStyle(color: AppTheme.textGrey, fontSize: 13),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                HoverButton(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.navyDeep,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
