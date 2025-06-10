import 'package:equatable/equatable.dart';
import 'user_settings.dart';

/// Community transfer request entity
class CommunityTransferRequest extends Equatable {
  final String id;
  final String playerId;
  final String playerName;
  final String playerEmail;
  final String fromCommunityId;
  final String fromCommunityName;
  final String toCommunityId;
  final String toCommunityName;
  final String reason;
  final CommunityTransferStatus status;
  final DateTime requestDate;
  final DateTime? processedDate;
  final String? processedBy; // Admin ID who processed the request
  final String? adminNotes;
  final String? rejectionReason;

  const CommunityTransferRequest({
    required this.id,
    required this.playerId,
    required this.playerName,
    required this.playerEmail,
    required this.fromCommunityId,
    required this.fromCommunityName,
    required this.toCommunityId,
    required this.toCommunityName,
    required this.reason,
    required this.status,
    required this.requestDate,
    this.processedDate,
    this.processedBy,
    this.adminNotes,
    this.rejectionReason,
  });

  /// Check if request is pending
  bool get isPending => status == CommunityTransferStatus.pending;

  /// Check if request is approved
  bool get isApproved => status == CommunityTransferStatus.approved;

  /// Check if request is rejected
  bool get isRejected => status == CommunityTransferStatus.rejected;

  /// Get status display name
  String get statusDisplayName {
    switch (status) {
      case CommunityTransferStatus.none:
        return 'None';
      case CommunityTransferStatus.pending:
        return 'Pending Review';
      case CommunityTransferStatus.approved:
        return 'Approved';
      case CommunityTransferStatus.rejected:
        return 'Rejected';
    }
  }

  /// Get formatted request date
  String get formattedRequestDate {
    return '${requestDate.day}/${requestDate.month}/${requestDate.year}';
  }

  /// Get formatted processed date
  String? get formattedProcessedDate {
    if (processedDate == null) return null;
    return '${processedDate!.day}/${processedDate!.month}/${processedDate!.year}';
  }

  /// Copy with updated fields
  CommunityTransferRequest copyWith({
    String? id,
    String? playerId,
    String? playerName,
    String? playerEmail,
    String? fromCommunityId,
    String? fromCommunityName,
    String? toCommunityId,
    String? toCommunityName,
    String? reason,
    CommunityTransferStatus? status,
    DateTime? requestDate,
    DateTime? processedDate,
    String? processedBy,
    String? adminNotes,
    String? rejectionReason,
  }) {
    return CommunityTransferRequest(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      playerEmail: playerEmail ?? this.playerEmail,
      fromCommunityId: fromCommunityId ?? this.fromCommunityId,
      fromCommunityName: fromCommunityName ?? this.fromCommunityName,
      toCommunityId: toCommunityId ?? this.toCommunityId,
      toCommunityName: toCommunityName ?? this.toCommunityName,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      requestDate: requestDate ?? this.requestDate,
      processedDate: processedDate ?? this.processedDate,
      processedBy: processedBy ?? this.processedBy,
      adminNotes: adminNotes ?? this.adminNotes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  @override
  List<Object?> get props => [
        id,
        playerId,
        playerName,
        playerEmail,
        fromCommunityId,
        fromCommunityName,
        toCommunityId,
        toCommunityName,
        reason,
        status,
        requestDate,
        processedDate,
        processedBy,
        adminNotes,
        rejectionReason,
      ];
}

/// Import the enum from user_settings.dart
enum CommunityTransferStatus { none, pending, approved, rejected }
