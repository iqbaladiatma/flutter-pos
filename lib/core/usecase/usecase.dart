import '../error/either.dart';

/// Base use-case contract following Clean Architecture.
///
/// Each use-case is a single-purpose class with one public method [call].
/// Input `Params` and output `Type` are declared as type parameters.
///
/// Usage:
/// ```dart
/// class CreateOrderUseCase
///     extends UseCase<Order, CreateOrderParams> {
///   @override
///   Future<Result<Order>> call(CreateOrderParams params) async { ... }
/// }
/// ```
abstract class UseCase<T, Params> {
  Future<Result<T>> call(Params params);
}

/// Marker for use-cases that take no parameters.
class NoParams {
  const NoParams();
}
