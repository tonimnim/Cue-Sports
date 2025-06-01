import 'package:flutter/material.dart';

class ShopMerchandiseCarousel extends StatelessWidget {
  final VoidCallback onShopTap;
  
  const ShopMerchandiseCarousel({
    Key? key,
    required this.onShopTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sample merchandise data - this would come from the shop feature
    final List<Map<String, dynamic>> merchandise = [
      {
        'name': 'Pool Cue Stick',
        'price': 'KSh 2,500',
        'image': 'assets/images/logo.png', // Placeholder
        'discount': '20% OFF',
      },
      {
        'name': 'Pool Table Cover',
        'price': 'KSh 1,200',
        'image': 'assets/images/logo.png', // Placeholder
        'discount': null,
      },
      {
        'name': 'Club T-Shirt',
        'price': 'KSh 800',
        'image': 'assets/images/logo.png', // Placeholder
        'discount': '15% OFF',
      },
      {
        'name': 'Pool Chalk Set',
        'price': 'KSh 300',
        'image': 'assets/images/logo.png', // Placeholder
        'discount': null,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Shop Merchandise',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: onShopTap,
              child: const Text(
                'see all',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Merchandise carousel
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: merchandise.length,
            itemBuilder: (context, index) {
              final item = merchandise[index];
              return Padding(
                padding: EdgeInsets.only(right: index < merchandise.length - 1 ? 12.0 : 0),
                child: _buildMerchandiseCard(item, onShopTap),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMerchandiseCard(Map<String, dynamic> item, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 26), // 0.1 * 255 ≈ 26
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image with discount badge
            Stack(
              children: [
                Container(
                  height: 80,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    color: Colors.grey[100],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.asset(
                      item['image'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image,
                            color: Colors.grey,
                            size: 32,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (item['discount'] != null)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item['discount'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Product details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['name'],
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item['price'],
                      style: const TextStyle(
                        color: Color(0xFF0F4A22),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 