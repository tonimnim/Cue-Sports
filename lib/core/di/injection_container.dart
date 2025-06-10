import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Core imports
import '../../core/network/network_info.dart';
import '../../core/services/logger_service.dart';
import '../../core/services/secure_storage_service.dart';
import '../../core/services/token_service.dart';
import '../../core/services/email_service.dart';
import '../../core/services/ranking_service.dart';
import '../../core/services/local_storage_service.dart';
import '../../firebase/firebase_services.dart';

// Auth feature imports - using the repository that implementation actually implements
import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/data/auth_repository_impl.dart';
import '../../features/auth/data/auth_remote_data_source.dart';
import '../../features/auth/data/auth_local_data_source.dart';
import '../../features/auth/domain/auth_service.dart';

// Auth use cases - using correct class names
import '../../features/auth/domain/register_use_case.dart';
import '../../features/auth/domain/login_use_case.dart';
import '../../features/auth/domain/logout_use_case.dart';
import '../../features/auth/domain/get_current_user_use_case.dart';
import '../../features/auth/domain/password_reset_use_case.dart';
import '../../features/auth/domain/email_verification_use_case.dart';
import '../../features/auth/domain/update_profile_use_case.dart';
import '../../features/auth/domain/upgrade_to_player_use_case.dart';

// Community feature imports - using the repository that implementation actually implements
import '../../features/community/domain/community_repository.dart';
import '../../features/community/data/repositories/community_repository_impl.dart';
import '../../features/community/data/datasources/community_remote_data_source.dart';
import '../../features/community/data/datasources/firebase_community_remote_data_source.dart';
import '../../features/community/data/datasources/community_local_data_source.dart';

// Community use cases
import '../../features/community/domain/use_cases/get_communities_use_case.dart';
import '../../features/community/domain/use_cases/get_community_details_use_case.dart';
import '../../features/community/domain/use_cases/get_user_community_use_case.dart';
import '../../features/community/domain/use_cases/join_community_use_case.dart';
import '../../features/community/domain/use_cases/check_community_membership_use_case.dart';
import '../../features/community/domain/use_cases/get_communities_by_location_use_case.dart';
import '../../features/community/domain/use_cases/get_top_ranked_communities_use_case.dart';
import '../../features/community/domain/use_cases/search_communities_use_case.dart';
import '../../features/community/domain/use_cases/leave_community_use_case.dart';

// Shop feature imports
import '../../features/shop/domain/repositories/shop_repository.dart';
import '../../features/shop/data/repositories/shop_repository_impl.dart';
import '../../features/shop/data/datasources/shop_remote_datasource.dart';
import '../../features/shop/domain/usecases/get_products_usecase.dart';
import '../../features/shop/domain/usecases/cart_usecases.dart';
import '../../features/shop/domain/usecases/order_usecases.dart';
import '../../features/shop/presentation/bloc/shop_bloc.dart';

// Shop feature entities
import '../../features/shop/domain/entities/cart_item.dart';
import '../../features/shop/domain/entities/shop_order.dart';

// Tournament feature imports
import '../../features/tournaments/domain/repositories/tournament_repository.dart';
import '../../features/tournaments/data/repositories/tournament_repository_impl.dart';
import '../../features/tournaments/data/datasources/tournament_remote_datasource.dart';
import '../../features/tournaments/presentation/bloc/tournament_bloc.dart';

// Community bloc
import '../../features/community/presentation/bloc/community_bloc.dart';

// Auth bloc
import '../../features/auth/presentation/bloc/auth_bloc.dart';

// Payment feature
import '../../features/payment/di/payment_injection.dart';

// SMS Service
import '../../core/services/sms_service.dart';

// Service locator
final sl = GetIt.instance;

/// Initialize the dependency injection container
Future<void> init() async {
  // ======== EXTERNAL DEPENDENCIES ========

  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);
  sl.registerLazySingleton(() => InternetConnectionChecker());

  // Register secure storage for tokens
  const secureStorage = FlutterSecureStorage();
  sl.registerLazySingleton(() => secureStorage);

  // Register FirebaseServices as a singleton (uses factory pattern)
  sl.registerLazySingleton(() => FirebaseServices());

  // ======== CORE SERVICES ========

  // Network Info
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(connectionChecker: sl<InternetConnectionChecker>()),
  );

  // Local storage
  sl.registerLazySingleton<LocalStorageService>(
    () => LocalStorageServiceImpl(sl<SharedPreferences>()),
  );

  // Logger
  sl.registerLazySingleton<LoggerService>(() => LoggerService());

  // Secure Storage Service for registration drafts, tokens, and user data
  sl.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(logger: sl<LoggerService>()),
  );

  // Token Service
  sl.registerLazySingleton<TokenService>(
    () => TokenService(
      storage: sl<FlutterSecureStorage>(),
      logger: sl<LoggerService>(),
    ),
  );

  // Email Service
  sl.registerLazySingleton<EmailService>(
    () => EmailService(
      logger: sl<LoggerService>(),
      emailUsername: const String.fromEnvironment('EMAIL_USERNAME',
          defaultValue: 'kenyapoolbilliardsclub@gmail.com'),
      emailPassword:
          const String.fromEnvironment('EMAIL_PASSWORD', defaultValue: ''),
    ),
  );

  // SMS Service
  sl.registerLazySingleton<SmsService>(
    () => SmsService(), // SMS service for verification codes
  );

  // Ranking Service
  sl.registerLazySingleton<RankingService>(
    () => RankingService(logger: sl<LoggerService>()),
  );

  // ======== AUTH FEATURE ========

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      auth: sl<FirebaseAuth>(),
      firestore: sl<FirebaseFirestore>(),
      logger: sl<LoggerService>(),
      tokenService: sl<TokenService>(),
    ),
  );

  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(
      sharedPreferences: sl<SharedPreferences>(),
      logger: sl<LoggerService>(),
    ),
  );

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl<AuthRemoteDataSource>(),
      localDataSource: sl<AuthLocalDataSource>(),
      networkInfo: sl<NetworkInfo>(),
      logger: sl<LoggerService>(),
      firebaseServices: sl<FirebaseServices>(),
      tokenService: sl<TokenService>(),
      emailService: sl<EmailService>(),
      smsService: sl<SmsService>(),
    ),
  );

  // Use cases - using correct class names
  sl.registerLazySingleton(() => RegisterFanUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => RegisterPlayerUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => LogoutUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(
      () => SendPasswordResetUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(
      () => VerifyPasswordResetUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(
      () => SendEmailVerificationUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => VerifyEmailUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => UpgradeToPlayerUseCase(sl<AuthRepository>()));

  // AuthService - Direct Firebase Authentication service
  sl.registerLazySingleton<AuthService>(
    () => AuthService(
      auth: sl<FirebaseAuth>(),
      firestore: sl<FirebaseFirestore>(),
    ),
  );

  // BLoCs - Auth with new Firebase email verification dependencies
  sl.registerFactory(() => AuthBloc(
        logger: sl<LoggerService>(),
        authRepository: sl<AuthRepository>(),
        secureStorage: sl<SecureStorageService>(),
        firebaseAuth: sl<FirebaseAuth>(),
      ));

  // ======== COMMUNITY FEATURE ========

  // Data sources
  sl.registerLazySingleton<CommunityRemoteDataSource>(
    () => FirebaseCommunityRemoteDataSource(
      firestore: sl<FirebaseFirestore>(),
      auth: sl<FirebaseAuth>(),
    ),
  );

  sl.registerLazySingleton<CommunityLocalDataSource>(
    () => CommunityLocalDataSourceImpl(
      sharedPreferences: sl<SharedPreferences>(),
    ),
  );

  // Repository
  sl.registerLazySingleton<CommunityRepository>(
    () => CommunityRepositoryImpl(
      remoteDataSource: sl<CommunityRemoteDataSource>(),
      localDataSource: sl<CommunityLocalDataSource>(),
      networkInfo: sl<NetworkInfo>(),
      logger: sl<LoggerService>(),
    ),
  );

  // Use cases - only keeping the ones that might be used elsewhere
  sl.registerLazySingleton(
      () => GetCommunitiesUseCase(sl<CommunityRepository>()));
  sl.registerLazySingleton(
      () => GetCommunityDetailsUseCase(sl<CommunityRepository>()));
  sl.registerLazySingleton(
      () => GetUserCommunityUseCase(sl<CommunityRepository>()));
  sl.registerLazySingleton(
      () => JoinCommunityUseCase(sl<CommunityRepository>()));
  sl.registerLazySingleton(
      () => CheckCommunityMembershipUseCase(sl<CommunityRepository>()));
  sl.registerLazySingleton(
      () => SearchCommunitiesUseCase(sl<CommunityRepository>()));

  // BLoCs - Community
  sl.registerFactory(
    () => CommunityBloc(
      repository: sl<CommunityRepository>(),
    ),
  );

  // ======== SHOP FEATURE ========

  // Data sources
  sl.registerLazySingleton<ShopRemoteDataSource>(
    () => ShopRemoteDataSourceImpl(sl<FirebaseServices>()),
  );

  // Repository
  sl.registerLazySingleton<ShopRepository>(
    () => ShopRepositoryImpl(remoteDataSource: sl<ShopRemoteDataSource>()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetProductsUseCase(sl<ShopRepository>()));
  sl.registerLazySingleton(
      () => GetProductsByCategoryUseCase(sl<ShopRepository>()));
  sl.registerLazySingleton(
      () => GetFeaturedProductsUseCase(sl<ShopRepository>()));
  sl.registerLazySingleton(
      () => GetPopularProductsUseCase(sl<ShopRepository>()));
  sl.registerLazySingleton(() => GetNewArrivalsUseCase(sl<ShopRepository>()));
  sl.registerLazySingleton(() => GetProductByIdUseCase(sl<ShopRepository>()));

  sl.registerLazySingleton(() => GetCartItemsUseCase(sl<ShopRepository>()));
  sl.registerLazySingleton(() => AddToCartUseCase(sl<ShopRepository>()));
  sl.registerLazySingleton(() => UpdateCartItemUseCase(sl<ShopRepository>()));
  sl.registerLazySingleton(() => RemoveFromCartUseCase(sl<ShopRepository>()));
  sl.registerLazySingleton(() => ClearCartUseCase(sl<ShopRepository>()));

  sl.registerLazySingleton(() => GetUserOrdersUseCase(sl<ShopRepository>()));
  sl.registerLazySingleton(() => CreateOrderUseCase(sl<ShopRepository>()));
  sl.registerLazySingleton(() => UpdateOrderUseCase(sl<ShopRepository>()));

  // BLoCs - Shop
  sl.registerFactory(() => ShopBloc(
        getProductsUseCase: sl<GetProductsUseCase>(),
        getProductsByCategoryUseCase: sl<GetProductsByCategoryUseCase>(),
        getFeaturedProductsUseCase: sl<GetFeaturedProductsUseCase>(),
        getPopularProductsUseCase: sl<GetPopularProductsUseCase>(),
        getNewArrivalsUseCase: sl<GetNewArrivalsUseCase>(),
        getProductByIdUseCase: sl<GetProductByIdUseCase>(),
        getCartItemsUseCase: sl<GetCartItemsUseCase>(),
        addToCartUseCase: sl<AddToCartUseCase>(),
        updateCartItemUseCase: sl<UpdateCartItemUseCase>(),
        removeFromCartUseCase: sl<RemoveFromCartUseCase>(),
        clearCartUseCase: sl<ClearCartUseCase>(),
        getUserOrdersUseCase: sl<GetUserOrdersUseCase>(),
        createOrderUseCase: sl<CreateOrderUseCase>(),
        updateOrderUseCase: sl<UpdateOrderUseCase>(),
      ));

  // Providers
  sl.registerLazySingleton<List<CartItem>>(
      () => <CartItem>[]); // Cart items list
  sl.registerLazySingleton<List<ShopOrder>>(() => <ShopOrder>[]); // Orders list

  // ======== TOURNAMENT FEATURE ========

  // Data sources
  sl.registerLazySingleton<TournamentRemoteDataSource>(
    () => FirebaseTournamentRemoteDataSource(
      firestore: sl<FirebaseFirestore>(),
      auth: sl<FirebaseAuth>(),
    ),
  );

  // Repository
  sl.registerLazySingleton<TournamentRepository>(
    () => TournamentRepositoryImpl(
      remoteDataSource: sl<TournamentRemoteDataSource>(),
      networkInfo: sl<NetworkInfo>(),
      logger: sl<LoggerService>(),
    ),
  );

  // BLoCs - Tournament
  sl.registerFactory(() => TournamentBloc(
        repository: sl<TournamentRepository>(),
        logger: sl<LoggerService>(),
      ));

  // ======== PAYMENT FEATURE ========
  injectPaymentDependencies(sl);
}
