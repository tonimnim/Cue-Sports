import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_settings_model.dart';
import '../models/community_transfer_request_model.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/entities/community_transfer_request.dart';

/// Remote data source for settings
abstract class SettingsRemoteDataSource {
  /// Get user settings
  Future<UserSettingsModel> getUserSettings(String userId);

  /// Update user settings
  Future<void> updateUserSettings(UserSettingsModel settings);

  /// Create community transfer request
  Future<String> createCommunityTransferRequest(
      CommunityTransferRequestModel request);

  /// Get community transfer requests for admin
  Future<List<CommunityTransferRequestModel>> getCommunityTransferRequests(
      String communityId);

  /// Get user's transfer request
  Future<CommunityTransferRequestModel?> getUserTransferRequest(String userId);

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

/// Firebase implementation of settings remote data source
class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  final FirebaseFirestore _firestore;

  SettingsRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<UserSettingsModel> getUserSettings(String userId) async {
    try {
      final doc =
          await _firestore.collection('user_settings').doc(userId).get();

      if (!doc.exists) {
        throw Exception('User settings not found');
      }

      return UserSettingsModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get user settings: $e');
    }
  }

  @override
  Future<void> updateUserSettings(UserSettingsModel settings) async {
    try {
      await _firestore.collection('user_settings').doc(settings.userId).set(
            settings.copyWith(updatedAt: DateTime.now()).toFirestore(),
            SetOptions(merge: true),
          );
    } catch (e) {
      throw Exception('Failed to update user settings: $e');
    }
  }

  @override
  Future<String> createCommunityTransferRequest(
      CommunityTransferRequestModel request) async {
    try {
      // Check if user already has a pending request
      final existingRequest = await getUserTransferRequest(request.playerId);
      if (existingRequest != null && existingRequest.isPending) {
        throw Exception('You already have a pending transfer request');
      }

      final docRef = await _firestore
          .collection('community_transfer_requests')
          .add(request.toFirestore());

      // Update user settings to reflect pending transfer
      await _firestore
          .collection('user_settings')
          .doc(request.playerId)
          .update({
        'transferStatus': CommunityTransferStatus.pending.name,
        'pendingCommunityId': request.toCommunityId,
        'pendingCommunityName': request.toCommunityName,
        'transferRequestDate': Timestamp.fromDate(request.requestDate),
        'transferReason': request.reason,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create transfer request: $e');
    }
  }

  @override
  Future<List<CommunityTransferRequestModel>> getCommunityTransferRequests(
      String communityId) async {
    try {
      final querySnapshot = await _firestore
          .collection('community_transfer_requests')
          .where('toCommunityId', isEqualTo: communityId)
          .where('status', isEqualTo: CommunityTransferStatus.pending.name)
          .orderBy('requestDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => CommunityTransferRequestModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get transfer requests: $e');
    }
  }

  @override
  Future<CommunityTransferRequestModel?> getUserTransferRequest(
      String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('community_transfer_requests')
          .where('playerId', isEqualTo: userId)
          .where('status', isEqualTo: CommunityTransferStatus.pending.name)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return CommunityTransferRequestModel.fromFirestore(
          querySnapshot.docs.first);
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
      // Get the transfer request first
      final requestDoc = await _firestore
          .collection('community_transfer_requests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        throw Exception('Transfer request not found');
      }

      final request = CommunityTransferRequestModel.fromFirestore(requestDoc);

      // Update the transfer request
      await _firestore
          .collection('community_transfer_requests')
          .doc(requestId)
          .update({
        'status': status.name,
        'processedDate': Timestamp.fromDate(DateTime.now()),
        'processedBy': processedBy,
        'adminNotes': adminNotes,
        'rejectionReason': rejectionReason,
      });

      // Update user settings based on status
      final userSettingsUpdate = <String, dynamic>{
        'transferStatus': status.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (status == CommunityTransferStatus.approved) {
        // Move user to new community
        userSettingsUpdate.addAll({
          'currentCommunityId': request.toCommunityId,
          'currentCommunityName': request.toCommunityName,
          'pendingCommunityId': null,
          'pendingCommunityName': null,
          'transferRequestDate': null,
          'transferReason': null,
        });
      } else if (status == CommunityTransferStatus.rejected) {
        // Clear pending transfer data
        userSettingsUpdate.addAll({
          'pendingCommunityId': null,
          'pendingCommunityName': null,
          'transferRequestDate': null,
          'transferReason': null,
        });
      }

      await _firestore
          .collection('user_settings')
          .doc(request.playerId)
          .update(userSettingsUpdate);
    } catch (e) {
      throw Exception('Failed to update transfer request status: $e');
    }
  }

  @override
  Future<void> cancelTransferRequest(String requestId) async {
    try {
      // Get the transfer request first
      final requestDoc = await _firestore
          .collection('community_transfer_requests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        throw Exception('Transfer request not found');
      }

      final request = CommunityTransferRequestModel.fromFirestore(requestDoc);

      // Delete the transfer request
      await _firestore
          .collection('community_transfer_requests')
          .doc(requestId)
          .delete();

      // Clear user settings transfer data
      await _firestore
          .collection('user_settings')
          .doc(request.playerId)
          .update({
        'transferStatus': CommunityTransferStatus.none.name,
        'pendingCommunityId': null,
        'pendingCommunityName': null,
        'transferRequestDate': null,
        'transferReason': null,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to cancel transfer request: $e');
    }
  }
}
