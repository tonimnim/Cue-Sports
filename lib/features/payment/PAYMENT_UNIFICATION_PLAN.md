# Payment Feature Unification Plan

## Overview
Consolidate all payment functionality (registration, tournament, merchandise) into a single, well-structured payment feature module.

## Current State Analysis

### Existing Payment Implementations:
1. **Auth Payment** (`lib/features/auth/presentation/payment_page.dart`)
   - Handles player registration payments
   - Updates user `isPaid` status in Firestore
   - Amount: Registration fee

2. **Shop Payment** (`lib/features/shop/payment/payment_page.dart`)
   - Handles merchandise purchases
   - Creates orders after successful payment
   - Amount: Cart total

3. **Tournament Payment** (`lib/features/tournaments/payment/payment_page.dart`)
   - Handles tournament registration fees
   - Registers user for tournament after payment
   - Amount: Tournament entry fee

### Common Elements:
- TinyPesa API integration for M-Pesa STK Push
- Transaction status polling
- Receipt number tracking
- Similar UI/UX flow

## Proposed Unified Structure

```
lib/features/payment/
├── domain/
│   ├── entities/
│   │   ├── payment.dart
│   │   └── payment_result.dart
│   ├── repositories/
│   │   └── payment_repository.dart
│   └── usecases/
│       ├── process_payment_usecase.dart
│       ├── check_payment_status_usecase.dart
│       └── get_payment_history_usecase.dart
├── data/
│   ├── models/
│   │   ├── payment_model.dart
│   │   └── payment_result_model.dart
│   ├── datasources/
│   │   ├── payment_remote_datasource.dart
│   │   └── payment_local_datasource.dart
│   └── repositories/
│       └── payment_repository_impl.dart
├── presentation/
│   ├── bloc/
│   │   ├── payment_bloc.dart
│   │   ├── payment_event.dart
│   │   └── payment_state.dart
│   ├── screens/
│   │   └── unified_payment_screen.dart
│   └── widgets/
│       ├── payment_form.dart
│       ├── payment_status_indicator.dart
│       └── payment_success_dialog.dart
└── services/
    ├── payment_callback_service.dart
    └── tinypesa_service.dart
```

## Key Components

### 1. Payment Entity
```dart
enum PaymentType {
  registration,  // Player registration
  tournament,    // Tournament entry
  merchandise    // Shop purchase
}

class Payment {
  final String id;
  final String userId;
  final PaymentType type;
  final String typeId; // communityId, tournamentId, or orderId
  final double amount;
  final String phoneNumber;
  final PaymentStatus status;
  final String? mpesaReceiptNumber;
  final String? checkoutRequestId;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata; // Additional type-specific data
}
```

### 2. Payment Callback Service
```dart
abstract class PaymentCallbackService {
  Future<void> onPaymentSuccess(Payment payment);
  Future<void> onPaymentFailed(Payment payment);
}

class RegistrationPaymentCallback implements PaymentCallbackService {
  // Update user isPaid status
}

class TournamentPaymentCallback implements PaymentCallbackService {
  // Register user for tournament
}

class MerchandisePaymentCallback implements PaymentCallbackService {
  // Create order and clear cart
}
```

### 3. Unified Payment Screen
```dart
class UnifiedPaymentScreen extends StatefulWidget {
  final PaymentType paymentType;
  final String typeId;
  final String userId;
  final double amount;
  final PaymentCallbackService callbackService;
  final Map<String, dynamic>? metadata;
}
```

## Migration Steps

### Phase 1: Create Core Structure
1. Create domain entities and repositories
2. Implement TinyPesa service wrapper
3. Create payment BLoC with proper state management
4. Build unified payment screen UI

### Phase 2: Implement Callbacks
1. Create callback service interface
2. Implement registration payment callback
3. Implement tournament payment callback
4. Implement merchandise payment callback

### Phase 3: Migrate Existing Code
1. Update auth feature to use unified payment
2. Update shop feature to use unified payment
3. Update tournament feature to use unified payment
4. Remove duplicate payment implementations

### Phase 4: Testing & Refinement
1. Add comprehensive unit tests
2. Test all payment flows
3. Add proper error handling
4. Implement retry logic

## Benefits

1. **Single Source of Truth**: One payment implementation to maintain
2. **Consistent UX**: Same payment flow across all features
3. **Better Error Handling**: Centralized error management
4. **Easier Testing**: Mock payment service once
5. **Scalability**: Easy to add new payment types
6. **Security**: Centralized security measures

## Security Considerations

1. **Server-side Validation**: All amounts should be validated server-side
2. **Idempotency**: Prevent duplicate payments with transaction IDs
3. **Audit Trail**: Log all payment attempts and results
4. **Receipt Verification**: Verify M-Pesa receipts with Safaricom
5. **User Authentication**: Ensure proper user context

## Mock Payment for Testing

```dart
class MockPaymentService implements PaymentService {
  // Returns success after 3 seconds
  // Receipt: "MOCK_RECEIPT_123"
  // For testing without real M-Pesa
}
```

## Next Steps

1. Create the payment feature structure
2. Move common code to shared services
3. Implement payment callbacks
4. Update existing features to use unified payment
5. Remove old payment implementations 