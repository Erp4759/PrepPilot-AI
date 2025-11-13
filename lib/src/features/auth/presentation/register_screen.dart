import 'dart:ui';

import 'package:flutter/material.dart';
import '../../../library/auth_helper.dart';
import 'widgets/glass_form.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  static const routeName = '/register';

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthHelper.register(
        email: email,
        password: password,
        username: name,
      );

      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Registration failed: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Create account'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _AuthBackdrop(),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: GlassFormCard(
              title: 'Create your account',
              footer: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account?'),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pushReplacementNamed('/login'),
                    child: const Text('Sign in'),
                  ),
                ],
              ),
              children: [
                GlassTextField(
                  label: 'Name',
                  keyboardType: TextInputType.name,
                  controller: _nameController,
                ),
                const SizedBox(height: 12),
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
                  label: _isLoading ? 'Creating...' : 'Sign up',
                  onPressed: _isLoading
                      ? null
                      : () {
                          _register().then((_) {});
                        },
                ),
              ],
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
