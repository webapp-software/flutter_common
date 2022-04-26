import '../core/either.dart';
import '../failure/value_failure.dart';
import 'core/value_object.dart';

class Price extends ValueObject<ValueFailure, double> {
  factory Price(String value) {
    if (value.trim().isEmpty) {
      return Price._(left(const ValueFailure.empty()));
    }

    final double? priceValue = double.tryParse(value);
    if (priceValue == null || priceValue.isNaN) {
      return Price._(left(ValueFailure.invalid()));
    }

    return Price._(right(priceValue));
  }

  factory Price.empty() => Price('');

  Price._(Either<ValueFailure, double> value) : super(value);
}
