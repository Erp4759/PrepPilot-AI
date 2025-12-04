import 'package:flutter/material.dart';

// About dialog helper for the PrepPilot-AI app.
const String _appName = 'PrepPilot-AI';
const String _appVersion = '1.01';
const String _copyright = '© 2025 Team7';
const List<String> _authors = [
  'Erik Papernyuk',
  'Quekzhengseng',
  'Cho Sung',
  'Cho Haeyoung',
];

const List<String> _servicesUsed = [
  'open_ai (OpenAI API)',
  'supabase',
  'Flutter & Dart',
];

Future<void> showCustomAboutDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Center(
                      child: Column(
                        children: [
                          const FlutterLogo(size: 72),
                          const SizedBox(height: 12),
                          Text(
                            _appName,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text('Version $_appVersion', style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _InfoTile(title: 'Made by', lines: [..._authors, _copyright]),
                    const SizedBox(height: 12),
                    _InfoTile(title: 'Services / Libraries', lines: _servicesUsed),
                    const SizedBox(height: 16),
                    Text(
                      'This dialog shows the app version and third-party licenses.',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                    const SizedBox(height: 18),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              // Close button at top-right
              Positioned(
                right: 0,
                top: 0,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _InfoTile extends StatelessWidget {
  final String title;
  final List<String> lines;

  const _InfoTile({required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...lines.map((l) => Text(l)),
        ],
      ),
    );
  }
}
