import 'dart:ui';
import 'package:flutter/material.dart';
import '../data/writing_essay.dart';

class WritingEssayStructuresScreen extends StatefulWidget {
  const WritingEssayStructuresScreen({super.key});

  @override
  State<WritingEssayStructuresScreen> createState() =>
      _WritingEssayStructuresScreenState();
}

class _WritingEssayStructuresScreenState
    extends State<WritingEssayStructuresScreen> {
  final _essayController = TextEditingController();
  String? _userEssay;

  @override
  Widget build(BuildContext context) {
    final topic = topics;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFC), Color(0xFFF2F5F8)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'essay structures',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    _GlassButton(
                      label: 'Back',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(topic[0]),
                    const SizedBox(height: 10),
                    Container(
                      alignment: Alignment.topCenter,
                      child: TextFormField(
                        controller: _essayController,
                        minLines: 3,
                        maxLines: 10,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Essay',
                          hintText: 'Write down essay here...',
                          alignLabelWithHint: true,
                        ),

                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please write down essay.';
                          }
                          return null;
                        },
                        onSaved: (newValue) {
                          _userEssay = newValue;
                        },
                        keyboardType: TextInputType.multiline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _GlassButton(
                  label: 'Submit',
                  onTap: () => Navigator.of(context).pushNamed('/results'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.label,
    required this.onTap,
    this.fullWidth = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: fullWidth ? double.infinity : null,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withOpacity(.06)),
              color: Colors.white.withOpacity(.72),
            ),
            child: Text(
              label,
              textAlign: fullWidth ? TextAlign.center : TextAlign.start,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}
