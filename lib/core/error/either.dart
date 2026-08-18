import '../error/failures.dart';

/// Simple `Either<L, R>` sealed class for functional error handling.
///
/// Instead of adding the `dartz` dependency, this lightweight implementation
/// covers the common `Either<Failure, T>` pattern used in Clean Architecture.
///
/// Usage:
/// ```dart
/// Future<Either<Failure, Order>> createOrder(...) async {
///   try {
///     final order = ...;
///     return Right(order);
///   } catch (e) {
///     return Left(ServerFailure(original: e));
///   }
/// }
/// ```
sealed class Either<L, R> {
  const Either();

  /// Returns `true` if this is a [Left].
  bool get isLeft => this is Left<L, R>;

  /// Returns `true` if this is a [Right].
  bool get isRight => this is Right<L, R>;

  /// Folds: calls [ifLeft] for [Left], [ifRight] for [Right].
  T fold<T>({
    required T Function(L left) ifLeft,
    required T Function(R right) ifRight,
  }) {
    final self = this;
    if (self is Left<L, R>) return ifLeft(self.value);
    return ifRight((self as Right<L, R>).value);
  }

  /// Maps the right value via [mapper]. Left passes through unchanged.
  Either<L, R2> map<R2>(R2 Function(R right) mapper) {
    final self = this;
    if (self is Left<L, R>) return Left(self.value);
    return Right(mapper((self as Right<L, R>).value));
  }
}

/// Left side — conventionally the failure.
class Left<L, R> extends Either<L, R> {
  final L value;
  const Left(this.value);
}

/// Right side — conventionally the success value.
class Right<L, R> extends Either<L, R> {
  final R value;
  const Right(this.value);
}

/// Convenience typedef for the common case of `Failure` on the left.
typedef Result<T> = Either<Failure, T>;
