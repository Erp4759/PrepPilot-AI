import 'dart:ui';

import 'package:flutter/material.dart';
import 'widgets/glass_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  static const routeName = '/login';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Login'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // subtle gradient bg
          const _AuthBackdrop(),
          SingleChildScrollView(
            child: GlassFormCard(
              title: 'Welcome back',
              children: const [
                GlassTextField(
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 12),
                GlassTextField(label: 'Password', obscure: true),
                SizedBox(height: 16),
                GlassPrimaryButton(label: 'Sign in', onPressed: _noop),
              ],
              footer: Row(
                children: [
                  const Text("Don't have an account?"),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pushReplacementNamed('/register'),
                    child: const Text('Create one'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _noop() {}

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
