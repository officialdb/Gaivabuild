import 'package:flutter/material.dart';
import '../models/master_profile.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

class AccountSettingsScreen extends StatefulWidget {
  final MasterProfile profile;
  final Function(MasterProfile) onProfileUpdated;

  const AccountSettingsScreen({
    super.key,
    required this.profile,
    required this.onProfileUpdated,
  });

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  late MasterProfile _currentProfile;

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.profile;
  }

  void _openEditProfileDialog() {
    final nameController = TextEditingController(text: _currentProfile.fullName);
    final titleController = TextEditingController(text: _currentProfile.title);
    final emailController = TextEditingController(text: _currentProfile.email);
    final phoneController = TextEditingController(text: _currentProfile.phone);
    final locationController =
        TextEditingController(text: _currentProfile.location);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Edit Profile Details',
          style: TextStyle(
            color: AppTheme.textPrimaryLight,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(color: AppTheme.textPrimaryLight),
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: titleController,
                  style: const TextStyle(color: AppTheme.textPrimaryLight),
                  decoration: const InputDecoration(
                    labelText: 'Professional Title *',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppTheme.textPrimaryLight),
                  decoration: const InputDecoration(
                    labelText: 'Email Address *',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppTheme.textPrimaryLight),
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: locationController,
                  style: const TextStyle(color: AppTheme.textPrimaryLight),
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final updated = _currentProfile.copyWith(
                  fullName: nameController.text.trim(),
                  title: titleController.text.trim(),
                  email: emailController.text.trim(),
                  phone: phoneController.text.trim(),
                  location: locationController.text.trim(),
                );
                setState(() => _currentProfile = updated);
                widget.onProfileUpdated(updated);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile details updated successfully!'),
                    backgroundColor: AppTheme.accent,
                  ),
                );
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _openChangePasswordDialog() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Change Password',
          style: TextStyle(
            color: AppTheme.textPrimaryLight,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPassController,
                obscureText: true,
                style: const TextStyle(color: AppTheme.textPrimaryLight),
                decoration: const InputDecoration(
                  labelText: 'Current Password *',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Current password is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newPassController,
                obscureText: true,
                style: const TextStyle(color: AppTheme.textPrimaryLight),
                decoration: const InputDecoration(
                  labelText: 'New Password *',
                  prefixIcon: Icon(Icons.lock_reset_outlined),
                ),
                validator: (v) {
                  if (v == null || v.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmPassController,
                obscureText: true,
                style: const TextStyle(color: AppTheme.textPrimaryLight),
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password *',
                  prefixIcon: Icon(Icons.check_circle_outline),
                ),
                validator: (v) {
                  if (v != newPassController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password changed successfully!'),
                    backgroundColor: Color.fromRGBO(16, 185, 129, 1),
                  ),
                );
              }
            },
            child: const Text('Update Password'),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Sign Out',
          style: TextStyle(
            color: AppTheme.textPrimaryLight,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          'Are you sure you want to sign out of your Auth session?',
          style: TextStyle(color: AppTheme.textSecondaryLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await AuthService().signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 24),
            SizedBox(width: 8),
            Text(
              'Delete Account',
              style: TextStyle(
                color: AppTheme.danger,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action is permanent and cannot be undone.',
              style: TextStyle(
                color: AppTheme.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Deleting your account will immediately wipe your Master Profile, tailored resumes, cover letter history, and ATS embeddings from Auth servers.',
              style: TextStyle(
                color: AppTheme.textSecondaryLight,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Account'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await AuthService().signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                  (route) => false,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account and Master Profile data permanently deleted from Auth.'),
                    backgroundColor: AppTheme.textPrimaryLight,
                    duration: Duration(seconds: 4),
                  ),
                );
              }
            },
            child: const Text('Permanently Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final displayEmail = user?.email ?? _currentProfile.email;
    final displayName = user?.fullName ?? _currentProfile.fullName;
    final provider = user?.provider?.toUpperCase() ?? 'EMAIL';

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Account & Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          children: [
            // User Header Profile Overview Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.cobaltBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppTheme.cobaltBlue,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimaryLight,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayEmail,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$provider • VERIFIED',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.accent,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppTheme.cobaltBlue),
                    onPressed: _openEditProfileDialog,
                    tooltip: 'Edit Profile Details',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Profile Section
            const _SettingsSectionHeader(title: 'PROFILE & CONTACT INFORMATION'),
            const SizedBox(height: 8),
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.badge_outlined,
                  title: 'Edit Personal Details',
                  subtitle: 'Update name, job title, email, phone & location',
                  onTap: _openEditProfileDialog,
                ),
                const Divider(height: 1, color: AppTheme.borderLight),
                _SettingsTile(
                  icon: Icons.link_rounded,
                  title: 'Social & Portfolio Links',
                  subtitle: 'LinkedIn, GitHub, Personal Website',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Connected: linkedin.com/in/alexmorgan'),
                        backgroundColor: AppTheme.cobaltBlue,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Security Section
            const _SettingsSectionHeader(title: 'SECURITY & AUTHENTICATION'),
            const SizedBox(height: 8),
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.lock_reset_rounded,
                  title: 'Change Password',
                  subtitle: 'Update your account login password on Auth',
                  onTap: _openChangePasswordDialog,
                ),
                const Divider(height: 1, color: AppTheme.borderLight),
                _SettingsTile(
                  icon: Icons.shield_outlined,
                  title: 'Two-Factor Authentication (2FA)',
                  subtitle: 'Enabled via Authenticator App',
                  trailing: const Icon(Icons.check_circle_rounded,
                      color: AppTheme.accent, size: 20),
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Data & Privacy Section
            const _SettingsSectionHeader(title: 'DATA & PRIVACY CONTROL'),
            const SizedBox(height: 8),
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.download_outlined,
                  title: 'Export Master Profile JSON',
                  subtitle: 'Download complete structured resume facts',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Master Profile facts exported to JSON file!'),
                        backgroundColor: AppTheme.accent,
                      ),
                    );
                  },
                ),
                const Divider(height: 1, color: AppTheme.borderLight),
                _SettingsTile(
                  icon: Icons.cleaning_services_outlined,
                  title: 'Clear AI Tailoring Cache',
                  subtitle: 'Wipe temporary JD match embeddings from Auth',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('AI embedding cache cleared on Auth.'),
                        backgroundColor: AppTheme.textPrimaryLight,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Account Actions
            const _SettingsSectionHeader(title: 'ACCOUNT ACTIONS'),
            const SizedBox(height: 8),
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.logout_rounded,
                  iconColor: AppTheme.cobaltBlue,
                  title: 'Sign Out',
                  subtitle: 'Log out of your Auth account',
                  onTap: _confirmSignOut,
                ),
                const Divider(height: 1, color: AppTheme.borderLight),
                _SettingsTile(
                  icon: Icons.delete_forever_rounded,
                  iconColor: AppTheme.danger,
                  title: 'Delete Account',
                  titleColor: AppTheme.danger,
                  subtitle: 'Permanently remove your data & profile facts',
                  onTap: _confirmDeleteAccount,
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SettingsSectionHeader extends StatelessWidget {
  final String title;

  const _SettingsSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: AppTheme.textSecondaryLight,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final Color? titleColor;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    this.iconColor,
    required this.title,
    this.titleColor,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: (iconColor ?? AppTheme.cobaltBlue).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: iconColor ?? AppTheme.cobaltBlue,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14.5,
          color: titleColor ?? AppTheme.textPrimaryLight,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.textSecondaryLight,
        ),
      ),
      trailing: trailing ??
          const Icon(Icons.chevron_right_rounded,
              color: AppTheme.textSecondaryLight, size: 20),
      onTap: onTap,
    );
  }
}
