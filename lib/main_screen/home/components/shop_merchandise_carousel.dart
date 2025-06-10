import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../features/shop/presentation/bloc/shop_bloc.dart';
import '../../../features/shop/presentation/bloc/shop_event.dart';
import '../../../features/shop/presentation/bloc/shop_state.dart';
import '../../../features/shop/domain/entities/product.dart';
import '../../../core/config/theme.dart';

class ShopMerchandiseCarousel extends StatefulWidget {
  final VoidCallback onShopTap;

  const ShopMerchandiseCarousel({
    Key? key,
    required this.onShopTap,
  }) : super(key: key);

  @override
  State<ShopMerchandiseCarousel> createState() =>
      _ShopMerchandiseCarouselState();
}

class _ShopMerchandiseCarouselState extends State<ShopMerchandiseCarousel> {
  final PageController _pageController = PageController();
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Load products when carousel initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShopBloc>().add(LoadProductsEvent());
    });
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        final state = context.read<ShopBloc>().state;
        if (state.isLoaded) {
          final merchandise = _getMerchandiseFromState(state);
          if (merchandise.isNotEmpty) {
            final pageCount = _getPageCount(merchandise.length);
            final nextPage = (_currentPage + 1) % pageCount;
            _pageController.animateToPage(
              nextPage,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
            setState(() {
              _currentPage = nextPage;
            });
          }
        }
      }
    });
  }

  List<Product> _getMerchandiseFromState(ShopState state) {
    // Get featured and popular products, prioritizing featured
    final featuredProducts = state.products.where((p) => p.isFeatured).toList();
    final popularProducts = state.products.where((p) => p.isPopular).toList();

    // Combine and remove duplicates, prioritizing featured products
    final merchandiseProducts = <Product>[];

    // Add featured products first
    merchandiseProducts.addAll(featuredProducts);

    // Add popular products that are not already in the list
    for (final product in popularProducts) {
      if (!merchandiseProducts.any((p) => p.id == product.id)) {
        merchandiseProducts.add(product);
      }
    }

    // If we still don't have enough products, add from all products
    if (merchandiseProducts.length < 6) {
      final allProducts = state.products;
      for (final product in allProducts) {
        if (!merchandiseProducts.any((p) => p.id == product.id) &&
            merchandiseProducts.length < 8) {
          merchandiseProducts.add(product);
        }
      }
    }

    return merchandiseProducts.take(8).toList();
  }

  int _getPageCount(int itemCount) {
    // Show 3 items per page
    return (itemCount / 3).ceil();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ShopBloc, ShopState>(
      builder: (context, state) {
        if (state.isLoading) {
          return _buildLoadingState();
        }

        if (state.hasError) {
          return _buildErrorState(state.errorMessage ?? 'Unknown error');
        }

        if (state.isLoaded) {
          final merchandise = _getMerchandiseFromState(state);

          if (merchandise.isEmpty) {
            return _buildEmptyState();
          }

          final pageCount = _getPageCount(merchandise.length);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header using new typography
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Shop Merchandise',
                    style: AppTheme.h3Style, // 18px Medium Raleway
                  ),
                  GestureDetector(
                    onTap: widget.onShopTap,
                    child: Text(
                      'see all',
                      style: AppTheme.bodySmallStyle.copyWith(
                        color: Colors.white70,
                      ), // 14px Regular Raleway
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Auto-scrolling merchandise carousel
              SizedBox(
                height: 160,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemCount: pageCount,
                  itemBuilder: (context, pageIndex) {
                    return _buildPage(merchandise, pageIndex);
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Page indicators
              _buildPageIndicators(pageCount),
            ],
          );
        }

        return _buildEmptyState();
      },
    );
  }

  Widget _buildLoadingState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shop Merchandise',
          style: AppTheme.h3Style,
        ),
        const SizedBox(height: 16),
        Container(
          height: 160,
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shop Merchandise',
          style: AppTheme.h3Style,
        ),
        const SizedBox(height: 16),
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppTheme.errorColor,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Failed to load products',
                  style: AppTheme.bodySmallStyle,
                ),
                TextButton(
                  onPressed: () {
                    context.read<ShopBloc>().add(LoadProductsEvent());
                  },
                  child: Text(
                    'Retry',
                    style: AppTheme.captionStyle.copyWith(
                      color: AppTheme.accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shop Merchandise',
          style: AppTheme.h3Style,
        ),
        const SizedBox(height: 16),
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.white54,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'No products available',
                  style: AppTheme.bodySmallStyle,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPage(List<Product> merchandise, int pageIndex) {
    final startIndex = pageIndex * 3;
    final endIndex = (startIndex + 3).clamp(0, merchandise.length);
    final pageItems = merchandise.sublist(startIndex, endIndex);

    return Row(
      children: pageItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 6,
              right: index == pageItems.length - 1 ? 0 : 6,
            ),
            child: _buildMerchandiseCard(item),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPageIndicators(int pageCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
          ),
        );
      }),
    );
  }

  Widget _buildMerchandiseCard(Product product) {
    return GestureDetector(
      onTap: widget.onShopTap,
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: AppTheme.cardColor, // Using the proper card color #16543A
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
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
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    color: Colors.grey.withValues(alpha: 0.2),
                  ),
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: product.imageUrl.startsWith('http')
                        ? Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildImagePlaceholder();
                            },
                          )
                        : Image.asset(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildImagePlaceholder();
                            },
                          ),
                  ),
                ),
                // Show badge for featured or popular products
                if (product.isFeatured)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'FEATURED',
                        style: AppTheme.overlineStyle.copyWith(
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w500,
                        ), // 10px Regular Raleway
                      ),
                    ),
                  )
                else if (product.isPopular)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'POPULAR',
                        style: AppTheme.overlineStyle.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
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
                      product.name,
                      style: AppTheme.captionStyle.copyWith(
                        fontWeight: FontWeight.w600,
                      ), // 12px Medium Raleway
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Current price
                        Text(
                          'KSh ${product.price.toStringAsFixed(0)}',
                          style: AppTheme.captionStyle.copyWith(
                            color: AppTheme.accentColor,
                            fontWeight: FontWeight.w600,
                          ), // 12px Medium Raleway
                        ),
                        // Rating if available
                        if (product.rating > 0)
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: AppTheme.accentColor,
                                size: 10,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                product.rating.toStringAsFixed(1),
                                style: AppTheme.overlineStyle.copyWith(
                                  color: Colors.white70,
                                ), // 10px Regular Raleway
                              ),
                            ],
                          ),
                      ],
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

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey.withValues(alpha: 0.2),
      child: const Center(
        child: Icon(
          Icons.shopping_bag,
          color: Colors.white54,
          size: 32,
        ),
      ),
    );
  }
}
