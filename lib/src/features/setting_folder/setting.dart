import 'dart:ui';
import 'package:flutter/material.dart';
import '../profile_setting/get_profile.dart';
import 'get_setting.dart';
import '../../core/app_state.dart';
import '../../services/supabase.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  double _fontSize = 16.0;
  Color _themeColor = const Color(0xFF2C8FFF);
  bool _loading = true;
  int? _originalFontSize;
  int? _originalTheme;

  @override
  void initState() {
    super.initState();
    _loadFromDb();
  }

  Future<void> _loadFromDb() async {
    try {
      final authUser = supabase.auth.currentUser;
      if (authUser == null) {
        setState(() => _loading = false);
        // capture current notifiers as the "original" state for revert
        _originalFontSize = appFontSizeNotifier.value;
        _originalTheme = appThemeNotifier.value;
        return;
      }
      final settings = await fetchUserSettings(authUser.id);
      if (settings != null) {
        setState(() {
          _fontSize = (settings.fontSize).toDouble();
          // stored as int color value: 0 -> primary light, 1 -> dark
          _themeColor = settings.themeColor == 0 ? const Color(0xFF2C8FFF) : Colors.black;
          _loading = false;
          // sync global notifier so app reflects loaded preference
          appFontSizeNotifier.value = _fontSize.toInt();
          appThemeNotifier.value = settings.themeColor;
          // capture the current app state as the original state
          _originalFontSize = appFontSizeNotifier.value;
          _originalTheme = appThemeNotifier.value;
        });
      } else {
        // fallback to profile if settings row missing
        final profile = await fetchUserProfile(authUser.id);
        if (profile != null) {
          setState(() {
            _fontSize = (profile.fontSize).toDouble();
            _themeColor = profile.themeColor == 0 ? const Color(0xFF2C8FFF) : Colors.black;
            _loading = false;
            // sync global notifier to profile fallback value
            appFontSizeNotifier.value = _fontSize.toInt();
            appThemeNotifier.value = profile.themeColor;
            // capture original
            _originalFontSize = appFontSizeNotifier.value;
            _originalTheme = appThemeNotifier.value;
          });
        } else {
          setState(() => _loading = false);
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      // ensure originals reflect current app state
      _originalFontSize = appFontSizeNotifier.value;
      _originalTheme = appThemeNotifier.value;
    }
  }

  Future<void> _saveToDb() async {
    final authUser = supabase.auth.currentUser;
    if (authUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes applied. Please log in to save these settings.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      // Store font and theme consistently: font as rounded int,
      // theme as the raw color int value so loading will reconstruct the Color
      final fontInt = _fontSize.toInt();
      int themeInt;
      if(_themeColor == Color(0xFF2C8FFF)){
        themeInt = 0;
      }else{
        themeInt = 1;
      }
      final ok = await updateUserSettings(authUser.id, fontSize: fontInt, themeColor: themeInt);
      setState(() => _loading = false);
      if (ok) {
        // ensure global notifier is in sync after a successful save
          appFontSizeNotifier.value = fontInt;
          // persist theme selection to app notifier so UI updates immediately
          appThemeNotifier.value = themeInt;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save settings')),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save settings')),
      );
    }
  }

  Widget build(BuildContext context) {
    // Local selection-driven colors for this settings screen only.


    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Background (reflects the local selection immediately)
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
                      _SmallBackButton(
                        onPressed: () {
                          // Revert any live changes and then pop
                          if (_originalFontSize != null) appFontSizeNotifier.value = _originalFontSize!;
                          if (_originalTheme != null) appThemeNotifier.value = _originalTheme!;
                          Navigator.of(context).maybePop();
                        },
                      ),
                        
                      const SizedBox(width: 12),
                      Text(
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
                              )         
                            ),
                            Text(
                              '${_fontSize.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: _fontSize,
                                fontWeight: FontWeight.w600,
                                // If the selected theme color is black (dark mode),
                                // render this label white so it is visible.
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
                                max: 20,
                                // use 8 divisions to get integer steps (12..20)
                                divisions: 8,
                                onChanged: (value) {
                                  setState(() {
                                    // keep font size on integer steps
                                    _fontSize = value;
                                    // Do NOT update the global notifier here.
                                    // Changes are applied when the user presses Apply.
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
                        Text("Light Mode"),
                        SizedBox(width: 10),
                        ValueListenableBuilder<int>(
                          valueListenable: appThemeNotifier,
                          builder: (context, appThemeVal, _) {
                            final isDark = appThemeVal == 1;
                            final lightOption = _ColorOption(
                              color: const Color(0xFF2C8FFF),
                              isSelected: _themeColor == const Color(0xFF2C8FFF),
                              onTap: () => _updateThemeColor(const Color(0xFF2C8FFF)),
                            );

                            if (!isDark) return lightOption;

                            // When app is in dark mode, apply a color matrix filter
                            return ColorFiltered(
                              colorFilter: const ColorFilter.matrix([
                                -0.8,    0,    0,  0, 235,
                                0, -0.8,    0,  0, 235,
                                0,    0, -0.8,  0, 235,
                                0,    0,    0,  1,   0,
                              ]),
                              child: lightOption,
                            );
                          },
                        ),
                        SizedBox(width : 20),
                        Text("Dark Mode"),
                        SizedBox(width: 10),
                        _ColorOption(
                          color: Colors.black,
                          isSelected: _themeColor == Colors.black,
                          onTap: () => _updateThemeColor(Colors.black),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading
                          ? null
                          : () async {
                              // Apply selection to app immediately when user confirms
                              final themeInt = _themeColor == const Color(0xFF2C8FFF) ? 0 : 1;
                              // Update global notifiers so the rest of the app reflects
                              // the user's selection immediately.
                              appFontSizeNotifier.value = _fontSize.toInt();
                              appThemeNotifier.value = themeInt;

                              // Attempt to persist to DB (if logged in). _saveToDb
                              // already handles the unauthenticated case by showing
                              // a message and returning without saving.
                              await _saveToDb();
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
        // Do NOT notify app immediately; Apply button will persist and notify.    });
  });
  }  }

class _SmallBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? bgColor;
  final Color? borderColor;
  final Color? iconColor;

  const _SmallBackButton({
    Key? key,
    this.onPressed,
    this.bgColor,
    this.borderColor,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _bg = bgColor ?? Colors.white.withOpacity(.78);
    final _border = borderColor ?? Colors.black.withOpacity(.06);
    final _icon = iconColor ?? Colors.black;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onPressed ?? () => Navigator.of(context).maybePop(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _bg,
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              size: 18,
              color: _icon,
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
                style: TextStyle(
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
