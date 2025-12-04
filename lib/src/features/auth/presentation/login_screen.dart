import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../library/auth_helper.dart';
import 'widgets/glass_form.dart';
import '../../../app/main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  static const routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Login Failed 😔'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog('Please fill both email and password fields.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthHelper.login(email: email, password: password);

      // Navigate to home/main shell
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
    } catch (e) {
      // 3. Replace SnackBar with the new dialog method for login failures
      if (!mounted) return;
      _showErrorDialog('Login failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _AuthBackdrop(),
          SingleChildScrollView(
            // Set the constraints to the full height of the viewport.
            // This allows the Center widget inside to align the form vertically.
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
                minWidth: MediaQuery.of(context).size.width,
              ),
              child: Center(
                // The form card is now centered both horizontally and vertically.
                child: GlassFormCard(
                  title: 'Welcome back',
                  footer: Row(
                    mainAxisAlignment: MainAxisAlignment
                        .center, // Center the footer row elements
                    children: [
                      const Text("Don't have an account?"),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => Navigator.of(
                          context,
                        ).pushReplacementNamed('/register'),
                        child: const Text('Create one'),
                      ),
                    ],
                  ),
                  children: [
                    GlassTextField(
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailController,
                    ),
                    const SizedBox(height: 12),
                    GlassTextField(
                      label: 'Password',
                      obscure: true,
                      controller: _passwordController,
                    ),
                    const SizedBox(height: 16),
                    GlassPrimaryButton(
                      label: _isLoading ? 'Signing in...' : 'Sign in',
                      onPressed: _isLoading ? null : () async => await _login(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF8FAFC), Color(0xFFF2F5F8)],
            ),
          ),
        ),
        Positioned(
          top: -80,
          left: -60,
          child: _blob(const Color(0x2882CEFF), const Color(0x28B78DFF), 440),
        ),
        Positioned(
          bottom: -60,
          right: -80,
          child: _blob(const Color(0x28FFD17C), const Color(0x28FFA078), 520),
        ),
      ],
    );
  }

  Widget _blob(Color a, Color b, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [a, b], stops: const [0.2, 1]),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
        child: const SizedBox.expand(),
      ),
    );
  }
}
