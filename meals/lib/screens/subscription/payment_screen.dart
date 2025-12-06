import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class PaymentScreen extends StatefulWidget {
  final String clientSecret;
  final String planName;
  final String planPrice;
  final String planPeriod;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const PaymentScreen({
    super.key,
    required this.clientSecret,
    required this.planName,
    required this.planPrice,
    required this.planPeriod,
    required this.onSuccess,
    required this.onCancel,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _cardFormController = CardFormEditController();

  bool _isProcessing = false;
  bool _cardComplete = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cardFormController.addListener(_onCardChanged);
  }

  @override
  void dispose() {
    _cardFormController.removeListener(_onCardChanged);
    _cardFormController.dispose();
    super.dispose();
  }

  void _onCardChanged() {
    setState(() {
      _cardComplete = _cardFormController.details.complete;
      _errorMessage = null;
    });
  }

  String _getNextBillingDate() {
    final now = DateTime.now();
    final nextDate = widget.planPeriod.contains('year')
        ? DateTime(now.year + 1, now.month, now.day)
        : DateTime(now.year, now.month + 1, now.day);

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[nextDate.month - 1]} ${nextDate.day}, ${nextDate.year}';
  }

  Future<void> _processPayment() async {
    if (!_cardComplete) {
      setState(() {
        _errorMessage = 'Please complete your card details';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      final paymentIntent = await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: widget.clientSecret,
        data: PaymentMethodParams.cardFromMethodId(
          paymentMethodData: PaymentMethodDataCardFromMethod(
            paymentMethodId: paymentMethod.id,
          ),
        ),
      );

      if (paymentIntent.status == PaymentIntentsStatus.Succeeded) {
        if (mounted) widget.onSuccess();
      } else if (paymentIntent.status == PaymentIntentsStatus.RequiresAction) {
        final result = await Stripe.instance.handleNextAction(
          widget.clientSecret,
        );
        if (result.status == PaymentIntentsStatus.Succeeded) {
          if (mounted) widget.onSuccess();
        } else {
          setState(() {
            _errorMessage = 'Authentication failed. Please try again.';
            _isProcessing = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Payment failed. Please try again.';
          _isProcessing = false;
        });
      }
    } on StripeException catch (e) {
      setState(() {
        _errorMessage = e.error.localizedMessage ?? 'Payment failed';
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final mutedColor = isDark ? Colors.white54 : Colors.black54;
    final surfaceColor = isDark
        ? const Color(0xFF1C1C1E)
        : const Color(0xFFF5F5F7);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: _isProcessing ? null : widget.onCancel,
                      style: TextButton.styleFrom(
                        foregroundColor: mutedColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline, size: 14, color: mutedColor),
                        const SizedBox(width: 4),
                        Text(
                          'Secure checkout',
                          style: TextStyle(
                            fontSize: 12,
                            color: mutedColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Plan info
                      Text(
                        'Subscribe to Premium',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.planName} plan · ${widget.planPeriod}',
                        style: TextStyle(
                          fontSize: 15,
                          color: mutedColor,
                          letterSpacing: -0.2,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Order summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            // Plan item
                            _buildLineItem(
                              'Premium ${widget.planName}',
                              widget.planPrice,
                              textColor,
                              mutedColor,
                            ),
                            const SizedBox(height: 10),

                            // Subtotal
                            _buildLineItem(
                              'Subtotal',
                              widget.planPrice,
                              textColor,
                              mutedColor,
                            ),
                            const SizedBox(height: 10),

                            // Tax
                            _buildLineItem(
                              'Tax',
                              '\$0.00',
                              textColor,
                              mutedColor,
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Divider(height: 1, color: borderColor),
                            ),

                            // Total
                            _buildLineItem(
                              'Total due today',
                              widget.planPrice,
                              textColor,
                              mutedColor,
                              isTotal: true,
                            ),

                            const SizedBox(height: 8),

                            // Renewal info
                            Text(
                              'Then ${widget.planPrice} ${widget.planPeriod} starting ${_getNextBillingDate()}',
                              style: TextStyle(
                                fontSize: 12,
                                color: mutedColor,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Card section header
                      Text(
                        'Payment method',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: mutedColor,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Stripe CardFormField - renders separate fields
                      CardFormField(
                        controller: _cardFormController,
                        enablePostalCode: false,
                        style: CardFormStyle(
                          backgroundColor: surfaceColor,
                          textColor: textColor,
                          placeholderColor: isDark
                              ? Colors.white38
                              : Colors.black38,
                          textErrorColor: Colors.red,
                          fontSize: 16,
                          borderWidth: 1,
                          borderColor: borderColor,
                          borderRadius: 12,
                          cursorColor: isDark ? Colors.white : Colors.black,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Accepted cards hint
                      Row(
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 13,
                            color: mutedColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Secured by Stripe',
                            style: TextStyle(fontSize: 12, color: mutedColor),
                          ),
                          const Spacer(),
                          Text(
                            'Visa, Mastercard, Amex',
                            style: TextStyle(fontSize: 12, color: mutedColor),
                          ),
                        ],
                      ),

                      // Error message
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.red,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Terms
                      Text(
                        'By subscribing, you agree to our Terms of Service. '
                        'Your subscription will automatically renew ${widget.planPeriod} '
                        'until you cancel. Cancel anytime in Settings.',
                        style: TextStyle(
                          fontSize: 12,
                          color: mutedColor,
                          height: 1.5,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom button
              Container(
                padding: EdgeInsets.fromLTRB(
                  24,
                  16,
                  24,
                  16 + MediaQuery.of(context).padding.bottom,
                ),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black : Colors.white,
                  border: Border(top: BorderSide(color: borderColor)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _isProcessing || !_cardComplete
                        ? null
                        : _processPayment,
                    style: FilledButton.styleFrom(
                      backgroundColor: _cardComplete
                          ? (isDark ? Colors.white : Colors.black)
                          : surfaceColor,
                      foregroundColor: _cardComplete
                          ? (isDark ? Colors.black : Colors.white)
                          : mutedColor,
                      disabledBackgroundColor: surfaceColor,
                      disabledForegroundColor: mutedColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isProcessing
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: isDark ? Colors.black : Colors.white,
                            ),
                          )
                        : Text(
                            'Pay ${widget.planPrice}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.3,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLineItem(
    String label,
    String value,
    Color textColor,
    Color mutedColor, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 15 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
            color: isTotal ? textColor : mutedColor,
            letterSpacing: -0.2,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 15 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
            color: textColor,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}
