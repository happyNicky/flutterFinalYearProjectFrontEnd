import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import 'providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (mounted) {
      if (success) {
        context.go('/home');
      } else {
        final error = ref.read(authProvider).errorMessage ?? 'Login failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error, style: const TextStyle(fontWeight: FontWeight.w600)),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    }
  }

  void _loginSocial(String provider) async {
    final success = await ref.read(authProvider.notifier).loginWithOAuth(provider);
    if (mounted) {
      if (success) {
        context.go('/home');
      } else {
        final error = ref.read(authProvider).errorMessage ?? 'OAuth Login failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error, style: const TextStyle(fontWeight: FontWeight.w600)),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Beautiful Mesh Gradient Background
          Positioned.fill(
            child: Container(
              color: isDark ? const Color(0xFF07070A) : const Color(0xFFF6F8FC),
            ),
          ),
          // Glowing Orb 1
          Positioned(
            top: -100,
            right: -100,
            width: 400,
            height: 400,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorScheme.primary.withOpacity(isDark ? 0.25 : 0.15),
                    colorScheme.primary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Glowing Orb 2
          Positioned(
            bottom: -50,
            left: -150,
            width: 500,
            height: 500,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isDark ? const Color(0xFF8B5CF6) : const Color(0xFFC084FC)).withOpacity(isDark ? 0.2 : 0.12),
                    colorScheme.primary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          // Subtle grid pattern overlay
          Positioned.fill(
            child: Opacity(
              opacity: isDark ? 0.015 : 0.03,
              child: CustomPaint(
                painter: _GridPainter(),
              ),
            ),
          ),

          // 2. Scrollable Content Layer
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo Icon
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primary,
                                colorScheme.primary.withOpacity(0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            LucideIcons.newspaper,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'DailyFeed',
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Glassmorphic Login Card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.04)
                                  : Colors.white.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.08)
                                    : Colors.white.withOpacity(0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDark ? 0.15 : 0.05),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(28.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome Back',
                                    style: textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Sign in to personalize your daily news feed',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                  const SizedBox(height: 28),

                                  CustomTextField(
                                    label: 'Email Address',
                                    hint: 'Enter your email',
                                    prefixIcon: LucideIcons.mail,
                                    controller: _emailController,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Email is required';
                                      }
                                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                          .hasMatch(value.trim())) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  CustomTextField(
                                    label: 'Password',
                                    hint: 'Enter your password',
                                    prefixIcon: LucideIcons.lock,
                                    isPassword: true,
                                    controller: _passwordController,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Password is required';
                                      }
                                      if (value.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),

                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {},
                                      child: Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  CustomButton(
                                    text: 'Sign In',
                                    isLoading: authState.isLoading,
                                    onPressed: _login,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Or Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: colorScheme.onSurface.withOpacity(0.1))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Or continue with',
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.4),
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: colorScheme.onSurface.withOpacity(0.1))),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Social Buttons
                      Row(
                        children: [
                          Expanded(
                            child: _SocialButton(
                              iconPath: 'google',
                              label: 'Google',
                              isLoading: authState.isLoading,
                              onPressed: () => _loginSocial('google'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _SocialButton(
                              iconPath: 'github',
                              label: 'GitHub',
                              isLoading: authState.isLoading,
                              onPressed: () => _loginSocial('github'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Sign Up Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account?",
                            style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/signup'),
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

// 3. Grid Background Painter
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1.0;

    const double step = 30.0;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 4. Custom Social Button Component
class _SocialButton extends StatelessWidget {
  final String iconPath;
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.iconPath,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget iconWidget;
    if (iconPath == 'google') {
      // Paint standard Google multi-color colors or custom icon layout
      iconWidget = SizedBox(
        width: 20,
        height: 20,
        child: CustomPaint(
          painter: _GoogleLogoPainter(),
        ),
      );
    } else {
      iconWidget = Icon(
        LucideIcons.github,
        size: 20,
        color: isDark ? Colors.white : Colors.black,
      );
    }

    return Container(
      height: 56,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
            width: 1.2,
          ),
          backgroundColor: isDark
              ? Colors.white.withOpacity(0.02)
              : Colors.white.withOpacity(0.8),
          elevation: 0,
        ),
        onPressed: isLoading ? null : onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 5. Google Logo Painter
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double r = w / 2;

    final Paint paintRed = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;
    final Paint paintYellow = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;
    final Paint paintGreen = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;
    final Paint paintBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    // Draw Blue G arc
    final Path bluePath = Path()
      ..moveTo(cx, cy)
      ..relativeLineTo(r * 0.95, 0)
      ..arcTo(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        0.0,
        0.75, // around 43 degrees
        false,
      )
      ..lineTo(cx, cy)
      ..close();
    // Google logo has specific path, we can paint beautiful segments to represent Google branding
    // segment 1: blue horizontal bar and bottom arc
    final double sweepAngle = 360 / 4 * (3.14159 / 180);

    // Let's paint 4 quadrants with standard google colors for clean visuals
    canvas.drawArc(Rect.fromLTWH(0, 0, w, h), -0.785, 1.57, true, paintRed); // Top Red
    canvas.drawArc(Rect.fromLTWH(0, 0, w, h), 0.785, 1.57, true, paintYellow); // Left Yellow
    canvas.drawArc(Rect.fromLTWH(0, 0, w, h), 2.355, 1.57, true, paintGreen); // Bottom Green
    canvas.drawArc(Rect.fromLTWH(0, 0, w, h), -2.355, 1.57, true, paintBlue); // Right Blue

    // Draw smaller center circle to make it look like a ring/G
    final Paint paintBackground = Paint()
      ..color = const Color(0x00FFFFFF)
      ..blendMode = BlendMode.clear;
    canvas.drawCircle(Offset(cx, cy), r * 0.5, paintBackground);

    // Standard drawing of a simplified beautiful colored wheel representing Google color scheme
    // We can also draw it using standard arcs
    final Paint paintWhite = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    // We can clean the center
    canvas.drawCircle(Offset(cx, cy), r * 0.5, paintWhite);
    
    // To make it look like a clean google logo, we can paint a circle overlay
    // Or we can just let it blend. Let's make sure the background matches the button background
    // Since button background is white or near-black, we will draw a solid circle of the corresponding color
    // but even simpler: let's draw four distinct colored arc sectors with a white/dark center
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

