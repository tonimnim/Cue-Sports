import 'package:equatable/equatable.dart';
import '../../domain/entities/user_settings.dart';
import '../../domain/entities/community_transfer_request.dart';

/// Base class for settings states
abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

/// Loading state
class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

/// Settings loaded successfully
class SettingsLoaded extends SettingsState {
  final UserSettings settings;
  final CommunityTransferRequest? transferRequest;

  const SettingsLoaded({
    required this.settings,
    this.transferRequest,
  });

  @override
  List<Object?> get props => [settings, transferRequest];

  /// Copy with updated fields
  SettingsLoaded copyWith({
    UserSettings? settings,
    CommunityTransferRequest? transferRequest,
    bool clearTransferRequest = false,
  }) {
    return SettingsLoaded(
      settings: settings ?? this.settings,
      transferRequest: clearTransferRequest
          ? null
          : (transferRequest ?? this.transferRequest),
    );
  }
}

/// Settings update in progress
class SettingsUpdating extends SettingsState {
  final UserSettings currentSettings;
  final String updateType;

  const SettingsUpdating({
    required this.currentSettings,
    required this.updateType,
  });

  @override
  List<Object?> get props => [currentSettings, updateType];
}

/// Settings updated successfully
class SettingsUpdated extends SettingsState {
  final UserSettings settings;
  final String message;

  const SettingsUpdated({
    required this.settings,
    required this.message,
  });

  @override
  List<Object?> get props => [settings, message];
}

/// Community transfer request in progress
class CommunityTransferRequesting extends SettingsState {
  final UserSettings currentSettings;

  const CommunityTransferRequesting({required this.currentSettings});

  @override
  List<Object?> get props => [currentSettings];
}

/// Community transfer request created successfully
class CommunityTransferRequestCreated extends SettingsState {
  final UserSettings settings;
  final String requestId;
  final String message;

  const CommunityTransferRequestCreated({
    required this.settings,
    required this.requestId,
    required this.message,
  });

  @override
  List<Object?> get props => [settings, requestId, message];
}

/// Community transfer request cancelled
class CommunityTransferRequestCancelled extends SettingsState {
  final UserSettings settings;
  final String message;

  const CommunityTransferRequestCancelled({
    required this.settings,
    required this.message,
  });

  @override
  List<Object?> get props => [settings, message];
}

/// Password change in progress
class PasswordChanging extends SettingsState {
  const PasswordChanging();
}

/// Password changed successfully
class PasswordChanged extends SettingsState {
  final String message;

  const PasswordChanged({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Account deletion in progress
class AccountDeleting extends SettingsState {
  const AccountDeleting();
}

/// Account deleted successfully
class AccountDeleted extends SettingsState {
  final String message;

  const AccountDeleted({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Settings reset to default
class SettingsResetToDefault extends SettingsState {
  final UserSettings settings;
  final String message;

  const SettingsResetToDefault({
    required this.settings,
    required this.message,
  });

  @override
  List<Object?> get props => [settings, message];
}

/// Error state
class SettingsError extends SettingsState {
  final String message;
  final UserSettings? currentSettings;

  const SettingsError({
    required this.message,
    this.currentSettings,
  });

  @override
  List<Object?> get props => [message, currentSettings];
}

/// Validation error state
class SettingsValidationError extends SettingsState {
  final String message;
  final Map<String, String> fieldErrors;
  final UserSettings currentSettings;

  const SettingsValidationError({
    required this.message,
    required this.fieldErrors,
    required this.currentSettings,
  });

  @override
  List<Object?> get props => [message, fieldErrors, currentSettings];
}
