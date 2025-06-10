import 'package:flutter/material.dart';
import 'package:pool_billiard_app/features/shop/models/product.dart';
import 'package:pool_billiard_app/core/config/theme.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final bool isGridItem;
  final Function()? onBuyPressed;
  
  const ProductCard({
    Key? key,
    required this.product,
    this.isGridItem = false,
    this.onBuyPressed,
  }) : super(key: key);
  
  // Helper method to build the product image
  Widget _buildProductImage(BuildContext context, String imageUrl) {
    // Provide a placeholder for missing or invalid URLs
    if (imageUrl.isEmpty || imageUrl.contains('via.placeholder.com')) {
      return Container(
        color: AppTheme.primaryColor,
        child: Center(
          child: Icon(
            Icons.image,
            size: 50,
            color: Colors.white70,
          ),
        ),
      );
    }
    
    // Check if the image URL is a network image or an asset
    if (imageUrl.startsWith('http')) {
      // For network images
      return Image.network(
        imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Return a placeholder if the image fails to load
          return Container(
            color: AppTheme.primaryColor,
            child: Center(
              child: Icon(
                Icons.broken_image,
                size: 50,
                color: Colors.white70,
              ),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.secondary),
            ),
          );
        },
      );
    } else {
      // For asset images
      return Image.asset(
        imageUrl,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Return a placeholder if the asset image fails to load
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: Icon(
                Icons.broken_image,
                size: 50,
                color: Colors.grey[400],
              ),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isGridItem ? 250 : 240,
      width: isGridItem ? null : 170,
      margin: EdgeInsets.only(right: isGridItem ? 0 : 16, bottom: isGridItem ? 20 : 0),
      decoration: BoxDecoration(
        // Use primary color for the card background
        color: AppTheme.primaryColor, // Primary color background as requested
        borderRadius: BorderRadius.circular(12),
        // Removed border line as requested
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Product Image
          Stack(
            children: [
              Container(
                height: 140,
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0.0),
                color: AppTheme.primaryColor, // Added primaryColor background to match the card
                child: _buildProductImage(context, product.imageUrl),
              ),
            ],
          ),
          // Product details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isGridItem) ... [
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        Icons.star,
                        color: AppTheme.warningColor, // Use theme warning color for stars
                        size: 16,
                      );
                    }),
                  ),
                  const SizedBox(height: 3),
                ],
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white, // White text for contrast on primary color
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  product.description.isEmpty ? 'Premium quality product' : product.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70, // Light white color for good visibility on primary color
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'KES ',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white, // White text for price
                          ),
                        ),
                        Text(
                          '${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // White text for price
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: onBuyPressed ?? () {
                        // Default buy action if none provided
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} added to cart!'),
                            duration: const Duration(seconds: 1),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor, // Use yellowish secondary color
                        foregroundColor: Colors.black, // Black text on gold background
                        minimumSize: const Size(40, 30),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Buy', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
