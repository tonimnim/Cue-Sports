import 'package:equatable/equatable.dart';

/// Enum for user types
enum UserType { fan, player }

/// Enum for community transfer request status
enum CommunityTransferStatus { none, pending, approved, rejected }

/// User settings entity with fan/player specific settings
class UserSettings extends Equatable {
  final String userId;
  final UserType userType;

  // Profile Information (Both)
  final String fullName;
  final String email;
  final String phoneNumber;
  final String? profileImageUrl;
  final String? nationalRank;
  final bool isPremiumMember;

  // Account Settings (Both)
  final bool twoFactorEnabled;
  final String? backupEmail;
  final DateTime? lastPasswordChange;

  // Notification Settings (Both)
  final bool tournamentReminders;
  final bool communityUpdates;
  final bool paymentNotifications;
  final bool systemNotifications;
  final bool emailNotifications;
  final bool pushNotifications;

  // Community Settings (Players Only)
  final String? currentCommunityId;
  final String? currentCommunityName;
  final CommunityTransferStatus transferStatus;
  final String? pendingCommunityId;
  final String? pendingCommunityName;
  final DateTime? transferRequestDate;
  final String? transferReason;

  // Privacy Settings (Both)
  final bool profileVisible;
  final bool showRanking;
  final bool showMatchHistory;
  final bool allowDirectMessages;

  // App Preferences (Both)
  final String language;
  final String theme;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool autoPlayVideos;

  // Player Specific Settings
  final bool availableForMatches;
  final List<String> preferredGameTypes;
  final String? playingStyle;
  final bool openToSponsorship;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserSettings({
    required this.userId,
    required this.userType,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.profileImageUrl,
    this.nationalRank,
    this.isPremiumMember = false,
    this.twoFactorEnabled = false,
    this.backupEmail,
    this.lastPasswordChange,
    this.tournamentReminders = true,
    this.communityUpdates = true,
    this.paymentNotifications = true,
    this.systemNotifications = true,
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.currentCommunityId,
    this.currentCommunityName,
    this.transferStatus = CommunityTransferStatus.none,
    this.pendingCommunityId,
    this.pendingCommunityName,
    this.transferRequestDate,
    this.transferReason,
    this.profileVisible = true,
    this.showRanking = true,
    this.showMatchHistory = true,
    this.allowDirectMessages = true,
    this.language = 'en',
    this.theme = 'dark',
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.autoPlayVideos = false,
    this.availableForMatches = true,
    this.preferredGameTypes = const ['8Ball'],
    this.playingStyle,
    this.openToSponsorship = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if user is a player
  bool get isPlayer => userType == UserType.player;

  /// Check if user is a fan
  bool get isFan => userType == UserType.fan;

  /// Check if community transfer is pending
  bool get hasTransferRequest =>
      transferStatus == CommunityTransferStatus.pending;

  /// Check if user can request community transfer
  bool get canRequestTransfer =>
      isPlayer &&
      transferStatus == CommunityTransferStatus.none &&
      currentCommunityId != null;

  /// Get display name for user type
  String get userTypeDisplayName {
    switch (userType) {
      case UserType.fan:
        return 'Fan';
      case UserType.player:
        return 'Player';
    }
  }

  /// Get transfer status display name
  String get transferStatusDisplayName {
    switch (transferStatus) {
      case CommunityTransferStatus.none:
        return 'No Transfer Request';
      case CommunityTransferStatus.pending:
        return 'Transfer Pending';
      case CommunityTransferStatus.approved:
        return 'Transfer Approved';
      case CommunityTransferStatus.rejected:
        return 'Transfer Rejected';
    }
  }

  /// Copy with updated fields
  UserSettings copyWith({
    String? userId,
    UserType? userType,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
    String? nationalRank,
    bool? isPremiumMember,
    bool? twoFactorEnabled,
    String? backupEmail,
    DateTime? lastPasswordChange,
    bool? tournamentReminders,
    bool? communityUpdates,
    bool? paymentNotifications,
    bool? systemNotifications,
    bool? emailNotifications,
    bool? pushNotifications,
    String? currentCommunityId,
    String? currentCommunityName,
    CommunityTransferStatus? transferStatus,
    String? pendingCommunityId,
    String? pendingCommunityName,
    DateTime? transferRequestDate,
    String? transferReason,
    bool? profileVisible,
    bool? showRanking,
    bool? showMatchHistory,
    bool? allowDirectMessages,
    String? language,
    String? theme,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? autoPlayVideos,
    bool? availableForMatches,
    List<String>? preferredGameTypes,
    String? playingStyle,
    bool? openToSponsorship,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearTransferRequest = false,
    bool clearPendingCommunity = false,
  }) {
    return UserSettings(
      userId: userId ?? this.userId,
      userType: userType ?? this.userType,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      nationalRank: nationalRank ?? this.nationalRank,
      isPremiumMember: isPremiumMember ?? this.isPremiumMember,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      backupEmail: backupEmail ?? this.backupEmail,
      lastPasswordChange: lastPasswordChange ?? this.lastPasswordChange,
      tournamentReminders: tournamentReminders ?? this.tournamentReminders,
      communityUpdates: communityUpdates ?? this.communityUpdates,
      paymentNotifications: paymentNotifications ?? this.paymentNotifications,
      systemNotifications: systemNotifications ?? this.systemNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      currentCommunityId: currentCommunityId ?? this.currentCommunityId,
      currentCommunityName: currentCommunityName ?? this.currentCommunityName,
      transferStatus: clearTransferRequest
          ? CommunityTransferStatus.none
          : (transferStatus ?? this.transferStatus),
      pendingCommunityId: clearPendingCommunity
          ? null
          : (pendingCommunityId ?? this.pendingCommunityId),
      pendingCommunityName: clearPendingCommunity
          ? null
          : (pendingCommunityName ?? this.pendingCommunityName),
      transferRequestDate: clearTransferRequest
          ? null
          : (transferRequestDate ?? this.transferRequestDate),
      transferReason:
          clearTransferRequest ? null : (transferReason ?? this.transferReason),
      profileVisible: profileVisible ?? this.profileVisible,
      showRanking: showRanking ?? this.showRanking,
      showMatchHistory: showMatchHistory ?? this.showMatchHistory,
      allowDirectMessages: allowDirectMessages ?? this.allowDirectMessages,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      autoPlayVideos: autoPlayVideos ?? this.autoPlayVideos,
      availableForMatches: availableForMatches ?? this.availableForMatches,
      preferredGameTypes: preferredGameTypes ?? this.preferredGameTypes,
      playingStyle: playingStyle ?? this.playingStyle,
      openToSponsorship: openToSponsorship ?? this.openToSponsorship,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        userType,
        fullName,
        email,
        phoneNumber,
        profileImageUrl,
        nationalRank,
        isPremiumMember,
        twoFactorEnabled,
        backupEmail,
        lastPasswordChange,
        tournamentReminders,
        communityUpdates,
        paymentNotifications,
        systemNotifications,
        emailNotifications,
        pushNotifications,
        currentCommunityId,
        currentCommunityName,
        transferStatus,
        pendingCommunityId,
        pendingCommunityName,
        transferRequestDate,
        transferReason,
        profileVisible,
        showRanking,
        showMatchHistory,
        allowDirectMessages,
        language,
        theme,
        soundEnabled,
        vibrationEnabled,
        autoPlayVideos,
        availableForMatches,
        preferredGameTypes,
        playingStyle,
        openToSponsorship,
        createdAt,
        updatedAt,
      ];
}
