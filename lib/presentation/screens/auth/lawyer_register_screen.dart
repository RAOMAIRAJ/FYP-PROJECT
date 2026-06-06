import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qanoon_buddy/core/api_service.dart';
import 'package:qanoon_buddy/data/auth_provider.dart';
import 'package:qanoon_buddy/presentation/widgets/hover_button.dart';
import 'package:qanoon_buddy/core/theme.dart';

class LawyerRegisterScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialData;
  const LawyerRegisterScreen({super.key, this.initialData});

  @override
  ConsumerState<LawyerRegisterScreen> createState() =>
      _LawyerRegisterScreenState();
}

class _LawyerRegisterScreenState
    extends ConsumerState<LawyerRegisterScreen> {
  // Controllers
  final _nameController       = TextEditingController();
  final _emailController      = TextEditingController();
  final _passwordController   = TextEditingController();
  final _phoneController      = TextEditingController();
  final _cityController       = TextEditingController();
  final _barCouncilController = TextEditingController();
  final _cnicController       = TextEditingController();
  final _feeController        = TextEditingController();
  final _bioController        = TextEditingController();
  final _expController        = TextEditingController();
  final _otpController        = TextEditingController();

  String _specialization   = 'family_law';
  bool   _availableOnline  = true;
  bool   _availableInPerson= true;
  bool   _obscurePassword  = true;
  bool   _isLoading        = false;
  bool   _isOtpSent        = false;
  bool   _isEmailVerified  = false;
  String? _error;

  int _currentStep = 0; // 0 = personal, 1 = professional, 2 = review

  static const Color primaryBlue = AppTheme.navyDeep;
  static const Color accentBlue  = AppTheme.goldPremium;
  static const Color bgGrey      = AppTheme.navyDeep;
  static const Color textMuted   = AppTheme.textGrey;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _nameController.text = widget.initialData!['fullName'] ?? '';
      _emailController.text = widget.initialData!['email'] ?? '';
      _passwordController.text = widget.initialData!['password'] ?? '';
      _isEmailVerified = true;
      _isOtpSent = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _barCouncilController.dispose();
    _cnicController.dispose();
    _feeController.dispose();
    _bioController.dispose();
    _expController.dispose();
    super.dispose();
  }

  void _register() async {
    // Validation
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _cityController.text.trim().isEmpty ||
        _barCouncilController.text.trim().isEmpty ||
        _cnicController.text.trim().isEmpty ||
        _feeController.text.trim().isEmpty) {
      setState(() => _error = 'Please fill in all required fields.');
      return;
    }

    if (_passwordController.text.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      await apiService.registerLawyer(
        fullName         : _nameController.text.trim(),
        email            : _emailController.text.trim(),
        password         : _passwordController.text,
        phone            : _phoneController.text.trim(),
        city             : _cityController.text.trim(),
        barCouncilNumber : _barCouncilController.text.trim(),
        cnic             : _cnicController.text.trim(),
        specialization   : _specialization,
        consultationFee  : double.parse(_feeController.text.trim()),
        yearsExperience  : int.tryParse(_expController.text.trim()) ?? 0,
        bio              : _bioController.text.trim(),
        availableOnline  : _availableOnline,
        availableInPerson: _availableInPerson,
      );

      setState(() => _isLoading = false);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            backgroundColor: AppTheme.navyDeep,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withOpacity(0.1))),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(
                    color: AppTheme.completed.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.check_circle_rounded,
                        color: AppTheme.completed, size: 40),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Application Submitted!',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    )),
                const SizedBox(height: 8),
                const Text(
                  'Your lawyer account is pending admin approval. You will be notified once approved.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppTheme.textGrey, fontSize: 13),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentBlue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Go to Login',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString().contains('409')
            ? 'Email or CNIC already registered.'
            : 'Registration failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      body: Column(
        children: [
          // ── Header ──
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryBlue, AppTheme.navyDeep.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft : Radius.circular(24),
                bottomRight: Radius.circular(24),
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
                          onTap: () {
                            if (_currentStep > 0) {
                              setState(() => _currentStep--);
                            } else {
                              context.go('/login');
                            }
                          },
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.12)),
                            ),
                            child: const Icon(Icons.arrow_back,
                                color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Lawyer Registration',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                )),
                            Text('Join as a verified lawyer',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                )),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Step indicator
                    Row(
                      children: List.generate(3, (i) {
                        final done   = i < _currentStep;
                        final active = i == _currentStep;
                        return Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: done || active
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              if (i < 2) const SizedBox(width: 4),
                            ],
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentStep == 0
                          ? 'Step 1 of 3 — Personal Info'
                          : _currentStep == 1
                              ? 'Step 2 of 3 — Professional Info'
                              : 'Step 3 of 3 — Review & Submit',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Form Body ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Error box
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.error.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppTheme.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!,
                                style: const TextStyle(
                                    color: AppTheme.error, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),

                  // ── STEP 1: Email Verification & Personal Info ──
                  if (_currentStep == 0) ...[
                    // Email Section
                    _label('Email *'),
                    _field(_emailController, 'ahmed@lawyer.com',
                        Icons.email_outlined,
                        keyboard: TextInputType.emailAddress,
                        enabled: !(_isOtpSent && _isEmailVerified)),
                    
                    const SizedBox(height: 12),
                    
                    if (!_isEmailVerified) ...[
                      if (!_isOtpSent)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () async {
                              final auth = ref.read(authProvider.notifier);
                              if (_emailController.text.trim().isEmpty) {
                                setState(() => _error = 'Enter your email first');
                                return;
                              }
                              setState(() { _isLoading = true; _error = null; });
                              final success = await auth.sendOtp(_emailController.text.trim());
                              setState(() {
                                _isLoading = false;
                                if (success) {
                                  _isOtpSent = true;
                                  _error = null;
                                } else {
                                  _error = ref.read(authProvider).error ?? 'Failed to send OTP';
                                }
                              });
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: accentBlue),
                            child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Send Verification Code', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      if (_isOtpSent) ...[
                        _label('Enter OTP sent to email *'),
                        TextField(
                          controller: _otpController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: _inputDeco(hint: '123456', icon: Icons.lock_clock_outlined),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () async {
                              final auth = ref.read(authProvider.notifier);
                              if (_otpController.text.trim().length != 6) {
                                setState(() => _error = 'Enter a valid 6-digit OTP');
                                return;
                              }
                              setState(() { _isLoading = true; _error = null; });
                              final success = await auth.verifyOtp(_emailController.text.trim(), _otpController.text.trim());
                              setState(() {
                                _isLoading = false;
                                if (success) {
                                  _isEmailVerified = true;
                                  _error = null;
                                } else {
                                  _error = ref.read(authProvider).error ?? 'Invalid OTP';
                                }
                              });
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.completed),
                            child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Verify OTP', style: TextStyle(color: Colors.white)),
                          ),
                        )
                      ],
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 20),
                    ] else ...[
                       Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(color: AppTheme.completed.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Row(
                          children: [
                             Icon(Icons.check_circle, color: AppTheme.completed, size: 18),
                            SizedBox(width: 8),
                             Text('Email Verified', style: TextStyle(color: AppTheme.completed, fontWeight: FontWeight.bold)),
                          ]
                        ),
                      ),
                      
                      _label('Full Name *'),
                      _field(_nameController, 'Adv. Ahmed Khan',
                          Icons.person_outline),
                      const SizedBox(height: 16),

                      _label('Phone Number'),
                      _field(_phoneController, '0300-1234567',
                          Icons.phone_outlined,
                          keyboard: TextInputType.phone),
                      const SizedBox(height: 16),

                      _label('City *'),
                      _field(_cityController, 'Karachi',
                          Icons.location_city_outlined),
                      const SizedBox(height: 16),

                      if (widget.initialData == null) ...[
                        _label('Password *'),
                        TextField(
                          controller: _passwordController,
                          style: const TextStyle(color: Colors.white),
                          obscureText: _obscurePassword,
                          decoration: _inputDeco(
                            hint: '••••••••',
                            icon: Icons.lock_outline,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: textMuted,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),
                      ],
                    ]
                  ],

                  // ── STEP 2 — Professional Info ──
                  if (_currentStep == 1) ...[
                    _label('Bar Council Number *'),
                    _field(_barCouncilController, 'KHI-2024-001',
                        Icons.badge_outlined),
                    const SizedBox(height: 4),
                    const Text(
                      'Format: KHI-2024-001 or LHR-2024-001',
                      style: TextStyle(
                          color: AppTheme.textGrey, fontSize: 11),
                    ),
                    const SizedBox(height: 16),

                    _label('CNIC *'),
                    _field(_cnicController, '42101-1234567-1',
                        Icons.credit_card_outlined,
                        keyboard: TextInputType.number),
                    const SizedBox(height: 4),
                    const Text(
                      'Format: XXXXX-XXXXXXX-X',
                      style: TextStyle(
                          color: AppTheme.textGrey, fontSize: 11),
                    ),
                    const SizedBox(height: 16),

                    _label('Specialization *'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _specTab('👪 Family Law', 'family_law'),
                        _specTab('💰 Tax & Corporate', 'tax_law'),
                        _specTab('⚖ Criminal Defense', 'criminal_law'),
                        _specTab('🏢 Property & Real', 'property_law'),
                        _specTab('💻 Cybercrime', 'cybercrime_law'),
                        _specTab('📜 Civil Litigation', 'civil_law'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _label('Consultation Fee (PKR) *'),
                    _field(_feeController, '2500',
                        Icons.payments_outlined,
                        keyboard: TextInputType.number),
                    const SizedBox(height: 16),

                    _label('Years of Experience'),
                    _field(_expController, '5',
                        Icons.work_outline,
                        keyboard: TextInputType.number),
                    const SizedBox(height: 16),

                    _label('Bio / About'),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.1)),
                      ),
                       child: TextField(
                        controller: _bioController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        decoration: const InputDecoration(
                          filled: false,
                          hintText:
                              'Brief description of your expertise...',
                          hintStyle: TextStyle(
                              color: AppTheme.textGrey, fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _label('Availability'),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.videocam_outlined,
                                  color: accentBlue, size: 20),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text('Available Online',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    )),
                              ),
                              Switch(
                                value: _availableOnline,
                                onChanged: (v) =>
                                    setState(() => _availableOnline = v),
                                activeColor: accentBlue,
                              ),
                            ],
                          ),
                          const Divider(height: 1),
                          Row(
                            children: [
                              const Icon(Icons.business_outlined,
                                  color: accentBlue, size: 20),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text('Available In-Person',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    )),
                              ),
                              Switch(
                                value: _availableInPerson,
                                onChanged: (v) => setState(
                                    () => _availableInPerson = v),
                                activeColor: accentBlue,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── STEP 3 — Review ──
                  if (_currentStep == 2) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _reviewRow('Full Name',
                              _nameController.text),
                          _reviewRow('Email',
                              _emailController.text),
                          _reviewRow('City',
                              _cityController.text),
                          _reviewRow('Bar Council No.',
                              _barCouncilController.text),
                          _reviewRow('CNIC',
                              _cnicController.text),
                          _reviewRow('Specialization',
                              _specialization),
                          _reviewRow('Fee',
                              '₨${_feeController.text}/session'),
                          _reviewRow('Experience',
                              '${_expController.text} years'),
                          _reviewRow('Online',
                              _availableOnline ? 'Yes' : 'No',
                              isLast: true),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: accentBlue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: accentBlue.withOpacity(0.2)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: accentBlue, size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Your account will be reviewed by admin before appearing in search results. This usually takes 24-48 hours.',
                              style: TextStyle(
                                color: accentBlue,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // ── Navigation Buttons ──
                  if (_currentStep == 0 && !_isEmailVerified)
                    const SizedBox.shrink()
                  else
                  Row(
                    children: [
                      if (_currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(
                                () => _currentStep--),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: primaryBlue),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                            ),
                            child: const Text('Back',
                                style: TextStyle(
                                    color: primaryBlue,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      if (_currentStep > 0)
                        const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  if (_currentStep < 2) {
                                    setState(() => _currentStep++);
                                  } else {
                                    _register();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(
                                  _currentStep < 2
                                      ? 'Next Step →'
                                      : 'Submit Application',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────

  Widget _specTab(String label, String value) {
    final selected = _specialization == value;
    return HoverButton(
      onTap: () => setState(() => _specialization = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: selected
              ? accentBlue
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            )),
      ),
    );
  }

  Widget _reviewRow(String label, String value,
      {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppTheme.glassBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textGrey, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.white,
              )),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.white,
          )),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
    bool enabled = true,
  }) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboard,
      enabled: enabled,
      decoration: _inputDeco(hint: hint, icon: icon),
    );
  }

  InputDecoration _inputDeco({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.textGrey, fontSize: 13),
      prefixIcon: Icon(icon, color: accentBlue, size: 20),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accentBlue, width: 1.5),
      ),
    );
  }
}