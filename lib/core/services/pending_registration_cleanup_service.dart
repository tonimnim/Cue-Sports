import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'logger_service.dart';

/// Service to clean up expired pending registrations
class PendingRegistrationCleanupService {
  final FirebaseFirestore _firestore;
  final LoggerService _logger;
  Timer? _cleanupTimer;
  
  PendingRegistrationCleanupService({
    required FirebaseFirestore firestore,
    required LoggerService logger,
  }) : _firestore = firestore, _logger = logger;

  /// Start the automatic cleanup process
  void startCleanup() {
    _logger.i('🧹 Starting pending registration cleanup service');
    
    // Run cleanup every hour
    _cleanupTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _cleanupExpiredRegistrations();
    });
    
    // Run cleanup immediately on start
    _cleanupExpiredRegistrations();
  }

  /// Stop the cleanup service
  void stopCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _logger.i('🛑 Stopped pending registration cleanup service');
  }

  /// Clean up expired pending registrations
  Future<void> _cleanupExpiredRegistrations() async {
    try {
      _logger.i('🧹 Running cleanup for expired pending registrations');
      
      final now = DateTime.now();
      final cutoffTime = now.subtract(const Duration(hours: 24));
      
      // Query for expired registrations
      final expiredRegistrations = await _firestore
          .collection('pendingRegistrations')
          .where('expiresAt', isLessThan: cutoffTime.toIso8601String())
          .get();
      
      if (expiredRegistrations.docs.isEmpty) {
        _logger.i('✅ No expired pending registrations found');
        return;
      }
      
      _logger.i('🗑️ Found ${expiredRegistrations.docs.length} expired pending registrations');
      
      // Delete expired registrations in batch
      final batch = _firestore.batch();
      
      for (final doc in expiredRegistrations.docs) {
        final data = doc.data();
        final email = data['email'] as String? ?? 'unknown';
        final paymentStatus = data['paymentStatus'] as bool? ?? false;
        
        if (!paymentStatus) {
          // Only delete if payment not completed
          batch.delete(doc.reference);
          _logger.i('🗑️ Marking for deletion: $email (payment not completed)');
        } else {
          _logger.w('⚠️ Skipping deletion of $email (payment completed but not cleaned up properly)');
        }
      }
      
      // Execute batch delete
      await batch.commit();
      _logger.i('✅ Cleanup completed - deleted expired pending registrations');
      
    } catch (e) {
      _logger.e('🔥 Error during pending registration cleanup: $e');
    }
  }

  /// Force cleanup now (for testing or manual cleanup)
  Future<void> forceCleanup() async {
    await _cleanupExpiredRegistrations();
  }
} 