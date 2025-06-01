import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pool_billiard_app/features/shop/components/product_card.dart';
import 'package:pool_billiard_app/features/shop/models/product.dart';
import 'package:pool_billiard_app/features/shop/domain/entities/cart_item.dart';
import 'package:pool_billiard_app/services/cart_provider.dart';

class CategoryPage extends StatelessWidget {
  final String title;
  final List<Product> products;
  
  const CategoryPage({
    Key? key,
    required this.title,
    required this.products,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Container(
        color: Theme.of(context).colorScheme.primary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.54, // Decreased aspect ratio to make cards taller
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return ProductCard(
                      product: products[index],
                      isGridItem: true,
                      onBuyPressed: () {
                        // Get the cart provider
                        final cartProvider = Provider.of<CartProvider>(context, listen: false);
                        final product = products[index];
                        
                        // Create a CartItem from the product
                        final cartItem = CartItem(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          productId: product.id,
                          name: product.name,
                          price: product.price,
                          quantity: 1,
                          imageUrl: product.imageUrl,
                        );
                        
                        // Add the cart item
                        cartProvider.addItem(cartItem);
                        
                        // Show a confirmation message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} added to cart!'),
                            duration: const Duration(seconds: 1),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            action: SnackBarAction(
                              label: 'VIEW CART',
                              textColor: Theme.of(context).colorScheme.secondary,
                              onPressed: () {
                                Navigator.pushNamed(context, '/cart');
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
