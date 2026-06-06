import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:qanoon_buddy/core/api_service.dart';
import 'package:qanoon_buddy/data/auth_provider.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qanoon_buddy/presentation/widgets/hover_button.dart';
import 'package:go_router/go_router.dart';
import 'package:qanoon_buddy/core/theme.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _audioPath;
  bool _isUrdu = false;
  
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  String? _currentlySpeakingText;
  
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  
  List<dynamic> _sessions = [];
  String? _currentSessionId;
  List<String> _suggestions = [];

  static const Color primary = AppTheme.navyDeep;
  static const Color accent = AppTheme.goldPremium;
  static const Color bg = AppTheme.surface;
  static const Color textDark = AppTheme.textDark;
  static const Color textGrey = AppTheme.textGrey;
  static const Color border = AppTheme.border;

  @override
  void initState() {
    super.initState();
    _loadSessions();
    _initTts();
  }

  void _initTts() {
    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _currentlySpeakingText = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    final token = ref.read(authProvider).token;
    if (token == null) return;
    try {
      final sessions = await apiService.getChatSessions(token);
      if (mounted) {
        setState(() {
          _sessions = sessions;
        });
      }
    } catch (e) {
      debugPrint("Could not load sessions: $e");
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

  Future<void> _loadSessionHistory(String sessionId) async {
    final token = ref.read(authProvider).token;
    if (token == null) return;
    
    setState(() {
      _currentSessionId = sessionId;
      _isLoading = true;
      _messages.clear();
    });
    
    try {
       final history = await apiService.getSessionMessages(sessionId, token);
       if (mounted) {
         setState(() {
           for (var msg in history) {
             _messages.add({
               'role': msg['role'] as String,
               'text': msg['content'] as String,
               'time': _formatTime(DateTime.tryParse(msg['created_at'] ?? '') ?? DateTime.now()),
             });
           }
           _isLoading = false;
         });
         _scrollToBottom();
       }
    } catch (e) {
       setState(() => _isLoading = false);
    }
  }

  void _createNewSessionLocally() {
    setState(() {
       _currentSessionId = null;
       _messages.clear();
       _suggestions.clear();
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final hasImage = _selectedImage != null;
    if (text.isEmpty && !hasImage) return;
    
    final token = ref.read(authProvider).token;
    if (token == null) return;

    HapticFeedback.lightImpact();
    setState(() {
      _messages.add({
        'role': 'user', 
        'text': hasImage ? '[Image Attached] $text' : text, 
        'time': _formatTime(DateTime.now())
      });
      _isLoading = true;
    });
    
    final imageFile = _selectedImage;
    _messageController.clear();
    setState(() => _selectedImage = null);
    _scrollToBottom();
    
    try {
      if (_currentSessionId == null) {
         final newSession = await apiService.createChatSession(text.isNotEmpty ? text : "Image Query", token);
         _currentSessionId = newSession['id'];
         _loadSessions();
      }

      String payload = text;
      if (_isUrdu) {
        payload += "\n[SYSTEM INSTRUCTION: Provide the response strictly in clear, simple Urdu language (اردو) while translating all legal concepts accurately.]";
      }

      Map<String, dynamic> responseData;
      if (hasImage) {
        responseData = await apiService.sendImageQuery(imageFile!.path, payload, token, sessionId: _currentSessionId);
      } else {
        responseData = await apiService.sendChatMessage(_currentSessionId!, payload, token);
      }
      
      final responseText = responseData['response'] as String? ?? '';
      final rawSuggestions = responseData['suggestions'] as List<dynamic>? ?? [];
      final action = responseData['action'] as String?;
      final actionData = responseData['action_data'] as Map<String, dynamic>?;
      final sources = (responseData['sources'] as List<dynamic>?)?.map((s) => s.toString()).toList() ?? [];
      final isVerified = responseData['is_verified'] as bool? ?? false;
      final messageId = responseData['message_id'] as String?;

      if (mounted) {
        HapticFeedback.mediumImpact();
        setState(() {
          _messages.add({
            'role': 'bot', 
            'text': responseText, 
            'time': _formatTime(DateTime.now()),
            'sources': sources,
            'is_verified': isVerified,
            'message_id': messageId,
          });
          _suggestions = rawSuggestions.map((s) => s.toString()).toList();
          _isLoading = false;
        });
        _scrollToBottom();
      }

      // Handle Smart Actions (Tier 2)
      if (action == 'RECOMMEND_LAWYER' && actionData != null) {
        final specialization = actionData['specialization'];
        if (specialization != null) {
          try {
            final lawyers = await apiService.getLawyers(specialization: specialization);
            if (lawyers.isNotEmpty) {
              String lawyerText = "Here are some top **$specialization** lawyers I found for you:\n\n";
              for (var i = 0; i < lawyers.length && i < 3; i++) {
                final l = lawyers[i];
                lawyerText += "• **${l['name']}**\n  ⭐ ${l['rating']} | Rs. ${l['hourly_rate']}/hr\n";
                lawyerText += "  👉 [🗓️ Book Consultation](/form-booking?lawyer=${Uri.encodeComponent(l['name'])})\n\n";
              }
              lawyerText += "To view their full profiles, please visit the **Find Lawyers** tab!";
              
              if (mounted) {
                setState(() {
                  _messages.add({'role': 'bot', 'text': lawyerText.trim(), 'time': _formatTime(DateTime.now())});
                });
                _scrollToBottom();
              }
            }
          } catch (e) {
            debugPrint("Failed to fetch recommended lawyers: $e");
          }
        }
      } else if (action == 'RECOMMEND_TOOL' && actionData != null) {
        final toolName = actionData['tool_name'];
        if (toolName != null) {
          final String advice = "💡 **I recommend using our $toolName tool for this!**\n\nYou can access it anytime from the **AI Tools** tab on your home screen.";
          if (mounted) {
            setState(() {
              _messages.add({'role': 'bot', 'text': advice, 'time': _formatTime(DateTime.now())});
            });
            _scrollToBottom();
          }
        }
      } else if (action == 'DRAFT_FIR_INLINE' && actionData != null) {
        final details = actionData['incident_details'];
        if (details != null && mounted) {
          setState(() {
            _messages.add({'role': 'bot', 'text': 'I am drafting your FIR based on the details provided. Please wait a moment...', 'time': _formatTime(DateTime.now())});
          });
          _scrollToBottom();
          
          try {
            final draftResult = await apiService.generateFir(details, ref.read(authProvider).token ?? '');
            final String draftedFir = draftResult['fir_draft'] ?? 'Failed to draft FIR.';
            if (mounted) {
              setState(() {
                _messages.add({'role': 'bot', 'text': "📄 **Here is your auto-drafted FIR:**\n\n" + draftedFir + "\n\n*(Please review this draft carefully before submitting it to the authorities)*", 'time': _formatTime(DateTime.now())});
              });
              _scrollToBottom();
            }
          } catch (e) {
            if (mounted) {
              setState(() {
                _messages.add({'role': 'bot', 'text': 'Sorry, I encountered an error while drafting the FIR.', 'time': _formatTime(DateTime.now())});
              });
            }
          }
        }
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({'role': 'bot', 'text': 'Sorry, I encountered an error. Please try again later.', 'time': _formatTime(DateTime.now())});
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      await _flutterTts.stop();
      if (mounted) setState(() { _isSpeaking = false; _currentlySpeakingText = null; });
      if (await Permission.microphone.request().isGranted) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/query_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() {
          _isRecording = true;
          _audioPath = path;
        });
      }
    } catch (e) {
      debugPrint("Error starting record: $e");
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        _handleVoiceSubmit(path);
      }
    } catch (e) {
      debugPrint("Error stopping record: $e");
    }
  }

  Future<void> _handleVoiceSubmit(String path) async {
    final token = ref.read(authProvider).token;
    if (token == null) return;

    setState(() {
      _messages.add({'role': 'user', 'text': '[Voice Message]', 'time': _formatTime(DateTime.now())});
      _isLoading = true;
    });
    HapticFeedback.lightImpact();
    _scrollToBottom();

    try {
      // Auto-create session if none exists to ensure history is saved
      if (_currentSessionId == null) {
          final newSession = await apiService.createChatSession("Voice Query", token);
          _currentSessionId = newSession['id'];
          _loadSessions();
      }

      final result = await apiService.sendVoiceQuery(path, token, sessionId: _currentSessionId);
      final responseText = result['response'];
      final transcriptionText = result['transcription'] ?? '';
      final rawSuggestions = result['suggestions'] as List<dynamic>? ?? [];
      final action = result['action'] as String?;
      final actionData = result['action_data'] as Map<String, dynamic>?;

      if (mounted) {
        HapticFeedback.mediumImpact();
        setState(() {
          // Update the placeholder voice message with the actual transcription
          final lastUserMsgIndex = _messages.lastIndexWhere((m) => m['role'] == 'user' && m['text'] == '[Voice Message]');
          if (lastUserMsgIndex != -1 && transcriptionText.isNotEmpty) {
             _messages[lastUserMsgIndex] = {
                'role': 'user',
                'text': '[Voice Note] $transcriptionText',
                'time': _messages[lastUserMsgIndex]['time'] ?? _formatTime(DateTime.now())
             };
          }

          _messages.add({'role': 'bot', 'text': responseText, 'time': _formatTime(DateTime.now())});
          _suggestions = rawSuggestions.map((s) => s.toString()).toList();
          _isLoading = false;
        });
        _scrollToBottom();
      }

      // Handle Smart Actions (Tier 2/3)
      if (action == 'RECOMMEND_LAWYER' && actionData != null) {
        final specialization = actionData['specialization'];
        if (specialization != null) {
          try {
            final lawyers = await apiService.getLawyers(specialization: specialization);
            if (lawyers.isNotEmpty) {
              String lawyerText = "Here are some top **$specialization** lawyers I found for you:\n\n";
              for (var i = 0; i < lawyers.length && i < 3; i++) {
                final l = lawyers[i];
                lawyerText += "• **${l['name']}**\n  ⭐ ${l['rating']} | Rs. ${l['hourly_rate']}/hr\n";
                lawyerText += "  👉 [🗓️ Book Consultation](/form-booking?lawyer=${Uri.encodeComponent(l['name'])})\n\n";
              }
              lawyerText += "To view their full profiles, please visit the **Find Lawyers** tab!";
              
              if (mounted) {
                setState(() {
                  _messages.add({'role': 'bot', 'text': lawyerText.trim(), 'time': _formatTime(DateTime.now())});
                });
                _scrollToBottom();
              }
            }
          } catch (e) {
            debugPrint("Failed to fetch recommended lawyers: $e");
          }
        }
      } else if (action == 'RECOMMEND_TOOL' && actionData != null) {
        final toolName = actionData['tool_name'];
        if (toolName != null) {
          final String advice = "💡 **I recommend using our $toolName tool for this!**\n\nYou can access it anytime from the **AI Tools** tab on your home screen.";
          if (mounted) {
            setState(() {
              _messages.add({'role': 'bot', 'text': advice, 'time': _formatTime(DateTime.now())});
            });
            _scrollToBottom();
          }
        }
      } else if (action == 'DRAFT_FIR_INLINE' && actionData != null) {
        final details = actionData['incident_details'];
        if (details != null && mounted) {
          setState(() {
            _messages.add({'role': 'bot', 'text': 'I am drafting your FIR based on the details provided. Please wait a moment...', 'time': _formatTime(DateTime.now())});
          });
          _scrollToBottom();
          
          try {
            final draftResult = await apiService.generateFir(details, ref.read(authProvider).token ?? '');
            final String draftedFir = draftResult['fir_draft'] ?? 'Failed to draft FIR.';
            if (mounted) {
              setState(() {
                _messages.add({'role': 'bot', 'text': "📄 **Here is your auto-drafted FIR:**\n\n" + draftedFir + "\n\n*(Please review this draft carefully before submitting it to the authorities)*", 'time': _formatTime(DateTime.now())});
              });
              _scrollToBottom();
            }
          } catch (e) {
            if (mounted) {
              setState(() {
                _messages.add({'role': 'bot', 'text': 'Sorry, I encountered an error while drafting the FIR.', 'time': _formatTime(DateTime.now())});
              });
            }
          }
        }
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({'role': 'bot', 'text': 'Error processing voice: $e', 'time': _formatTime(DateTime.now())});
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } finally {
      // Cleanup temp file (only on native platforms)
      if (!kIsWeb) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      endDrawer: Drawer(
        child: Column(
          children: [
            Container(
               width: double.infinity,
               padding: const EdgeInsets.only(top: 60, bottom: 20, left: 24),
               decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [primary, AppTheme.navyDeep]),
               ),
               child: const Text('Chat History', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.add_circle, color: accent),
              title: const Text('New Conversation', style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _createNewSessionLocally();
              },
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _sessions.length,
                itemBuilder: (context, index) {
                  final s = _sessions[index];
                  final isSelected = s['id'] == _currentSessionId;
                  return ListTile(
                    leading: Icon(Icons.chat_bubble_outline, color: isSelected ? accent : Colors.grey),
                    title: Text(s['title'], maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    selected: isSelected,
                    selectedTileColor: accent.withOpacity(0.05),
                    onTap: () {
                       Navigator.pop(context);
                       _loadSessionHistory(s['id']);
                    },
                  );
                }
              ),
            ),
          ]
        )
      ),
      body: Column(
        children: [
          // ── Premium Gradient Header ──
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primary, Color(0xFF001A33)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: primary.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    HoverButton(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Legal AI Assistant',
                              style: TextStyle(
                                color: Colors.white, 
                                fontSize: 18, 
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5
                              )),
                          Row(
                            children: [
                              Container(
                                width: 6, height: 6,
                                decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 4),
                              Text('ONLINE', 
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7), 
                                  fontSize: 10, 
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0
                                )
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Language Toggle
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _isUrdu = !_isUrdu);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isUrdu ? accent.withOpacity(0.2) : Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _isUrdu ? accent.withOpacity(0.5) : Colors.white.withOpacity(0.1)),
                        ),
                        child: Text(
                          _isUrdu ? 'اردو' : 'EN',
                          style: TextStyle(color: _isUrdu ? accent : Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Drawer trigger
                    Builder(
                      builder: (ctx) => HoverButton(
                        onTap: () => Scaffold.of(ctx).openEndDrawer(),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: accent.withOpacity(0.2)),
                          ),
                          child: const Icon(Icons.history_rounded, color: accent, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().slideY(begin: -0.1).fade(),

          // ── Chat Body ──
          Expanded(
            child: _messages.isEmpty
              ? SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 60),
                        // Glowing AI Orb
                        Center(
                          child: Container(
                            width: 100, height: 100,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [primary, AppTheme.navyDeep], begin: Alignment.topLeft, end: Alignment.bottomRight),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: primary.withOpacity(0.3), blurRadius: 30, spreadRadius: 10, offset: const Offset(0, 15)),
                                BoxShadow(color: accent.withOpacity(0.2), blurRadius: 20, spreadRadius: 5, offset: const Offset(0, -5))
                              ],
                              border: Border.all(color: accent.withOpacity(0.6), width: 2),
                            ),
                            child: const Center(
                              child: Icon(Icons.psychology_rounded, size: 50, color: accent),
                            ),
                          ).animate(onPlay: (c) => c.repeat(reverse: true))
                           .scaleXY(begin: 1.0, end: 1.05, duration: 2.seconds, curve: Curves.easeInOut)
                           .shimmer(duration: 3.seconds, color: Colors.white24),
                        ),
                         
                        const SizedBox(height: 32),
                        // Personalized Greeting
                        Text(
                          _getGreeting(),
                          style: const TextStyle(
                            color: textDark, 
                            fontSize: 26, 
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5
                          ),
                          textAlign: TextAlign.left,
                        ).animate().fade().slideY(begin: 0.1),
                        const SizedBox(height: 12),
                        const Text('Your Elite AI Legal Counsel is ready.',
                          style: TextStyle(
                            color: textGrey, 
                            fontSize: 15, 
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5
                          ),
                          textAlign: TextAlign.left,
                        ).animate().fade(delay: 200.ms).slideY(begin: 0.1),
                        const SizedBox(height: 48),
                        
                        // Section Header
                        const Text('RECOMMENDED INQUIRIES', 
                          style: TextStyle(
                            color: textGrey, 
                            fontSize: 11, 
                            fontWeight: FontWeight.w900, 
                            letterSpacing: 2.0
                          )
                        ).animate().fade(delay: 400.ms),
                        const SizedBox(height: 16),
                        
                        // Advanced Grid Suggestion Cards
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.1,
                          children: [
                            _buildQuickAction('LODGE FIR', 'File Complaints', 'How do I legally draft a complaint?', Icons.edit_document),
                            _buildQuickAction('RIGHTS', 'Legal Protections', 'What are my fundamental rights?', Icons.shield_rounded),
                            _buildQuickAction('TENANCY', 'Rental Agreements', 'What are the rules for renting property?', Icons.home_work_rounded),
                            _buildQuickAction('FAMILY', 'Marriage & Custody', 'What are the laws regarding marriage and family?', Icons.family_restroom_rounded),
                          ].animate(interval: 80.ms).fade().slideY(begin: 0.1, curve: Curves.easeOut),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: _messages.length + (_isLoading ? 1 : 0) + (_suggestions.isNotEmpty && !_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Typing indicator
                    if (_isLoading && index == _messages.length) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18).copyWith(bottomLeft: const Radius.circular(4)),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildDot(0),
                              const SizedBox(width: 4),
                              _buildDot(1),
                              const SizedBox(width: 4),
                              _buildDot(2),
                              const SizedBox(width: 10),
                              const Text('Thinking...', style: TextStyle(color: AppTheme.textGrey, fontSize: 12, fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                      ).animate().fade().slideX(begin: -0.05);
                    }
                    
                    // Follow-up suggestion chips
                    final suggestionsIndex = _messages.length + (_isLoading ? 1 : 0);
                    if (index == suggestionsIndex && _suggestions.isNotEmpty && !_isLoading) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _suggestions.map((s) => _buildSuggestionChip(s)).toList()
                            ..forEach((w) {}),
                        ),
                      ).animate().fade().slideY(begin: 0.1);
                    }
                    
                    final msg = _messages[index];
                    final isUser = msg['role'] == 'user';
                    final timeStr = msg['time'] as String? ?? '';
                    final sources = (msg['sources'] as List<String>?) ?? [];
                    final isVerified = msg['is_verified'] as bool? ?? false;
                    final messageId = msg['message_id'] as String?;
                    final feedback = msg['feedback'] as String?;
                    
                    return _buildChatBubble(msg['text'] ?? '', isUser, timeStr, sources: sources, isVerified: isVerified, messageId: messageId, feedback: feedback, messageIndex: index).animate(key: ValueKey(index)).fade().slideY(begin: 0.05);
                  },
              ),
          ),

          // ── Input Area ──
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, -4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedImage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_selectedImage!, height: 80, width: 80, fit: BoxFit.cover),
                        ),
                        Positioned(
                          right: -8, top: -8,
                          child: IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.redAccent, size: 20),
                            onPressed: () => setState(() => _selectedImage = null),
                          ),
                        ),
                      ],
                    ).animate().scale(duration: 200.ms, curve: Curves.easeOut),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(fontSize: 14, color: AppTheme.textDark),
                      decoration: const InputDecoration(
                        hintText: 'Ask a legal question...',
                        hintStyle: TextStyle(color: AppTheme.textGrey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Attachment Button
                HoverButton(
                  onTap: _pickImage,
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.border), shape: BoxShape.circle),
                    child: const Icon(Icons.image_outlined, color: AppTheme.textGrey, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                // Mic Button
                HoverButton(
                  onLongPressStart: (_) => _startRecording(),
                  onLongPressEnd: (_) => _stopRecording(),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Hold the button to record your legal query'), duration: Duration(seconds: 1)),
                    );
                  },
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _isRecording ? const Color(0xFFEF4444) : Colors.white,
                      border: Border.all(color: _isRecording ? Colors.transparent : AppTheme.border),
                      shape: BoxShape.circle,
                      boxShadow: _isRecording ? [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 12, spreadRadius: 4)] : null,
                    ),
                    child: Icon(
                      _isRecording ? Icons.mic : Icons.mic_none,
                      color: _isRecording ? Colors.white : AppTheme.textGrey,
                      size: 20,
                    ),
                  ),
                ).animate(
                  target: _isRecording ? 1 : 0,
                  onComplete: (c) => c.repeat(),
                ).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 600.ms, curve: Curves.easeInOut),
                const SizedBox(width: 8),
                // Send Button
                HoverButton(
                  onTap: _isLoading ? null : _sendMessage,
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [primary, AppTheme.navyDeep]),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: _isLoading 
                        ? const Padding(padding: EdgeInsets.all(14), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
                  ],
                ),
              ],
            ),
          ).animate().slideY(begin: 0.2).fade(),
        ],
      ),
    );
  }

  Future<void> _speak(String text) async {
    if (_isSpeaking && _currentlySpeakingText == text) {
      await _flutterTts.stop();
      setState(() { _isSpeaking = false; _currentlySpeakingText = null; });
      return;
    }
    
    await _flutterTts.stop();
    
    // Clean text: remove markdown asterisks before speaking
    String cleanText = text.replaceAll(RegExp(r'\*+'), '');
    
    // Set language based on current toggle
    await _flutterTts.setLanguage(_isUrdu ? "ur-PK" : "en-US");
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    setState(() { _isSpeaking = true; _currentlySpeakingText = text; });
    await _flutterTts.speak(cleanText);
  }

  Widget _buildChatBubble(String text, bool isUser, String time, {List<String> sources = const [], bool isVerified = false, String? messageId, String? feedback, int? messageIndex}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Bot label (only for bot messages)
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 22, height: 22,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [accent, AppTheme.goldPremium]),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(child: Text('⚖️', style: TextStyle(fontSize: 11))),
                  ),
                  const SizedBox(width: 6),
                  const Text('Qanoon Buddy', style: TextStyle(fontSize: 11, color: AppTheme.textGrey, fontWeight: FontWeight.w600)),
                  if (isVerified) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF27AE60).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, size: 10, color: Color(0xFF27AE60)),
                          SizedBox(width: 3),
                          Text('Verified Source', style: TextStyle(fontSize: 9, color: Color(0xFF27AE60), fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          // Message bubble
          Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                gradient: isUser ? const LinearGradient(colors: [primary, AppTheme.navyDeep]) : null,
                color: isUser ? null : Colors.white,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
                  bottomLeft: !isUser ? const Radius.circular(4) : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUser ? accent.withOpacity(0.2) : Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              ),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  isUser 
                    ? Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4))
                    : MarkdownBody(
                        data: text,
                        selectable: true,
                        onTapLink: (text, href, title) {
                          if (href != null && href.startsWith('/form-booking')) {
                            final uri = Uri.parse(href);
                            final lawyerName = uri.queryParameters['lawyer'];
                            context.push('/form-booking', extra: lawyerName);
                          }
                        },
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(color: AppTheme.textDark, fontSize: 14, height: 1.5),
                          listBullet: const TextStyle(color: AppTheme.textDark, fontSize: 14),
                          strong: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                  if (time.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(time, style: TextStyle(
                      fontSize: 10, 
                      color: isUser ? Colors.white.withOpacity(0.7) : AppTheme.textGrey,
                    )),
                  ],
                ],
              ),
            ),
          ),
          // Source citations for bot messages
          if (!isUser && sources.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 6),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: sources.map((source) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isVerified ? const Color(0xFF27AE60).withOpacity(0.08) : Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isVerified ? const Color(0xFF27AE60).withOpacity(0.3) : Colors.orange.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.description_outlined, size: 10, color: isVerified ? const Color(0xFF27AE60) : Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        source.length > 30 ? '${source.substring(0, 27)}...' : source,
                        style: TextStyle(fontSize: 9, color: isVerified ? const Color(0xFF27AE60) : Colors.orange, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          // Action bar for bot messages (Copy & Share)
          if (!isUser && text.isNotEmpty && !text.startsWith('Sorry'))
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionButton(Icons.copy_rounded, 'Copy', () {
                    Clipboard.setData(ClipboardData(text: text));
                    HapticFeedback.selectionClick();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Response copied to clipboard'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }),
                  const SizedBox(width: 4),
                  _buildActionButton(Icons.share_rounded, 'Share', () {
                    HapticFeedback.selectionClick();
                    Share.share('Legal Advice from Qanoon Buddy:\n\n$text');
                  }),
                  const SizedBox(width: 4),
                  _buildActionButton(
                    _isSpeaking && _currentlySpeakingText == text ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                    _isSpeaking && _currentlySpeakingText == text ? 'Stop' : 'Listen', 
                    () {
                      HapticFeedback.selectionClick();
                      _speak(text);
                    }
                  ),
                  if (messageId != null) ...[
                    const SizedBox(width: 8),
                    Container(width: 1, height: 16, color: AppTheme.textGrey.withOpacity(0.2)),
                    const SizedBox(width: 8),
                    _buildFeedbackButton(Icons.thumb_up_rounded, feedback == 'up', () => _submitFeedback(messageId, 'up', messageIndex)),
                    const SizedBox(width: 4),
                    _buildFeedbackButton(Icons.thumb_down_rounded, feedback == 'down', () => _submitFeedback(messageId, 'down', messageIndex)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppTheme.textGrey),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textGrey, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackButton(IconData icon, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? accent.withOpacity(0.15) : AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: isActive ? Border.all(color: accent.withOpacity(0.3), width: 0.5) : null,
        ),
        child: Icon(icon, size: 14, color: isActive ? accent : AppTheme.textGrey),
      ),
    );
  }

  Future<void> _submitFeedback(String messageId, String feedbackType, int? messageIndex) async {
    final token = ref.read(authProvider).token;
    if (token == null) return;

    try {
      await apiService.submitFeedback(messageId, feedbackType, token);
      HapticFeedback.selectionClick();
      if (mounted && messageIndex != null) {
        setState(() {
          _messages[messageIndex]['feedback'] = feedbackType;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(feedbackType == 'up' ? '👍 Thanks for your feedback!' : '👎 We\'ll improve — thanks!'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Feedback error: $e");
    }
  }

  // ── Premium Quick Action Card ──
  Widget _buildQuickAction(String title, String subtitle, String query, IconData icon) {
    return HoverButton(
      onTap: () {
        HapticFeedback.mediumImpact();
        _messageController.text = query;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: border),
          boxShadow: [BoxShadow(color: primary.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: primary.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: primary, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: textGrey, fontSize: 11, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Follow-Up Suggestion Chip ──
  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _messageController.text = text;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent.withOpacity(0.08), accent.withOpacity(0.04)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app_rounded, size: 14, color: accent),
            const SizedBox(width: 6),
            Flexible(
              child: Text(text, style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Typing Animation Dot ──
  Widget _buildDot(int index) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: accent.withOpacity(0.6),
        shape: BoxShape.circle,
      ),
    ).animate(
      onPlay: (controller) => controller.repeat(),
    ).scale(
      begin: const Offset(0.5, 0.5),
      end: const Offset(1.0, 1.0),
      duration: 600.ms,
      delay: (index * 200).ms,
      curve: Curves.easeInOut,
    ).then().scale(
      begin: const Offset(1.0, 1.0),
      end: const Offset(0.5, 0.5),
      duration: 600.ms,
      curve: Curves.easeInOut,
    );
  }

  // ── Helpers ──
  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString()}:${dt.minute.toString().padLeft(2, '0')} $period';
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    final user = ref.read(authProvider).user;
    final name = (user?['full_name'] as String?)?.split(' ').first ?? '';
    
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }
    return name.isNotEmpty ? '$greeting, $name! 👋' : '$greeting! 👋';
  }
}