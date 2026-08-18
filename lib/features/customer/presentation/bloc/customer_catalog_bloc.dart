import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/models/product_model.dart';
import '../../domain/repositories/customer_catalog_repository.dart';
import 'customer_catalog_event.dart';
import 'customer_catalog_state.dart';

/// BLoC managing customer catalog browsing and QR table scanning.
class CustomerCatalogBloc
    extends Bloc<CustomerCatalogEvent, CustomerCatalogState> {
  final CustomerCatalogRepository _repository;
  String? _outletId;

  CustomerCatalogBloc({required CustomerCatalogRepository repository})
      : _repository = repository,
        super(const CustomerCatalogInitial()) {
    on<CustomerCatalogLoad>(_onLoad);
    on<CustomerCatalogFilter>(_onFilter);
    on<CustomerCatalogScanQr>(_onScanQr);
    on<CustomerCatalogClearTable>(_onClearTable);
  }

  void _onLoad(
    CustomerCatalogLoad event,
    Emitter<CustomerCatalogState> emit,
  ) async {
    _outletId = event.outletId;
    emit(const CustomerCatalogLoading());

    final catResult =
        await _repository.getOutletCategories(outletId: event.outletId);
    final prodResult =
        await _repository.getOutletProducts(outletId: event.outletId);
    final bannerResult =
        await _repository.getBanners(outletId: event.outletId);

    List<CategoryModel> categories = [];
    List<ProductModel> products = [];
    List<Banner> banners = [];

    catResult.fold(
      ifLeft: (_) {},
      ifRight: (cats) => categories = cats,
    );
    prodResult.fold(
      ifLeft: (_) {},
      ifRight: (prods) => products = prods,
    );
    bannerResult.fold(
      ifLeft: (_) {},
      ifRight: (bns) => banners = bns,
    );

    if (categories.isEmpty && products.isEmpty) {
      emit(CustomerCatalogError(
        catResult.fold(
          ifLeft: (f) => f.message,
          ifRight: (_) => 'Gagal memuat katalog',
        ),
      ));
      return;
    }

    emit(CustomerCatalogLoaded(
      categories: categories,
      products: products,
      banners: banners,
    ));
  }

  void _onFilter(
    CustomerCatalogFilter event,
    Emitter<CustomerCatalogState> emit,
  ) async {
    final current = state;
    if (current is! CustomerCatalogLoaded || _outletId == null) return;

    final result = await _repository.getOutletProducts(
      outletId: _outletId!,
      categoryId: event.categoryId,
    );

    result.fold(
      ifLeft: (failure) =>
          emit(CustomerCatalogError(failure.message)),
      ifRight: (products) => emit(current.copyWith(
        products: products,
        selectedCategoryId: event.categoryId,
        clearFilter: event.categoryId == null,
      )),
    );
  }

  void _onScanQr(
    CustomerCatalogScanQr event,
    Emitter<CustomerCatalogState> emit,
  ) async {
    final current = state;
    if (current is! CustomerCatalogLoaded) return;

    emit(current.copyWith(isScanning: true));

    final result = await _repository.getTableByQrCode(
      outletId: event.outletId,
      qrCode: event.qrCode,
    );

    result.fold(
      ifLeft: (failure) {
        emit(current.copyWith(isScanning: false));
        emit(CustomerCatalogError(failure.message));
        // Re-emit loaded state to dismiss error overlay
        emit(current);
      },
      ifRight: (table) =>
          emit(current.copyWith(table: table, isScanning: false)),
    );
  }

  void _onClearTable(
    CustomerCatalogClearTable event,
    Emitter<CustomerCatalogState> emit,
  ) {
    final current = state;
    if (current is! CustomerCatalogLoaded) return;
    emit(current.copyWith(clearTable: true));
  }
}
