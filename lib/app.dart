import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/generated/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/di/injection.dart';
import 'core/utils/responsive_helper.dart';
import 'features/pos/presentation/pages/pos_screen.dart';
import 'features/kitchen/presentation/pages/kitchen_screen.dart';
import 'features/customer/customer_catalog_screen.dart';
import 'features/loyalty/loyalty_screen.dart';
import 'features/driver/presentation/pages/driver_screen.dart';
import 'features/admin/presentation/pages/admin_screen.dart';
import 'features/printer_config/printer_config_screen.dart';

class PostSAApp extends StatefulWidget {
  const PostSAApp({super.key});

  @override
  State<PostSAApp> createState() => _PostSAAppState();
}

class _PostSAAppState extends State<PostSAApp> {
  late final ThemeController _themeController;

  @override
  void initState() {
    super.initState();
    _themeController = getIt<ThemeController>();
    _themeController.loadThemeMode();
    _themeController.addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _themeController.removeListener(_onThemeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PostSA Flutter POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeController.themeMode,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id'),
        Locale('en'),
      ],
      home: const MainNavigationShell(),
    );
  }
}

/// All screens in the app, indexed by their position.
class _ScreenIndex {
  static const int pos = 0;
  static const int kitchen = 1;
  static const int catalog = 2;
  static const int loyalty = 3;
  static const int driver = 4;
  static const int admin = 5;
  static const int printer = 6;
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    POSScreen(),
    KitchenScreen(outletId: '00000000-0000-0000-0000-000000000001'),
    CustomerCatalogScreen(),
    LoyaltyScreen(),
    DriverScreen(driverId: '00000000-0000-0000-0000-000000000002'),
    AdminScreen(outletId: '00000000-0000-0000-0000-000000000001'),
    PrinterConfigScreen(),
  ];

  // Main nav items (max 5 for NavigationBar).
  // Secondary items accessible via "More" bottom sheet.
  static const _mainNavIndexes = [
    _ScreenIndex.pos,
    _ScreenIndex.kitchen,
    _ScreenIndex.admin,
    _ScreenIndex.catalog,
  ];

  static const _moreNavIndexes = [
    _ScreenIndex.loyalty,
    _ScreenIndex.driver,
    _ScreenIndex.printer,
  ];

  @override
  Widget build(BuildContext context) {
    final useRail = ResponsiveHelper.useNavigationRail(context);

    if (useRail) {
      return _DesktopLayout(
        currentIndex: _currentIndex,
        onIndexChanged: (idx) => setState(() => _currentIndex = idx),
      );
    }

    final l10n = AppLocalizations.of(context)!;
    // Determine which main nav index is selected (or -1 if current screen is in "More").
    final selectedMainIndex = _mainNavIndexes.indexOf(_currentIndex);
    final isMoreSelected = _moreNavIndexes.contains(_currentIndex);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: isMoreSelected ? _mainNavIndexes.length : selectedMainIndex,
        onDestinationSelected: (idx) {
          if (idx < _mainNavIndexes.length) {
            setState(() => _currentIndex = _mainNavIndexes[idx]);
          } else {
            _showMoreSheet(context, l10n);
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.point_of_sale),
            selectedIcon: const Icon(Icons.point_of_sale),
            label: l10n.pos,
          ),
          NavigationDestination(
            icon: const Icon(Icons.soup_kitchen_outlined),
            selectedIcon: const Icon(Icons.soup_kitchen),
            label: l10n.kitchen,
          ),
          NavigationDestination(
            icon: const Icon(Icons.analytics_outlined),
            selectedIcon: const Icon(Icons.analytics),
            label: l10n.admin,
          ),
          NavigationDestination(
            icon: const Icon(Icons.restaurant_menu_outlined),
            selectedIcon: const Icon(Icons.restaurant_menu),
            label: l10n.catalog,
          ),
          NavigationDestination(
            icon: Icon(isMoreSelected
                ? Icons.more_horiz
                : Icons.more_horiz_outlined),
            label: 'More',
          ),
        ],
      ),
    );
  }

  void _showMoreSheet(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'More',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.stars),
              title: Text(l10n.loyalty),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _currentIndex = _ScreenIndex.loyalty);
              },
            ),
            ListTile(
              leading: const Icon(Icons.two_wheeler),
              title: Text(l10n.driver),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _currentIndex = _ScreenIndex.driver);
              },
            ),
            ListTile(
              leading: const Icon(Icons.print),
              title: Text(l10n.printer),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _currentIndex = _ScreenIndex.printer);
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
              title: Text(
                Theme.of(context).brightness == Brightness.dark
                    ? l10n.lightMode
                    : l10n.darkMode,
              ),
              onTap: () {
                Navigator.pop(ctx);
                getIt<ThemeController>().toggleTheme();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Desktop/tablet layout with a navigation rail showing all items.
class _DesktopLayout extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  const _DesktopLayout({
    required this.currentIndex,
    required this.onIndexChanged,
  });

  static const _allItems = <_NavItem>[
    _NavItem(icon: Icons.point_of_sale, labelKey: 'pos', screenIndex: _ScreenIndex.pos),
    _NavItem(icon: Icons.soup_kitchen, labelKey: 'kitchen', screenIndex: _ScreenIndex.kitchen),
    _NavItem(icon: Icons.restaurant_menu, labelKey: 'catalog', screenIndex: _ScreenIndex.catalog),
    _NavItem(icon: Icons.stars, labelKey: 'loyalty', screenIndex: _ScreenIndex.loyalty),
    _NavItem(icon: Icons.two_wheeler, labelKey: 'driver', screenIndex: _ScreenIndex.driver),
    _NavItem(icon: Icons.analytics, labelKey: 'admin', screenIndex: _ScreenIndex.admin),
    _NavItem(icon: Icons.print, labelKey: 'printer', screenIndex: _ScreenIndex.printer),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = {
      'pos': l10n.pos,
      'kitchen': l10n.kitchen,
      'catalog': l10n.catalog,
      'loyalty': l10n.loyalty,
      'driver': l10n.driver,
      'admin': l10n.admin,
      'printer': l10n.printer,
    };

    return Scaffold(
      body: Row(
        children: [
          // Navigation rail
          Container(
            width: 220,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // App header
                Container(
                  height: 80,
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.appName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const Divider(height: 1),
                // Nav items
                Expanded(
                  child: ListView.builder(
                    itemCount: _allItems.length,
                    itemBuilder: (context, index) {
                      final item = _allItems[index];
                      final selected = item.screenIndex == currentIndex;
                      return ListTile(
                        leading: Icon(
                          item.icon,
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        title: Text(
                          labels[item.labelKey] ?? item.labelKey,
                          style: TextStyle(
                            color: selected
                                ? Theme.of(context).colorScheme.primary
                                : null,
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: selected,
                        onTap: () => onIndexChanged(item.screenIndex),
                      );
                    },
                  ),
                ),
                // Theme toggle
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Theme.of(context).brightness == Brightness.dark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                  ),
                  title: Text(
                    Theme.of(context).brightness == Brightness.dark
                        ? l10n.lightMode
                        : l10n.darkMode,
                  ),
                  onTap: () => getIt<ThemeController>().toggleTheme(),
                ),
              ],
            ),
          ),
          // Main content — all screens via IndexedStack
          Expanded(
            child: IndexedStack(
              index: currentIndex,
              children: const [
                POSScreen(),
                KitchenScreen(outletId: '00000000-0000-0000-0000-000000000001'),
                CustomerCatalogScreen(),
                LoyaltyScreen(),
                DriverScreen(driverId: '00000000-0000-0000-0000-000000000002'),
                AdminScreen(outletId: '00000000-0000-0000-0000-000000000001'),
                PrinterConfigScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String labelKey;
  final int screenIndex;

  const _NavItem({
    required this.icon,
    required this.labelKey,
    required this.screenIndex,
  });
}
