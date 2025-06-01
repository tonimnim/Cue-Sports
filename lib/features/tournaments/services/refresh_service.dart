import 'package:flutter/material.dart';

/// A service that provides pull-to-refresh functionality that can be
/// used across different pages in the app.
class RefreshService {
  /// Creates a RefreshIndicator wrapper around any widget with the app's theme
  /// 
  /// [child] - The widget to wrap with the refresh indicator
  /// [onRefresh] - The callback function to execute when the user pulls to refresh
  /// [color] - Optional custom color for the refresh indicator
  /// [backgroundColor] - Optional custom background color for the refresh indicator
  static Widget buildRefreshIndicator({
    required Widget child,
    required Future<void> Function() onRefresh,
    Color? color,
    Color? backgroundColor,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color, // Will use primary color from theme if null
      backgroundColor: backgroundColor, // Will use surface color from theme if null
      displacement: 40.0,
      strokeWidth: 3.0,
      triggerMode: RefreshIndicatorTriggerMode.onEdge,
      child: child,
    );
  }

  /// Creates a refresh callback for a specific data source
  /// 
  /// [fetchData] - The function to fetch new data
  /// [updateState] - The function to update the UI with new data
  /// [onError] - Optional callback for handling errors
  static Future<void> createRefreshCallback({
    required Future<dynamic> Function() fetchData,
    required Function(dynamic) updateState,
    Function(dynamic)? onError,
  }) async {
    try {
      final data = await fetchData();
      updateState(data);
    } catch (error) {
      if (onError != null) {
        onError(error);
      }
    }
  }
}
