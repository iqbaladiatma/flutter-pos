import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../database/sync_queue_service.dart';
import '../network/connectivity_service.dart';
import '../network/supabase_service.dart';
import '../printer/thermal_printer_service.dart';
import '../repositories/order_repository.dart';
import '../repositories/product_repository.dart';
import '../theme/theme_controller.dart';
import '../../features/cashier_shift/data/repositories/cashier_shift_repository_impl.dart';
import '../../features/cashier_shift/domain/repositories/cashier_shift_repository.dart';
import '../../features/customer/data/repositories/customer_auth_repository_impl.dart';
import '../../features/customer/data/repositories/customer_catalog_repository_impl.dart';
import '../../features/customer/data/repositories/customer_delivery_repository_impl.dart';
import '../../features/customer/data/repositories/customer_loyalty_repository_impl.dart';
import '../../features/customer/domain/repositories/customer_auth_repository.dart';
import '../../features/customer/domain/repositories/customer_catalog_repository.dart';
import '../../features/customer/domain/repositories/customer_delivery_repository.dart';
import '../../features/customer/domain/repositories/customer_loyalty_repository.dart';
import '../../features/admin/data/repositories/admin_repository_impl.dart';
import '../../features/admin/domain/repositories/admin_repository.dart';
import '../../features/auth/data/repositories/staff_auth_repository_impl.dart';
import '../../features/auth/domain/repositories/staff_auth_repository.dart';
import '../../features/driver/data/repositories/driver_repository_impl.dart';
import '../../features/driver/domain/repositories/driver_repository.dart';
import '../../features/kitchen/data/repositories/kitchen_repository_impl.dart';
import '../../features/kitchen/domain/repositories/kitchen_repository.dart';
import '../../features/pos/data/datasources/pos_local_data_source.dart';
import '../../features/pos/data/repositories/pos_repository_impl.dart';
import '../../features/pos/domain/repositories/pos_repository.dart';

/// Global service locator instance.
final GetIt getIt = GetIt.instance;

/// Registers all dependencies (services, repositories) into the [getIt]
/// container. Call once in `main()` before `runApp()`.
///
/// Registration strategy:
/// - **Singletons** for stateful services (Supabase, Printer, Database).
/// - **Lazy singletons** for repositories (created on first access).
Future<void> setupDependencies() async {
  // ── Services ──────────────────────────────────────────────────────
  final supabaseService = SupabaseService();
  await supabaseService.init();
  getIt.registerSingleton<SupabaseService>(supabaseService);

  getIt.registerSingleton<ThermalPrinterService>(ThermalPrinterService());

  // Offline-first: Drift database + sync queue
  final database = AppDatabase();
  getIt.registerSingleton<AppDatabase>(database);

  getIt.registerSingleton<ConnectivityService>(ConnectivityService.instance);

  getIt.registerSingleton<SyncQueueService>(
    SyncQueueService(database: database),
  );

  // Utilities
  getIt.registerLazySingleton<Uuid>(() => const Uuid());

  // ── Repositories (legacy — will be migrated to feature-scoped DI) ──
  getIt.registerLazySingleton<OrderRepository>(
    () => OrderRepository(),
  );
  getIt.registerLazySingleton<ProductRepository>(
    () => ProductRepository(),
  );

  // ── Feature: POS (Clean Architecture + offline-first) ─────────────
  getIt.registerLazySingleton<PosLocalDataSource>(
    () => PosLocalDataSource(getIt<AppDatabase>()),
  );
  getIt.registerLazySingleton<PosRepository>(
    () => PosRepositoryImpl(
      database: getIt<AppDatabase>(),
      connectivityService: getIt<ConnectivityService>(),
      syncQueueService: getIt<SyncQueueService>(),
      uuid: getIt<Uuid>(),
    ),
  );

  // ── Feature: Cashier Shift ────────────────────────────────────────
  getIt.registerLazySingleton<CashierShiftRepository>(
    () => CashierShiftRepositoryImpl(
      connectivity: getIt<ConnectivityService>(),
    ),
  );

  // ── Feature: Kitchen Display System (KDS) ─────────────────────────
  getIt.registerLazySingleton<KitchenRepository>(
    () => KitchenRepositoryImpl(),
  );

  // ── Feature: Customer (Auth, Catalog, Loyalty, Delivery) ─────────
  getIt.registerLazySingleton<CustomerAuthRepository>(
    () => CustomerAuthRepositoryImpl(),
  );
  getIt.registerLazySingleton<CustomerCatalogRepository>(
    () => CustomerCatalogRepositoryImpl(),
  );
  getIt.registerLazySingleton<CustomerLoyaltyRepository>(
    () => CustomerLoyaltyRepositoryImpl(),
  );
  getIt.registerLazySingleton<CustomerDeliveryRepository>(
    () => CustomerDeliveryRepositoryImpl(),
  );

  // ── Feature: Driver App ───────────────────────────────────────────
  getIt.registerLazySingleton<DriverRepository>(
    () => DriverRepositoryImpl(),
  );

  // ── Feature: Admin Dashboard ──────────────────────────────────────
  getIt.registerLazySingleton<AdminRepository>(
    () => AdminRepositoryImpl(),
  );

  // ── Feature: Auth & Security ──────────────────────────────────────
  getIt.registerLazySingleton<StaffAuthRepository>(
    () => StaffAuthRepositoryImpl(),
  );

  // ── Theme Controller ──────────────────────────────────────────────
  getIt.registerLazySingleton<ThemeController>(
    () => ThemeController(),
  );
}
