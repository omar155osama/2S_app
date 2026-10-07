import 'package:go_router/go_router.dart';
import 'package:sales_odoo_app/core/di/injection.dart';
import 'package:sales_odoo_app/core/network/session_manager.dart';
import 'package:sales_odoo_app/features/auth/presentation/pages/login_page.dart';
import 'package:sales_odoo_app/features/customers/presentation/pages/customer_details_page.dart';
import 'package:sales_odoo_app/features/home/presentation/pages/main_layout_page.dart';
import 'package:sales_odoo_app/features/sales_orders/presentation/pages/sales_order_details_page.dart';
import 'package:sales_odoo_app/features/settings/presentation/pages/settings_page.dart';
import 'package:sales_odoo_app/features/splash/presentation/pages/splash_screen.dart';

GoRouter createAppRouter({String initialLocation = '/splash'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/home', builder: (context, state) => const MainLayoutPage()),
    // Map old routes to /home for compatibility or just leave as is, but we redirect top-level links
    GoRoute(path: '/customers', redirect: (context, state) => '/home'),
    GoRoute(path: '/sales_orders', redirect: (context, state) => '/home'),
    GoRoute(
      path: '/customer_details',
      builder: (context, state) {
        final id = state.extra as int? ?? 0;
        return CustomerDetailsPage(customerId: id);
      },
    ),
    GoRoute(
      path: '/sales_order_details/:id',
      redirect: (context, state) {
        final session = sl<SessionManager>().currentUser;
        if (session == null) return '/login';
        if (!session.isInternalUser) return '/home';
        return null;
      },
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
        return SalesOrderDetailsPage(orderId: id);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
  ],
);

final GoRouter appRouter = createAppRouter();
