import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/community_transfer_request.dart';
import '../../domain/entities/user_settings.dart';

/// Firebase model for community transfer request
class CommunityTransferRequestModel extends CommunityTransferRequest {
  const CommunityTransferRequestModel({
    required super.id,
    required super.playerId,
    required super.playerName,
    required super.playerEmail,
    required super.fromCommunityId,
    required super.fromCommunityName,
    required super.toCommunityId,
    required super.toCommunityName,
    required super.reason,
    required super.status,
    required super.requestDate,
    super.processedDate,
    super.processedBy,
    super.adminNotes,
    super.rejectionReason,
  });

  /// Create from Firebase document
  factory CommunityTransferRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CommunityTransferRequestModel(
      id: doc.id,
      playerId: data['playerId'] ?? '',
      playerName: data['playerName'] ?? '',
      playerEmail: data['playerEmail'] ?? '',
      fromCommunityId: data['fromCommunityId'] ?? '',
      fromCommunityName: data['fromCommunityName'] ?? '',
      toCommunityId: data['toCommunityId'] ?? '',
      toCommunityName: data['toCommunityName'] ?? '',
      reason: data['reason'] ?? '',
      status: CommunityTransferStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => CommunityTransferStatus.pending,
      ),
      requestDate: (data['requestDate'] as Timestamp).toDate(),
      processedDate: data['processedDate'] != null
          ? (data['processedDate'] as Timestamp).toDate()
          : null,
      processedBy: data['processedBy'],
      adminNotes: data['adminNotes'],
      rejectionReason: data['rejectionReason'],
    );
  }

  /// Convert to Firebase document
  Map<String, dynamic> toFirestore() {
    return {
      'playerId': playerId,
      'playerName': playerName,
      'playerEmail': playerEmail,
      'fromCommunityId': fromCommunityId,
      'fromCommunityName': fromCommunityName,
      'toCommunityId': toCommunityId,
      'toCommunityName': toCommunityName,
      'reason': reason,
      'status': status.name,
      'requestDate': Timestamp.fromDate(requestDate),
      'processedDate':
          processedDate != null ? Timestamp.fromDate(processedDate!) : null,
      'processedBy': processedBy,
      'adminNotes': adminNotes,
      'rejectionReason': rejectionReason,
    };
  }

  /// Create from CommunityTransferRequest entity
  factory CommunityTransferRequestModel.fromEntity(
      CommunityTransferRequest request) {
    return CommunityTransferRequestModel(
      id: request.id,
      playerId: request.playerId,
      playerName: request.playerName,
      playerEmail: request.playerEmail,
      fromCommunityId: request.fromCommunityId,
      fromCommunityName: request.fromCommunityName,
      toCommunityId: request.toCommunityId,
      toCommunityName: request.toCommunityName,
      reason: request.reason,
      status: request.status,
      requestDate: request.requestDate,
      processedDate: request.processedDate,
      processedBy: request.processedBy,
      adminNotes: request.adminNotes,
      rejectionReason: request.rejectionReason,
    );
  }
}
