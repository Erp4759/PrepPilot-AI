import 'dart:ui';
import 'package:flutter/material.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  double _fontSize = 16.0;
  Color _themeColor = const Color(0xFF2C8FFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF8FAFC), Color(0xFFF2F5F8)],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar with back button and title
                  Row(
                    children: [
                      _SmallBackButton(),
                      const SizedBox(width: 12),
                      const Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Font Size Settings
                  _SettingsCard(
                    title: 'Font Size',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Text Size',
                              style: TextStyle(
                                fontSize: _fontSize,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${_fontSize.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: _fontSize,
                                fontWeight: FontWeight.w600,
                                color: _themeColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: _themeColor,
                            inactiveTrackColor: _themeColor.withOpacity(0.2),
                            thumbColor: _themeColor,
                            overlayColor: _themeColor.withOpacity(0.1),
                          ),
                          child: Slider(
                            value: _fontSize,
                            min: 12,
                            max: 24,
                            divisions: 6,
                            onChanged: (value) {
                              setState(() {
                                _fontSize = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Theme Color Settings
                  _SettingsCard(
                    title: 'Theme Color',
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _ColorOption(
                          color: const Color(0xFF2C8FFF),
                          isSelected: _themeColor == const Color(0xFF2C8FFF),
                          onTap: () => _updateThemeColor(const Color(0xFF2C8FFF)),
                        ),
                        _ColorOption(
                          color: Colors.green,
                          isSelected: _themeColor == Colors.green,
                          onTap: () => _updateThemeColor(Colors.green),
                        ),
                        _ColorOption(
                          color: Colors.purple,
                          isSelected: _themeColor == Colors.purple,
                          onTap: () => _updateThemeColor(Colors.purple),
                        ),
                        _ColorOption(
                          color: Colors.orange,
                          isSelected: _themeColor == Colors.orange,
                          onTap: () => _updateThemeColor(Colors.orange),
                        ),
                        _ColorOption(
                          color: Colors.red,
                          isSelected: _themeColor == Colors.red,
                          onTap: () => _updateThemeColor(Colors.red),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Save settings
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _themeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'Apply Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateThemeColor(Color color) {
    setState(() {
      _themeColor = color;
    });
  }
}

class _SmallBackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bgColor = Colors.white.withOpacity(.78);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).maybePop(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(color: Colors.black.withOpacity(.06)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SettingsCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorOption extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorOption({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: isSelected ? 2 : 0,
            ),
          ],
        ),
        child: isSelected
            ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 24,
              )
            : null,
      ),
    );
  }
}
