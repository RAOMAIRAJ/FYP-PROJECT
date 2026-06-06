import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qanoon_buddy/core/api_service.dart';
import 'package:qanoon_buddy/data/auth_provider.dart';
import 'package:qanoon_buddy/presentation/screens/qna_detail_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qanoon_buddy/presentation/widgets/hover_button.dart';
import 'package:qanoon_buddy/core/theme.dart';

class QnaForumScreen extends ConsumerStatefulWidget {
  const QnaForumScreen({super.key});

  @override
  ConsumerState<QnaForumScreen> createState() => _QnaForumScreenState();
}

class _QnaForumScreenState extends ConsumerState<QnaForumScreen> {
  static const Color primary = AppTheme.navyDeep;
  static const Color accent = AppTheme.goldPremium;
  static const Color bg = AppTheme.surface;
  static const Color textDark = AppTheme.textDark;

  List<dynamic> _questions = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', 'General', 'Family Law', 'Tax Law', 'Criminal Law', 'Civil Law'];

  @override
  void initState() {
    super.initState();
    _fetchQuestions(refresh: true);
  }

  Future<void> _fetchQuestions({bool refresh = false}) async {
    if (refresh) {
      setState(() { 
        _isLoading = true; 
        _page = 1; 
        _hasMore = true; 
        _questions = []; 
      });
    } else {
      if (!_hasMore || _isLoadingMore) return;
      setState(() => _isLoadingMore = true);
    }

    try {
      final data = await apiService.getQuestions(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        page: _page,
      );
      if (mounted) {
        setState(() {
          if (refresh) {
            _questions = data;
          } else {
            _questions.addAll(data);
          }
          _isLoading = false;
          _isLoadingMore = false;
          _hasMore = data.length == 10;
          if (_hasMore) _page++;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _voteQuestion(String id, String action, int index) async {
    final token = ref.read(authProvider).token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to vote.')));
      return;
    }
    
    // Optimistic UI update
    setState(() {
      if (action == 'upvote') {
        _questions[index]['upvotes'] = (_questions[index]['upvotes'] ?? 0) + 1;
      } else {
        _questions[index]['downvotes'] = (_questions[index]['downvotes'] ?? 0) + 1;
      }
    });
    
    try {
      final result = await apiService.voteQuestion(token, id, action);
      if (mounted) {
        setState(() {
          _questions[index]['upvotes'] = result['upvotes'];
          _questions[index]['downvotes'] = result['downvotes'];
        });
      }
    } catch (e) {
      // Revert if API fails
      if (mounted) {
        setState(() {
          if (action == 'upvote') {
            _questions[index]['upvotes'] = (_questions[index]['upvotes'] ?? 1) - 1;
          } else {
            _questions[index]['downvotes'] = (_questions[index]['downvotes'] ?? 1) - 1;
          }
        });
      }
    }
  }

  void _showAskQuestionDialog(WidgetRef ref) {
    final auth = ref.read(authProvider);
    if (auth.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in first.')));
      return;
    }

    final controller = TextEditingController();
    String category = 'General';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
              ),
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Ask Anonymously', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textDark)),
                      HoverButton(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppTheme.surface, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 20, color: AppTheme.textGrey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Your identity will be protected with a generated pseudonym.', style: TextStyle(fontSize: 13, color: AppTheme.textGrey)),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: category,
                        isExpanded: true,
                        style: const TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.w600),
                        icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.textGrey),
                        items: _categories.where((c) => c != 'All').map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => category = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    maxLines: 5,
                    style: const TextStyle(fontSize: 15, color: textDark, height: 1.5),
                    decoration: InputDecoration(
                      hintText: 'Describe your legal situation... No personal details required.',
                      hintStyle: const TextStyle(color: AppTheme.textGrey),
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: accent)),
                      contentPadding: const EdgeInsets.all(20),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (controller.text.trim().length < 10) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Question must be at least 10 characters.'), backgroundColor: Colors.red),
                          );
                          return;
                        }
                        final token = ref.read(authProvider).token;
                        if (token == null) return;
                        try {
                          await apiService.askQuestion(token, controller.text.trim(), category);
                          if (mounted) {
                            Navigator.pop(context);
                            _fetchQuestions(refresh: true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Question posted successfully!'), backgroundColor: Colors.green),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to post: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Post Question', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                            child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('COMMUNITY FORUMS', 
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                              Text('REDDIT-STYLE LEGAL DISCUSSIONS', 
                                style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          final isSelected = _selectedCategory == cat;
                          return HoverButton(
                            onTap: () {
                              setState(() => _selectedCategory = cat);
                              _fetchQuestions(refresh: true);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? accent : AppTheme.glassWhite.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: isSelected ? accent : AppTheme.glassBorder),
                                boxShadow: isSelected ? [BoxShadow(color: accent.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))] : [],
                              ),
                              child: Text(
                                cat.toUpperCase(),
                                style: TextStyle(
                                  color: isSelected ? primary : Colors.white.withOpacity(0.6),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().slideY(begin: -0.2).fade(),

          // ── Body ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: primary))
                : RefreshIndicator(
                    onRefresh: () => _fetchQuestions(refresh: true),
                    color: primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      itemCount: _questions.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _questions.length) {
                          return _buildLoadMore();
                        }
                        final q = _questions[index];
                        final upvotes = q['upvotes'] ?? 0;
                        final downvotes = q['downvotes'] ?? 0;
                        final score = upvotes - downvotes;
                        final avatarColor = _parseColor(q['avatar_color']);
                        
                        return HoverButton(
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => QnaDetailScreen(questionId: q['id'])));
                            _fetchQuestions(refresh: true); 
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.border),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4)),
                              ],
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
                                        onTap: () => _voteQuestion(q['id'], 'upvote', index),
                                        child: const Icon(Icons.keyboard_arrow_up_rounded, size: 28, color: AppTheme.textGrey),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Text(
                                          score.toString(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14,
                                            color: score > 0 ? Colors.green : (score < 0 ? Colors.red : textDark),
                                          ),
                                        ),
                                      ),
                                      HoverButton(
                                        onTap: () => _voteQuestion(q['id'], 'downvote', index),
                                        child: const Icon(Icons.keyboard_arrow_down_rounded, size: 28, color: AppTheme.textGrey),
                                      ),
                                      const SizedBox(height: 12),
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
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(color: avatarColor.withOpacity(0.15), shape: BoxShape.circle),
                                              child: Icon(Icons.person, size: 14, color: avatarColor),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                q['pseudonym'] ?? 'Anonymous',
                                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: textDark),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text('•  ${q['category']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textGrey)),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          q['content'],
                                          maxLines: 4,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textDark, height: 1.4),
                                        ),
                                        const SizedBox(height: 16),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            if (q['ai_insight'] != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.purple.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.purple.withOpacity(0.2)),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.auto_awesome, size: 12, color: Colors.purple),
                                                    SizedBox(width: 4),
                                                    Text('AI Insight', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple)),
                                                  ],
                                                ),
                                              ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(8)),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.chat_bubble_outline_rounded, size: 12, color: AppTheme.textGrey),
                                                  const SizedBox(width: 6),
                                                  Text('${q['answer_count']} Comments', style: const TextStyle(fontSize: 11, color: AppTheme.textGrey, fontWeight: FontWeight.w700)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fade(delay: (index * 50).ms).slideX(begin: 0.1);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAskQuestionDialog(ref),
        backgroundColor: primary,
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ask Question', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildLoadMore() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: _isLoadingMore
          ? const Center(child: CircularProgressIndicator(color: primary))
          : Center(
              child: HoverButton(
                onTap: _fetchQuestions,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: const Text('LOAD MORE QUESTIONS', 
                    style: TextStyle(color: primary, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                ),
              ),
            ),
    );
  }
}
