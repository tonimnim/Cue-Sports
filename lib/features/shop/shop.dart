import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/product.dart';
// Removed non-existent imports
import 'orders.dart';
import 'payment/payment_page.dart';
// Removed non-existent imports
import 'services/product_provider.dart';
import 'services/cart_provider.dart';
import 'package:pool_billiard_app/features/shop/components/product_card.dart';
import 'package:pool_billiard_app/features/shop/components/category_page.dart';
import 'package:pool_billiard_app/features/shop/components/section_header.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String selectedCategory = 'All'; // Default to showing all products
  final TextEditingController _searchController = TextEditingController();
  // Bottom navigation is now handled by HomeScreen
  String _searchQuery = '';

  // We now load products from Firebase instead of hardcoding them

  @override
  void initState() {
    super.initState();
    // Load products when the screen initializes
    Future.microtask(() {
      if (mounted) {
        Provider.of<ProductProvider>(context, listen: false).loadProducts();
        Provider.of<CartProvider>(context, listen: false).loadCartItems();
      }
    });
    
    // Set up search controller listener
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    
    // Get filtered products based on selected category and search query
    List<Product> filteredFeatured = productProvider.getFeaturedProductsByCategory(selectedCategory);
    List<Product> filteredPopular = productProvider.getPopularProductsByCategory(selectedCategory);
    List<Product> filteredNewArrivals = productProvider.getNewArrivalsByCategory(selectedCategory);
    
    // Apply search filter if there's a search query
    if (_searchQuery.isNotEmpty) {
      filteredFeatured = filteredFeatured.where(
        (product) => product.name.toLowerCase().contains(_searchQuery) ||
          product.description.toLowerCase().contains(_searchQuery)
      ).toList();
      
      filteredPopular = filteredPopular.where(
        (product) => product.name.toLowerCase().contains(_searchQuery) ||
          product.description.toLowerCase().contains(_searchQuery)
      ).toList();
      
      filteredNewArrivals = filteredNewArrivals.where(
        (product) => product.name.toLowerCase().contains(_searchQuery) ||
          product.description.toLowerCase().contains(_searchQuery)
      ).toList();
    }

    // Limit displayed products to 5 per category
    final displayedFeatured = filteredFeatured.take(5).toList();
    final displayedPopular = filteredPopular.take(5).toList();
    final displayedNewArrivals = filteredNewArrivals.take(5).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fresh Arrivals',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Premium quality apparels & accessories',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentScreen(
                        paymentType: 'merchandise',
                        typeId: 'cart',
                        userId: 'user_id',
                        amount: 0.0,
                      ),
                    ),
                  );
                },
              ),
              if (cartProvider.itemCount > 0)
                Positioned(
                  right: 5,
                  top: 5,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${cartProvider.itemCount}',
                      style: const TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()));
            },
          ),
        ],
      ),
      body: Container(
        color: Theme.of(context).colorScheme.primary,
        child: SingleChildScrollView(
          child: Container(
            color: Theme.of(context).colorScheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'T-shirt Collection',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                        prefixIcon: Icon(Icons.menu, color: Colors.white.withOpacity(0.7)),
                        suffixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15),
                        fillColor: Colors.transparent,
                        filled: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryButton('All'),
                      const SizedBox(width: 10),
                      _buildCategoryButton('Apparel'),
                      const SizedBox(width: 10),
                      _buildCategoryButton('Equipment'),
                      const SizedBox(width: 10),
                      _buildCategoryButton('Accessories'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (displayedFeatured.isNotEmpty) ... [
                  SectionHeader(
                    title: 'Featured',
                    onViewAllPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryPage(
                            title: 'Featured Products',
                            products: filteredFeatured,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(
                    height: 290,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: displayedFeatured.length,
                      itemBuilder: (context, index) {
                        return ProductCard(
                          product: displayedFeatured[index],
                          onBuyPressed: () async {
                            try {
                              await cartProvider.addToCart(displayedFeatured[index]);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${displayedFeatured[index].name} added to cart!'),
                                  duration: const Duration(seconds: 1),
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to add to cart: $e'),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                if (displayedPopular.isNotEmpty) ... [
                  SectionHeader(
                    title: 'Popular',
                    onViewAllPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryPage(
                            title: 'Popular Products',
                            products: filteredPopular,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(
                    height: 290,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: displayedPopular.length,
                      itemBuilder: (context, index) {
                        return ProductCard(
                          product: displayedPopular[index],
                          onBuyPressed: () async {
                            try {
                              await cartProvider.addToCart(displayedPopular[index]);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${displayedPopular[index].name} added to cart!'),
                                  duration: const Duration(seconds: 1),
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to add to cart: $e'),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                if (displayedNewArrivals.isNotEmpty) ... [
                  SectionHeader(
                    title: 'New Arrivals',
                    onViewAllPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryPage(
                            title: 'New Arrivals',
                            products: filteredNewArrivals,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(
                    height: 290,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: displayedNewArrivals.length,
                      itemBuilder: (context, index) {
                        return ProductCard(
                          product: displayedNewArrivals[index],
                          onBuyPressed: () async {
                            try {
                              await cartProvider.addToCart(displayedNewArrivals[index]);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${displayedNewArrivals[index].name} added to cart!'),
                                  duration: const Duration(seconds: 1),
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to add to cart: $e'),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      // Bottom navigation is now handled by HomeScreen
    );
  }

  Widget _buildCategoryButton(String category) {
    final isSelected = selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = category;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2A9C70) // Lighter green for active category
              : Color.fromRGBO(
                  Theme.of(context).colorScheme.primary.red.toInt(),
                  Theme.of(context).colorScheme.primary.green.toInt(),
                  Theme.of(context).colorScheme.primary.blue.toInt(),
                  0.7), // Slightly lighter green for inactive
          border: Border.all(color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.3), width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          category,
          style: TextStyle(
            color: Colors.white, // Always white text for visibility on green background
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // We're no longer using this method as we've moved it to a separate component
  // This remains for backward compatibility but is unused
  Widget _buildProductCard(Product product, {bool isGridItem = false}) {
    return ProductCard(product: product, isGridItem: isGridItem);
  }
}