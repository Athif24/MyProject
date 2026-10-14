import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_daily/core/widgets/app_bottom_nav.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    int currentIndex = 0;
    if (location.startsWith('/chat')) {
      currentIndex = 1;
    } else if (location.startsWith('/notes')) {
      currentIndex = 2;
    } else if (location.startsWith('/calendar')) {
      currentIndex = 3;
    } else {
      currentIndex = 0;
    }

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: AppBottomNav(
        currentIndex: currentIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/chat');
              break;
            case 2:
              context.go('/notes');
              break;
            case 3:
              context.go('/calendar');
              break;
            case 4:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Buat baru - akan diimplementasikan')),
              );
              break;
          }
        },
      ),
    );
  }
}
