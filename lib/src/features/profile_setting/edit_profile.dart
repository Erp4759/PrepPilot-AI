import 'dart:ui';

import 'package:flutter/material.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  static const _accent = Color(0xFF2C8FFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // 배경 그라디언트
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF8FAFC), Color(0xFFF2F5F8)],
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단: back 버튼 + 제목
                  Row(
                    children: const [
                      _SmallBackButton(),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'edit profile',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 프로필 이미지와 변경 버튼
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            // 프로필 이미지
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xD282CEFF), Color(0xD2B78DFF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF82CEFF).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 60,
                              ),
                            ),
                            // 카메라 아이콘 버튼
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _accent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _accent.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: InkWell(
                                  onTap: () => _showChangeProfileImageDialog(context),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),

                  // chainging ID 버튼 (더 큼)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showChangeIdDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        elevation: 6,
                      ),
                      child: const Text('Change ID'),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // chainging password 버튼 (더 큼)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _showChangePasswordDialog(context),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(color: _accent.withOpacity(0.14)),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      child: const Text('Change password'),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Level Setting 제목
                  const Text(
                    'Level Setting',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  // 네 가지 항목
                  const LevelSelector(title: 'Reading'),
                  const SizedBox(height: 12),
                  const LevelSelector(title: 'Speaking'),
                  const SizedBox(height: 12),
                  const LevelSelector(title: 'Listening'),
                  const SizedBox(height: 12),
                  const LevelSelector(title: 'Writing'),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallBackButton extends StatelessWidget {
  const _SmallBackButton({Key? key}) : super(key: key);

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

class LevelSelector extends StatefulWidget {
  const LevelSelector({required this.title, Key? key}) : super(key: key);

  final String title;

  @override
  State<LevelSelector> createState() => _LevelSelectorState();
}

class _LevelSelectorState extends State<LevelSelector>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  String _selected = 'change difficulty';
  final _options = const ['easy', 'medium', 'hard', 'very hard'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.86),
                border: Border.all(color: Colors.black.withOpacity(.06)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selected,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _expanded = !_expanded),
                        icon: AnimatedRotation(
                          duration: const Duration(milliseconds: 200),
                          turns: _expanded ? 0.5 : 0.0,
                          child: const Icon(Icons.keyboard_arrow_down_rounded),
                        ),
                      ),
                    ],
                  ),

                  // 확장된 옵션
                  AnimatedSize(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOut,
                    child: ConstrainedBox(
                      constraints: _expanded
                          ? const BoxConstraints()
                          : const BoxConstraints(maxHeight: 0),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          children: _options
                              .map((opt) => InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selected = opt;
                                        _expanded = false;
                                      });
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 8),
                                      margin:
                                          const EdgeInsets.symmetric(vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _selected == opt
                                            ? const Color(0xFFEEF6FF)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(opt),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Dialog helpers
void _showChangeIdDialog(BuildContext context) {
  // Placeholder for current ID; replace with real user data when available
  const currentId = 'alex_morgan';
  final newController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Change ID', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              const Align(alignment: Alignment.centerLeft, child: Text('Current ID')),
              const SizedBox(height: 6),
              // non-editable display of current ID
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(currentId, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 12),
              const Align(alignment: Alignment.centerLeft, child: Text('New ID')),
              const SizedBox(height: 6),
              TextField(controller: newController, decoration: const InputDecoration(border: OutlineInputBorder())),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () {
                      // TODO: implement change id logic
                      Navigator.of(context).pop();
                    },
                    child: const Text('Confirm'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    ),
  );
}

void _showChangeProfileImageDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Change Profile Picture',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ImageOptionButton(
                  icon: Icons.photo_camera_rounded,
                  label: 'Camera',
                  onTap: () {
                    // TODO: Implement camera capture
                    Navigator.pop(context);
                  },
                ),
                _ImageOptionButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  onTap: () {
                    // TODO: Implement gallery picker
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ImageOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageOptionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2C8FFF).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF2C8FFF),
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

void _showChangePasswordDialog(BuildContext context) {
  final nowController = TextEditingController();
  final newController = TextEditingController();
  bool obscured = true;
  bool isPasswordVerified = false;
  String verificationMessage = '';
  // TODO: Replace this with actual stored password
  const storedPassword = "password123";

  showDialog(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: StatefulBuilder(builder: (context, setState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Change password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                const Align(alignment: Alignment.centerLeft, child: Text('Current Password')),
                const SizedBox(height: 6),
                TextField(
                  controller: nowController,
                  obscureText: obscured,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscured ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => obscured = !obscured),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (nowController.text == storedPassword) {
                        isPasswordVerified = true;
                        verificationMessage = 'Password verified successfully!';
                      } else {
                        isPasswordVerified = false;
                        verificationMessage = 'Password does not match';
                      }
                    });
                  },
                  child: const Text('Verify'),
                ),
                if (verificationMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      verificationMessage,
                      style: TextStyle(
                        color: isPasswordVerified ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                if (isPasswordVerified) ...[
                  const Align(alignment: Alignment.centerLeft, child: Text('New Password')),
                  const SizedBox(height: 6),
                  TextField(
                    controller: newController,
                    obscureText: obscured,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                ],
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: isPasswordVerified ? () {
                        // TODO: implement change password logic
                        Navigator.of(context).pop();
                      } : null,
                      child: const Text('Confirm'),
                    ),
                  ],
                )
              ],
            );
          }),
        ),
      ),
    ),
  );
}