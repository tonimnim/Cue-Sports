class AppConfig {
  static const String appName = 'Billiard Clash';
  static const String appVersion = '1.0.0';
  
  // API Configuration
  static const String apiBaseUrl = 'https://api.billiardclash.com';
  
  // Firebase Configuration
  static const String firebaseProjectId = 'billiard-clash';
  
  // Feature Flags
  static const bool enableTournaments = true;
  static const bool enableShop = true;
  static const bool enableCommunity = true;
  
  // Cache Configuration
  static const int cacheDuration = 7; // days
  
  // Timeouts
  static const int connectionTimeout = 30000; // milliseconds
  static const int receiveTimeout = 30000; // milliseconds
} 