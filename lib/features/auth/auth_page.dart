import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';

class AuthPage extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const AuthPage({
    super.key,
    required this.onAuthenticated,
  });

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController =
      TextEditingController();

  final _emailController =
      TextEditingController();

  final _passwordController =
      TextEditingController();

  final _confirmPasswordController =
      TextEditingController();

  bool isLogin = true;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _switchMode(bool login) {
    setState(() {
      isLogin = login;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      if (isLogin) {
        await ApiService.login(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await ApiService.register(
          fullName: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
      }

      if (!mounted) {
        return;
      }

      widget.onAuthenticated();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.message);
    } catch (error) {
      debugPrint(
        'ResQNav authentication error: $error',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to connect to the server.',
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  String? _validateName(String? value) {
    if (isLogin) {
      return null;
    }

    if (value == null ||
        value.trim().isEmpty) {
      return 'Please enter your name';
    }

    if (value.trim().length < 2) {
      return 'Enter a valid name';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Please enter your email';
    }

    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(
      value.trim(),
    )) {
      return 'Enter a valid email address';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null ||
        value.isEmpty) {
      return 'Please enter your password';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  String? _validateConfirmPassword(
    String? value,
  ) {
    if (value == null ||
        value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FB),
      body: Center(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(24),
          child: LayoutBuilder(
            builder: (
              context,
              constraints,
            ) {
              return ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 980,
                ),
                child: Container(
                  decoration:
                      BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      26,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 35,
                        offset: Offset(0, 14),
                        color:
                            Color(0x18000000),
                      ),
                    ],
                  ),
                  child: constraints.maxWidth >
                          700
                      ? _buildDesktopLayout()
                      : _buildMobileLayout(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: _buildBrandPanel(),
          ),
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.all(42),
              child: _buildAuthForm(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Padding(
      padding:
          const EdgeInsets.all(28),
      child: _buildAuthForm(),
    );
  }

  Widget _buildBrandPanel() {
    return Container(
      padding:
          const EdgeInsets.all(42),
      decoration: const BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(26),
          bottomLeft: Radius.circular(26),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white
                  .withValues(alpha: 0.14),
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.navigation_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'ResQNav',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Smart Emergency &\nService Locator',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              height: 1.3,
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            'Find your destination, discover nearby emergency services and get directions from one place.',
            style: TextStyle(
              color: Colors.white
                  .withValues(alpha: 0.78),
              fontSize: 14,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 38),

          _buildFeature(
            Icons.location_on_rounded,
            'Search any destination',
          ),

          _buildFeature(
            Icons.emergency_rounded,
            'Locate emergency services',
          ),

          _buildFeature(
            Icons.directions_rounded,
            'Get routes and directions',
          ),

          const Spacer(),

          Container(
            padding:
                const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white
                  .withValues(alpha: 0.10),
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shield_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'One platform for everyday navigation and emergency assistance.',
                    style: TextStyle(
                      color: Colors.white
                          .withValues(alpha: 0.85),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(
    IconData icon,
    String text,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 17),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white
                  .withValues(alpha: 0.12),
              borderRadius:
                  BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 19,
            ),
          ),
          const SizedBox(width: 11),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color:
                    AppTheme.primary.withValues(
                  alpha: 0.09,
                ),
                borderRadius:
                    BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppTheme.primary,
                size: 27,
              ),
            ),
          ),

          const SizedBox(height: 18),

          Center(
            child: Text(
              isLogin
                  ? 'Welcome back'
                  : 'Create your account',
              style: const TextStyle(
                fontSize: 26,
                fontWeight:
                    FontWeight.w800,
                color:
                    AppTheme.textPrimary,
              ),
            ),
          ),

          const SizedBox(height: 6),

          Center(
            child: Text(
              isLogin
                  ? 'Sign in to continue to ResQNav'
                  : 'Join ResQNav and stay connected',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color:
                    AppTheme.textSecondary,
              ),
            ),
          ),

          const SizedBox(height: 25),

          _buildModeSelector(),

          const SizedBox(height: 24),

          if (!isLogin) ...[
            _buildLabel('Full name'),

            const SizedBox(height: 7),

            TextFormField(
              controller: _nameController,
              validator: _validateName,
              textInputAction:
                  TextInputAction.next,
              decoration:
                  _inputDecoration(
                hint:
                    'Enter your full name',
                icon:
                    Icons.person_outline_rounded,
              ),
            ),

            const SizedBox(height: 16),
          ],

          _buildLabel('Email address'),

          const SizedBox(height: 7),

          TextFormField(
            controller: _emailController,
            validator: _validateEmail,
            keyboardType:
                TextInputType.emailAddress,
            textInputAction:
                TextInputAction.next,
            decoration:
                _inputDecoration(
              hint:
                  'Enter your email address',
              icon:
                  Icons.email_outlined,
            ),
          ),

          const SizedBox(height: 16),

          _buildLabel('Password'),

          const SizedBox(height: 7),

          TextFormField(
            controller:
                _passwordController,
            validator:
                _validatePassword,
            obscureText:
                obscurePassword,
            textInputAction:
                isLogin
                    ? TextInputAction.done
                    : TextInputAction.next,
            onFieldSubmitted:
                isLogin
                    ? (_) => _submit()
                    : null,
            decoration:
                _inputDecoration(
              hint: 'Enter your password',
              icon:
                  Icons.lock_outline_rounded,
              suffix: IconButton(
                onPressed: () {
                  setState(() {
                    obscurePassword =
                        !obscurePassword;
                  });
                },
                icon: Icon(
                  obscurePassword
                      ? Icons
                          .visibility_outlined
                      : Icons
                          .visibility_off_outlined,
                ),
              ),
            ),
          ),

          if (!isLogin) ...[
            const SizedBox(height: 16),

            _buildLabel(
              'Confirm password',
            ),

            const SizedBox(height: 7),

            TextFormField(
              controller:
                  _confirmPasswordController,
              validator:
                  _validateConfirmPassword,
              obscureText:
                  obscureConfirmPassword,
              textInputAction:
                  TextInputAction.done,
              onFieldSubmitted:
                  (_) => _submit(),
              decoration:
                  _inputDecoration(
                hint:
                    'Re-enter your password',
                icon:
                    Icons.lock_reset_rounded,
                suffix: IconButton(
                  onPressed: () {
                    setState(() {
                      obscureConfirmPassword =
                          !obscureConfirmPassword;
                    });
                  },
                  icon: Icon(
                    obscureConfirmPassword
                        ? Icons
                            .visibility_outlined
                        : Icons
                            .visibility_off_outlined,
                  ),
                ),
              ),
            ),
          ],

          if (isLogin) ...[
            const SizedBox(height: 8),

            Align(
              alignment:
                  Alignment.centerRight,
              child: TextButton(
                onPressed: _showForgotPassword,
                child: const Text(
                  'Forgot password?',
                ),
              ),
            ),
          ],

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed:
                  loading ? null : _submit,
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isLogin
                          ? 'Sign in'
                          : 'Create account',
                    ),
            ),
          ),

          const SizedBox(height: 20),

          Center(
            child: Wrap(
              alignment:
                  WrapAlignment.center,
              children: [
                Text(
                  isLogin
                      ? "Don't have an account? "
                      : 'Already have an account? ',
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color:
                        AppTheme.textSecondary,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _switchMode(!isLogin);
                  },
                  child: Text(
                    isLogin
                        ? 'Register'
                        : 'Sign in',
                    style:
                        const TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w700,
                      color:
                          AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding:
          const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F9),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _modeButton(
              title: 'Sign in',
              selected: isLogin,
              onTap: () {
                _switchMode(true);
              },
            ),
          ),
          Expanded(
            child: _modeButton(
              title: 'Register',
              selected: !isLogin,
              onTap: () {
                _switchMode(false);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(9),
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white
              : Colors.transparent,
          borderRadius:
              BorderRadius.circular(9),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    blurRadius: 6,
                    offset: Offset(0, 2),
                    color:
                        Color(0x10000000),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: selected
                  ? AppTheme.primary
                  : AppTheme
                      .textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 12,
        color: AppTheme.textSecondary,
      ),
      prefixIcon: Icon(
        icon,
        size: 19,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor:
          const Color(0xFFF7F9FC),
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFE5E9F0),
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppTheme.primary,
          width: 1.4,
        ),
      ),
      errorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.4,
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> _showForgotPassword() async {
    final emailController = TextEditingController(text: _emailController.text);
    final uidController = TextEditingController();
    final tokenController = TextEditingController();
    final passwordController = TextEditingController();
    var step = 0;
    var busy = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            Future<void> requestReset() async {
              setDialogState(() => busy = true);
              try {
                final result = await ApiService.requestPasswordReset(
                  emailController.text,
                );
                if (result['uid'] != null) {
                  uidController.text = result['uid'].toString();
                  tokenController.text = result['token']?.toString() ?? '';
                }
                setDialogState(() {
                  busy = false;
                  step = 1;
                });
              } on ApiException catch (e) {
                setDialogState(() => busy = false);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.message)),
                );
              } catch (_) {
                setDialogState(() => busy = false);
              }
            }

            Future<void> confirmReset() async {
              setDialogState(() => busy = true);
              try {
                await ApiService.confirmPasswordReset(
                  uid: uidController.text,
                  token: tokenController.text,
                  password: passwordController.text,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                _showMessage('Password updated. Sign in with your new password.');
              } on ApiException catch (e) {
                setDialogState(() => busy = false);
                _showMessage(e.message);
              } catch (_) {
                setDialogState(() => busy = false);
              }
            }

            return AlertDialog(
              title: Text(step == 0 ? 'Reset password' : 'Set a new password'),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (step == 0)
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Account email',
                        ),
                      )
                    else ...[
                      const Text(
                        'Enter the reset ID and code from your email (shown automatically in development).',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: uidController,
                        decoration: const InputDecoration(labelText: 'Reset ID'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: tokenController,
                        decoration: const InputDecoration(labelText: 'Reset code'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'New password'),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: busy ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: busy
                      ? null
                      : () => step == 0 ? requestReset() : confirmReset(),
                  child: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(step == 0 ? 'Send reset' : 'Update password'),
                ),
              ],
            );
          },
        );
      },
    );

    emailController.dispose();
    uidController.dispose();
    tokenController.dispose();
    passwordController.dispose();
  }
}