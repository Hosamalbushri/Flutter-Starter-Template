import 'package:document_engine/document_engine.dart';
import 'package:test/test.dart';

void main() {
  group('DecimalNumber', () {
    test('parses integers and decimals accurately', () {
      final a = DecimalNumber.parse('123.45');
      expect(a.scale, 2);
      expect(a.unscaledValue, BigInt.from(12345));
      expect(a.toString(), '123.45');

      final b = DecimalNumber.parse('-0.050');
      expect(b.isNegative, isTrue);
      expect(b.toString(), '-0.050');

      final c = DecimalNumber.parse('42');
      expect(c.scale, 0);
      expect(c.toString(), '42');
    });

    test('rejects malformed decimal strings', () {
      expect(() => DecimalNumber.parse(''), throwsFormatException);
      expect(() => DecimalNumber.parse('abc'), throwsFormatException);
      expect(() => DecimalNumber.parse('12.34.56'), throwsFormatException);
    });

    test('exact addition avoiding IEEE-754 floating point drift', () {
      // 0.1 + 0.2 in binary float is 0.30000000000000004
      final a = DecimalNumber.parse('0.1');
      final b = DecimalNumber.parse('0.2');
      final sum = a + b;
      expect(sum.toString(), '0.3');
      expect(sum == DecimalNumber.parse('0.30'), isTrue);
    });

    test('exact subtraction and negation', () {
      final a = DecimalNumber.parse('100.50');
      final b = DecimalNumber.parse('45.25');
      final diff = a - b;
      expect(diff.toString(), '55.25');

      final neg = -diff;
      expect(neg.toString(), '-55.25');
      expect(neg.isNegative, isTrue);
    });

    test('exact multiplication', () {
      final a = DecimalNumber.parse('12.5');
      final b = DecimalNumber.parse('0.04');
      final prod = a * b; // 0.5
      expect(prod.toString(), '0.5');
    });

    test('division with configurable scale and rounding', () {
      final ten = DecimalNumber.fromInt(10);
      final three = DecimalNumber.fromInt(3);

      final resHalfUp = ten.divide(
        three,
        targetScale: 2,
        rounding: RoundingMode.halfUp,
      );
      expect(resHalfUp.toString(), '3.33');

      final resHalfUp4 = ten.divide(
        three,
        targetScale: 4,
        rounding: RoundingMode.halfUp,
      );
      expect(resHalfUp4.toString(), '3.3333');

      // Banker's rounding test (halfEven)
      // 2.5 rounded to 0 decimals with halfEven -> 2 (nearest even)
      final twoPointFive = DecimalNumber.parse('2.5');
      final roundedBanker = twoPointFive.roundToScale(
        0,
        rounding: RoundingMode.halfEven,
      );
      expect(roundedBanker.toString(), '2');

      // 3.5 rounded to 0 decimals with halfEven -> 4 (nearest even)
      final threePointFive = DecimalNumber.parse('3.5');
      final roundedBanker2 = threePointFive.roundToScale(
        0,
        rounding: RoundingMode.halfEven,
      );
      expect(roundedBanker2.toString(), '4');
    });

    test('division by zero throws UnsupportedError', () {
      final ten = DecimalNumber.fromInt(10);
      expect(
        () => ten.divide(DecimalNumber.zero),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('comparisons and ordering', () {
      final a = DecimalNumber.parse('1.00');
      final b = DecimalNumber.parse('1');
      final c = DecimalNumber.parse('1.01');
      final d = DecimalNumber.parse('-0.5');

      expect(a == b, isTrue);
      expect(a < c, isTrue);
      expect(c > b, isTrue);
      expect(d < DecimalNumber.zero, isTrue);

      final list = [c, d, a];
      list.sort();
      expect(list, [d, a, c]);
    });

    test('toStringAsFixed padding and rounding', () {
      final num = DecimalNumber.parse('12.3');
      expect(num.toStringAsFixed(2), '12.30');
      expect(num.toStringAsFixed(0), '12');

      final num2 = DecimalNumber.parse('12.356');
      expect(num2.toStringAsFixed(2), '12.36');
    });
  });
}
