import 'package:flutter/material.dart';
import 'package:qanoon_buddy/core/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qanoon_buddy/core/api_service.dart';
import 'package:qanoon_buddy/data/auth_provider.dart';
import 'package:qanoon_buddy/presentation/screens/booking_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qanoon_buddy/presentation/widgets/hover_button.dart';

class QnaDetailScreen extends ConsumerStatefulWidget {
  final String questionId;
  const QnaDetailScreen({super.key, required this.questionId});

  @override
  ConsumerState<QnaDetailScreen> createState() => _QnaDetailScreenState();
}

class _QnaDetailScreenState extends ConsumerState<QnaDetailScreen> {
  static const Color primary = AppTheme.navyDeep;
  static const Color accent = AppTheme.goldPremium;
  static const Color bg = AppTheme.surface;
  static const Color textDark = AppTheme.textDark;
  static const Color textGrey = AppTheme.textGrey;

  Map<String, dynamic>? _questionData;
  bool _isLoading = true;
  final _answerController = TextEditingController();
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() => _isLoading = true);
    try {
      final data = await apiService.getQuestionDetails(widget.questionId);
      if (mounted) {
        setState(() {
          _questionData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _voteQuestion(String action) async {
    final auth = ref.read(authProvider);
    if (auth.token == null) return;
    
    setState(() {
      if (action == 'upvote') {
        _questionData!['upvotes'] = (_questionData!['upvotes'] ?? 0) + 1;
      } else {
        _questionData!['downvotes'] = (_questionData!['downvotes'] ?? 0) + 1;
      }
    });
    try {
      final result = await apiService.voteQuestion(auth.token!, widget.questionId, action);
      if (mounted) {
        setState(() {
          _questionData!['upvotes'] = result['upvotes'];
          _questionData!['downvotes'] = result['downvotes'];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (action == 'upvote') _questionData!['upvotes']--;
          else _questionData!['downvotes']--;
        });
      }
    }
  }

  Future<void> _voteAnswer(String answerId, String action, int index) async {
    final auth = ref.read(authProvider);
    if (auth.token == null) return;
    
    setState(() {
      if (action == 'upvote') {
        _questionData!['answers'][index]['upvotes'] = (_questionData!['answers'][index]['upvotes'] ?? 0) + 1;
      } else {
        _questionData!['answers'][index]['downvotes'] = (_questionData!['answers'][index]['downvotes'] ?? 0) + 1;
      }
    });
    try {
      final result = await apiService.voteAnswer(auth.token!, answerId, action);
      if (mounted) {
        setState(() {
          _questionData!['answers'][index]['upvotes'] = result['upvotes'];
          _questionData!['answers'][index]['downvotes'] = result['downvotes'];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (action == 'upvote') _questionData!['answers'][index]['upvotes']--;
          else _questionData!['answers'][index]['downvotes']--;
        });
      }
    }
  }

  Future<void> _postAnswer() async {
    final auth = ref.read(authProvider);
    if (auth.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in first.')));
      return;
    }
    
    if (_answerController.text.trim().length < 10) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Your comment must be at least 10 characters long.'),
          backgroundColor: Colors.red,
        ));
      }
      return;
    }
    
    setState(() => _isPosting = true);
    try {
      await apiService.postAnswer(auth.token!, widget.questionId, _answerController.text.trim());
      _answerController.clear();
      await _fetchDetail();
      if (mounted) setState(() => _isPosting = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isPosting = false);
      }
    }
  }

  Color _parseColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return accent;
    try {
      final hex = hexString.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuth = ref.watch(authProvider).user != null;

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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                    const Text('Thread Discussion', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  ],
                ),
              ),
            ),
          ).animate().slideY(begin: -0.2).fade(),

          // ── Body ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primary))
                : _questionData == null
                    ? const Center(child: Text('Thread not found', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)))
                    : RefreshIndicator(
                        color: primary,
                        onRefresh: _fetchDetail,
                        child: CustomScrollView(
                          slivers: [
                          // ── Original Question ──
                          SliverToBoxAdapter(
                            child: Container(
                              margin: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.border),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 6))],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left Voting Sidebar
                                  Container(
                                    width: 50,
                                    decoration: BoxDecoration(
                                      color: AppTheme.surface,
                                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
                                    ),
                                    child: Column(
                                      children: [
                                        const SizedBox(height: 12),
                                        HoverButton(
                                          onTap: () => _voteQuestion('upvote'),
                                          child: const Icon(Icons.keyboard_arrow_up_rounded, size: 28, color: AppTheme.textGrey),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: Text(
                                            ((_questionData!['upvotes'] ?? 0) - (_questionData!['downvotes'] ?? 0)).toString(),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14,
                                              color: ((_questionData!['upvotes'] ?? 0) - (_questionData!['downvotes'] ?? 0)) > 0 ? Colors.green : textDark,
                                            ),
                                          ),
                                        ),
                                        HoverButton(
                                          onTap: () => _voteQuestion('downvote'),
                                          child: const Icon(Icons.keyboard_arrow_down_rounded, size: 28, color: AppTheme.textGrey),
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                    ),
                                  ),
                                  // Main Content
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(color: _parseColor(_questionData!['avatar_color']).withOpacity(0.15), shape: BoxShape.circle),
                                                child: Icon(Icons.person, color: _parseColor(_questionData!['avatar_color']), size: 14),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  _questionData!['pseudonym'] ?? 'Anonymous User',
                                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: textDark),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const Spacer(),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(8)),
                                                child: Text(_questionData!['category'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textGrey)),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            _questionData!['content'],
                                            style: const TextStyle(fontSize: 16, height: 1.6, color: textDark, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fade().slideY(begin: 0.1),
                          ),

                          // ── AI Insight (If Available) ──
                          if (_questionData!['ai_insight'] != null)
                            SliverToBoxAdapter(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.purple.withOpacity(0.2)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.auto_awesome, color: Colors.purple, size: 20),
                                        const SizedBox(width: 10),
                                        const Text('AI Legal Insight', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.purple, fontSize: 15)),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: Colors.purple, borderRadius: BorderRadius.circular(4)),
                                          child: const Text('AUTOMOD', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _questionData!['ai_insight'],
                                      style: const TextStyle(fontSize: 14, height: 1.6, color: textDark, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ).animate().fade().slideX(begin: -0.1),
                            ),
                            
                          const SliverToBoxAdapter(child: SizedBox(height: 8)),

                          // ── Answers List ──
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final ans = _questionData!['answers'][index];
                                final isLawyer = ans['lawyer'] != null;
                                final lawyer = ans['lawyer'];
                                final avatarColor = _parseColor(ans['avatar_color']);
                                final score = (ans['upvotes'] ?? 0) - (ans['downvotes'] ?? 0);

                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: isLawyer ? accent.withOpacity(0.5) : AppTheme.border, width: isLawyer ? 1.5 : 1),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Left Voting Sidebar for Comment
                                      Container(
                                        width: 44,
                                        decoration: BoxDecoration(
                                          color: AppTheme.surface,
                                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                                        ),
                                        child: Column(
                                          children: [
                                            const SizedBox(height: 8),
                                            HoverButton(
                                              onTap: () => _voteAnswer(ans['id'], 'upvote', index),
                                              child: const Icon(Icons.keyboard_arrow_up_rounded, size: 22, color: AppTheme.textGrey),
                                            ),
                                            Text(
                                              score.toString(),
                                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: score > 0 ? Colors.green : textGrey),
                                            ),
                                            HoverButton(
                                              onTap: () => _voteAnswer(ans['id'], 'downvote', index),
                                              child: const Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: AppTheme.textGrey),
                                            ),
                                            const SizedBox(height: 8),
                                          ],
                                        ),
                                      ),
                                      // Main Content
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  if (isLawyer)
                                                    CircleAvatar(
                                                      radius: 14,
                                                      backgroundColor: AppTheme.accepted.withOpacity(0.1),
                                                      child: const Icon(Icons.gavel_rounded, size: 14, color: accent),
                                                    )
                                                  else
                                                    CircleAvatar(
                                                      radius: 14,
                                                      backgroundColor: avatarColor.withOpacity(0.15),
                                                      child: Icon(Icons.person, size: 14, color: avatarColor),
                                                    ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      isLawyer ? lawyer['name'] : (ans['pseudonym'] ?? 'Community Member'),
                                                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: isLawyer ? accent : textDark),
                                                    ),
                                                  ),
                                                  if (isLawyer) ...[
                                                    const SizedBox(width: 4),
                                                    const Icon(Icons.verified_rounded, size: 14, color: AppTheme.completed),
                                                  ],
                                                ],
                                              ),
                                              if (isLawyer) ...[
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.star_rounded, size: 12, color: AppTheme.warning),
                                                    const SizedBox(width: 4),
                                                    Text('${lawyer['avg_rating']} rating', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textGrey)),
                                                    const Spacer(),
                                                    HoverButton(
                                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScreen(lawyer: lawyer))),
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: AppTheme.accepted.withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        child: const Text('Hire', style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.bold)),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                              const SizedBox(height: 12),
                                              Text(
                                                ans['content'],
                                                style: const TextStyle(fontSize: 14, height: 1.5, color: textDark, fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ).animate().fade(delay: (100 * index).ms).slideY(begin: 0.1);
                              },
                              childCount: (_questionData!['answers'] as List).length,
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 32)),
                        ],
                      ),
                    ),
          ),

          // ── Write Comment Bottom Bar (All Users) ──
          if (isAuth)
            Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, -6))],
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
                        controller: _answerController,
                        maxLines: 3,
                        minLines: 1,
                        style: const TextStyle(fontSize: 14, color: textDark),
                        decoration: const InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: TextStyle(color: textGrey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  HoverButton(
                    onTap: _isPosting ? null : _postAnswer,
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: primary,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                      ),
                      child: _isPosting 
                          ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ).animate().slideY(begin: 0.2).fade(),
        ],
      ),
    );
  }
}
