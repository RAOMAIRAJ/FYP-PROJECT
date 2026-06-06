import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qanoon_buddy/core/api_service.dart';
import 'package:qanoon_buddy/presentation/widgets/hover_button.dart';
import 'package:qanoon_buddy/core/theme.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;
  const ResetPasswordScreen({super.key, required this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  static const Color primary  = AppTheme.navyDeep;
  static const Color accent   = AppTheme.goldPremium;
  static const Color bg       = AppTheme.surface;
  static const Color textDark = AppTheme.textDark;
  static const Color border   = AppTheme.border;

  final _passwordController  = TextEditingController();
  final _confirmController   = TextEditingController();
  bool _isLoading            = false;
  bool _showPassword         = false;
  bool _showConfirm          = false;
  bool _isDone               = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    if (_passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 8 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await apiService.resetPassword(
        token      : widget.token,
        newPassword: _passwordController.text,
      );
      setState(() { _isLoading = false; _isDone = true; });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
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
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.glassWhite.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.glassBorder),
                      ),
                      child: const Center(
                        child: Text('🔑',
                            style: TextStyle(fontSize: 28)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('RESET PASSWORD',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        )),
                    const SizedBox(height: 6),
                    const Text(
                      'SECURE CREDENTIAL SYNCHRONIZATION',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: _isDone
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('✅',
                              style: TextStyle(fontSize: 64)),
                          const SizedBox(height: 20),
                          const Text('Password Reset!',
                              style: TextStyle(
                                color: textDark,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              )),
                          const SizedBox(height: 8),
                          const Text(
                            'Your password has been reset successfully.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppTheme.textGrey,
                                fontSize: 14),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () => context.go('/login'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(13)),
                              ),
                              child: const Text('Login Now',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  )),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),

                        // New password
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: border),
                          ),
                          child: TextField(
                            controller: _passwordController,
                            obscureText: !_showPassword,
                            style: const TextStyle(
                                color: textDark, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'New password',
                              hintStyle: const TextStyle(
                                  color: AppTheme.textGrey,
                                  fontSize: 13),
                              prefixIcon: const Icon(
                                  Icons.lock_outline,
                                  color: AppTheme.textGrey,
                                  size: 20),
                              suffixIcon: HoverButton(
                                onTap: () => setState(
                                    () => _showPassword = !_showPassword),
                                child: Icon(
                                  _showPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppTheme.textGrey,
                                  size: 20,
                                ),
                              ),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 16),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Confirm password
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: border),
                          ),
                          child: TextField(
                            controller: _confirmController,
                            obscureText: !_showConfirm,
                            style: const TextStyle(
                                color: textDark, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Confirm new password',
                              hintStyle: const TextStyle(
                                  color: AppTheme.textGrey,
                                  fontSize: 13),
                              prefixIcon: const Icon(
                                  Icons.lock_outline,
                                  color: AppTheme.textGrey,
                                  size: 20),
                              suffixIcon: HoverButton(
                                onTap: () => setState(
                                    () => _showConfirm = !_showConfirm),
                                child: Icon(
                                  _showConfirm
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: AppTheme.textGrey,
                                  size: 20,
                                ),
                              ),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 16),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _reset,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14)),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2))
                                : const Text('Reset Password',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    )),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}