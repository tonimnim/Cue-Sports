import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../../../../core/config/theme.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../bloc/shop_bloc.dart';
import '../bloc/shop_event.dart';
import '../bloc/shop_state.dart';
import '../../domain/entities/shop_order.dart';
import '../../data/models/shop_order_model.dart';
import '../../../../firebase/firebase_services.dart';

class ShopOrdersScreen extends StatefulWidget {
  const ShopOrdersScreen({Key? key}) : super(key: key);

  @override
  State<ShopOrdersScreen> createState() => _ShopOrdersScreenState();
}

class _ShopOrdersScreenState extends State<ShopOrdersScreen> {
  late FirebaseServices firebaseServices;
  late String userId;
  StreamSubscription? _ordersSubscription;
  List<ShopOrder> _realtimeOrders = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    firebaseServices = di.sl<FirebaseServices>();
    userId = firebaseServices.currentUser?.uid ?? '';
    _setupOrdersStream();
  }
  
  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }
  
  void _setupOrdersStream() {
    if (userId.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'User not logged in';
      });
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final ordersStream = firebaseServices.firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          // Note: This query requires a composite index on userId (Ascending) and createdAt (Descending)
          // If you see an error, you need to create the index in the Firebase console
          .snapshots();
      
      _ordersSubscription = ordersStream.listen(
        (snapshot) {
          final orders = snapshot.docs.map((doc) {
            // Use the ShopOrderModel.fromFirestore constructor
            return ShopOrderModel.fromFirestore(doc);
          }).toList();
          
          setState(() {
            _realtimeOrders = orders;
            _isLoading = false;
            _errorMessage = null;
          });
        },
        onError: (error) {
          setState(() {
            _isLoading = false;
            if (error.toString().contains('The query requires an index')) {
              _errorMessage = 'This query requires a Firestore index. Please check the console logs for a link to create it.';
            } else {
              _errorMessage = 'Error loading orders: $error';
            }
          });
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        if (e.toString().contains('The query requires an index')) {
          _errorMessage = 'This query requires a Firestore index. Please check the console logs for a link to create it.';
        } else {
          _errorMessage = 'Failed to setup orders stream: $e';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          di.sl<ShopBloc>()..add(LoadUserOrdersEvent(userId)),
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundColor,
          elevation: 0,
          title: Text('My Orders', style: AppTheme.h2Style),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _setupOrdersStream(),
              tooltip: 'Refresh orders',
            ),
          ],
        ),
        body: BlocBuilder<ShopBloc, ShopState>(
          builder: (context, state) {
            // Show loading indicator if we're loading from either source
            if (_isLoading || state.isOrderCreating) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: AppTheme.accentColor),
                    const SizedBox(height: 16),
                    Text(
                      state.isOrderCreating 
                          ? 'Creating your order...' 
                          : 'Loading orders...',
                      style: AppTheme.h3Style,
                    ),
                  ],
                ),
              );
            }

            // Show error if we have one from either source
            if ((_errorMessage != null || state.hasError) && _realtimeOrders.isEmpty && state.orders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.white, size: 64),
                    const SizedBox(height: 16),
                    Text(_errorMessage ?? state.errorMessage ?? 'Error loading orders', 
                         style: AppTheme.h3Style),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        _setupOrdersStream();
                        context.read<ShopBloc>().add(LoadUserOrdersEvent(userId));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            // Merge orders from both sources, prioritizing realtime orders
            final List<ShopOrder> combinedOrders = [..._realtimeOrders];
            
            // Add any orders from the bloc state that aren't already in the realtime list
            for (final order in state.orders) {
              if (!combinedOrders.any((o) => o.id == order.id)) {
                combinedOrders.add(order);
              }
            }
            
            // Sort by creation date (newest first)
            combinedOrders.sort((a, b) => 
              (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
            
            if (combinedOrders.isEmpty) {
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

            return RefreshIndicator(
              onRefresh: () async {
                _setupOrdersStream();
                context.read<ShopBloc>().add(LoadUserOrdersEvent(userId));
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: combinedOrders.length,
                itemBuilder: (context, index) {
                  final order = combinedOrders[index];
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
                              'Order #${order.orderNumber.length > 15 ? order.orderNumber.substring(0, 12) + '...' : order.orderNumber}',
                              style: AppTheme.bodyLargeStyle.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
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
              ),
            );
          },
        ),
      ),
    );
  }
}

