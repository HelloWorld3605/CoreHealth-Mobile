import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/adaptive.dart';
import '../widgets/visuals.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralCodeController = TextEditingController();
  final _resetEmailController = TextEditingController();
  final _resetOtpController = TextEditingController();
  final _resetPasswordController = TextEditingController();
  final _resetConfirmPasswordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralCodeController.dispose();
    _resetEmailController.dispose();
    _resetOtpController.dispose();
    _resetPasswordController.dispose();
    _resetConfirmPasswordController.dispose();
    super.dispose();
  }

  static const _googleServerClientId =
      String.fromEnvironment('GOOGLE_CLIENT_ID');

  Future<void> _submitGoogle(AppController controller) async {
    setState(() => _isSubmitting = true);
    final error = await controller.signInWithGoogle(
      serverClientId:
          _googleServerClientId.isEmpty ? null : _googleServerClientId,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (error != null) {
      _showMessage(error);
    }
  }

  Future<void> _submit(AppController controller) async {
    final mode = controller.authMode;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final referralCode = _referralCodeController.text.trim();
    String? message;

    if (email.isEmpty || password.isEmpty) {
      message = 'Vui lòng nhập email và mật khẩu.';
    } else if (mode == AuthMode.signUp &&
        _displayNameController.text.trim().isEmpty) {
      message = 'Vui lòng nhập tên hiển thị.';
    } else if (mode == AuthMode.signUp &&
        password != _confirmPasswordController.text) {
      message = 'Mật khẩu xác nhận chưa khớp.';
    }

    if (message != null) {
      _showMessage(message);
      return;
    }

    setState(() => _isSubmitting = true);
    final error = mode == AuthMode.signIn
        ? await controller.signIn(email: email, password: password)
        : await controller.register(
            displayName: _displayNameController.text.trim(),
            email: email,
            password: password,
            referralCode: referralCode.isEmpty ? null : referralCode,
          );
    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);
    if (error != null) {
      _showMessage(error);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showForgotPasswordSheet(AppController controller) {
    _resetEmailController.text = _emailController.text.trim();
    _resetOtpController.clear();
    _resetPasswordController.clear();
    _resetConfirmPasswordController.clear();
    var step = 0;
    var submitting = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> requestReset() async {
              final email = _resetEmailController.text.trim();
              if (email.isEmpty) {
                _showMessage('Vui lòng nhập email đã đăng ký.');
                return;
              }

              setSheetState(() => submitting = true);
              final error = await controller.requestPasswordReset(email: email);
              if (!mounted) return;
              setSheetState(() => submitting = false);
              if (error != null) {
                _showMessage(error);
                return;
              }
              setSheetState(() => step = 1);
              _showMessage('Nếu email tồn tại, mã OTP đã được gửi.');
            }

            Future<void> resetPassword() async {
              final email = _resetEmailController.text.trim();
              final otp = _resetOtpController.text.trim();
              final password = _resetPasswordController.text;
              if (password != _resetConfirmPasswordController.text) {
                _showMessage('Mật khẩu xác nhận chưa khớp.');
                return;
              }
              final navigator = Navigator.of(sheetContext);

              setSheetState(() => submitting = true);
              final error = await controller.resetPassword(
                email: email,
                otp: otp,
                newPassword: password,
              );
              if (!mounted) return;
              setSheetState(() => submitting = false);
              if (error != null) {
                _showMessage(error);
                return;
              }
              navigator.pop();
              _emailController.text = email;
              _passwordController.clear();
              _showMessage('Đã đặt lại mật khẩu. Vui lòng đăng nhập lại.');
            }

            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            final tt = Theme.of(context).textTheme;
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
              child: Material(
                color: AppPalette.surface,
                borderRadius: BorderRadius.circular(28),
                clipBehavior: Clip.antiAlias,
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppPalette.emeraldSoft,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.lock_reset_rounded,
                                color: AppPalette.emeraldDeep,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Quên mật khẩu',
                                    style: tt.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    step == 0
                                        ? 'Nhập email để nhận mã OTP.'
                                        : 'Nhập mã OTP và mật khẩu mới.',
                                    style: tt.bodySmall?.copyWith(
                                      color: AppPalette.mutedText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _resetEmailController,
                          enabled: step == 0 && !submitting,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email đã đăng ký',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        if (step == 1) ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: _resetOtpController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            maxLength: 6,
                            decoration: const InputDecoration(
                              labelText: 'Mã OTP',
                              counterText: '',
                              prefixIcon: Icon(Icons.pin_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _resetPasswordController,
                            obscureText: true,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Mật khẩu mới',
                              prefixIcon: Icon(Icons.lock_outline_rounded),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _resetConfirmPasswordController,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => resetPassword(),
                            decoration: const InputDecoration(
                              labelText: 'Xác nhận mật khẩu mới',
                              prefixIcon: Icon(Icons.verified_user_outlined),
                            ),
                          ),
                        ],
                        if (controller.devPasswordResetOtp != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppPalette.emeraldSoft,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppPalette.accentMuted),
                            ),
                            child: Text(
                              'Development OTP: ${controller.devPasswordResetOtp}',
                              style: tt.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        FilledButton.icon(
                          onPressed: submitting
                              ? null
                              : step == 0
                                  ? requestReset
                                  : resetPassword,
                          icon: Icon(step == 0
                              ? Icons.mark_email_read_outlined
                              : Icons.check_circle_outline_rounded),
                          label: Text(
                            submitting
                                ? 'Đang xử lý...'
                                : step == 0
                                    ? 'Gửi mã OTP'
                                    : 'Đặt lại mật khẩu',
                          ),
                        ),
                        if (step == 1) ...[
                          const SizedBox(height: 10),
                          Center(
                            child: TextButton(
                              onPressed: submitting ? null : requestReset,
                              child: const Text('Gửi lại mã OTP'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = CoreHealthScope.of(context);
    final mode = controller.authMode;
    final layout = PhoneLayout.of(context);
    final isSignIn = mode == AuthMode.signIn;

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
                    onPressed: controller.goToWelcome,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isSignIn ? 'Đăng nhập' : 'Tạo tài khoản',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isSignIn
                        ? 'Tiếp tục với dữ liệu sức khỏe đã lưu trên thiết bị.'
                        : 'Tạo hồ sơ người dùng trước, sau đó hoàn thiện onboarding.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppPalette.surfaceElevated,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ModeButton(
                            selected: isSignIn,
                            label: 'Đăng nhập',
                            onTap: () =>
                                controller.switchAuthMode(AuthMode.signIn),
                          ),
                        ),
                        Expanded(
                          child: _ModeButton(
                            selected: !isSignIn,
                            label: 'Đăng ký',
                            onTap: () =>
                                controller.switchAuthMode(AuthMode.signUp),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isSignIn) ...[
                          TextField(
                            controller: _displayNameController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Tên hiển thị',
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          textInputAction: isSignIn
                              ? TextInputAction.done
                              : TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Mật khẩu',
                          ),
                        ),
                        if (isSignIn) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () => _showForgotPasswordSheet(controller),
                              child: const Text(
                                'Quên mật khẩu?',
                                style: TextStyle(
                                  color: AppPalette.emeraldDeep,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (!isSignIn) ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Xác nhận mật khẩu',
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _referralCodeController,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Mã giới thiệu (nếu có)',
                              hintText: 'Ví dụ: XXXX-123456',
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        GradientActionButton(
                          label: _isSubmitting
                              ? 'Đang xử lý...'
                              : isSignIn
                                  ? 'Đăng nhập'
                                  : 'Tạo tài khoản',
                          onPressed:
                              _isSubmitting ? () {} : () => _submit(controller),
                          colors: const [
                            AppPalette.emerald,
                            Color(0xFF18C290),
                          ],
                          icon: Icon(
                            isSignIn
                                ? Icons.login_rounded
                                : Icons.person_add_alt_1_rounded,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                'hoặc',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppPalette.mutedText),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: _isSubmitting
                              ? null
                              : () => _submitGoogle(controller),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            side: const BorderSide(color: AppPalette.border),
                            foregroundColor: AppPalette.text,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon:
                              const Icon(Icons.g_mobiledata_rounded, size: 28),
                          label: const Text('Tiếp tục với Google'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [AppPalette.emerald, Color(0xFF18C290)],
                )
              : null,
          color: selected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppPalette.emerald.withValues(alpha: 0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: selected ? Colors.white : AppPalette.mutedText,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}
