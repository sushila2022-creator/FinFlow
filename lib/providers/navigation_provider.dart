import 'package:flutter/material.dart';

class NavigationProvider with ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void setTab(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  // Helper to switch to specific tabs by name/context if needed
  void switchToDashboard() => setTab(0);
  void switchToTransactions() => setTab(1);
  void switchToAnalytics() => setTab(2);
  void switchToSettings() => setTab(3);
}
