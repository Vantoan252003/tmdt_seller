import 'package:flutter/material.dart';

class AppTheme {
  // Gradient colors - Shoppee style (Orange & White)
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFF8F5), // Very light orange
      Color(0xFFFFFFFF), // White
      Color(0xFFFFF0E6), // Light orange
    ],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF5722), // Shoppee orange
      Color(0xFFFF6B35), // Lighter orange
    ],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF), // White
      Color(0xFFFFF8F5), // Very light orange
    ],
  );

  // Primary colors - Shoppee orange theme
  static const Color primaryColor = Color(0xFFFF5722); // Shoppee orange
  static const Color secondaryColor = Color(0xFFFF6B35); // Lighter orange
  static const Color accentColor = Color(0xFFFF8A65); // Accent orange
  
  // Text colors
  static const Color textPrimary = Color(0xFF2D3748); // Dark gray
  static const Color textSecondary = Color(0xFF718096); // Medium gray
  static const Color textLight = Color(0xFFA0AEC0); // Light gray
  
  // Background colors
  static const Color backgroundColor = Color(0xFFFFF8F5); // Very light orange
  static const Color cardColor = Color(0xFFFFFFFF); // White
  static const Color dividerColor = Color(0xFFFFE0D6); // Light orange divider
  
  // Status colors
  static const Color successColor = Color(0xFF4CAF50); // Green
  static const Color warningColor = Color(0xFFFF9800); // Orange
  static const Color errorColor = Color(0xFFF44336); // Red
  static const Color infoColor = Color(0xFF2196F3); // Blue
  
  // Rating color
  static const Color ratingColor = Color(0xFFFFC107); // Yellow
  
  // Discount color
  static const Color discountColor = Color(0xFFE91E63); // Pink
}
