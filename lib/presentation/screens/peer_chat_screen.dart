import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qanoon_buddy/core/api_service.dart';
import 'package:qanoon_buddy/data/auth_provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qanoon_buddy/presentation/widgets/hover_button.dart';
import 'package:qanoon_buddy/core/theme.dart';

class PeerChatScreen extends ConsumerStatefulWidget {
  final String peerId;
  final String peerName;
  final String peerRole;

  const PeerChatScreen({
    super.key,
    required this.peerId,
    required this.peerName,
    required this.peerRole,
  });

  @override
  ConsumerState<PeerChatScreen> createState() => _PeerChatScreenState();
}

class _PeerChatScreenState extends ConsumerState<PeerChatScreen> {
  static const Color primary = AppTheme.navyDeep;
  static const Color accent = AppTheme.goldPremium;
  static const Color bg = AppTheme.surface;
  static const Color textDark = AppTheme.textDark;
  static const Color textGrey = AppTheme.textGrey;
  static const Color border = AppTheme.border;
  
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _skip = 0;
  final int _limit = 20;
  WebSocketChannel? _channel;
  String? _myUserId;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final token = ref.read(authProvider).token;
    _myUserId = ref.read(authProvider).user?['id'];
    
    if (token == null || _myUserId == null) return;

    try {
      final history = await apiService.getPeerChatHistory(widget.peerId, token, skip: 0, limit: _limit);
      if (mounted) {
        setState(() {
          _messages = history;
          _isLoading = false;
          _hasMore = history.length == _limit;
          if (_hasMore) _skip = _limit;
        });
        _scrollToBottom();
      }
      
      final baseUrl = ApiService.wsUrl.endsWith('/') ? ApiService.wsUrl.substring(0, ApiService.wsUrl.length - 1) : ApiService.wsUrl;
      final wsUrl = '$baseUrl/messages/ws?token=$token&target_id=${widget.peerId}';
      
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      _channel!.stream.listen(
        (data) {
          final msg = jsonDecode(data);
          if (msg['sender_id'] == _myUserId) return;
          if (mounted) {
            setState(() {
              _messages.add(msg);
            });
            _scrollToBottom();
          }
        },
        onError: (error) => print('WebSocket Error: $error'),
      );
      
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadOlderMessages() async {
    if (!_hasMore || _isLoadingMore) return;
    final token = ref.read(authProvider).token;
    if (token == null) return;

    setState(() => _isLoadingMore = true);

    try {
      final olderMessages = await apiService.getPeerChatHistory(widget.peerId, token, skip: _skip, limit: _limit);
      if (mounted) {
        setState(() {
          // Prepend older messages
          _messages.insertAll(0, olderMessages);
          _isLoadingMore = false;
          _hasMore = olderMessages.length == _limit;
          if (_hasMore) _skip += _limit;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty || _channel == null) return;
    
    setState(() {
      _messages.add({
        'sender_id': _myUserId,
        'receiver_id': widget.peerId,
        'content': text,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
    _scrollToBottom();
    
    _channel!.sink.add(text);
    _controller.clear();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          // ── Gradient Header ──
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: accent.withOpacity(0.2),
                      child: Text(
                        widget.peerName[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.peerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(widget.peerRole.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 0.5, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().slideY(begin: -0.1).fade(),

          // ── Chat Body ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: accent))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: _messages.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_hasMore && index == 0) {
                        return _buildLoadMore();
                      }
                      
                      final msgIndex = _hasMore ? index - 1 : index;
                      final msg = _messages[msgIndex];
                      final isMe = msg['sender_id'] == _myUserId;
                      return _buildChatBubble(msg['content'] ?? '', isMe).animate().fade().slideY(begin: 0.1);
                    },
                  ),
          ),

          // ── Input Area ──
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, -4)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(fontSize: 14, color: AppTheme.textDark),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: const TextStyle(color: AppTheme.textGrey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                HoverButton(
                  onTap: _sendMessage,
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [primary, AppTheme.navyLight]),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ).animate().slideY(begin: 0.2).fade(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isMe ? const LinearGradient(colors: [primary, AppTheme.navyLight]) : null,
          color: isMe ? null : Colors.white,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
            bottomLeft: !isMe ? const Radius.circular(4) : const Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: isMe ? accent.withOpacity(0.2) : Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Text(
          text,
          style: TextStyle(
            color: isMe ? Colors.white : AppTheme.textDark,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMore() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: _isLoadingMore
          ? const Center(child: CircularProgressIndicator(color: accent, strokeWidth: 2))
          : Center(
              child: TextButton(
                onPressed: _loadOlderMessages,
                child: const Text('Load Older Messages', 
                  style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
    );
  }
}
