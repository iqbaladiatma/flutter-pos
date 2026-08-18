import 'package:equatable/equatable.dart';
import '../../../../shared/models/product_model.dart';
import '../../../../shared/models/table_model.dart';
import '../../domain/repositories/customer_catalog_repository.dart';

sealed class CustomerCatalogState extends Equatable {
  const CustomerCatalogState();

  @override
  List<Object?> get props => [];
}

class CustomerCatalogInitial extends CustomerCatalogState {
  const CustomerCatalogInitial();
}

class CustomerCatalogLoading extends CustomerCatalogState {
  const CustomerCatalogLoading();
}

class CustomerCatalogLoaded extends CustomerCatalogState {
  final List<CategoryModel> categories;
  final List<ProductModel> products;
  final List<Banner> banners;
  final String? selectedCategoryId;
  final TableModel? table;
  final bool isScanning;

  const CustomerCatalogLoaded({
    required this.categories,
    required this.products,
    required this.banners,
    this.selectedCategoryId,
    this.table,
    this.isScanning = false,
  });

  CustomerCatalogLoaded copyWith({
    List<CategoryModel>? categories,
    List<ProductModel>? products,
    List<Banner>? banners,
    String? selectedCategoryId,
    TableModel? table,
    bool? isScanning,
    bool clearTable = false,
    bool clearFilter = false,
  }) =>
      CustomerCatalogLoaded(
        categories: categories ?? this.categories,
        products: products ?? this.products,
        banners: banners ?? this.banners,
        selectedCategoryId:
            clearFilter ? null : (selectedCategoryId ?? this.selectedCategoryId),
        table: clearTable ? null : (table ?? this.table),
        isScanning: isScanning ?? this.isScanning,
      );

  @override
  List<Object?> get props =>
      [categories, products, banners, selectedCategoryId, table, isScanning];
}

class CustomerCatalogError extends CustomerCatalogState {
  final String message;
  const CustomerCatalogError(this.message);

  @override
  List<Object?> get props => [message];
}
