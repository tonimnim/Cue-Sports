import '../../domain/entities/user_settings.dart';
import '../../domain/entities/community_transfer_request.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_remote_data_source.dart';
import '../models/user_settings_model.dart';
import '../models/community_transfer_request_model.dart';

/// Implementation of settings repository
class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsRemoteDataSource _remoteDataSource;

  SettingsRepositoryImpl({
    required SettingsRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<UserSettings> getUserSettings(String userId) async {
    try {
      return await _remoteDataSource.getUserSettings(userId);
    } catch (e) {
      throw Exception('Failed to get user settings: $e');
    }
  }

  @override
  Future<void> updateUserSettings(UserSettings settings) async {
    try {
      final model = UserSettingsModel.fromEntity(settings);
      await _remoteDataSource.updateUserSettings(model);
    } catch (e) {
      throw Exception('Failed to update user settings: $e');
    }
  }

  @override
  Future<String> createCommunityTransferRequest(
      CommunityTransferRequest request) async {
    try {
      final model = CommunityTransferRequestModel.fromEntity(request);
      return await _remoteDataSource.createCommunityTransferRequest(model);
    } catch (e) {
      throw Exception('Failed to create transfer request: $e');
    }
  }

  @override
  Future<List<CommunityTransferRequest>> getCommunityTransferRequests(
      String communityId) async {
    try {
      final models =
          await _remoteDataSource.getCommunityTransferRequests(communityId);
      return models.cast<CommunityTransferRequest>();
    } catch (e) {
      throw Exception('Failed to get transfer requests: $e');
    }
  }

  @override
  Future<CommunityTransferRequest?> getUserTransferRequest(
      String userId) async {
    try {
      final model = await _remoteDataSource.getUserTransferRequest(userId);
      return model; // Model extends entity, so this is safe
    } catch (e) {
      throw Exception('Failed to get user transfer request: $e');
    }
  }

  @override
  Future<void> updateTransferRequestStatus(
    String requestId,
    CommunityTransferStatus status,
    String processedBy, {
    String? adminNotes,
    String? rejectionReason,
  }) async {
    try {
      await _remoteDataSource.updateTransferRequestStatus(
        requestId,
        status,
        processedBy,
        adminNotes: adminNotes,
        rejectionReason: rejectionReason,
      );
    } catch (e) {
      throw Exception('Failed to update transfer request status: $e');
    }
  }

  @override
  Future<void> cancelTransferRequest(String requestId) async {
    try {
      await _remoteDataSource.cancelTransferRequest(requestId);
    } catch (e) {
      throw Exception('Failed to cancel transfer request: $e');
    }
  }
}
