import 'package:flutter/material.dart';

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Reduced from 16
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16, // Reduced from 18
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  icon,
                  color: color,
                ),
              ],
            ),
            const SizedBox(height: 12), // Reduced from 16
            Text(
              value,
              style: const TextStyle(
                fontSize: 22, // Reduced from 24
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
