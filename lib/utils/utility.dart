import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


void showSnackBar(BuildContext context, String message) {
  final snackBar = SnackBar(
    content: Text(message),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

void showErrorSnackBar(BuildContext context, String message) {
  final snackBar = SnackBar(
    content: Text(message),
    backgroundColor: const Color(0xFFEF4444), // Consistent error red
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    action: SnackBarAction(
      label: 'Dismiss',
      textColor: Colors.white,
      onPressed: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      },
    ),
  );
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
