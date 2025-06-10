import 'package:flutter/material.dart';
import 'package:pool_billiard_app/core/config/theme.dart';
import 'package:pool_billiard_app/features/auth/domain/entities/user.dart';
import 'package:pool_billiard_app/features/community/presentation/pages/communities_page.dart';

class CommunityDemo extends StatefulWidget {
  const CommunityDemo({Key? key}) : super(key: key);

  @override
  State<CommunityDemo> createState() => _CommunityDemoState();
}

class _CommunityDemoState extends State<CommunityDemo> {
  bool _isPlayer = true;

  @override
  Widget build(BuildContext context) {
    final User currentUser = User(
      id: 'demo_user',
      email: 'demo@example.com',
      isEmailVerified: true,
      fullName: _isPlayer ? 'John Player' : 'Jane Fan',
      phoneNumber: '+254700000000',
      userType: _isPlayer ? 'player' : 'fan',
      createdAt: DateTime.now(),
      registeredAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      isActive: true,
    );

    return MaterialApp(
      title: 'Community System Demo',
      theme: AppTheme.theme,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Community Demo'),
          actions: [
            // Toggle between Player and Fan view
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  Text(
                    _isPlayer ? 'Player View' : 'Fan View',
                    style: AppTheme.bodyStyle.copyWith(
                      color: AppTheme.textLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: !_isPlayer,
                    onChanged: (value) {
                      setState(() {
                        _isPlayer = !value;
                      });
                    },
                    activeColor: AppTheme.accentColor,
                    inactiveThumbColor: AppTheme.textLight,
                    inactiveTrackColor: AppTheme.cardColor,
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // User type indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: _isPlayer
                  ? AppTheme.successColor.withOpacity(0.1)
                  : AppTheme.accentColor.withOpacity(0.1),
              child: Column(
                children: [
                  Icon(
                    _isPlayer ? Icons.sports_esports : Icons.favorite,
                    color: _isPlayer
                        ? AppTheme.successColor
                        : AppTheme.accentColor,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Viewing as: ${currentUser.userType.toUpperCase()}',
                    style: AppTheme.subheadingStyle.copyWith(
                      color: _isPlayer
                          ? AppTheme.successColor
                          : AppTheme.accentColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _isPlayer
                        ? 'Players can join ONE community only'
                        : 'Fans can follow multiple communities',
                    style: AppTheme.bodyStyle.copyWith(
                      color: AppTheme.textLight.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Communities page
            Expanded(
              child: CommunitiesPage(currentUser: currentUser),
            ),
          ],
        ),
      ),
    );
  }
}

// To run this demo, create a simple main.dart:
/*
import 'package:flutter/material.dart';
import 'community_demo.dart';

void main() {
  runApp(CommunityDemo());
}
*/
