import 'package:meta/meta.dart';

/// Rounding strategies for decimal division and scaling operations.
enum RoundingMode {
  /// Rounds towards the nearest neighbor, or away from zero if equidistant.
  halfUp,

  /// Rounds towards the nearest neighbor, or towards the nearest even number if equidistant (banker's rounding).
  halfEven,

  /// Rounds towards zero (truncation).
  truncate,

  /// Rounds towards negative infinity.
  floor,

  /// Rounds towards positive infinity.
  ceil,
}

/// An immutable, exact decimal number that avoids IEEE-754 floating-point errors.
///
/// Internally stored as an unscaled [BigInt] integer and a non-negative [scale].
/// Value is: `unscaledValue * 10^(-scale)`.
@immutable
class DecimalNumber implements Comparable<DecimalNumber> {
  const DecimalNumber._(this.unscaledValue, this.scale)
    : assert(scale >= 0, 'scale must be non-negative');

  /// Creates a decimal number with unscaled [BigInt] and [scale].
  factory DecimalNumber.fromUnscaled(BigInt unscaledValue, int scale) {
    if (scale < 0) {
      final multiplier = BigInt.from(10).pow(-scale);
      return DecimalNumber._(unscaledValue * multiplier, 0);
    }
    return DecimalNumber._(unscaledValue, scale);
  }

  /// Creates a decimal number from an [int].
  factory DecimalNumber.fromInt(int value) =>
      DecimalNumber._(BigInt.from(value), 0);

  /// Creates a decimal number from an integer [BigInt].
  factory DecimalNumber.fromBigInt(BigInt value) => DecimalNumber._(value, 0);

  /// Converts a [double] to a [DecimalNumber] via string representation.
  factory DecimalNumber.fromDouble(double value) {
    if (value.isNaN || value.isInfinite) {
      throw ArgumentError.value(
        value,
        'value',
        'Cannot convert NaN or Infinity to DecimalNumber',
      );
    }
    return DecimalNumber.parse(value.toString());
  }

  /// Parses a decimal string (e.g. "123.456", "-0.05", "42").
  ///
  /// Throws [FormatException] if the string is not a valid decimal number.
  factory DecimalNumber.parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Cannot parse empty string as DecimalNumber');
    }

    final isNegative = trimmed.startsWith('-');
    final clean = trimmed.startsWith('-') || trimmed.startsWith('+')
        ? trimmed.substring(1)
        : trimmed;

    final dotIndex = clean.indexOf('.');
    if (dotIndex == -1) {
      final unscaled = BigInt.parse(clean);
      return DecimalNumber._(isNegative ? -unscaled : unscaled, 0);
    }

    final integerPart = clean.substring(0, dotIndex);
    final fractionalPart = clean.substring(dotIndex + 1);

    if (fractionalPart.contains('.')) {
      throw FormatException('Multiple decimal separators in "$input"');
    }

    final combinedDigits = '$integerPart$fractionalPart';
    if (combinedDigits.isEmpty) {
      throw FormatException('Invalid decimal representation: "$input"');
    }

    final unscaled = BigInt.parse(combinedDigits);
    final scale = fractionalPart.length;

    return DecimalNumber._(isNegative ? -unscaled : unscaled, scale);
  }

  /// Zero constant.
  static final zero = DecimalNumber._(BigInt.zero, 0);

  /// One constant.
  static final one = DecimalNumber.fromInt(1);

  /// Attempts to parse [input], returning `null` on failure.
  static DecimalNumber? tryParse(String? input) {
    if (input == null) return null;
    try {
      return DecimalNumber.parse(input);
    } on FormatException {
      return null;
    }
  }

  final BigInt unscaledValue;
  final int scale;

  /// Whether this decimal is negative.
  bool get isNegative => unscaledValue < BigInt.zero;

  /// Whether this decimal equals zero.
  bool get isZero => unscaledValue == BigInt.zero;

  /// Returns the absolute value.
  DecimalNumber abs() =>
      isNegative ? DecimalNumber._(-unscaledValue, scale) : this;

  /// Negates this decimal.
  DecimalNumber operator -() => DecimalNumber._(-unscaledValue, scale);

  /// Adds [other] to this decimal.
  DecimalNumber operator +(DecimalNumber other) {
    final targetScale = scale > other.scale ? scale : other.scale;
    final a = _rescale(unscaledValue, scale, targetScale);
    final b = _rescale(other.unscaledValue, other.scale, targetScale);
    return DecimalNumber._(a + b, targetScale)._simplify();
  }

  /// Subtracts [other] from this decimal.
  DecimalNumber operator -(DecimalNumber other) => this + (-other);

  /// Multiplies this decimal by [other].
  DecimalNumber operator *(DecimalNumber other) {
    final resultUnscaled = unscaledValue * other.unscaledValue;
    final resultScale = scale + other.scale;
    return DecimalNumber._(resultUnscaled, resultScale)._simplify();
  }

  /// Divides this decimal by [other], with specified [targetScale] and [rounding].
  DecimalNumber divide(
    DecimalNumber other, {
    int targetScale = 4,
    RoundingMode rounding = RoundingMode.halfUp,
  }) {
    if (other.isZero) {
      throw UnsupportedError('Cannot divide DecimalNumber by zero');
    }

    final sign = (isNegative ^ other.isNegative) ? -1 : 1;
    final num = unscaledValue.abs();
    final den = other.unscaledValue.abs();

    final shift = targetScale + other.scale - scale;
    final BigInt quotient;
    final BigInt remainder;
    final BigInt effectiveDen;

    if (shift >= 0) {
      final scaledNum = num * BigInt.from(10).pow(shift);
      quotient = scaledNum ~/ den;
      remainder = scaledNum % den;
      effectiveDen = den;
    } else {
      effectiveDen = den * BigInt.from(10).pow(-shift);
      quotient = num ~/ effectiveDen;
      remainder = num % effectiveDen;
    }

    var finalQuotient = quotient;
    if (remainder != BigInt.zero) {
      final doubleRem = remainder * BigInt.from(2);
      final cmp = doubleRem.compareTo(
        effectiveDen,
      ); // < 0: less than half, 0: exact half, > 0: more than half

      switch (rounding) {
        case RoundingMode.truncate:
        case RoundingMode.floor:
          if (sign < 0) finalQuotient += BigInt.one;
        case RoundingMode.ceil:
          if (sign > 0) finalQuotient += BigInt.one;
        case RoundingMode.halfUp:
          if (cmp >= 0) finalQuotient += BigInt.one;
        case RoundingMode.halfEven:
          if (cmp > 0) {
            finalQuotient += BigInt.one;
          } else if (cmp == 0) {
            if (quotient.isOdd) finalQuotient += BigInt.one;
          }
      }
    }

    final result = sign < 0 ? -finalQuotient : finalQuotient;
    return DecimalNumber._(result, targetScale)._simplify();
  }

  /// Normalizes by stripping redundant trailing zeros in scale.
  DecimalNumber _simplify() {
    if (unscaledValue == BigInt.zero) return DecimalNumber.zero;
    var u = unscaledValue;
    var s = scale;
    final ten = BigInt.from(10);
    while (s > 0 && u % ten == BigInt.zero) {
      u ~/= ten;
      s--;
    }
    return DecimalNumber._(u, s);
  }

  static BigInt _rescale(BigInt value, int currentScale, int targetScale) {
    if (currentScale == targetScale) return value;
    final diff = targetScale - currentScale;
    if (diff > 0) {
      return value * BigInt.from(10).pow(diff);
    }
    return value ~/ BigInt.from(10).pow(-diff);
  }

  /// Rounds to [fractionalDigits] places with [rounding].
  DecimalNumber roundToScale(
    int fractionalDigits, {
    RoundingMode rounding = RoundingMode.halfUp,
  }) {
    if (scale <= fractionalDigits) return this;
    return divide(one, targetScale: fractionalDigits, rounding: rounding);
  }

  /// Converts to standard string format (e.g. "123.45").
  @override
  String toString() {
    if (scale == 0) return unscaledValue.toString();

    final isNeg = unscaledValue < BigInt.zero;
    final absVal = unscaledValue.abs().toString();

    if (absVal.length <= scale) {
      final padded = absVal.padLeft(scale, '0');
      return '${isNeg ? '-' : ''}0.$padded';
    }

    final intPart = absVal.substring(0, absVal.length - scale);
    final fracPart = absVal.substring(absVal.length - scale);
    return '${isNeg ? '-' : ''}$intPart.$fracPart';
  }

  /// Formats with a fixed number of decimal digits, padding with zeros if necessary.
  String toStringAsFixed(int fractionDigits) {
    final rounded = roundToScale(fractionDigits, rounding: RoundingMode.halfUp);
    final str = rounded.toString();
    final dot = str.indexOf('.');
    if (fractionDigits == 0) {
      return dot == -1 ? str : str.substring(0, dot);
    }
    if (dot == -1) {
      return '$str.${'0' * fractionDigits}';
    }
    final existingFraction = str.substring(dot + 1);
    if (existingFraction.length < fractionDigits) {
      return '$str${'0' * (fractionDigits - existingFraction.length)}';
    }
    return str;
  }

  /// Converts to standard [double]. Note that precision may be lost for extreme values.
  double toDouble() => double.parse(toString());

  /// Converts to integer, truncating any fractional part.
  int toInt() =>
      (scale == 0 ? unscaledValue : unscaledValue ~/ BigInt.from(10).pow(scale))
          .toInt();

  @override
  int compareTo(DecimalNumber other) {
    final targetScale = scale > other.scale ? scale : other.scale;
    final a = _rescale(unscaledValue, scale, targetScale);
    final b = _rescale(other.unscaledValue, other.scale, targetScale);
    return a.compareTo(b);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DecimalNumber) return false;
    return compareTo(other) == 0;
  }

  @override
  int get hashCode {
    final simplified = _simplify();
    return Object.hash(simplified.unscaledValue, simplified.scale);
  }

  bool operator <(DecimalNumber other) => compareTo(other) < 0;
  bool operator <=(DecimalNumber other) => compareTo(other) <= 0;
  bool operator >(DecimalNumber other) => compareTo(other) > 0;
  bool operator >=(DecimalNumber other) => compareTo(other) >= 0;
}
