import 'package:equatable/equatable.dart';
import '../../domain/repositories/admin_repository.dart';

sealed class AdminState extends Equatable {
  const AdminState();

  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {
  const AdminInitial();
}

class AdminLoading extends AdminState {
  const AdminLoading();
}

/// Dashboard state with analytics data.
class AdminDashboardLoaded extends AdminState {
  final SalesSummary? summary;
  final List<HourlySales> hourlySales;
  final List<PaymentMethodSummary> paymentBreakdown;
  final List<OutletSalesSummary> outletComparison;
  final bool isLoadingChart;
  final bool isLoadingBreakdown;
  final bool isLoadingOutletComparison;
  final String? errorMessage;

  const AdminDashboardLoaded({
    this.summary,
    this.hourlySales = const [],
    this.paymentBreakdown = const [],
    this.outletComparison = const [],
    this.isLoadingChart = false,
    this.isLoadingBreakdown = false,
    this.isLoadingOutletComparison = false,
    this.errorMessage,
  });

  AdminDashboardLoaded copyWith({
    SalesSummary? summary,
    List<HourlySales>? hourlySales,
    List<PaymentMethodSummary>? paymentBreakdown,
    List<OutletSalesSummary>? outletComparison,
    bool? isLoadingChart,
    bool? isLoadingBreakdown,
    bool? isLoadingOutletComparison,
    String? errorMessage,
    bool clearError = false,
  }) =>
      AdminDashboardLoaded(
        summary: summary ?? this.summary,
        hourlySales: hourlySales ?? this.hourlySales,
        paymentBreakdown:
            paymentBreakdown ?? this.paymentBreakdown,
        outletComparison:
            outletComparison ?? this.outletComparison,
        isLoadingChart: isLoadingChart ?? this.isLoadingChart,
        isLoadingBreakdown:
            isLoadingBreakdown ?? this.isLoadingBreakdown,
        isLoadingOutletComparison:
            isLoadingOutletComparison ?? this.isLoadingOutletComparison,
        errorMessage:
            clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [
        summary,
        hourlySales,
        paymentBreakdown,
        outletComparison,
        isLoadingChart,
        isLoadingBreakdown,
        isLoadingOutletComparison,
        errorMessage,
      ];
}

/// Products management state.
class AdminProductsLoaded extends AdminState {
  final List<Map<String, dynamic>> products;
  final bool isLoading;
  final String? errorMessage;

  const AdminProductsLoaded({
    this.products = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  AdminProductsLoaded copyWith({
    List<Map<String, dynamic>>? products,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) =>
      AdminProductsLoaded(
        products: products ?? this.products,
        isLoading: isLoading ?? this.isLoading,
        errorMessage:
            clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [products, isLoading, errorMessage];
}

/// Staff management state.
class AdminStaffLoaded extends AdminState {
  final List<Map<String, dynamic>> staff;
  final bool isLoading;
  final String? errorMessage;

  const AdminStaffLoaded({
    this.staff = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  AdminStaffLoaded copyWith({
    List<Map<String, dynamic>>? staff,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) =>
      AdminStaffLoaded(
        staff: staff ?? this.staff,
        isLoading: isLoading ?? this.isLoading,
        errorMessage:
            clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [staff, isLoading, errorMessage];
}

class AdminError extends AdminState {
  final String message;
  const AdminError(this.message);

  @override
  List<Object?> get props => [message];
}
