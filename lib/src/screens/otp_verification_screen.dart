import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_controller.dart';
import '../theme.dart';
import '../widgets/adaptive.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isSubmitting = false;
  int _countdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _countdown = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 0) {
        timer.cancel();
      } else {
        setState(() {
          _countdown--;
        });
      }
    });
  }

  Future<void> _submit(AppController controller) async {
    final otp = _otpController.text.trim();
    if (otp.length < 6) {
      _showMessage('Vui lòng nhập đầy đủ mã OTP 6 chữ số.');
      return;
    }

    setState(() => _isSubmitting = true);
    final error = await controller.verifyOtp(
      email: controller.pendingVerificationEmail ?? '',
      otp: otp,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (error != null) {
      _showMessage(error);
    }
  }

  Future<void> _resend(AppController controller) async {
    final email = controller.pendingVerificationEmail;
    if (email == null) return;

    setState(() => _isSubmitting = true);
    final error = await controller.resendOtp(email: email);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (error != null) {
      _showMessage(error);
    } else {
      _showMessage('Mã xác thực mới đã được gửi.');
      _startCountdown();
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = CoreHealthScope.of(context);
    final email = controller.pendingVerificationEmail ?? '';
    final layout = PhoneLayout.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppPalette.background,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              layout.horizontalPadding,
              16,
              layout.horizontalPadding,
              32,
            ),
            child: AdaptiveContent(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: controller.cancelVerification,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Xác thực tài khoản',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Chúng tôi đã gửi mã xác thực 6 chữ số đến địa chỉ email:\n$email',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 36),
                  PinInput(
                    controller: _otpController,
                    length: 6,
                    onCompleted: (val) => _submit(controller),
                  ),
                  const SizedBox(height: 36),
                  if (_isSubmitting)
                    const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation(AppPalette.emeraldDeep),
                      ),
                    )
                  else
                    FilledButton(
                      onPressed: () => _submit(controller),
                      child: const Text('Xác nhận'),
                    ),
                  const SizedBox(height: 24),
                  Center(
                    child: _countdown > 0
                        ? Text(
                            'Gửi lại mã sau ${_countdown}s',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppPalette.mutedText,
                                ),
                          )
                        : TextButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => _resend(controller),
                            child: const Text(
                              'Gửi lại mã xác thực',
                              style: TextStyle(
                                color: AppPalette.emeraldDeep,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 48),
                  if (controller.devOtp != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppPalette.emeraldSoft,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppPalette.accentMuted),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.bug_report,
                                  color: AppPalette.emeraldDeep),
                              SizedBox(width: 8),
                              Text(
                                'Chế độ nhà phát triển (Development OTP)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppPalette.text,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Mã OTP được hệ thống giả lập phát sinh: ${controller.devOtp}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppPalette.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PinInput extends StatefulWidget {
  final TextEditingController controller;
  final int length;
  final ValueChanged<String>? onCompleted;

  const PinInput({
    super.key,
    required this.controller,
    this.length = 6,
    this.onCompleted,
  });

  @override
  State<PinInput> createState() => _PinInputState();
}

class _PinInputState extends State<PinInput> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _focusNode.requestFocus,
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final text = widget.controller.text;
          return SizedBox(
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  maxLength: widget.length,
                  cursorColor: Colors.transparent,
                  style: const TextStyle(color: Colors.transparent),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(widget.length),
                  ],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (val) {
                    if (val.length == widget.length) {
                      widget.onCompleted?.call(val);
                    }
                  },
                ),
                IgnorePointer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(widget.length, (index) {
                      final hasChar = index < text.length;
                      final char = hasChar ? text[index] : '';
                      final isFocused =
                          _focusNode.hasFocus && index == text.length;

                      return Container(
                        width: 46,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppPalette.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFocused
                                ? AppPalette.emeraldDeep
                                : hasChar
                                    ? AppPalette.emeraldDeep
                                        .withValues(alpha: 0.5)
                                    : AppPalette.border,
                            width: isFocused ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          char,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppPalette.text,
                              ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
