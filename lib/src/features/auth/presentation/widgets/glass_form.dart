import 'dart:ui';

import 'package:flutter/material.dart';

class GlassFormCard extends StatelessWidget {
  const GlassFormCard({
    super.key,
    required this.title,
    required this.children,
    this.footer,
  });
  final String title;
  final List<Widget> children;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  color: Colors.white.withOpacity(.76),
                  border: Border.all(color: Colors.black.withOpacity(.06)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 32,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...children,
                    if (footer != null) ...[
                      const SizedBox(height: 14),
                      footer!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassTextField extends StatelessWidget {
  const GlassTextField({
    super.key,
    required this.label,
    this.obscure = false,
    this.keyboardType,
    this.controller,
  });

  final String label;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        TextFormField(
          obscureText: obscure,
          keyboardType: keyboardType,
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(.85),
            border: _border(),
            enabledBorder: _border(),
            focusedBorder: _border(color: const Color(0xFF2C8FFF)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border({Color? color}) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: BorderSide(color: color ?? Colors.black.withOpacity(.08)),
  );
}

class GlassPrimaryButton extends StatelessWidget {
  const GlassPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          backgroundColor: const Color(0xFF2C8FFF),
          foregroundColor: Colors.white,
          shadowColor: const Color(0x302C8FFF),
          elevation: 6,
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
