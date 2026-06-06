import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qanoon_buddy/core/api_service.dart';
import 'package:qanoon_buddy/data/auth_provider.dart';
import 'package:qanoon_buddy/presentation/widgets/hover_button.dart';
import 'package:qanoon_buddy/core/theme.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String consultationId;
  final double amount;
  final String lawyerName;

  const PaymentScreen({
    super.key,
    required this.consultationId,
    required this.amount,
    required this.lawyerName,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  static const Color primary  = AppTheme.navyDeep;
  static const Color accent   = AppTheme.goldPremium;
  static const Color bg       = AppTheme.surface;
  static const Color textDark = AppTheme.textDark;
  static const Color textGrey = AppTheme.textGrey;
  static const Color border   = AppTheme.border;
  static const Color jazz     = AppTheme.brandJazz;

  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _isPaid    = false;
  String? _txnId;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (_phoneController.text.trim().length < 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: const Text('Please enter a valid phone number'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final token  = ref.read(authProvider).token!;
      final result = await apiService.initiatePayment(
        consultationId: widget.consultationId,
        phoneNumber   : _phoneController.text.trim(),
        amount        : widget.amount,
        token         : token,
      );
      setState(() {
        _isLoading = false;
        _isPaid    = true;
        _txnId     = result['transaction_id'];
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (!_isPaid) {
          try {
            final token = ref.read(authProvider).token;
            if (token != null) {
              await apiService.cancelConsultation(widget.consultationId, token);
            }
          } catch (e) {
            debugPrint('Cancel error on pop: $e');
          }
        }
        if (context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
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
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: Row(
                  children: [
                    HoverButton(
                      onTap: () async {
                        if (!_isPaid) {
                          try {
                            final token = ref.read(authProvider).token;
                            if (token != null) {
                              await apiService.cancelConsultation(widget.consultationId, token);
                            }
                          } catch (e) {
                            debugPrint('Cancel error on back: $e');
                          }
                        }
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.glassWhite.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.glassBorder),
                        ),
                        child: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PAYMENT PROTOCOL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            )),
                        Text('SECURE ESCROW CHANNEL',
                            style: TextStyle(
                              color: accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: _isPaid
                ? _buildSuccess()
                : _buildPaymentForm(),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildPaymentForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [

          // JazzCash logo card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: jazz.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('📱',
                        style: TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('JazzCash',
                    style: TextStyle(
                      color: jazz,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    )),
                const SizedBox(height: 4),
                const Text('Mobile Account Payment',
                    style: TextStyle(
                        color: textGrey, fontSize: 13)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Order summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Payment Summary',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 12),
                _SummaryRow(
                    label: 'Lawyer',
                    value: widget.lawyerName),
                _SummaryRow(
                    label: 'Consultation Fee',
                    value: '₨${widget.amount.toStringAsFixed(0)}'),
                _SummaryRow(
                    label: 'Platform Fee',
                    value: '₨0'),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total',
                        style: TextStyle(
                          color: textDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        )),
                    Text(
                      '₨${widget.amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Escrow Protection Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.navyDeep, AppTheme.navyLight],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: const Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_rounded, color: AppTheme.completed, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Escrow Protected',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Your funds are held securely and only released to the lawyer after they submit your consultation report.',
                  style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.5, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Phone number input
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('JazzCash Mobile Number',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border),
                  ),
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(
                        color: textDark, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: '03XX-XXXXXXX',
                      hintStyle: const TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 13),
                      prefixIcon: Icon(
                          Icons.phone_android_rounded,
                          color: AppTheme.textGrey,
                          size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.warning
                            .withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: AppTheme.warning, size: 15),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You will receive a confirmation SMS on this number',
                          style: TextStyle(
                            color: AppTheme.warning,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Pay button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _pay,
              style: ElevatedButton.styleFrom(
                backgroundColor: jazz,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)
                  : Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        const Text('📱',
                            style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Text(
                          'Pay ₨${widget.amount.toStringAsFixed(0)} via JazzCash',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 12),

          // Security note
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline,
                  color: textGrey.withOpacity(0.6), size: 13),
              const SizedBox(width: 5),
              Text('Secured by JazzCash',
                  style: TextStyle(
                    color: textGrey.withOpacity(0.6),
                    fontSize: 11,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: AppTheme.completed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('✅',
                    style: TextStyle(fontSize: 48)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Payment Successful!',
                style: TextStyle(
                  color: textDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 8),
            Text(
              'Your consultation with ${widget.lawyerName} has been confirmed.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: textGrey, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),

            // Transaction ID
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.completed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppTheme.completed
                        .withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  const Text('Transaction ID',
                      style: TextStyle(
                          color: textGrey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    _txnId ?? '',
                    style: const TextStyle(
                      color: AppTheme.completed,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => context.go('/'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13)),
                ),
                child: const Text('Back to Home',
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
    );
  }
}

// ── Summary Row ───────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final String label, value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textGrey, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                color: AppTheme.textDark,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}