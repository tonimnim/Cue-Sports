# Unified Payment System

## Overview

The unified payment system consolidates all payment functionality across the app (registration, tournament entry, and merchandise purchases) into a single, reusable feature. It uses TinyPesa for M-Pesa integration and follows clean architecture principles with BLoC pattern for state management.

## Architecture

### Domain Layer
- **Payment Entity**: Core payment model with type, status, and metadata
- **PaymentType Enum**: `registration`, `tournament`, `merchandise`
- **PaymentStatus Enum**: `initial`, `pending`, `processing`, `success`, `failed`, `cancelled`, `timeout`

### Services Layer
- **TinyPesaService**: Wrapper for TinyPesa M-Pesa API integration
- **PaymentCallbackService**: Handles type-specific post-payment actions
- **PaymentMigrationHelper**: Utilities for migrating from old payment implementations

### Presentation Layer
- **PaymentBloc**: Manages payment state and business logic
- **UnifiedPaymentScreen**: Reusable payment UI
- **PaymentStatusIndicator**: Animated payment status widget

## Usage

### 1. Registration Payment
```dart
Navigator.of(context).pushNamed(
  '/unified-payment',
  arguments: {
    'paymentType': PaymentType.registration,
    'typeId': communityId,
    'userId': userId,
    'amount': 500.0,
    'prefillPhoneNumber': phoneNumber,
    'metadata': {
      'communityId': communityId,
      'userType': 'player',
    },
    'onSuccess': () {
      Navigator.pushNamedAndRemoveUntil('/home', (route) => false);
    },
  },
);
```

### 2. Tournament Entry Payment
```dart
Navigator.of(context).pushNamed(
  '/unified-payment',
  arguments: {
    'paymentType': PaymentType.tournament,
    'typeId': tournamentId,
    'userId': userId,
    'amount': entryFee,
    'metadata': {
      'tournamentName': name,
      'tournamentDate': date,
    },
    'onSuccess': () {
      // Refresh tournaments and show success
    },
  },
);
```

### 3. Shop Purchase Payment
```dart
Navigator.of(context).pushNamed(
  '/unified-payment',
  arguments: {
    'paymentType': PaymentType.merchandise,
    'typeId': orderId,
    'userId': userId,
    'amount': totalAmount,
    'metadata': {
      'cartItems': items,
      'itemCount': count,
    },
    'onSuccess': () {
      // Clear cart and navigate to orders
    },
  },
);
```

## Configuration

### TinyPesa Setup
1. Set environment variables:
   - `TINYPESA_API_KEY`: Your TinyPesa API key
   - `TINYPESA_ACCOUNT_NUMBER`: Your account number

2. Configure in `TinyPesaService`:
```dart
static const String _baseUrl = 'https://api.tinypesa.com';
static const String _apiKey = String.fromEnvironment('TINYPESA_API_KEY');
static const String _accountNumber = String.fromEnvironment('TINYPESA_ACCOUNT_NUMBER');
```

### Testing
Use `MockTinyPesaService` for testing:
```dart
// In injection_container.dart
sl.registerLazySingleton<TinyPesaService>(
  () => MockTinyPesaService(shouldSucceed: true),
);
```

## Security Considerations

1. **API Keys**: Never hardcode API keys. Use environment variables.
2. **Phone Number Validation**: Always validate phone numbers before initiating payment.
3. **Amount Validation**: Verify amounts server-side before processing.
4. **Transaction IDs**: Store and verify transaction IDs to prevent duplicate payments.
5. **SSL/TLS**: Ensure all API calls use HTTPS.

## Error Handling

The system handles various error scenarios:
- Network errors
- Invalid phone numbers
- Insufficient balance
- Payment timeouts
- User cancellation
- API errors

Each error is properly displayed to the user with appropriate retry options.

## State Management

Payment states are managed through `PaymentBloc`:
- **Initial**: Ready to accept payment details
- **Processing**: Payment initiated, waiting for user action
- **Success**: Payment completed successfully
- **Error**: Payment failed with error message

## Best Practices

1. **Always clean up resources**: Timers and subscriptions are properly disposed
2. **Prevent memory leaks**: Use `mounted` checks before setState
3. **Handle async operations**: Proper error handling for all async calls
4. **User feedback**: Clear loading states and error messages
5. **Idempotency**: Prevent duplicate payments with transaction tracking

## Migration from Old System

To migrate from old payment implementations:

1. Replace old payment navigation with unified payment
2. Use `PaymentMigrationHelper` for common tasks
3. Update payment type strings to `PaymentType` enum
4. Remove duplicate payment screens and logic

## Future Enhancements

1. Support for multiple payment methods (cards, bank transfer)
2. Payment history and receipts
3. Recurring payments for subscriptions
4. Payment analytics and reporting
5. Offline payment queue with sync 