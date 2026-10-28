import 'package:flutter_test/flutter_test.dart';
import 'package:stoco_family/core/format.dart';

void main() {
  test('parseMoney aceita vírgula e ponto', () {
    expect(parseMoney('1234,56'), 1234.56);
    expect(parseMoney('1234.56'), 1234.56);
    expect(parseMoney('1.234,56'), 1234.56);
    expect(parseMoney(''), isNull);
  });

  test('formatBRL formata em reais', () {
    expect(formatBRL(1234.5), 'R\$ 1.234,50');
  });
}
