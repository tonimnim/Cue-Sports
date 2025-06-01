import 'package:equatable/equatable.dart';

/// Trophy types that can be won
enum TrophyType {
  regional,
  national
}

/// Trophy entity representing a trophy won by a player
class Trophy extends Equatable {
  final String id;
  final String name;
  final TrophyType type;
  final String playerId;
  final DateTime wonAt;

  const Trophy({
    required this.id,
    required this.name,
    required this.type,
    required this.playerId,
    required this.wonAt,
  });

  @override
  List<Object> get props => [id, name, type, playerId, wonAt];
} 