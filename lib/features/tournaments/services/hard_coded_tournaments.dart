import '../domain/entities/tournament.dart';

class HardCodedTournaments {
  static List<Tournament> getSampleTournaments() {
    final now = DateTime.now();
    return [
      Tournament(
        id: '1',
        name: 'Nairobi Open Championship',
        type: '8-Ball Pool',
        location: 'Nairobi Sports Club',
        startDate: now.add(Duration(days: 30)),
        endDate: now.add(Duration(days: 30)),
        maxPlayers: 32,
        entryFee: 500.0,
        isFeatured: true,
        registeredUserIds: [],
        status: TournamentStatus.registration_open,
        createdAt: now,
        updatedAt: now,
        createdBy: 'admin',
      ),
      Tournament(
        id: '2',
        name: 'Kenya National Tournament',
        type: '9-Ball Pool',
        location: 'Mombasa Convention Centre',
        startDate: now.add(Duration(days: 60)),
        endDate: now.add(Duration(days: 62)),
        maxPlayers: 64,
        entryFee: 1000.0,
        isFeatured: false,
        registeredUserIds: [],
        status: TournamentStatus.upcoming,
        createdAt: now,
        updatedAt: now,
        createdBy: 'admin',
      ),
    ];
  }
} 