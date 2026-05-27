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
  bool _isSubmitting = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                        if (!isSignIn) ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Xác nhận mật khẩu',
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
