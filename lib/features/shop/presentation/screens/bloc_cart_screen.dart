import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/theme.dart';
import '../bloc/shop_bloc.dart';
import '../bloc/shop_event.dart';
import '../bloc/shop_state.dart';
import '../../domain/entities/cart_item.dart';
import '../../../payment/domain/entities/payment.dart' as payment_entity;
import 'package:firebase_auth/firebase_auth.dart';

class BlocCartScreen extends StatelessWidget {
  const BlocCartScreen({Key? key}) : super(key: key);

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Clear Cart',
          style: AppTheme.h3Style,
        ),
        content: Text(
          'Are you sure you want to remove all items from your cart?',
          style: AppTheme.bodyLargeStyle.copyWith(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
              context.read<ShopBloc>().add(ClearCartEvent(userId));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Cart cleared successfully'),
                  backgroundColor: AppTheme.successColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Clear Cart'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        title: Text('My Cart', style: AppTheme.h2Style),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Clear cart button
          BlocBuilder<ShopBloc, ShopState>(
            builder: (context, state) {
              if (state.cartItems.isNotEmpty) {
                return IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 24,
                  ),
                  onPressed: () => _showClearCartDialog(context),
                  tooltip: 'Clear Cart',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<ShopBloc, ShopState>(
        builder: (context, state) {
          if (state.isLoading && state.cartItems.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (state.hasError && state.cartItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.white, size: 64),
                  const SizedBox(height: 16),
                  Text('Error loading cart', style: AppTheme.h3Style),
                  const SizedBox(height: 8),
                  Text(
                    state.errorMessage ?? 'Unknown error occurred',
                    style:
                        AppTheme.bodyLargeStyle.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<ShopBloc>()
                          .add(LoadCartItemsEvent(FirebaseAuth.instance.currentUser?.uid ?? ''));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final cartItems = state.cartItems;

          if (cartItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  const SizedBox(height: 24),
                  Text('Your cart is empty', style: AppTheme.h2Style),
                  const SizedBox(height: 8),
                  Text(
                    'Add some products to get started',
                    style:
                        AppTheme.bodyLargeStyle.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Continue Shopping'),
                  ),
                ],
              ),
            );
          }

          final subtotal = cartItems.fold(
              0.0, (sum, item) => sum + (item.price * item.quantity));

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Product image
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                                ? item.imageUrl!.contains('via.placeholder.com')
                                  ? Icon(
                                      Icons.image,
                                      color: AppTheme.accentColor,
                                      size: 30,
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        item.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(
                                            Icons.broken_image,
                                            color: AppTheme.accentColor,
                                            size: 30,
                                          );
                                        },
                                      ),
                                    )
                                : Icon(
                                    Icons.sports_basketball,
                                    color: AppTheme.accentColor,
                                    size: 30,
                                  ),
                            ),
                            const SizedBox(width: 12),

                            // Product details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: AppTheme.bodyLargeStyle.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'KSh ${item.price.toStringAsFixed(0)}',
                                    style: AppTheme.bodySmallStyle.copyWith(
                                      color: AppTheme.accentColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Quantity controls
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Decrease quantity button
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () {
                                        if (item.quantity > 1) {
                                          context.read<ShopBloc>().add(
                                                UpdateCartItemQuantityEvent(
                                                  FirebaseAuth.instance.currentUser?.uid ?? '',
                                                  item.id,
                                                  item.quantity - 1,
                                                ),
                                              );
                                        } else {
                                          // Remove item if quantity would be 0
                                          context.read<ShopBloc>().add(
                                                RemoveFromCartEvent(
                                                    FirebaseAuth.instance.currentUser?.uid ?? '', item.id),
                                              );
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        child: Icon(
                                          item.quantity > 1
                                              ? Icons.remove
                                              : Icons.delete_outline,
                                          color: item.quantity > 1
                                              ? AppTheme.accentColor
                                              : Colors.red,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Quantity display
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Text(
                                      '${item.quantity}',
                                      style: AppTheme.bodyLargeStyle.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  // Increase quantity button
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () {
                                        context.read<ShopBloc>().add(
                                              UpdateCartItemQuantityEvent(
                                                FirebaseAuth.instance.currentUser?.uid ?? '',
                                                item.id,
                                                item.quantity + 1,
                                              ),
                                            );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        child: Icon(
                                          Icons.add,
                                          color: AppTheme.accentColor,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Checkout section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subtotal', style: AppTheme.h3Style),
                          Text(
                            'KSh ${subtotal.toStringAsFixed(0)}',
                            style: AppTheme.h3Style
                                .copyWith(color: AppTheme.accentColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please login to checkout'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            // Navigate to unified payment
                            Navigator.of(context).pushNamed(
                              '/unified-payment',
                              arguments: {
                                'paymentType':
                                    payment_entity.PaymentType.merchandise,
                                'typeId':
                                    'cart_${DateTime.now().millisecondsSinceEpoch}',
                                'userId': user.uid,
                                'amount': subtotal,
                                'metadata': {
                                  'cartItems': cartItems
                                      .map((item) => {
                                            'id': item.id,
                                            'name': item.name,
                                            'price': item.price,
                                            'quantity': item.quantity,
                                          })
                                      .toList(),
                                  'itemCount': cartItems.length,
                                },
                                'onSuccess': () {
                                  // Clear cart after successful payment
                                  context
                                      .read<ShopBloc>()
                                      .add(ClearCartEvent(user.uid));

                                  // Navigate to orders screen
                                  Navigator.of(context)
                                      .pushReplacementNamed('/orders');
                                },
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Checkout • KSh ${subtotal.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
