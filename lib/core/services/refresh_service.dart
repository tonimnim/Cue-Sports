import 'package:flutter/material.dart';

/// A utility service for handling refresh operations with consistent behavior
class RefreshService {
  /// Creates a refresh callback that handles data fetching, state updates, and error handling
  /// 
  /// [fetchData] - Function to fetch new data
  /// [updateState] - Function to update the state with new data
  /// [onError] - Function to handle errors
  static Future<void> createRefreshCallback<T>({
    required Future<T> Function() fetchData,
    required void Function(T data) updateState,
    required void Function(String error) onError,
  }) async {
    try {
      final data = await fetchData();
      updateState(data);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Builds a RefreshIndicator widget with consistent styling
  /// 
  /// [child] - The child widget to wrap
  /// [onRefresh] - The refresh callback function
  static Widget buildRefreshIndicator({
    required Widget child,
    required Future<void> Function() onRefresh,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: child,
    );
  }
} 