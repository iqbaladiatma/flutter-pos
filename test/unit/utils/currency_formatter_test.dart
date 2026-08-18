import 'package:flutter_test/flutter_test.dart';
import 'package:pos_flutter/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter', () {
    test('format formats positive amount with Rp prefix', () {
      expect(CurrencyFormatter.format(25000), contains('Rp'));
      expect(CurrencyFormatter.format(25000), contains('25'));
    });

    test('format handles zero', () {
      final result = CurrencyFormatter.format(0);
      expect(result, contains('0'));
    });

    test('format handles large amounts', () {
      final result = CurrencyFormatter.format(1500000);
      expect(result, contains('1.500.000'));
    });

    test('formatPlain returns number without symbol', () {
      final result = CurrencyFormatter.formatPlain(25000);
      expect(result, contains('25'));
      expect(result, isNot(contains('Rp')));
    });

    test('parse converts formatted string back to double', () {
      final formatted = CurrencyFormatter.format(25000);
      final parsed = CurrencyFormatter.parse(formatted);
      expect(parsed, equals(25000.0));
    });

    test('parse handles plain number string', () {
      final parsed = CurrencyFormatter.parse('25.000');
      expect(parsed, equals(25000.0));
    });

    test('parse returns 0 for invalid string', () {
      final parsed = CurrencyFormatter.parse('invalid');
      expect(parsed, equals(0.0));
    });

    test('round-trip: format then parse returns original value', () {
      const values = [0.0, 1000.0, 25500.0, 1500000.0, 999999.0];
      for (final v in values) {
        final formatted = CurrencyFormatter.format(v);
        final parsed = CurrencyFormatter.parse(formatted);
        expect(parsed, equals(v),
            reason: 'Round-trip failed for $v: got $parsed');
      }
    });
  });
}
