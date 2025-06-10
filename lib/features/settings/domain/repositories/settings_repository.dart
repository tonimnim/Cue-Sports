import '../entities/user_settings.dart';
import '../entities/community_transfer_request.dart';

/// Repository interface for settings
abstract class SettingsRepository {
  /// Get user settings
  Future<UserSettings> getUserSettings(String userId);

  /// Update user settings
  Future<void> updateUserSettings(UserSettings settings);

  /// Create community transfer request
  Future<String> createCommunityTransferRequest(
      CommunityTransferRequest request);

  /// Get community transfer requests for admin
  Future<List<CommunityTransferRequest>> getCommunityTransferRequests(
      String communityId);

  /// Get user's transfer request
  Future<CommunityTransferRequest?> getUserTransferRequest(String userId);

  /// Update transfer request status
  Future<void> updateTransferRequestStatus(
    String requestId,
    CommunityTransferStatus status,
    String processedBy, {
    String? adminNotes,
    String? rejectionReason,
  });

  /// Cancel transfer request
  Future<void> cancelTransferRequest(String requestId);
}
