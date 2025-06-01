import 'package:flutter/material.dart';
import 'package:pool_billiard_app/constants/asset_paths.dart';

/// Kenya Pool Billiards logo component
/// 
/// Displays the app logo with customizable size
class AppLogo extends StatelessWidget {
  final double size;
  final BoxFit fit;
  
  const AppLogo({
    Key? key,
    this.size = 120,
    this.fit = BoxFit.contain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AssetPaths.logo,
      width: size,
      height: size,
      fit: fit,
    );
  }
}
