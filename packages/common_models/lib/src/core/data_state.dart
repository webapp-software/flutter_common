import 'package:freezed_annotation/freezed_annotation.dart';

import 'either.dart';

part 'data_state.freezed.dart';

@freezed
class DataState<F, T> with _$DataState<F, T> {
  const factory DataState.success(T data) = _Success<F, T>;
  const factory DataState.idle() = _Idle<F, T>;
  const factory DataState.loading() = _Loading<F, T>;
  const factory DataState.error(F failure, [T? data]) = _Error<F, T>;

  const DataState._();

  factory DataState.fromEither(Either<F, T> either) =>
      either.fold((F l) => DataState<F, T>.error(l), (T r) => DataState<F, T>.success(r));

  bool get isSuccess => maybeWhen(
      success: (_) => true,
      orElse: () => false,
  );

  T get getOrThrow => maybeWhen(
    success: (T data) => data,
    orElse: () => throw Exception('getOrCrash called on !success'),
  );

  T? get get => maybeWhen(
    success: (T data) => data,
    orElse: () => null,
  );
}
