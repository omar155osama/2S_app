import 'package:flutter/material.dart';

import 'package:sales_odoo_app/core/di/injection.dart';
import 'package:sales_odoo_app/core/network/session_manager.dart';
import 'package:sales_odoo_app/features/customers/presentation/pages/customer_list_page.dart';
import 'package:sales_odoo_app/features/sales_orders/presentation/pages/sales_order_list_page.dart';
import 'package:sales_odoo_app/features/settings/presentation/pages/settings_page.dart';

class MainLayoutPage extends StatefulWidget {
  final int initialIndex;
  const MainLayoutPage({super.key, this.initialIndex = 0});

  @override
  State<MainLayoutPage> createState() => _MainLayoutPageState();
}

class _MainLayoutPageState extends State<MainLayoutPage> {
  late int _currentIndex;
  late bool _isInternal;

  final List<Widget> _internalPages = [
    const CustomerListPage(),
    const SalesOrderListPage(),
    const SettingsPage(),
  ];

  final List<Widget> _externalPages = [
    const CustomerListPage(),
    const SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _isInternal = sl<SessionManager>().currentUser?.isInternalUser ?? false;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = _isInternal ? _internalPages : _externalPages;
    if (_currentIndex >= pages.length) {
      _currentIndex = 0;
    }

    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.dividerColor, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTabTapped,
          elevation: 0,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Customers',
            ),
            if (_isInternal)
              const NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Sales',
              ),
            const NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
