import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sales_odoo_app/core/di/injection.dart';
import 'package:sales_odoo_app/core/network/session_manager.dart';
import 'package:sales_odoo_app/core/theme/app_theme.dart';

class AuthenticatedAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;

  const AuthenticatedAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final session = sl<SessionManager>().currentUser;
    final String initial = session?.uid.toString() ?? '?';

    return AppBar(
      title: Text(title, style: Theme.of(context).textTheme.displaySmall),
      centerTitle: false,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          child: InkWell(
            onTap: () {
              // We could navigate to a settings route or just switch the bottom nav tab if we wanted,
              // but since Settings is a tab, pushing a separate settings page over might be confusing.
              // We'll just switch the MainLayout tab by using an inherited widget or simply rely on
              // the fact that Settings is available in the bottom nav.
              // Wait, the prompt says "tappable to Settings".
              // We'll push the settings page on top if we use ShellRoute, but since we use IndexedStack,
              // maybe we should just create a standalone route for Settings or push a dialog.
              // Let's create a quick standalone push.
              context.push('/settings');
            },
            borderRadius: BorderRadius.circular(20),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primarySoft,
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
