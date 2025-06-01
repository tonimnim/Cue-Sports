import 'package:equatable/equatable.dart';

/// Types of community events
enum EventType {
  tournament,
  practice,
  meetup,
  workshop,
  competition,
  training,
  other
}

/// Status of community events
enum EventStatus {
  upcoming,
  ongoing,
  completed,
  cancelled,
  postponed,
}

/// Entity representing a community event
class CommunityEvent extends Equatable {
  final String id;
  final String communityId;
  final String title;
  final String description;
  final String organizerId;
  final String createdBy;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final EventType type;
  final EventType eventType;
  final EventStatus status;
  final String venue;
  final String venueAddress;
  final String location;
  final int maxParticipants;
  final List<String> participants;
  final List<String> registeredParticipants;
  final List<String> waitlist;
  final bool isPrivate;
  final bool requiresRegistration;
  final bool isActive;
  final double? entryFee;
  final double? prizePool;
  final Map<String, dynamic>? prizes;
  final String? coverImageUrl;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CommunityEvent({
    required this.id,
    required this.communityId,
    required this.title,
    required this.description,
    required this.organizerId,
    String? createdBy,
    required this.startTime,
    required this.endTime,
    DateTime? startDateTime,
    DateTime? endDateTime,
    required this.type,
    EventType? eventType,
    this.status = EventStatus.upcoming,
    required this.venue,
    required this.venueAddress,
    String? location,
    required this.maxParticipants,
    required this.participants,
    List<String>? registeredParticipants,
    required this.waitlist,
    required this.isPrivate,
    required this.requiresRegistration,
    this.isActive = true,
    this.entryFee,
    this.prizePool,
    this.prizes,
    this.coverImageUrl,
    this.imageUrl,
    required this.createdAt,
    this.updatedAt,
  }) : createdBy = createdBy ?? organizerId,
       startDateTime = startDateTime ?? startTime,
       endDateTime = endDateTime ?? endTime,
       eventType = eventType ?? type,
       location = location ?? venue,
       registeredParticipants = registeredParticipants ?? participants;

  /// Check if event is full
  bool get isFull => participants.length >= maxParticipants;

  /// Check if user is registered
  bool isUserRegistered(String userId) => participants.contains(userId);

  /// Check if user is on waitlist
  bool isUserOnWaitlist(String userId) => waitlist.contains(userId);

  /// Check if event has started
  bool get hasStarted => DateTime.now().isAfter(startTime);

  /// Check if event has ended
  bool get hasEnded => DateTime.now().isAfter(endTime);

  /// Check if event is ongoing
  bool get isOngoing => hasStarted && !hasEnded;

  /// Check if registration is open
  bool get isRegistrationOpen => !isFull && !hasStarted && requiresRegistration;

  /// Check if event is cancelled
  bool get isCancelled => status == EventStatus.cancelled;

  /// Check if event has a venue
  bool get hasVenue => venue.isNotEmpty && venueAddress.isNotEmpty;

  /// Get start date (for backward compatibility)
  DateTime get startDate => startDateTime;

  /// Create a copy of this event with some fields updated
  CommunityEvent copyWith({
    String? id,
    String? communityId,
    String? title,
    String? description,
    String? organizerId,
    String? createdBy,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? startDateTime,
    DateTime? endDateTime,
    EventType? type,
    EventType? eventType,
    EventStatus? status,
    String? venue,
    String? venueAddress,
    String? location,
    int? maxParticipants,
    List<String>? participants,
    List<String>? registeredParticipants,
    List<String>? waitlist,
    bool? isPrivate,
    bool? requiresRegistration,
    bool? isActive,
    double? entryFee,
    double? prizePool,
    Map<String, dynamic>? prizes,
    String? coverImageUrl,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommunityEvent(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      title: title ?? this.title,
      description: description ?? this.description,
      organizerId: organizerId ?? this.organizerId,
      createdBy: createdBy ?? this.createdBy,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      type: type ?? this.type,
      eventType: eventType ?? this.eventType,
      status: status ?? this.status,
      venue: venue ?? this.venue,
      venueAddress: venueAddress ?? this.venueAddress,
      location: location ?? this.location,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      participants: participants ?? this.participants,
      registeredParticipants: registeredParticipants ?? this.registeredParticipants,
      waitlist: waitlist ?? this.waitlist,
      isPrivate: isPrivate ?? this.isPrivate,
      requiresRegistration: requiresRegistration ?? this.requiresRegistration,
      isActive: isActive ?? this.isActive,
      entryFee: entryFee ?? this.entryFee,
      prizePool: prizePool ?? this.prizePool,
      prizes: prizes ?? this.prizes,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        communityId,
        title,
        description,
        organizerId,
        createdBy,
        startTime,
        endTime,
        startDateTime,
        endDateTime,
        type,
        eventType,
        status,
        venue,
        venueAddress,
        location,
        maxParticipants,
        participants,
        registeredParticipants,
        waitlist,
        isPrivate,
        requiresRegistration,
        isActive,
        entryFee,
        prizePool,
        prizes,
        coverImageUrl,
        imageUrl,
        createdAt,
        updatedAt,
      ];
} 