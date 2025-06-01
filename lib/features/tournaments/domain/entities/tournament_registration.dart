import 'package:equatable/equatable.dart';

enum RegistrationStatus {
  pending,
  confirmed,
  cancelled,
  waitlisted,
}

class TournamentRegistration extends Equatable {
  final String id;
  final String tournamentId;
  final String userId;
  final RegistrationStatus status;
  final String? paymentId;
  final DateTime registeredAt;
  final DateTime updatedAt;
  final String? notes;

  const TournamentRegistration({
    required this.id,
    required this.tournamentId,
    required this.userId,
    required this.status,
    this.paymentId,
    required this.registeredAt,
    required this.updatedAt,
    this.notes,
  });

  TournamentRegistration copyWith({
    String? id,
    String? tournamentId,
    String? userId,
    RegistrationStatus? status,
    String? paymentId,
    DateTime? registeredAt,
    DateTime? updatedAt,
    String? notes,
  }) {
    return TournamentRegistration(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      paymentId: paymentId ?? this.paymentId,
      registeredAt: registeredAt ?? this.registeredAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tournamentId,
        userId,
        status,
        paymentId,
        registeredAt,
        updatedAt,
        notes,
      ];
} 