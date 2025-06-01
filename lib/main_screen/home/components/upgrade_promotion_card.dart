import 'package:flutter/material.dart';

class UpgradePromotionCard extends StatelessWidget {
  final VoidCallback onUpgradeTap;
  
  const UpgradePromotionCard({
    Key? key,
    required this.onUpgradeTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF093218), Color(0xFF0B3D1C)],
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
                  const Text(
                    'UPGRADE TO PLAYER',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Flexible(
                    child: Text(
                      'BECOME A\nPLAYER',
                      style: TextStyle(
                        color: Color(0xFFF9D61D), // Bright yellow
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'JOIN TOURNAMENTS · TRACK STATS',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: onUpgradeTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9D61D).withValues(alpha: 51), // 0.2 * 255 ≈ 51
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'UPGRADE NOW - KSh 500',
                        style: TextStyle(
                          color: Color(0xFFF9D61D),
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
          // Pool balls image
          Container(
            width: 120,
            padding: const EdgeInsets.all(12),
            child: Image.asset(
              'assets/images/logo.png', // Using the logo since pool_balls.png doesn't exist
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
} 