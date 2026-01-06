import 'package:flutter/material.dart';

class RouteListScreen extends StatelessWidget {
  const RouteListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // A more robust way to get routes is to access them from the MaterialApp directly if possible,
    // but that's not directly exposed here. For demonstration, we'll assume routes are passed or
    // we can infer them from app.dart if we had access to its routes map.
    // For now, we'll use a placeholder and assume routes are passed or hardcoded for this example.

    // In a real app, you'd likely pass the routes map from app.dart or access it differently.
    final routes = ModalRoute.of(context)?.settings.arguments as Map<String, WidgetBuilder>? ?? {};
    final routeNames = routes.keys.toList();

    // Group routes by feature
    final transactionRoutes = routeNames.where((name) => name.contains('Transaction') || name.contains('categories')).toList();
    final budgetRoutes = routeNames.where((name) => name.contains('Budget')).toList();
    final savingsRoutes = routeNames.where((name) => name.contains('Savings')).toList();
    final otherRoutes = routeNames.where((name) => !transactionRoutes.contains(name) && !budgetRoutes.contains(name) && !savingsRoutes.contains(name)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All App Routes'),
      ),
      body: ListView(
        children: [
          _buildRouteSection(context, 'Transactions', transactionRoutes),
          _buildRouteSection(context, 'Budgets', budgetRoutes),
          _buildRouteSection(context, 'Savings Goals', savingsRoutes),
          _buildRouteSection(context, 'Other', otherRoutes),
        ],
      ),
    );
  }

  Widget _buildRouteSection(BuildContext context, String title, List<String> routes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        ...routes.map((routeName) => ListTile(
              title: Text(routeName),
              onTap: () {
                Navigator.pushNamed(context, routeName);
              },
            )),
      ],
    );
  }
}
