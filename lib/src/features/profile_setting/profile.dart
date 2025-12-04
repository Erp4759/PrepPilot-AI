import 'dart:ui';

import 'package:flutter/material.dart';

import 'profile_info.dart';
import 'get_profile.dart';
import '../../services/supabase.dart';
import '../profile_setting/profile_notifier.dart';
import '../auth/presentation/login_screen.dart';
import '../../app/app.dart' show routeObserver;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with RouteAware {
  static const _accent = Color(0xFF2C8FFF);
  bool _isLoggedIn = true;
  final GlobalKey<_ProfileInfoButtonState> _profileBtnKey = GlobalKey<_ProfileInfoButtonState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateAuthState());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modal = ModalRoute.of(context);
    if (modal != null) routeObserver.subscribe(this, modal);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() => _updateAuthState();

  @override
  void didPopNext() => _updateAuthState();

  void _updateAuthState() {
    final authUser = supabase.auth.currentUser;
    final loggedIn = authUser != null;
    if (mounted) setState(() => _isLoggedIn = loggedIn);
  }

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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: _isLoggedIn ? _buildProfileContent(context) : _buildNotLoggedContainer(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotLoggedContainer(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6), // 상단 여백 조정
          child: Row(
            children : [
              _SmallBackButton(),
              SizedBox(width: 12),
              Text(
                'Profile Info',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ],
          )
        ),
        const SizedBox(height: 50),
        Expanded(
          child: Center(
            child: Container(
              width: 500,
              height : 300,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.06)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Not logged in', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  const Text('You are not logged in. Please log in to view and edit your profile.'),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                        },
                        child: const Text('Close'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pushNamed(LoginScreen.routeName),
                        child: const Text('Login'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileContent(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SmallBackButton(),
              const SizedBox(width: 12),
              const Text(
                'Profile Info',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ],
          ),
      
          const SizedBox(height: 36),
      
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ProfileInfoButton(key: _profileBtnKey, onTap: () => Navigator.of(context).pushNamed('/profile/details')),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: 320,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final res = await Navigator.of(context).pushNamed('/profile/edit');
                        if (res == true) {
                          // refresh the profile info button
                          _profileBtnKey.currentState?._loadProfile();
                        }
                      },
                      icon: const Icon(Icons.edit_rounded, size: 26),
                      label: const Text('Edit profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        elevation: 10,
                        shadowColor: _accent.withOpacity(0.45),
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
            child: const Icon(Icons.arrow_back_rounded, size: 20),
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoButton extends StatefulWidget {
  const _ProfileInfoButton({required this.onTap, Key? key}) : super(key: key);

  final VoidCallback onTap;

  @override
  State<_ProfileInfoButton> createState() => _ProfileInfoButtonState();
}

class _ProfileInfoButtonState extends State<_ProfileInfoButton> {
  static const _accent = Color(0xFF2C8FFF);
  String _displayName = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
    profileRefreshCounter.addListener(_onProfileRefresh);
  }

  Future<void> _loadProfile() async {
    try {
      final authUser = supabase.auth.currentUser;
      if (authUser == null) return;
      final userId = authUser.id;
      final profile = await fetchUserProfile(userId);
      final authEmail = authUser.email ?? '';

      if (!mounted) return;
      setState(() {
        final dbEmail = profile?.email;
        _email = (dbEmail != null && dbEmail.isNotEmpty) ? dbEmail : authEmail;
        _displayName = profile?.username ?? (_email.isNotEmpty ? _email.split('@').first : 'User');
      });
    } catch (_) {
      // keep defaults on error
    }
  }

  void _onProfileRefresh() {
    if (!mounted) return;
    _loadProfile();
  }

  @override
  void dispose() {
    profileRefreshCounter.removeListener(_onProfileRefresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Colors.white.withOpacity(.82);
    final nameStyle = Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900, fontSize: 28);
    final emailStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16);

    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: SizedBox(width: 420, height: 180, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(color: Colors.black.withOpacity(.06)),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 6))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and email (left aligned)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_displayName.isNotEmpty ? _displayName : '-', style: nameStyle),
                    const SizedBox(height: 18),
                    Row(mainAxisSize: MainAxisSize.min, children: [Text('Email: ', style: emailStyle), const SizedBox(width: 8), Text(_email.isNotEmpty ? _email : '-', style: emailStyle)]),
                  ],
                ),

                // Button centered at the bottom
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileInfoScreen())),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), minimumSize: const Size(140, 36), backgroundColor: _accent.withOpacity(0.1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('View more details', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: _accent, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _accent),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )),
        ),
      ),
    );
  }
}