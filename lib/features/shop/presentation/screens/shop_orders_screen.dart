import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/theme.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../bloc/shop_bloc.dart';
import '../bloc/shop_event.dart';
import '../bloc/shop_state.dart';
import '../../domain/entities/shop_order.dart';
import '../../../../firebase/firebase_services.dart';

class ShopOrdersScreen extends StatelessWidget {
  const ShopOrdersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the current user ID from Firebase
    final firebaseServices = di.sl<FirebaseServices>();
    final String userId = firebaseServices.currentUser?.uid ?? '';
    
    return BlocProvider(
      create: (context) =>
          di.sl<ShopBloc>()..add(LoadUserOrdersEvent(userId)),
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundColor,
          elevation: 0,
          title: Text('My Orders', style: AppTheme.h2Style),
        ),
        body: BlocBuilder<ShopBloc, ShopState>(
          builder: (context, state) {
            if (state.status == ShopStatus.loading && state.orders.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.accentColor),
              );
            }

            if (state.hasError && state.orders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.white, size: 64),
                    const SizedBox(height: 16),
                    Text('Error loading orders', style: AppTheme.h3Style),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context
                            .read<ShopBloc>()
                            .add(LoadUserOrdersEvent(userId));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state.orders.isNotEmpty || state.status == ShopStatus.loaded) {
              if (state.orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 80,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      const SizedBox(height: 24),
                      Text('No orders found', style: AppTheme.h2Style),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/shop'),
                        child: const Text('Start Shopping'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.orders.length,
                itemBuilder: (context, index) {
                  final order = state.orders[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16543A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order #${order.orderNumber}',
                              style: AppTheme.bodyLargeStyle.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                order.status.toString().split('.').last,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Total: KSh ${order.total.toStringAsFixed(0)}',
                          style: AppTheme.bodyLargeStyle.copyWith(
                            color: AppTheme.accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${order.items.length} items • ${order.paymentMethod}',
                          style: AppTheme.bodySmallStyle.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Display order items
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 8),
                        Text(
                          'Items:',
                          style: AppTheme.bodySmallStyle.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // List of items
                        ...order.items.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Product image
                                  if (item.imageUrl != null && item.imageUrl?.isNotEmpty == true && !item.imageUrl!.contains('placeholder'))
                                    Container(
                                      width: 40,
                                      height: 40,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image: NetworkImage(item.imageUrl!),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 40,
                                      height: 40,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.cardColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.sports_basketball,
                                        color: AppTheme.accentColor,
                                        size: 24,
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      '${item.quantity}x ${item.name}',
                                      style: AppTheme.bodySmallStyle,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    'KSh ${(item.price * item.quantity).toStringAsFixed(0)}',
                                    style: AppTheme.bodySmallStyle,
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  );
                },
              );
            }

            return const Center(
              child: Text('Loading orders...',
                  style: TextStyle(color: Colors.white)),
            );
          },
        ),
      ),
    );
  }
}
