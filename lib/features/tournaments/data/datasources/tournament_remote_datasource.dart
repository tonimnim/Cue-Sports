import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../firebase/firebase_services.dart';
import '../../../../core/error/exceptions.dart';
import '../models/tournament_model.dart';
import '../../domain/entities/tournament.dart';

abstract class TournamentRemoteDataSource {
  Future<List<TournamentModel>> getTournaments();
  Future<List<TournamentModel>> getFeaturedTournaments();
  Future<List<TournamentModel>> getUpcomingTournaments();
  Future<List<TournamentModel>> getTournamentsByStatus(TournamentStatus status);
  Future<TournamentModel?> getTournamentById(String id);
  Future<String> createTournament(TournamentModel tournament);
  Future<void> updateTournament(TournamentModel tournament);
  Future<void> deleteTournament(String tournamentId);
}

class TournamentRemoteDataSourceImpl implements TournamentRemoteDataSource {
  final FirebaseServices _firebaseServices;

  TournamentRemoteDataSourceImpl(this._firebaseServices);

  @override
  Future<List<TournamentModel>> getTournaments() async {
    try {
      final snapshot = await _firebaseServices.tournamentsCollection.get();
      return snapshot.docs.map((doc) => TournamentModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw ServerException('Failed to get tournaments: $e');
    }
  }

  @override
  Future<List<TournamentModel>> getFeaturedTournaments() async {
    try {
      final snapshot = await _firebaseServices.tournamentsCollection
          .where('isFeatured', isEqualTo: true)
          .get();
      return snapshot.docs.map((doc) => TournamentModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw ServerException('Failed to get featured tournaments: $e');
    }
  }

  @override
  Future<List<TournamentModel>> getUpcomingTournaments() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firebaseServices.tournamentsCollection
          .where('startDate', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('startDate')
          .get();
      return snapshot.docs.map((doc) => TournamentModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw ServerException('Failed to get upcoming tournaments: $e');
    }
  }

  @override
  Future<List<TournamentModel>> getTournamentsByStatus(TournamentStatus status) async {
    try {
      final snapshot = await _firebaseServices.tournamentsCollection
          .where('status', isEqualTo: status.toString().split('.').last)
          .get();
      return snapshot.docs.map((doc) => TournamentModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw ServerException('Failed to get tournaments by status: $e');
    }
  }

  @override
  Future<TournamentModel?> getTournamentById(String id) async {
    try {
      final doc = await _firebaseServices.tournamentsCollection.doc(id).get();
      if (doc.exists) {
        return TournamentModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw ServerException('Failed to get tournament by id: $e');
    }
  }

  @override
  Future<String> createTournament(TournamentModel tournament) async {
    try {
      final docRef = await _firebaseServices.tournamentsCollection.add(tournament.toFirestore());
      return docRef.id;
    } catch (e) {
      throw ServerException('Failed to create tournament: $e');
    }
  }

  @override
  Future<void> updateTournament(TournamentModel tournament) async {
    try {
      await _firebaseServices.tournamentsCollection
          .doc(tournament.id)
          .update(tournament.toFirestore());
    } catch (e) {
      throw ServerException('Failed to update tournament: $e');
    }
  }

  @override
  Future<void> deleteTournament(String tournamentId) async {
    try {
      await _firebaseServices.tournamentsCollection.doc(tournamentId).delete();
    } catch (e) {
      throw ServerException('Failed to delete tournament: $e');
    }
  }
} 