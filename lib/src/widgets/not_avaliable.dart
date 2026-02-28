import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/app_router.gr.dart';

@RoutePage()
class NotAvailableScreen extends StatelessWidget {
  const NotAvailableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon / Illustration
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.construction_rounded,
                    size: 80,
                    color: Colors.orange.shade800,
                  ),
                ),

                const SizedBox(height: 40),

                // Main title
                Text(
                  "Not Available",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Subtitle / explanation
                Text(
                  "This module is currently disabled in Testing mode.\n\n"
                  "It will become available once the app is in production or "
                  "when testing restrictions are removed.",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Optional action buttons
                FilledButton.icon(
                  onPressed: () {
                    // Option 1: Go back
                    context.router.maybePop();
                  },
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  label: const Text("Go Back"),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),

                const SizedBox(height: 16),

                OutlinedButton(
                  onPressed: () {
                    // Option 2: Go to home / dashboard
                    context.router.push(
                      DashboardRoute(),
                    ); // ← adjust route name
                  },
                  child: const Text("Back to Home"),
                ),

                const SizedBox(height: 80),

                // Small hint (optional)
                Text(
                  "Testing Mode • ${DateTime.now().year}",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
