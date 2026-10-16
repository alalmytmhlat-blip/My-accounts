import 'package:flutter_test/flutter_test.dart';

int calculateInvoiceTotal({required int quantity, required int unitPriceMinor, int discountMinor = 0, int taxPercent = 0}) {
  final subtotal = quantity * unitPriceMinor;
  final taxable = (subtotal - discountMinor).clamp(0, 1 << 62);
  return taxable + (taxable * taxPercent / 100).round();
}

bool isBalancedEntry(int debitMinor, int creditMinor) => debitMinor == creditMinor;

void main() {
  group('حسابات مالية دقيقة بوحدات العملة الصغرى', () {
    test('يحسب الإجمالي بعد الخصم والضريبة', () {
      expect(calculateInvoiceTotal(quantity: 2, unitPriceMinor: 10000, discountMinor: 2000, taxPercent: 5), 18900);
    });
    test('يرفض القيد غير المتوازن', () {
      expect(isBalancedEntry(10000, 9000), isFalse);
      expect(isBalancedEntry(10000, 10000), isTrue);
    });
  });
}
