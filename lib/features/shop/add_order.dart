import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;

import '../../services/cart_provider.dart';
import '../../services/order_provider.dart';
import 'domain/entities/shop_order.dart';
import 'domain/entities/cart_item.dart';
import '../../features/payment/presentation/screens/payment_screen.dart';

/// Service class to add orders after successful payment
class OrderCreationService {
  /// Creates a new order from cart items after successful payment
  /// 
  /// [context] - BuildContext for provider access
  /// [userId] - ID of the user making the purchase
  /// [paymentMethod] - Method used for payment (e.g., 'M-Pesa')
  /// [receiptNumber] - Transaction receipt number
  /// [notes] - Any additional notes for the order
  /// 
  /// Returns a Future<bool> indicating if order creation was successful
  static Future<bool> createOrderAfterPayment({
    required BuildContext context,
    required String userId,
    required String paymentMethod,
    String? receiptNumber,
    String? notes,
  }) async {
    try {
      // Get provider references
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      
      // Log the order creation attempt
      developer.log(
        'Creating order after successful payment',
        name: 'OrderCreationService',
      );

      // Log cart items for debugging
      developer.log(
        'Cart items to convert to order: ${cartProvider.items.length} items, Total: ${cartProvider.totalPrice}',
        name: 'OrderCreationService',
      );
      
      // Create a new order from the cart items
      final order = ShopOrder(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        orderNumber: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
        items: List<CartItem>.from(cartProvider.items),
        total: cartProvider.totalPrice,
        status: OrderStatus.completed,
        paymentMethod: paymentMethod,
        shippingAddress: '', // This should be provided by the user
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Add the order
      orderProvider.addOrder(order);
      
      // Clear the cart after successful payment and order creation
      cartProvider.clearCart();
      developer.log('Cart cleared successfully', name: 'OrderCreationService');
      
      return true;
    } catch (e, stackTrace) {
      developer.log(
        'Error creating order: $e',
        name: 'OrderCreationService',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}

/// Widget to create an order from cart data
/// This can be used as a separate screen if needed
class AddOrderScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final double totalAmount;

  const AddOrderScreen({
    super.key,
    required this.cartItems,
    required this.totalAmount,
  });

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final order = ShopOrder(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'USER_ID', // Replace with actual user ID
        orderNumber: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
        items: List<CartItem>.from(widget.cartItems),
        total: widget.totalAmount,
        status: OrderStatus.pending,
        paymentMethod: 'pending',
        shippingAddress: _addressController.text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Navigate to payment screen
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            paymentType: 'merchandise',
            typeId: order.id,
            userId: 'USER_ID', // Replace with actual user ID
            amount: widget.totalAmount,
            prefillPhoneNumber: _phoneController.text,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating order: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Order'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Order summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Summary',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ...widget.cartItems.map((item) => ListTile(
                      title: Text(item.name),
                      subtitle: Text('Quantity: ${item.quantity}'),
                      trailing: Text('KES ${(item.price * item.quantity).toStringAsFixed(2)}'),
                    )),
                    const Divider(),
                    ListTile(
                      title: const Text('Total Amount'),
                      trailing: Text(
                        'KES ${widget.totalAmount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Shipping information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shipping Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Shipping Address',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your shipping address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                        hintText: '07XXXXXXXX',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (!RegExp(r'^07\d{8}$').hasMatch(value)) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            ElevatedButton(
              onPressed: _isLoading ? null : _submitOrder,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(),
                    )
                  : const Text('Proceed to Payment'),
            ),
          ],
        ),
      ),
    );
  }
}
