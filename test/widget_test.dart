import 'package:flutter_test/flutter_test.dart';

import 'package:rpi_sav_app/data/app_config.dart';

void main() {
  test('SavColumns.indexOf convertit les lettres de colonnes', () {
    expect(SavColumns.indexOf('A'), 0);
    expect(SavColumns.indexOf('Z'), 25);
    expect(SavColumns.indexOf('AA'), 26);
    expect(SavColumns.indexOf('AG'), 32);
  });
}
