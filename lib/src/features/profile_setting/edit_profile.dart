import 'dart:ui';

import 'package:flutter/material.dart';
import '../../services/supabase.dart';
import '../profile_setting/profile_notifier.dart';
import 'get_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 480,
                            child: ElevatedButton(
                              onPressed: () async {
                                  // Open the change email dialog. Keep the Edit screen open
                                  // even if the profile email was updated.
                                  await _showChangeEmailDialog(context);
                                },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                                elevation: 6,
                              ),
                              child: const Text('Change email'),
                            ),
                          ),

                          const SizedBox(height: 25),

                          SizedBox(
                            width: 480,
                            child: OutlinedButton(
                              onPressed: () => _showChangePasswordDialog(context),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                side: BorderSide(color: _accent.withOpacity(0.14)),
                                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                              child: const Text('Change password'),
                            ),
                          ),
                        ],
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



// Dialog helpers
Future<bool?> _showChangeEmailDialog(BuildContext context) async {
  // Fetch the current user and their profile email (if available)
  String currentEmail = '';
  try {
    final authUser = supabase.auth.currentUser;
    if (authUser != null) {
      final profile = await fetchUserProfile(authUser.id);
      // Prefer DB profile email (we update `users` table). If missing, fall back to auth user's email.
      currentEmail = (profile != null && profile.email.isNotEmpty)
          ? profile.email
          : ((authUser.email != null && authUser.email!.isNotEmpty) ? authUser.email! : '');
    }
  } catch (_) {
    // ignore errors and fall back to empty string
    currentEmail = '';
  }

  final newController = TextEditingController();
  bool isEmailLoading = false;
  String emailMessage = '';
  bool emailIsError = false;

  final result = await showDialog<bool?>(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: StatefulBuilder(builder: (context, setState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Change email', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                const Align(alignment: Alignment.centerLeft, child: Text('Current email')),
                const SizedBox(height: 6),
                // non-editable display of current email
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(currentEmail.isNotEmpty ? currentEmail : 'Not available', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 16),
                const Align(alignment: Alignment.centerLeft, child: Text('New email')),
                const SizedBox(height: 6),
                TextField(controller: newController, decoration: const InputDecoration(border: OutlineInputBorder())),
                const SizedBox(height: 12),
                if (emailMessage.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: emailIsError ? Colors.red.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: emailIsError ? Colors.red.shade200 : Colors.green.shade200),
                    ),
                    child: Text(
                      emailMessage,
                      style: TextStyle(color: emailIsError ? Colors.red.shade800 : Colors.green.shade800),
                    ),
                  ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: isEmailLoading ? null : () async {
                        final newEmail = newController.text.trim();
                        if (newEmail.isEmpty) {
                          setState(() {
                            emailMessage = 'Please enter a new email.';
                            emailIsError = true;
                          });
                          return;
                        }

                        setState(() {
                          isEmailLoading = true;
                          emailMessage = '';
                        });

                        try {
                          final authUser = supabase.auth.currentUser;
                          if (authUser == null) {
                            setState(() {
                              emailMessage = 'Please log in to continue.';
                              emailIsError = true;
                            });
                            return;
                          }

                          await supabase.rpc('update_user_email_bypass', params: {
                            'new_email': newEmail,
                          });

                          await supabase.auth.refreshSession();

                          await supabase.from('users').update({'email': newEmail}).eq('user_id', authUser.id);

                          profileRefreshCounter.value += 1;

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Email updated successfully.')),
                            );
                            Navigator.of(context).pop(true);
                          }
                        } on PostgrestException catch (e) {
                          setState(() {
                            emailMessage = e.message;
                            emailIsError = true;
                          });
                        } catch (e) {
                          debugPrint(e.toString());
                          setState(() {
                            emailMessage = 'An error occurred. Please try again later.';
                            emailIsError = true;
                          });
                        } finally {
                          try {
                            setState(() {
                              isEmailLoading = false;
                            });
                          } catch (_) {}
                        }
                      },
                      child: isEmailLoading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Confirm'),
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

  return result;
}

void _showChangePasswordDialog(BuildContext context) {
  final nowController = TextEditingController();
  final newController = TextEditingController();
  bool obscured = true;
  bool isPasswordVerified = false;
  String verificationMessage = '';
  bool isPasswordLoading = false;
  String passwordActionMessage = '';
  bool passwordActionIsError = false;

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
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      verificationMessage = 'Verifying...';
                    });
                    try {
                      final authUser = supabase.auth.currentUser;
                      if (authUser == null) {
                        setState(() {
                          isPasswordVerified = false;
                          verificationMessage = 'Not logged in';
                        });
                        return;
                      }

                      // Try to fetch profile from DB and prefer DB-stored password if present
                      final dbProfile = await fetchUserProfile(authUser.id);
                      if (dbProfile != null && dbProfile.password.isNotEmpty) {
                        if (dbProfile.password == nowController.text) {
                          setState(() {
                            isPasswordVerified = true;
                            verificationMessage = 'Password verified';
                          });
                        } else {
                          setState(() {
                            isPasswordVerified = false;
                            verificationMessage = 'Password does not match';
                          });
                        }
                        return;
                      }

                      // Fallback: verify via Supabase auth sign-in
                      final email = (dbProfile != null && dbProfile.email.isNotEmpty) ? dbProfile.email : (authUser.email ?? '');

                      final res = await supabase.auth.signInWithPassword(
                        email: email,
                        password: nowController.text,
                      );

                      if (res.session != null) {
                        setState(() {
                          isPasswordVerified = true;
                          verificationMessage = 'Password verified successfully!';
                        });
                      } else {
                        setState(() {
                          isPasswordVerified = false;
                          verificationMessage = 'Password does not match';
                        });
                      }
                    } catch (e) {
                      setState(() {
                        isPasswordVerified = false;
                        verificationMessage = 'Error verifying password';
                      });
                    }
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
                if (passwordActionMessage.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: passwordActionIsError ? Colors.red.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: passwordActionIsError ? Colors.red.shade200 : Colors.green.shade200),
                    ),
                    child: Text(
                      passwordActionMessage,
                      style: TextStyle(color: passwordActionIsError ? Colors.red.shade800 : Colors.green.shade800),
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
                      onPressed: (isPasswordVerified && !isPasswordLoading) ? () async {
                          final newPass = newController.text;
                          if (newPass.isEmpty) {
                            setState(() {
                              passwordActionMessage = 'Please enter a new password.';
                              passwordActionIsError = true;
                            });
                            return;
                          }
                          if (newPass.length < 6) {
                            setState(() {
                              passwordActionMessage = 'The new password must be at least 6 characters.';
                              passwordActionIsError = true;
                            });
                            return;
                          }

                          setState(() {
                            isPasswordLoading = true;
                            passwordActionMessage = '';
                          });

                          try {
                            // Update password for current user (auth)
                            final res = await supabase.auth.updateUser(UserAttributes(password: newPass));
                            if (res.user == null) {
                              throw Exception('Failed to update auth password');
                            }

                            // If the app stores a copy of the password in the `users` table, update it there as well
                            try {
                              final authUser = supabase.auth.currentUser;
                              if (authUser != null) {
                                await supabase.from('users').update({'password': newPass}).eq('user_id', authUser.id);
                              }
                            } catch (_) {
                              // ignore DB write errors for stored password sync
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password changed successfully.')),
                            );
                            Navigator.of(context).pop();
                          } catch (e) {
                            setState(() {
                              passwordActionMessage = 'Failed to change password.';
                              passwordActionIsError = true;
                            });
                          } finally {
                            try {
                              setState(() {
                                isPasswordLoading = false;
                              });
                            } catch (_) {}
                          }
                        } : null,
                      child: isPasswordLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Confirm'),
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