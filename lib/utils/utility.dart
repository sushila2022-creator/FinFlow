import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Static map of category names (lowercase) to specific Flutter icons
/// Used globally for consistent icon display across the app
const Map<String, IconData> categoryIcons = {
  // Food related
  'food': Icons.fastfood,
  'groceries': Icons.local_grocery_store,
  'snacks': Icons.restaurant,
  'restaurant': Icons.restaurant,
  'dining': Icons.local_dining,
  
  // Transport related
  'transport': Icons.directions_car,
  'transportation': Icons.directions_car,
  'fuel': Icons.local_gas_station,
  'taxi': Icons.local_taxi,
  'uber': Icons.directions_car,
  'travel': Icons.directions_bus,
  
  // Shopping related
  'shopping': Icons.shopping_bag,
  'clothes': Icons.shopping_bag,
  'clothing': Icons.shopping_bag,
  
  // Income related
  'salary': Icons.account_balance_wallet,
  'income': Icons.attach_money,
  'bonus': Icons.attach_money,
  
  // Bills related
  'bills': Icons.receipt_long,
  'electricity': Icons.receipt_long,
  'rent': Icons.receipt_long,
  'utilities': Icons.receipt_long,
  
  // Health related
  'health': Icons.medical_services,
  'medical': Icons.medical_services,
  'healthcare': Icons.local_hospital,
  
  // Entertainment related
  'entertainment': Icons.movie,
  'movies': Icons.movie,
  
  // Other common categories
  'housing': Icons.home,
  'home': Icons.home,
  'education': Icons.school,
  'work': Icons.work,
  'gifts': Icons.card_giftcard,
  'savings': Icons.savings,
  'investment': Icons.trending_up,
  'insurance': Icons.security,
  'subscriptions': Icons.subscriptions,
  'pets': Icons.pets,
  'personal': Icons.person,
  'other': Icons.category,
};

/// List of selectable icons for the category picker UI
const List<MapEntry<String, IconData>> selectableIcons = [
  MapEntry('fastfood', Icons.fastfood),
  MapEntry('restaurant', Icons.restaurant),
  MapEntry('local_grocery_store', Icons.local_grocery_store),
  MapEntry('local_dining', Icons.local_dining),
  MapEntry('directions_car', Icons.directions_car),
  MapEntry('directions_bus', Icons.directions_bus),
  MapEntry('local_taxi', Icons.local_taxi),
  MapEntry('local_gas_station', Icons.local_gas_station),
  MapEntry('shopping_bag', Icons.shopping_bag),
  MapEntry('shopping_cart', Icons.shopping_cart),
  MapEntry('attach_money', Icons.attach_money),
  MapEntry('account_balance_wallet', Icons.account_balance_wallet),
  MapEntry('receipt_long', Icons.receipt_long),
  MapEntry('receipt', Icons.receipt),
  MapEntry('medical_services', Icons.medical_services),
  MapEntry('local_hospital', Icons.local_hospital),
  MapEntry('movie', Icons.movie),
  MapEntry('sports_esports', Icons.sports_esports),
  MapEntry('home', Icons.home),
  MapEntry('school', Icons.school),
  MapEntry('work', Icons.work),
  MapEntry('card_giftcard', Icons.card_giftcard),
  MapEntry('savings', Icons.savings),
  MapEntry('trending_up', Icons.trending_up),
  MapEntry('security', Icons.security),
  MapEntry('subscriptions', Icons.subscriptions),
  MapEntry('pets', Icons.pets),
  MapEntry('person', Icons.person),
  MapEntry('flight', Icons.flight),
  MapEntry('hotel', Icons.hotel),
  MapEntry('fitness_center', Icons.fitness_center),
  MapEntry('local_cafe', Icons.local_cafe),
  MapEntry('local_bar', Icons.local_bar),
  MapEntry('category', Icons.category),
];

/// Get icon for a category by its name (looks up in categoryIcons map)
/// Falls back to Icons.category if not found
IconData getCategoryIconByName(String categoryName) {
  final lowerName = categoryName.toLowerCase().trim();
  return categoryIcons[lowerName] ?? Icons.category;
}

/// Get soft background color for a category
/// Returns a soft, pastel color based on category type
Color getCategoryBackgroundColor(String categoryName) {
  final lowerName = categoryName.toLowerCase().trim();

  // Map categories to soft background colors
  final colorMap = <String, Color>{
    // Food related - warm orange/red tones
    'food': const Color(0xFFFFE5E5),
    'groceries': const Color(0xFFFFF3E0),
    'snacks': const Color(0xFFFFF8E1),
    'restaurant': const Color(0xFFFFF3E0),
    'dining': const Color(0xFFFFE5E5),

    // Transport related - blue tones
    'transport': const Color(0xFFE3F2FD),
    'transportation': const Color(0xFFE3F2FD),
    'fuel': const Color(0xFFBBDEFB),
    'taxi': const Color(0xFFE3F2FD),
    'uber': const Color(0xFFBBDEFB),
    'travel': const Color(0xFFE8F5E8),

    // Shopping related - purple/pink tones
    'shopping': const Color(0xFFF3E5F5),
    'clothes': const Color(0xFFF3E5F5),
    'clothing': const Color(0xFFF8BBD9),

    // Income related - green tones
    'salary': const Color(0xFFE8F5E8),
    'income': const Color(0xFFE8F5E8),
    'bonus': const Color(0xFFC8E6C9),

    // Bills related - gray/blue tones
    'bills': const Color(0xFFF5F5F5),
    'electricity': const Color(0xFFF5F5F5),
    'rent': const Color(0xFFECEFF1),
    'utilities': const Color(0xFFECEFF1),

    // Health related - light green tones
    'health': const Color(0xFFE8F5E8),
    'medical': const Color(0xFFE8F5E8),
    'healthcare': const Color(0xFFC8E6C9),

    // Entertainment related - purple tones
    'entertainment': const Color(0xFFF3E5F5),
    'movies': const Color(0xFFF3E5F5),

    // Other common categories
    'housing': const Color(0xFFFFF3E0),
    'home': const Color(0xFFFFF3E0),
    'education': const Color(0xFFE3F2FD),
    'work': const Color(0xFFECEFF1),
    'gifts': const Color(0xFFFFF8E1),
    'savings': const Color(0xFFE8F5E8),
    'investment': const Color(0xFFC8E6C9),
    'insurance': const Color(0xFFF5F5F5),
    'subscriptions': const Color(0xFFECEFF1),
    'pets': const Color(0xFFFFF8E1),
    'personal': const Color(0xFFFFE5E5),
    'other': const Color(0xFFF5F5F5),
  };

  return colorMap[lowerName] ?? const Color(0xFFF5F5F5); // Default soft gray
}

void showSnackBar(BuildContext context, String message) {
  final snackBar = SnackBar(content: Text(message));
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

/// Formats a currency amount using the Indian Numbering System
/// Example: 150000.50 becomes ₹1,50,000.50
String formatIndianCurrency(double amount, {String symbol = '₹'}) {
  // Create a custom number format for Indian numbering system
  final format = NumberFormat.currency(
    symbol: symbol,
    decimalDigits: 2,
    customPattern: '##,##,##0.00',
  );

  final formattedAmount = format.format(amount);

  // Ensure the symbol is included in the result
  if (!formattedAmount.startsWith(symbol)) {
    return '$symbol$formattedAmount';
  }

  return formattedAmount;
}

/// Formats a currency amount using the Indian Numbering System with compact notation
/// Example: 150000 becomes ₹1.5L
String formatIndianCurrencyCompact(double amount, {String symbol = '₹'}) {
  final format = NumberFormat.compactCurrency(
    symbol: symbol,
    decimalDigits: 2,
  );

  return format.format(amount);
}

/// Get IconData from icon name string
IconData? getIconData(String iconName) {
  // Map common icon names to Material Icons
  final iconMap = {
    'fastfood': Icons.fastfood,
    'attach_money': Icons.attach_money,
    'home': Icons.home,
    'receipt': Icons.receipt,
    'directions_bus': Icons.directions_bus,
    'shopping_bag': Icons.shopping_bag,
    'category': Icons.category,
    'work': Icons.work,
    'school': Icons.school,
    'local_hospital': Icons.local_hospital,
    'local_gas_station': Icons.local_gas_station,
    'restaurant': Icons.restaurant,
    'local_cafe': Icons.local_cafe,
    'local_movies': Icons.local_movies,
    'favorite': Icons.favorite,
    'star': Icons.star,
    'flight': Icons.flight,
    'hotel': Icons.hotel,
    'local_bar': Icons.local_bar,
    'local_pizza': Icons.local_pizza,
    'local_grocery_store': Icons.local_grocery_store,
    'local_pharmacy': Icons.local_pharmacy,
    'local_laundry_service': Icons.local_laundry_service,
    'local_taxi': Icons.local_taxi,
    'local_airport': Icons.local_airport,
    'local_atm': Icons.local_atm,
    'local_car_wash': Icons.local_car_wash,
    'local_convenience_store': Icons.local_convenience_store,
    'local_dining': Icons.local_dining,
    'local_drink': Icons.local_drink,
    'local_fire_department': Icons.local_fire_department,
    'local_florist': Icons.local_florist,
    'local_library': Icons.local_library,
    'local_mall': Icons.local_mall,
    'local_offer': Icons.local_offer,
    'local_parking': Icons.local_parking,
    'local_phone': Icons.local_phone,
    'local_play': Icons.local_play,
    'local_post_office': Icons.local_post_office,
    'local_printshop': Icons.local_printshop,
    'local_see': Icons.local_see,
    'local_shipping': Icons.local_shipping,
    'account_balance': Icons.account_balance,
    'account_balance_wallet': Icons.account_balance_wallet,
    'account_box': Icons.account_box,
    'account_circle': Icons.account_circle,
    'add_shopping_cart': Icons.add_shopping_cart,
    'airport_shuttle': Icons.airport_shuttle,
    'business_center': Icons.business_center,
    'card_giftcard': Icons.card_giftcard,
    'card_membership': Icons.card_membership,
    'card_travel': Icons.card_travel,
    'casino': Icons.casino,
    'child_friendly': Icons.child_friendly,
    'credit_card': Icons.credit_card,
    'directions_car': Icons.directions_car,
    'directions_train': Icons.directions_train,
    'directions_walk': Icons.directions_walk,
    'eco': Icons.eco,
    'electric_car': Icons.electric_car,
    'electric_moped': Icons.electric_moped,
    'electric_scooter': Icons.electric_scooter,
    'emoji_transportation': Icons.emoji_transportation,
    'golf_course': Icons.golf_course,
    'home_work': Icons.home_work,
    'local_activity': Icons.local_activity,
    'local_hotel': Icons.local_hotel,
    'money': Icons.money,
    'money_off': Icons.money_off,
    'monetization_on': Icons.monetization_on,
    'paid': Icons.paid,
    'payment': Icons.payment,
    'pets': Icons.pets,
    'piano': Icons.piano,
    'piano_off': Icons.piano_off,
    'punch_clock': Icons.punch_clock,
    'redeem': Icons.redeem,
    'restaurant_menu': Icons.restaurant_menu,
    'savings': Icons.savings,
    'science': Icons.science,
    'self_improvement': Icons.self_improvement,
    'shopping_basket': Icons.shopping_basket,
    'shopping_cart': Icons.shopping_cart,
    'sports': Icons.sports,
    'sports_baseball': Icons.sports_baseball,
    'sports_basketball': Icons.sports_basketball,
    'sports_cricket': Icons.sports_cricket,
    'sports_esports': Icons.sports_esports,
    'sports_football': Icons.sports_football,
    'sports_golf': Icons.sports_golf,
    'sports_handball': Icons.sports_handball,
    'sports_hockey': Icons.sports_hockey,
    'sports_kabaddi': Icons.sports_kabaddi,
    'sports_martial_arts': Icons.sports_martial_arts,
    'sports_mma': Icons.sports_mma,
    'sports_motorsports': Icons.sports_motorsports,
    'sports_rugby': Icons.sports_rugby,
    'sports_soccer': Icons.sports_soccer,
    'sports_tennis': Icons.sports_tennis,
    'sports_volleyball': Icons.sports_volleyball,
    'store': Icons.store,
    'store_mall_directory': Icons.store_mall_directory,
    'theater_comedy': Icons.theater_comedy,
    'train': Icons.train,
    'tram': Icons.tram,
    'transfer_within_a_station': Icons.transfer_within_a_station,
    'two_wheeler': Icons.two_wheeler,
    'workspaces': Icons.workspaces,
    'yard': Icons.yard,
  };

  return iconMap[iconName] ?? Icons.category;
}

/// Safely converts a color string to a Color object
/// Handles malformed color codes by sanitizing input before parsing
/// 
/// This function prevents FormatException crashes by:
/// 1. Removing all '#' characters from the input
/// 2. Ensuring proper hex format (8 characters for ARGB)
/// 3. Adding '0xFF' prefix if not present
/// 
/// Examples:
/// - '4CAF50' -> Color(0xFF4CAF50)
/// - '#4CAF50' -> Color(0xFF4CAF50)
/// - '0xFF4CAF50' -> Color(0xFF4CAF50)
/// - '0xFF#4CAF50' -> Color(0xFF4CAF50) [malformed input fixed]
Color stringToColor(String colorString) {
  if (colorString.isEmpty) {
    return Colors.grey; // Default fallback color
  }
  
  try {
    // Remove all '#' characters and whitespace
    String cleanColor = colorString.replaceAll('#', '').trim();
    
    // If already has 0x prefix, use as is
    if (cleanColor.startsWith('0x') || cleanColor.startsWith('0X')) {
      return Color(int.parse(cleanColor));
    }
    
    // If has 8 characters (including alpha), use as is
    if (cleanColor.length == 8) {
      return Color(int.parse('0x$cleanColor'));
    }
    
    // If has 6 characters (RGB), add alpha channel
    if (cleanColor.length == 6) {
      return Color(int.parse('0xFF$cleanColor'));
    }
    
    // Invalid format, return default color
    return Colors.grey;
  } catch (e) {
    // If parsing fails, return default color instead of crashing
    return Colors.grey;
  }
}
