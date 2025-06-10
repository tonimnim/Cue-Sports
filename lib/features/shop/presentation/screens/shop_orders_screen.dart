import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/theme.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../bloc/shop_bloc.dart';
import '../bloc/shop_event.dart';
import '../bloc/shop_state.dart';
import '../../domain/entities/shop_order.dart';

class ShopOrdersScreen extends StatelessWidget {
  const ShopOrdersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          di.sl<ShopBloc>()..add(LoadUserOrdersEvent('current_user')),
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundColor,
          elevation: 0,
          title: Text('My Orders', style: AppTheme.h2Style),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                context
                    .read<ShopBloc>()
                    .add(LoadUserOrdersEvent('current_user'));
              },
            ),
          ],
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
                            .add(LoadUserOrdersEvent('current_user'));
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
