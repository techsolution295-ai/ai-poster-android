import 'package:flutter_test/flutter_test.dart';

import 'package:postermakerai/core/utils/color_utils.dart';

void main() {
  test('ColorUtils round-trips hex values', () {
    const hex = '#FF6C2BD9';
    final color = ColorUtils.fromHex(hex);
    expect(ColorUtils.toHex(color).toUpperCase(), hex);
  });

  test('ColorUtils expands 6-digit hex to opaque colour', () {
    final color = ColorUtils.fromHex('#6C2BD9');
    expect(ColorUtils.toHex(color).toUpperCase(), '#FF6C2BD9');
  });
}
