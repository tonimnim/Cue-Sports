import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_settings.dart';

/// Firebase model for user settings
class UserSettingsModel extends UserSettings {
  const UserSettingsModel({
    required super.userId,
    required super.userType,
    required super.fullName,
    required super.email,
    required super.phoneNumber,
    super.profileImageUrl,
    super.nationalRank,
    super.isPremiumMember,
    super.twoFactorEnabled,
    super.backupEmail,
    super.lastPasswordChange,
    super.tournamentReminders,
    super.communityUpdates,
    super.paymentNotifications,
    super.systemNotifications,
    super.emailNotifications,
    super.pushNotifications,
    super.currentCommunityId,
    super.currentCommunityName,
    super.transferStatus,
    super.pendingCommunityId,
    super.pendingCommunityName,
    super.transferRequestDate,
    super.transferReason,
    super.profileVisible,
    super.showRanking,
    super.showMatchHistory,
    super.allowDirectMessages,
    super.language,
    super.theme,
    super.soundEnabled,
    super.vibrationEnabled,
    super.autoPlayVideos,
    super.availableForMatches,
    super.preferredGameTypes,
    super.playingStyle,
    super.openToSponsorship,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Create from Firebase document
  factory UserSettingsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserSettingsModel(
      userId: doc.id,
      userType: UserType.values.firstWhere(
        (type) => type.name == data['userType'],
        orElse: () => UserType.fan,
      ),
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      nationalRank: data['nationalRank'],
      isPremiumMember: data['isPremiumMember'] ?? false,
      twoFactorEnabled: data['twoFactorEnabled'] ?? false,
      backupEmail: data['backupEmail'],
      lastPasswordChange: data['lastPasswordChange'] != null
          ? (data['lastPasswordChange'] as Timestamp).toDate()
          : null,
      tournamentReminders: data['tournamentReminders'] ?? true,
      communityUpdates: data['communityUpdates'] ?? true,
      paymentNotifications: data['paymentNotifications'] ?? true,
      systemNotifications: data['systemNotifications'] ?? true,
      emailNotifications: data['emailNotifications'] ?? true,
      pushNotifications: data['pushNotifications'] ?? true,
      currentCommunityId: data['currentCommunityId'],
      currentCommunityName: data['currentCommunityName'],
      transferStatus: CommunityTransferStatus.values.firstWhere(
        (status) => status.name == data['transferStatus'],
        orElse: () => CommunityTransferStatus.none,
      ),
      pendingCommunityId: data['pendingCommunityId'],
      pendingCommunityName: data['pendingCommunityName'],
      transferRequestDate: data['transferRequestDate'] != null
          ? (data['transferRequestDate'] as Timestamp).toDate()
          : null,
      transferReason: data['transferReason'],
      profileVisible: data['profileVisible'] ?? true,
      showRanking: data['showRanking'] ?? true,
      showMatchHistory: data['showMatchHistory'] ?? true,
      allowDirectMessages: data['allowDirectMessages'] ?? true,
      language: data['language'] ?? 'en',
      theme: data['theme'] ?? 'dark',
      soundEnabled: data['soundEnabled'] ?? true,
      vibrationEnabled: data['vibrationEnabled'] ?? true,
      autoPlayVideos: data['autoPlayVideos'] ?? false,
      availableForMatches: data['availableForMatches'] ?? true,
      preferredGameTypes:
          List<String>.from(data['preferredGameTypes'] ?? ['8Ball']),
      playingStyle: data['playingStyle'],
      openToSponsorship: data['openToSponsorship'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firebase document
  Map<String, dynamic> toFirestore() {
    return {
      'userType': userType.name,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'nationalRank': nationalRank,
      'isPremiumMember': isPremiumMember,
      'twoFactorEnabled': twoFactorEnabled,
      'backupEmail': backupEmail,
      'lastPasswordChange': lastPasswordChange != null
          ? Timestamp.fromDate(lastPasswordChange!)
          : null,
      'tournamentReminders': tournamentReminders,
      'communityUpdates': communityUpdates,
      'paymentNotifications': paymentNotifications,
      'systemNotifications': systemNotifications,
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
      'currentCommunityId': currentCommunityId,
      'currentCommunityName': currentCommunityName,
      'transferStatus': transferStatus.name,
      'pendingCommunityId': pendingCommunityId,
      'pendingCommunityName': pendingCommunityName,
      'transferRequestDate': transferRequestDate != null
          ? Timestamp.fromDate(transferRequestDate!)
          : null,
      'transferReason': transferReason,
      'profileVisible': profileVisible,
      'showRanking': showRanking,
      'showMatchHistory': showMatchHistory,
      'allowDirectMessages': allowDirectMessages,
      'language': language,
      'theme': theme,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'autoPlayVideos': autoPlayVideos,
      'availableForMatches': availableForMatches,
      'preferredGameTypes': preferredGameTypes,
      'playingStyle': playingStyle,
      'openToSponsorship': openToSponsorship,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create from UserSettings entity
  factory UserSettingsModel.fromEntity(UserSettings settings) {
    return UserSettingsModel(
      userId: settings.userId,
      userType: settings.userType,
      fullName: settings.fullName,
      email: settings.email,
      phoneNumber: settings.phoneNumber,
      profileImageUrl: settings.profileImageUrl,
      nationalRank: settings.nationalRank,
      isPremiumMember: settings.isPremiumMember,
      twoFactorEnabled: settings.twoFactorEnabled,
      backupEmail: settings.backupEmail,
      lastPasswordChange: settings.lastPasswordChange,
      tournamentReminders: settings.tournamentReminders,
      communityUpdates: settings.communityUpdates,
      paymentNotifications: settings.paymentNotifications,
      systemNotifications: settings.systemNotifications,
      emailNotifications: settings.emailNotifications,
      pushNotifications: settings.pushNotifications,
      currentCommunityId: settings.currentCommunityId,
      currentCommunityName: settings.currentCommunityName,
      transferStatus: settings.transferStatus,
      pendingCommunityId: settings.pendingCommunityId,
      pendingCommunityName: settings.pendingCommunityName,
      transferRequestDate: settings.transferRequestDate,
      transferReason: settings.transferReason,
      profileVisible: settings.profileVisible,
      showRanking: settings.showRanking,
      showMatchHistory: settings.showMatchHistory,
      allowDirectMessages: settings.allowDirectMessages,
      language: settings.language,
      theme: settings.theme,
      soundEnabled: settings.soundEnabled,
      vibrationEnabled: settings.vibrationEnabled,
      autoPlayVideos: settings.autoPlayVideos,
      availableForMatches: settings.availableForMatches,
      preferredGameTypes: settings.preferredGameTypes,
      playingStyle: settings.playingStyle,
      openToSponsorship: settings.openToSponsorship,
      createdAt: settings.createdAt,
      updatedAt: settings.updatedAt,
    );
  }
}
