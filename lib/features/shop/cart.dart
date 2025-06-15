import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/product.dart';
import 'package:pool_billiard_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pool_billiard_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:pool_billiard_app/core/config/theme.dart';
import 'package:pool_billiard_app/core/di/injection_container.dart' as di;
import 'presentation/bloc/shop_bloc.dart';
import 'presentation/bloc/shop_event.dart';
import 'presentation/bloc/shop_state.dart';
import 'domain/entities/cart_item.dart';
import 'payment/payment_page.dart';
import '../../firebase/firebase_services.dart';

/// BLoC-based cart screen - completely replaced Provider with BLoC
class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => 
          di.sl<ShopBloc>()..add(LoadCartItemsEvent(di.sl<FirebaseServices>().currentUser?.uid ?? '')),
      child: Scaffold(
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
            BlocBuilder<ShopBloc, ShopState>(
              builder: (context, state) {
                return IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  onPressed: () {
                    _showClearCartDialog(context);
                  },
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: BlocBuilder<ShopBloc, ShopState>(
            builder: (context, state) {
              if (state.isCartLoading && state.cartItems.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.accentColor),
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
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          context
                              .read<ShopBloc>()
                              .add(LoadCartItemsEvent(di.sl<FirebaseServices>().currentUser?.uid ?? ''));
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final cartItems = state.cartItems;

              if (cartItems.isEmpty) {
                return _buildEmptyCart(context);
              }

              return _buildCartWithItems(context, cartItems);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: AppTheme.h2Style,
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to get started',
            style: AppTheme.bodyLargeStyle.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartWithItems(BuildContext context, List<CartItem> cartItems) {
    final totalPrice = cartItems.fold<double>(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cart items section
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF16543A),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Cart Items', style: AppTheme.h3Style),
                        Text(
                          '${cartItems.length} ${cartItems.length == 1 ? 'item' : 'items'}',
                          style: AppTheme.bodyLargeStyle
                              .copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

                  // Cart items list
                  Expanded(
                    child: ListView.builder(
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        return _buildCartItem(context, item);
                      },
                    ),
                  ),

                  // Subtotal
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Subtotal', style: AppTheme.bodyLargeStyle),
                        Text(
                          'KSh ${totalPrice.toStringAsFixed(0)}',
                          style: AppTheme.h3Style
                              .copyWith(color: AppTheme.accentColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Checkout button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: () =>
                  _proceedToCheckout(context, cartItems, totalPrice),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Proceed to Checkout (KSh ${totalPrice.toStringAsFixed(0)})',
                style: AppTheme.h3Style.copyWith(color: Colors.black),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCartItem(BuildContext context, CartItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 60,
              height: 60,
              color: AppTheme.accentColor.withOpacity(0.2),
              child: const Icon(
                Icons.sports,
                color: Colors.white54,
                size: 30,
              ),
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
                  style: AppTheme.bodyLargeStyle
                      .copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'KSh ${item.price.toStringAsFixed(0)}',
                  style: AppTheme.bodyLargeStyle
                      .copyWith(color: AppTheme.accentColor),
                ),
              ],
            ),
          ),

          // Quantity controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline,
                    color: Colors.white70),
                onPressed: () {
                  if (item.quantity > 1) {
                    context.read<ShopBloc>().add(UpdateCartItemQuantityEvent(
                        di.sl<FirebaseServices>().currentUser?.uid ?? '', item.id, item.quantity - 1));
                  } else {
                    _showRemoveItemDialog(context, item.id);
                  }
                },
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${item.quantity}',
                  style: AppTheme.bodyLargeStyle
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon:
                    const Icon(Icons.add_circle_outline, color: Colors.white70),
                onPressed: () {
                  context.read<ShopBloc>().add(UpdateCartItemQuantityEvent(
                      di.sl<FirebaseServices>().currentUser?.uid ?? '', item.id, item.quantity + 1));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRemoveItemDialog(BuildContext context, String itemId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Text('Remove Item', style: AppTheme.h3Style),
        content: Text(
          'Are you sure you want to remove this item from your cart?',
          style: AppTheme.bodyLargeStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel',
                style: AppTheme.bodyLargeStyle.copyWith(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              context
                  .read<ShopBloc>()
                  .add(RemoveFromCartEvent(di.sl<FirebaseServices>().currentUser?.uid ?? '', itemId));
              Navigator.of(context).pop();
            },
            child: Text('Remove',
                style: AppTheme.bodyLargeStyle
                    .copyWith(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Text('Clear Cart', style: AppTheme.h3Style),
        content: Text(
          'Are you sure you want to clear your cart?',
          style: AppTheme.bodyLargeStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel',
                style: AppTheme.bodyLargeStyle.copyWith(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              context.read<ShopBloc>().add(ClearCartEvent(di.sl<FirebaseServices>().currentUser?.uid ?? ''));
              Navigator.of(context).pop();
            },
            child: Text('Clear',
                style: AppTheme.bodyLargeStyle
                    .copyWith(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _proceedToCheckout(
      BuildContext context, List<CartItem> cartItems, double totalPrice) async {
    final cartId = const Uuid().v4();

    // Get user info
    final authState = context.read<AuthBloc>().state;
    String userId = '';
    String phoneNumber = '';

    // Try Firebase Auth first
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      userId = firebaseUser.uid;
      final userData = await _getUserDataFromFirestore(firebaseUser.uid);
      if (userData != null && userData.containsKey('phoneNumber')) {
        phoneNumber = userData['phoneNumber'] ?? '';
      }
    }

    // Fallback to AuthBloc
    if (userId.isEmpty && authState is AuthAuthenticated) {
      userId = authState.user.id;
      phoneNumber = authState.user.phoneNumber ?? '';
    }

    // Navigate to payment
    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          paymentType: 'merchandise',
          typeId: cartId,
          userId: userId.isEmpty ? 'guest_user' : userId,
          amount: totalPrice,
          prefillPhoneNumber: phoneNumber,
        ),
      ),
    ).then((result) {
      if (result == true && context.mounted) {
        // Payment successful, clear cart
        context.read<ShopBloc>().add(ClearCartEvent(di.sl<FirebaseServices>().currentUser?.uid ?? ''));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text('Payment successful! Your order has been placed.'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });
  }

  Future<Map<String, dynamic>?> _getUserDataFromFirestore(String userId) async {
    try {
      final collections = [
        'users',
        'Users',
        'user',
        'User',
        'Profiles',
        'profiles'
      ];

      for (String collection in collections) {
        try {
          DocumentSnapshot doc = await FirebaseFirestore.instance
              .collection(collection)
              .doc(userId)
              .get();

          if (doc.exists) {
            return doc.data() as Map<String, dynamic>?;
          }
        } catch (e) {
          // Continue to next collection
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
