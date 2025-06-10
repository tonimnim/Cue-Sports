import 'package:get_it/get_it.dart';
import '../presentation/bloc/payment_bloc.dart';
import '../services/tinypesa_service.dart';

/// Register payment dependencies
void injectPaymentDependencies(GetIt sl) {
  // Services
  sl.registerLazySingleton<TinyPesaService>(
    () => TinyPesaService(),
  );

  // For testing, you can use MockTinyPesaService instead:
  // sl.registerLazySingleton<TinyPesaService>(
  //   () => MockTinyPesaService(shouldSucceed: true),
  // );

  // BLoC
  sl.registerFactory(
    () => PaymentBloc(
      tinyPesaService: sl<TinyPesaService>(),
    ),
  );
}
