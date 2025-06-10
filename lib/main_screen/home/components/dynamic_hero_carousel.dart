import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DynamicHeroCarousel extends StatefulWidget {
  final VoidCallback? onUpgradeTap;
  final VoidCallback? onShopTap;

  const DynamicHeroCarousel({
    Key? key,
    this.onUpgradeTap,
    this.onShopTap,
  }) : super(key: key);

  @override
  State<DynamicHeroCarousel> createState() => _DynamicHeroCarouselState();
}

class _DynamicHeroCarouselState extends State<DynamicHeroCarousel> {
  final PageController _pageController = PageController();
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
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
        final cards = _getHeroCards();
        final nextPage = (_currentPage + 1) % cards.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        setState(() {
          _currentPage = nextPage;
        });
      }
    });
  }

  List<Map<String, dynamic>> _getHeroCards() {
    return [
      {
        'type': 'upgrade',
        'title': 'BECOME A\nPLAYER',
        'subtitle': 'UPGRADE TO PLAYER',
        'description': 'JOIN TOURNAMENTS · TRACK STATS',
        'buttonText': 'UPGRADE NOW - KSh 500',
        'color': const Color(0xFFF9D61D),
        'image': 'assets/images/BILLIARD POOL.svg',
      },
      {
        'type': 'merchandise',
        'title': 'PREMIUM\nPOOL CUE',
        'subtitle': 'SHOP EQUIPMENT',
        'description': 'PROFESSIONAL GRADE · 25% OFF',
        'buttonText': 'GET NOW - KSh 4,500',
        'color': const Color(0xFF0066FF),
        'image': 'assets/images/BILLIARD POOL.svg',
      },
      {
        'type': 'merchandise',
        'title': 'CLUB\nJERSEY',
        'subtitle': 'OFFICIAL MERCHANDISE',
        'description': 'REPRESENT YOUR COMMUNITY',
        'buttonText': 'ORDER NOW - KSh 1,200',
        'color': const Color(0xFF00CC66),
        'image': 'assets/images/BILLIARD POOL.svg',
      },
      {
        'type': 'merchandise',
        'title': 'TOURNAMENT\nRANKING',
        'subtitle': 'TRACK PROGRESS',
        'description': 'VIEW LEADERBOARDS · STATS',
        'buttonText': 'VIEW RANKINGS',
        'color': const Color(0xFFFF6600),
        'image': 'assets/images/BILLIARD POOL.svg',
      },
      {
        'type': 'merchandise',
        'title': 'POOL BALL\nSET',
        'subtitle': 'COMPLETE SET',
        'description': 'PROFESSIONAL TOURNAMENT BALLS',
        'buttonText': 'BUY NOW - KSh 3,200',
        'color': const Color(0xFF9933FF),
        'image': 'assets/images/BILLIARD POOL.svg',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cards = _getHeroCards();

    return Column(
      children: [
        SizedBox(
          height: 120,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return _buildHeroCard(card);
            },
          ),
        ),
        const SizedBox(height: 12),
        // Page indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(cards.length, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index
                    ? Colors.white
                    : Colors.white.withOpacity(0.3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildHeroCard(Map<String, dynamic> card) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF093218),
            const Color(0xFF0B3D1C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          // Text content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    card['subtitle'],
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Flexible(
                    child: Text(
                      card['title'],
                      style: TextStyle(
                        color: card['color'],
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    card['description'],
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      if (card['type'] == 'upgrade') {
                        widget.onUpgradeTap?.call();
                      } else {
                        widget.onShopTap?.call();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: card['color'].withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        card['buttonText'],
                        style: TextStyle(
                          color: card['color'],
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Image
          Container(
            width: 120,
            padding: const EdgeInsets.all(12),
            child: SvgPicture.asset(
              card['image'],
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
