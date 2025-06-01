import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/di/injection_container.dart' as di;
import 'core/services/logger_service.dart';
import 'firebase/firebase_options.dart';
import 'features/shop/domain/entities/cart_item.dart';
import 'features/shop/domain/entities/shop_order.dart';

// App class is defined in app.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase with error handling first
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");
    
    // Configure Firebase settings after initialization
    if (kDebugMode) {
      firestore.FirebaseFirestore.instance.settings = const firestore.Settings(
        persistenceEnabled: true,
        cacheSizeBytes: firestore.Settings.CACHE_SIZE_UNLIMITED,
      );
      print("Firebase debug mode enabled");
    }
  } catch (e) {
    print("Firebase initialization error: $e");
  }

  // Initialize dependency injection
  await di.init();
  
  // Initialize BlocObserver for debugging
  Bloc.observer = AppBlocObserver();
  
  // Log initialization success
  final logger = di.sl<LoggerService>();
  logger.i('🌟 Kenya Pool Billiards App initialized successfully');

  runApp(const MyApp());
}

class AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    debugPrint('${bloc.runtimeType} $change');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    debugPrint('${bloc.runtimeType} $error $stackTrace');
    super.onError(bloc, error, stackTrace);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<List<CartItem>>.value(value: di.sl<List<CartItem>>()),
        Provider<List<ShopOrder>>.value(value: di.sl<List<ShopOrder>>()),
      ],
      child: const App(),
    );
  }
}
