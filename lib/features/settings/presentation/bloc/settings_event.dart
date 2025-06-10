import 'package:equatable/equatable.dart';
import '../../domain/entities/user_settings.dart';

/// Base class for settings events
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Load user settings
class LoadUserSettings extends SettingsEvent {
  final String userId;

  const LoadUserSettings({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Update profile information
class UpdateProfileInfo extends SettingsEvent {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String? profileImageUrl;

  const UpdateProfileInfo({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.profileImageUrl,
  });

  @override
  List<Object?> get props => [fullName, email, phoneNumber, profileImageUrl];
}

/// Update account settings
class UpdateAccountSettings extends SettingsEvent {
  final bool twoFactorEnabled;
  final String? backupEmail;

  const UpdateAccountSettings({
    required this.twoFactorEnabled,
    this.backupEmail,
  });

  @override
  List<Object?> get props => [twoFactorEnabled, backupEmail];
}

/// Update notification settings
class UpdateNotificationSettings extends SettingsEvent {
  final bool tournamentReminders;
  final bool communityUpdates;
  final bool paymentNotifications;
  final bool systemNotifications;
  final bool emailNotifications;
  final bool pushNotifications;

  const UpdateNotificationSettings({
    required this.tournamentReminders,
    required this.communityUpdates,
    required this.paymentNotifications,
    required this.systemNotifications,
    required this.emailNotifications,
    required this.pushNotifications,
  });

  @override
  List<Object?> get props => [
        tournamentReminders,
        communityUpdates,
        paymentNotifications,
        systemNotifications,
        emailNotifications,
        pushNotifications,
      ];
}

/// Update privacy settings
class UpdatePrivacySettings extends SettingsEvent {
  final bool profileVisible;
  final bool showRanking;
  final bool showMatchHistory;
  final bool allowDirectMessages;

  const UpdatePrivacySettings({
    required this.profileVisible,
    required this.showRanking,
    required this.showMatchHistory,
    required this.allowDirectMessages,
  });

  @override
  List<Object?> get props => [
        profileVisible,
        showRanking,
        showMatchHistory,
        allowDirectMessages,
      ];
}

/// Update app preferences
class UpdateAppPreferences extends SettingsEvent {
  final String language;
  final String theme;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool autoPlayVideos;

  const UpdateAppPreferences({
    required this.language,
    required this.theme,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.autoPlayVideos,
  });

  @override
  List<Object?> get props => [
        language,
        theme,
        soundEnabled,
        vibrationEnabled,
        autoPlayVideos,
      ];
}

/// Update player specific settings
class UpdatePlayerSettings extends SettingsEvent {
  final bool availableForMatches;
  final List<String> preferredGameTypes;
  final String? playingStyle;
  final bool openToSponsorship;

  const UpdatePlayerSettings({
    required this.availableForMatches,
    required this.preferredGameTypes,
    this.playingStyle,
    required this.openToSponsorship,
  });

  @override
  List<Object?> get props => [
        availableForMatches,
        preferredGameTypes,
        playingStyle,
        openToSponsorship,
      ];
}

/// Request community transfer (Players only)
class RequestCommunityTransfer extends SettingsEvent {
  final String toCommunityId;
  final String toCommunityName;
  final String reason;

  const RequestCommunityTransfer({
    required this.toCommunityId,
    required this.toCommunityName,
    required this.reason,
  });

  @override
  List<Object?> get props => [toCommunityId, toCommunityName, reason];
}

/// Cancel community transfer request
class CancelCommunityTransferRequest extends SettingsEvent {
  final String requestId;

  const CancelCommunityTransferRequest({required this.requestId});

  @override
  List<Object?> get props => [requestId];
}

/// Load user's transfer request
class LoadUserTransferRequest extends SettingsEvent {
  final String userId;

  const LoadUserTransferRequest({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Change password
class ChangePassword extends SettingsEvent {
  final String currentPassword;
  final String newPassword;

  const ChangePassword({
    required this.currentPassword,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [currentPassword, newPassword];
}

/// Delete account
class DeleteAccount extends SettingsEvent {
  final String password;

  const DeleteAccount({required this.password});

  @override
  List<Object?> get props => [password];
}

/// Reset settings to default
class ResetSettingsToDefault extends SettingsEvent {
  const ResetSettingsToDefault();
}
