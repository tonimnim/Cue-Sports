import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/user_settings.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';
import '../widgets/user_profile_header.dart';
import 'profile_settings_screen.dart';
import 'account_settings_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_settings_screen.dart';
import 'app_preferences_screen.dart';
import 'player_settings_screen.dart';
import 'community_settings_screen.dart';
import 'support_screen.dart';

/// Main settings screen with fan/player specific options
class SettingsMainScreen extends StatefulWidget {
  const SettingsMainScreen({super.key});

  @override
  State<SettingsMainScreen> createState() => _SettingsMainScreenState();
}

class _SettingsMainScreenState extends State<SettingsMainScreen> {
  @override
  void initState() {
    super.initState();
    // Load user settings on screen init
    context
        .read<SettingsBloc>()
        .add(const LoadUserSettings(userId: 'current_user_id'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            color: AppTheme.textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state is SettingsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          } else if (state is SettingsUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.successColor,
              ),
            );
          } else if (state is CommunityTransferRequestCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.successColor,
              ),
            );
          } else if (state is PasswordChanged) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.successColor,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is SettingsLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            );
          }

          if (state is SettingsError && state.currentSettings == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load settings',
                    style: TextStyle(
                      color: AppTheme.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<SettingsBloc>().add(
                            const LoadUserSettings(userId: 'current_user_id'),
                          );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Get settings from current state
          UserSettings? settings;
          if (state is SettingsLoaded) {
            settings = state.settings;
          } else if (state is SettingsUpdating) {
            settings = state.currentSettings;
          } else if (state is SettingsError && state.currentSettings != null) {
            settings = state.currentSettings;
          }

          if (settings == null) {
            return const Center(
              child: Text(
                'No settings available',
                style: TextStyle(color: AppTheme.textColor),
              ),
            );
          }

          return _buildSettingsContent(context, settings, state);
        },
      ),
    );
  }

  Widget _buildSettingsContent(
      BuildContext context, UserSettings settings, SettingsState state) {
    final isUpdating = state is SettingsUpdating;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // User Profile Header
          UserProfileHeader(settings: settings),

          const SizedBox(height: 24),

          // Profile Information Section
          SettingsSection(
            title: 'Profile Information',
            children: [
              SettingsTile(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                subtitle: 'Update your personal information',
                onTap: isUpdating
                    ? null
                    : () => _navigateToProfileSettings(context),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Account Settings Section
          SettingsSection(
            title: 'Account Settings',
            children: [
              SettingsTile(
                icon: Icons.security_outlined,
                title: 'Security',
                subtitle: 'Password, 2FA, backup email',
                onTap: isUpdating
                    ? null
                    : () => _navigateToAccountSettings(context),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Community Settings Section (Players Only)
          if (settings.isPlayer) ...[
            SettingsSection(
              title: 'Community Settings',
              children: [
                SettingsTile(
                  icon: Icons.group_outlined,
                  title: 'Community Management',
                  subtitle: settings.hasTransferRequest
                      ? 'Transfer request pending'
                      : 'Manage community membership',
                  trailing: settings.hasTransferRequest
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.warningColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Pending',
                            style: TextStyle(
                              color: AppTheme.warningColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                  onTap: isUpdating
                      ? null
                      : () => _navigateToCommunitySettings(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Notification Settings Section
          SettingsSection(
            title: 'Notifications',
            children: [
              SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Notification Preferences',
                subtitle: 'Manage your notification settings',
                onTap: isUpdating
                    ? null
                    : () => _navigateToNotificationSettings(context),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Privacy Settings Section
          SettingsSection(
            title: 'Privacy',
            children: [
              SettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Settings',
                subtitle: 'Control your profile visibility',
                onTap: isUpdating
                    ? null
                    : () => _navigateToPrivacySettings(context),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // App Preferences Section
          SettingsSection(
            title: 'App Preferences',
            children: [
              SettingsTile(
                icon: Icons.palette_outlined,
                title: 'Appearance & Language',
                subtitle: 'Theme, language, and display options',
                onTap: isUpdating
                    ? null
                    : () => _navigateToAppPreferences(context),
              ),
            ],
          ),

          // Player Specific Settings (Players Only)
          if (settings.isPlayer) ...[
            const SizedBox(height: 16),
            SettingsSection(
              title: 'Player Settings',
              children: [
                SettingsTile(
                  icon: Icons.sports_outlined,
                  title: 'Game Preferences',
                  subtitle: 'Match availability and playing style',
                  onTap: isUpdating
                      ? null
                      : () => _navigateToPlayerSettings(context),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // Support Section
          SettingsSection(
            title: 'Support',
            children: [
              SettingsTile(
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'FAQ, contact us, feedback',
                onTap: () => _navigateToSupport(context),
              ),
              SettingsTile(
                icon: Icons.info_outline,
                title: 'About',
                subtitle: 'App version and legal information',
                onTap: () => _showAboutDialog(context),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Danger Zone
          SettingsSection(
            title: 'Danger Zone',
            children: [
              SettingsTile(
                icon: Icons.refresh_outlined,
                title: 'Reset Settings',
                subtitle: 'Reset all settings to default',
                textColor: AppTheme.warningColor,
                onTap:
                    isUpdating ? null : () => _showResetConfirmation(context),
              ),
              SettingsTile(
                icon: Icons.delete_outline,
                title: 'Delete Account',
                subtitle: 'Permanently delete your account',
                textColor: AppTheme.errorColor,
                onTap:
                    isUpdating ? null : () => _showDeleteAccountDialog(context),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _navigateToProfileSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProfileSettingsScreen(),
      ),
    );
  }

  void _navigateToAccountSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AccountSettingsScreen(),
      ),
    );
  }

  void _navigateToNotificationSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NotificationSettingsScreen(),
      ),
    );
  }

  void _navigateToPrivacySettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PrivacySettingsScreen(),
      ),
    );
  }

  void _navigateToAppPreferences(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AppPreferencesScreen(),
      ),
    );
  }

  void _navigateToPlayerSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PlayerSettingsScreen(),
      ),
    );
  }

  void _navigateToCommunitySettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CommunitySettingsScreen(),
      ),
    );
  }

  void _navigateToSupport(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SupportScreen(),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Cue Sports',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.sports_outlined,
        size: 48,
        color: AppTheme.primaryColor,
      ),
      children: [
        const Text(
          'A comprehensive billiards community and tournament management app.',
        ),
      ],
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text(
          'Reset Settings',
          style: TextStyle(color: AppTheme.textColor),
        ),
        content: const Text(
          'Are you sure you want to reset all settings to default? This action cannot be undone.',
          style: TextStyle(color: AppTheme.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<SettingsBloc>().add(const ResetSettingsToDefault());
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: AppTheme.warningColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: const Text(
          'Delete Account',
          style: TextStyle(color: AppTheme.errorColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This action will permanently delete your account and all associated data. This cannot be undone.',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: AppTheme.textColor),
              decoration: InputDecoration(
                labelText: 'Enter your password to confirm',
                labelStyle: const TextStyle(color: AppTheme.textSecondaryColor),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: AppTheme.primaryColor),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ),
          TextButton(
            onPressed: () {
              if (passwordController.text.isNotEmpty) {
                Navigator.of(context).pop();
                context.read<SettingsBloc>().add(
                      DeleteAccount(password: passwordController.text),
                    );
              }
            },
            child: const Text(
              'Delete Account',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}
