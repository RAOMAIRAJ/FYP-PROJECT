import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qanoon_buddy/data/auth_provider.dart';
import 'package:qanoon_buddy/core/theme.dart';

class AuthModal extends ConsumerStatefulWidget {
  final bool isLawyer;
  const AuthModal({super.key, this.isLawyer = false});

  static void show(BuildContext context, {bool isLawyer = false}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: AuthModal(isLawyer: isLawyer),
        ),
      ),
    );
  }

  @override
  ConsumerState<AuthModal> createState() => _AuthModalState();
}

enum AuthState { socialMenu, emailForm, phoneEntry, otpForm }
enum AuthMode { login, register, phone }

class _AuthModalState extends ConsumerState<AuthModal> {
  AuthState _currentState = AuthState.socialMenu;
  AuthMode _authMode = AuthMode.login;

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController(); // For registration
  final _otpCtrl = TextEditingController();

  bool _obscurePass = true;
  String? _localError;

  // Password Validation States
  bool get _hasMinLength => _passCtrl.text.length >= 8;
  bool get _hasUpper => RegExp(r'[A-Z]').hasMatch(_passCtrl.text);
  bool get _hasNumber => RegExp(r'\d').hasMatch(_passCtrl.text);
  bool get _hasSpecial => RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(_passCtrl.text);
  bool get _isPasswordValid => _hasMinLength && _hasUpper && _hasNumber && _hasSpecial;

  // Phone Auth State
  String? _verificationId;
  final _phoneCtrl = TextEditingController();

  // Loading state locally for UI transition
  bool _isLoading = false;

  static const Color _bgDark = AppTheme.navyDeep; 
  static const Color _bgDarker = AppTheme.navyDarker; 
  static const Color _border = AppTheme.glassBorder; 
  static const Color _textWhite = Colors.white;
  static const Color _textGrey = AppTheme.textGrey; 
  static const Color _accent = AppTheme.goldPremium; 

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _otpCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This feature is coming soon in V2 🚀'),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitEmailForm() async {
    setState(() => _localError = null);
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final name = _nameCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty || (_authMode == AuthMode.register && name.isEmpty)) {
      setState(() => _localError = "Please fill in all fields");
      return;
    }

    if (_authMode == AuthMode.register && !_isPasswordValid) {
      setState(() => _localError = "Password does not meet criteria");
      return;
    }

    setState(() => _isLoading = true);

    if (_authMode == AuthMode.login) {
      final success = await ref.read(authProvider.notifier).login(email: email, password: pass);
      if (!mounted) return;
      if (success) {
        context.pop(); // close modal
        context.go('/home');
      } else {
        setState(() {
          _localError = ref.read(authProvider).error ?? "Login failed";
          _isLoading = false;
        });
      }
    } else {
      // Register
      final success = await ref.read(authProvider.notifier).sendOtp(email);
      if (!mounted) return;
      if (success) {
        setState(() {
          _isLoading = false;
          _currentState = AuthState.otpForm; // Transition to OTP
        });
      } else {
        setState(() {
          _localError = ref.read(authProvider).error ?? "Failed to send OTP";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitOtp() async {
    setState(() => _localError = null);
    final otp = _otpCtrl.text.trim();
    if (otp.isEmpty) {
      setState(() => _localError = "Enter OTP");
      return;
    }

    setState(() => _isLoading = true);
    
    bool success = false;
    
    if (_authMode == AuthMode.phone && _verificationId != null) {
      // Phone Auth Verification
      success = await ref.read(authProvider.notifier).verifyPhoneOtp(_verificationId!, otp);
    } else {
      // Email OTP Verification
      final isVerified = await ref.read(authProvider.notifier).verifyOtp(
        _emailCtrl.text.trim(),
        otp,
      );
      
      if (isVerified) {
        if (widget.isLawyer) {
          context.pop();
          context.push('/lawyer-register', extra: {
            'email': _emailCtrl.text.trim(),
            'password': _passCtrl.text,
            'fullName': _nameCtrl.text.trim(),
          });
          return;
        } else {
          success = await ref.read(authProvider.notifier).register(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
            fullName: _nameCtrl.text.trim(),
            city: 'Not Specified',
          );
        }
      }
    }
    
    if (!mounted) return;
    
    if (success) {
      context.pop();
      context.go('/home');
    } else {
      setState(() {
        _isLoading = false;
        _localError = ref.read(authProvider).error ?? "Verification failed";
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _localError = null;
    });
    
    final success = await ref.read(authProvider.notifier).signInWithGoogle();
    
    if (!mounted) return;
    if (success) {
      context.pop();
      context.go('/home');
    } else {
      setState(() {
        _isLoading = false;
        _localError = ref.read(authProvider).error ?? "Google Sign-in failed";
      });
    }
  }

  Future<void> _submitPhone() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      setState(() => _localError = "Enter phone number");
      return;
    }

    setState(() {
      _isLoading = true;
      _localError = null;
    });

    await ref.read(authProvider.notifier).signInWithPhone(
      phoneNumber: phone,
      onCodeSent: (vid) {
        if (!mounted) return;
        setState(() {
          _verificationId = vid;
          _authMode = AuthMode.phone;
          _currentState = AuthState.otpForm;
          _isLoading = false;
        });
      },
      onError: (err) {
        if (!mounted) return;
        setState(() {
          _localError = err;
          _isLoading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      width: 420, // Constrain width for a perfect popup on Desktop
      decoration: BoxDecoration(
        color: const Color(0xFF131B2B), // Slightly lighter than deep navy for contrast
        borderRadius: BorderRadius.circular(28), // Softer radius
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1), // Reverted to subtle white
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 40,
            spreadRadius: -10,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32), // Adjusted padding
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildCurrentState(),
        ),
      ),
    );
  }

  Widget _buildCurrentState() {
    switch (_currentState) {
      case AuthState.socialMenu:
        return _buildSocialMenu();
      case AuthState.emailForm:
        return _buildEmailForm();
      case AuthState.phoneEntry:
        return _buildPhoneEntry();
      case AuthState.otpForm:
        return _buildOtpForm();
    }
  }

  // ---------------------------------------------------------
  // 1. Social Menu (The ChatGPT-style landing)
  // ---------------------------------------------------------
  Widget _buildSocialMenu() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 40), // Spacer for centering title
            Text(
              widget.isLawyer ? 'Join as Lawyer' : 'Log in or sign up',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: _textGrey, size: 22),
              onPressed: () => context.pop(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'You’ll get smarter responses and can\nupload files, images, and more.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14, height: 1.4, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 32),
        
        _SocialButton(
          icon: Icons.g_mobiledata,
          text: 'Continue with Google',
          onTap: _showComingSoon,
        ),
        const SizedBox(height: 12),
        _SocialButton(
          icon: Icons.apple,
          text: 'Continue with Apple',
          onTap: _showComingSoon,
        ),
        const SizedBox(height: 12),
        _SocialButton(
          icon: Icons.phone_outlined,
          text: 'Continue with phone',
          onTap: _showComingSoon,
        ),
        
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Divider(color: Colors.white.withOpacity(0.08))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('OR', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
            ),
            Expanded(child: Divider(color: Colors.white.withOpacity(0.08))),
          ],
        ),
        const SizedBox(height: 24),
        
        Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [Color(0xFFD4AF37), Color(0xFFA67C00)], // Muted, rich metallic gold (not neon yellow)
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: ElevatedButton(
            onPressed: () => setState(() => _currentState = AuthState.emailForm),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: const Color(0xFF070B14), // Deepest navy for high contrast text
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Continue with Email', 
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70, size: 22),
              onPressed: () => setState(() => _currentState = AuthState.socialMenu),
            ),
            Text(
              _authMode == AuthMode.login ? 'Welcome back' : 'Create an account',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textWhite, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.5),
            ),
            const SizedBox(width: 48), // Spacer to balance the back button
          ],
        ),
        const SizedBox(height: 24),

        if (_localError != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1), 
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                const SizedBox(width: 12),
                Expanded(child: Text(_localError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500))),
              ],
            ),
          ),

        if (_authMode == AuthMode.register) ...[
          _InputField(
            hint: 'Full Name',
            controller: _nameCtrl,
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
        ],

        _InputField(
          hint: 'Email address',
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          icon: Icons.email_outlined,
        ),
        const SizedBox(height: 16),
        
        _InputField(
          hint: 'Password',
          controller: _passCtrl,
          obscureText: _obscurePass,
          icon: Icons.lock_outline,
          onChanged: (v) => setState(() {}),
          suffix: IconButton(
            icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.white54, size: 20),
            onPressed: () => setState(() => _obscurePass = !_obscurePass),
          ),
        ),
        
        if (_authMode == AuthMode.login)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton(
                onPressed: () {
                  context.pop();
                  context.push('/forgot-password');
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                ),
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        
        if (_authMode == AuthMode.register) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPasswordCriteriaRow('At least 8 characters', _hasMinLength),
                _buildPasswordCriteriaRow('At least 1 uppercase letter', _hasUpper),
                _buildPasswordCriteriaRow('At least 1 number', _hasNumber),
                _buildPasswordCriteriaRow('At least 1 special character', _hasSpecial),
              ],
            ),
          ),
        ],

        const SizedBox(height: 28),
        
        Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [
                (_authMode == AuthMode.register && !_isPasswordValid) ? Colors.white.withOpacity(0.1) : const Color(0xFFD4AF37), 
                (_authMode == AuthMode.register && !_isPasswordValid) ? Colors.white.withOpacity(0.05) : const Color(0xFFA67C00)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: (_authMode == AuthMode.register && !_isPasswordValid) ? [] : [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : (_authMode == AuthMode.register && !_isPasswordValid) ? null : _submitEmailForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: const Color(0xFF070B14),
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              disabledForegroundColor: Colors.white30,
            ),
            child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF070B14)))
                : const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
          ),
        ),

        const SizedBox(height: 24),
        Center(
          child: TextButton(
            onPressed: () {
              setState(() {
                _authMode = _authMode == AuthMode.login ? AuthMode.register : AuthMode.login;
                _localError = null;
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _authMode == AuthMode.login ? "Don't have an account? " : "Already have an account? ",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                ),
                Text(
                  _authMode == AuthMode.login ? "Sign up" : "Log in",
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  // ---------------------------------------------------------
  // 3. Phone Entry (Firebase Phone SMS)
  // ---------------------------------------------------------
  Widget _buildPhoneEntry() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: _textGrey),
                onPressed: () => setState(() => _currentState = AuthState.socialMenu),
              ),
            ),
            const Text(
              'Enter phone number',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'We’ll send a code to verify your phone.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _textGrey, fontSize: 14),
        ),
        const SizedBox(height: 24),
        
        if (_localError != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(_localError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ),

        _InputField(
          hint: '+92 300 1234567',
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 24),
        
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitPhone,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Send Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  // 4. OTP Form (Verification)
  // ---------------------------------------------------------
  Widget _buildOtpForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Check your email',
          textAlign: TextAlign.center,
          style: TextStyle(color: _textWhite, fontSize: 24, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Text(
          _authMode == AuthMode.phone 
            ? 'We sent a code to\n${_phoneCtrl.text}'
            : 'We sent a verification code to\n${_emailCtrl.text}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _textGrey, fontSize: 15, height: 1.4),
        ),
        const SizedBox(height: 24),

        if (_localError != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(_localError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ),

        _InputField(
          hint: 'Enter 6-digit code',
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          fontSize: 20,
          letterSpacing: 4.0,
        ),
        const SizedBox(height: 24),

        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Verify Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
        
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _currentState = AuthState.emailForm),
            child: const Text('Go back', style: TextStyle(color: _textGrey)),
          ),
        )
      ],
    );
  }

  // Helpers
  Widget _buildPasswordCriteriaRow(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: isMet ? Colors.greenAccent : Colors.white24,
            size: 16,
          ),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(color: isMet ? Colors.white : Colors.white54, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// Custom specialized inputs and buttons for the exact ChatGPT layout
class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _SocialButton({required this.icon, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.white.withOpacity(0.02),
        side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1), // Reverted to subtle white
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: Colors.white.withOpacity(0.8)), // Reverted to white
          const SizedBox(width: 10),
          Text(text, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.9))),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final Widget? suffix;
  final IconData? icon;
  final TextInputType keyboardType;
  final Function(String)? onChanged;
  final TextAlign textAlign;
  final double? fontSize;
  final double? letterSpacing;

  const _InputField({
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.suffix,
    this.icon,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.textAlign = TextAlign.start,
    this.fontSize,
    this.letterSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      textAlign: textAlign,
      style: TextStyle(color: Colors.white, fontSize: fontSize ?? 15, letterSpacing: letterSpacing, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), letterSpacing: 0, fontWeight: FontWeight.w400),
        filled: true,
        fillColor: Colors.white.withOpacity(0.03), 
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        prefixIcon: icon != null ? Icon(icon, color: Colors.white54, size: 20) : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
        suffixIcon: suffix,
      ),
    );
  }
}
