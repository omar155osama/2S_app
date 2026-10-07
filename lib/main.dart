import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sales_odoo_app/core/di/injection.dart';
import 'package:sales_odoo_app/core/routes/app_router.dart';
import 'package:sales_odoo_app/core/theme/app_theme.dart';
import 'package:sales_odoo_app/core/theme/theme_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDI();
  runApp(const SalesOdooApp());
}

class SalesOdooApp extends StatefulWidget {
  final GoRouter? router;

  const SalesOdooApp({super.key, this.router});

  @override
  State<SalesOdooApp> createState() => _SalesOdooAppState();
}

class _SalesOdooAppState extends State<SalesOdooApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = widget.router ?? createAppRouter();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<ThemeCubit>(),
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: '2S Home Wear',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            routerConfig: _router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
