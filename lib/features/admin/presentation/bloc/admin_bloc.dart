import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/admin_repository.dart';
import 'admin_event.dart';
import 'admin_state.dart';

/// BLoC managing admin dashboard, menu, and staff operations.
class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepository _repository;

  AdminBloc({required AdminRepository repository})
      : _repository = repository,
        super(const AdminInitial()) {
    on<AdminLoadDashboard>(_onLoadDashboard);
    on<AdminLoadHourlyChart>(_onLoadHourlyChart);
    on<AdminLoadPaymentBreakdown>(_onLoadPaymentBreakdown);
    on<AdminLoadOutletComparison>(_onLoadOutletComparison);
    on<AdminLoadProducts>(_onLoadProducts);
    on<AdminCreateProduct>(_onCreateProduct);
    on<AdminUpdateProduct>(_onUpdateProduct);
    on<AdminDeleteProduct>(_onDeleteProduct);
    on<AdminLoadStaff>(_onLoadStaff);
    on<AdminCreateStaff>(_onCreateStaff);
    on<AdminUpdateStaff>(_onUpdateStaff);
    on<AdminRefresh>(_onRefresh);
  }

  void _onLoadDashboard(
    AdminLoadDashboard event,
    Emitter<AdminState> emit,
  ) async {
    emit(const AdminLoading());

    final result =
        await _repository.getTodaySalesSummary(outletId: event.outletId);

    result.fold(
      ifLeft: (failure) => emit(AdminError(failure.message)),
      ifRight: (summary) => emit(AdminDashboardLoaded(
        summary: summary,
      )),
    );

    // Load chart and breakdown in parallel
    add(AdminLoadHourlyChart(
      outletId: event.outletId,
      date: DateTime.now(),
    ));
    add(AdminLoadPaymentBreakdown(
      outletId: event.outletId,
      startDate: DateTime.now().subtract(const Duration(days: 7)),
      endDate: DateTime.now(),
    ));
  }

  void _onLoadHourlyChart(
    AdminLoadHourlyChart event,
    Emitter<AdminState> emit,
  ) async {
    final current = state;
    if (current is! AdminDashboardLoaded) return;

    emit(current.copyWith(isLoadingChart: true));

    final result = await _repository.getHourlySales(
      outletId: event.outletId,
      date: event.date,
    );

    result.fold(
      ifLeft: (failure) => emit(current.copyWith(
        isLoadingChart: false,
        errorMessage: failure.message,
      )),
      ifRight: (hourly) => emit(current.copyWith(
        hourlySales: hourly,
        isLoadingChart: false,
        clearError: true,
      )),
    );
  }

  void _onLoadPaymentBreakdown(
    AdminLoadPaymentBreakdown event,
    Emitter<AdminState> emit,
  ) async {
    final current = state;
    if (current is! AdminDashboardLoaded) return;

    emit(current.copyWith(isLoadingBreakdown: true));

    final result = await _repository.getSalesByPaymentMethod(
      outletId: event.outletId,
      startDate: event.startDate,
      endDate: event.endDate,
    );

    result.fold(
      ifLeft: (failure) => emit(current.copyWith(
        isLoadingBreakdown: false,
        errorMessage: failure.message,
      )),
      ifRight: (breakdown) => emit(current.copyWith(
        paymentBreakdown: breakdown,
        isLoadingBreakdown: false,
        clearError: true,
      )),
    );
  }

  void _onLoadOutletComparison(
    AdminLoadOutletComparison event,
    Emitter<AdminState> emit,
  ) async {
    final current = state;
    if (current is! AdminDashboardLoaded) return;

    emit(current.copyWith(isLoadingOutletComparison: true));

    final result = await _repository.getSalesByOutlet(
      organizationId: event.organizationId,
      startDate: event.startDate,
      endDate: event.endDate,
    );

    result.fold(
      ifLeft: (failure) => emit(current.copyWith(
        isLoadingOutletComparison: false,
        errorMessage: failure.message,
      )),
      ifRight: (outlets) => emit(current.copyWith(
        outletComparison: outlets,
        isLoadingOutletComparison: false,
        clearError: true,
      )),
    );
  }

  void _onLoadProducts(
    AdminLoadProducts event,
    Emitter<AdminState> emit,
  ) async {
    emit(const AdminProductsLoaded(isLoading: true));

    // Use Supabase directly via repository — but we need a products fetch
    // For now, use the existing ProductRepository pattern
    // This is a simplified version that fetches via Supabase
    try {
      // Note: In production, this would use a dedicated method
      // For now, emit empty list — the UI will use ProductRepository
      emit(const AdminProductsLoaded(products: []));
    } catch (e) {
      emit(const AdminProductsLoaded(
        errorMessage: 'Gagal memuat produk',
      ));
    }
  }

  void _onCreateProduct(
    AdminCreateProduct event,
    Emitter<AdminState> emit,
  ) async {
    final current = state;
    if (current is! AdminProductsLoaded) return;

    emit(current.copyWith(isLoading: true));

    final result = await _repository.createProduct(
      outletId: event.outletId,
      name: event.name,
      basePrice: event.basePrice,
      categoryId: event.categoryId,
      description: event.description,
    );

    result.fold(
      ifLeft: (failure) => emit(current.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      )),
      ifRight: (_) {
        // Reload products
        add(AdminLoadProducts(outletId: event.outletId));
      },
    );
  }

  void _onUpdateProduct(
    AdminUpdateProduct event,
    Emitter<AdminState> emit,
  ) async {
    final current = state;
    if (current is! AdminProductsLoaded) return;

    emit(current.copyWith(isLoading: true));

    final result = await _repository.updateProduct(
      productId: event.productId,
      name: event.name,
      basePrice: event.basePrice,
      categoryId: event.categoryId,
      description: event.description,
      isAvailable: event.isAvailable,
    );

    result.fold(
      ifLeft: (failure) => emit(current.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      )),
      ifRight: (_) => emit(current.copyWith(
        isLoading: false,
        clearError: true,
      )),
    );
  }

  void _onDeleteProduct(
    AdminDeleteProduct event,
    Emitter<AdminState> emit,
  ) async {
    final current = state;
    if (current is! AdminProductsLoaded) return;

    emit(current.copyWith(isLoading: true));

    final result =
        await _repository.deleteProduct(productId: event.productId);

    result.fold(
      ifLeft: (failure) => emit(current.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      )),
      ifRight: (_) {
        add(AdminLoadProducts(outletId: event.outletId));
      },
    );
  }

  void _onLoadStaff(
    AdminLoadStaff event,
    Emitter<AdminState> emit,
  ) async {
    emit(const AdminStaffLoaded(isLoading: true));

    final result = await _repository.getStaff(outletId: event.outletId);

    result.fold(
      ifLeft: (failure) => emit(AdminStaffLoaded(
        errorMessage: failure.message,
      )),
      ifRight: (staff) => emit(AdminStaffLoaded(staff: staff)),
    );
  }

  void _onCreateStaff(
    AdminCreateStaff event,
    Emitter<AdminState> emit,
  ) async {
    final current = state;
    if (current is! AdminStaffLoaded) return;

    emit(current.copyWith(isLoading: true));

    final result = await _repository.createStaff(
      outletId: event.outletId,
      name: event.name,
      phone: event.phone,
      role: event.role,
      pinHash: event.pinHash,
    );

    result.fold(
      ifLeft: (failure) => emit(current.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      )),
      ifRight: (_) {
        add(AdminLoadStaff(outletId: event.outletId));
      },
    );
  }

  void _onUpdateStaff(
    AdminUpdateStaff event,
    Emitter<AdminState> emit,
  ) async {
    final current = state;
    if (current is! AdminStaffLoaded) return;

    emit(current.copyWith(isLoading: true));

    final result = await _repository.updateStaff(
      staffId: event.staffId,
      name: event.name,
      phone: event.phone,
      role: event.role,
      isActive: event.isActive,
    );

    result.fold(
      ifLeft: (failure) => emit(current.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      )),
      ifRight: (_) => emit(current.copyWith(
        isLoading: false,
        clearError: true,
      )),
    );
  }

  void _onRefresh(
    AdminRefresh event,
    Emitter<AdminState> emit,
  ) {
    add(AdminLoadDashboard(outletId: event.outletId));
  }
}
