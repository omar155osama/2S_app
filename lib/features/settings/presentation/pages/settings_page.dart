import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sales_odoo_app/core/di/injection.dart';
import 'package:sales_odoo_app/core/network/session_manager.dart';
import 'package:sales_odoo_app/core/theme/app_theme.dart';
import 'package:sales_odoo_app/core/theme/theme_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Log out?'),
          content: const Text('Are you sure you want to log out?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                sl<SessionManager>().currentUser = null;
                context.go('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Log out'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = sl<SessionManager>().currentUser;
    final String initial = session?.uid.toString() ?? '?';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.primarySoft,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'User ${session?.uid ?? 'Unknown'}',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  session?.isInternalUser == true
                      ? 'Internal User'
                      : 'External User',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.mega),
          Text(
            'Preferences',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            clipBehavior: Clip.antiAlias,
            child: BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, themeMode) {
                final isDark = themeMode == ThemeMode.dark;
                return SwitchListTile(
                  title: const Text(
                    'Dark Theme',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  secondary: Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    color: AppColors.primary,
                  ),
                  value: isDark,
                  onChanged: (_) {
                    context.read<ThemeCubit>().toggleTheme();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Account',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.errorSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.logout,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
              title: const Text(
                'Log out',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Sign out from this account',
                style: TextStyle(
                  color: AppColors.error.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
              onTap: () => _showLogoutDialog(context),
            ),
          ),
        ],
      ),
    );
  }
}
