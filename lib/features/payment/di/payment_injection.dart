import 'package:get_it/get_it.dart';
import '../data/repositories/mock_payment_repository.dart';
import '../domain/repositories/payment_repository.dart';
import '../domain/usecases/check_payment_status.dart';
import '../domain/usecases/initiate_payment.dart';
import '../presentation/bloc/payment_bloc.dart';

/// Register payment dependencies
void injectPaymentDependencies(GetIt sl) {
  // BLoC
  sl.registerFactory(
    () => PaymentBloc(
      initiatePayment: sl(),
      checkPaymentStatus: sl(),
      logger: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => InitiatePayment(sl()));
  sl.registerLazySingleton(() => CheckPaymentStatus(sl()));

  // Repository
  // TODO: Replace with real repository when ready
  sl.registerLazySingleton<PaymentRepository>(() => MockPaymentRepository());
} 