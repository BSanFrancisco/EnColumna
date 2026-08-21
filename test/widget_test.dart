import 'package:flutter_test/flutter_test.dart';

import 'package:multiplicaciones_columna/app.dart';

void main() {
  testWidgets('La app arranca y muestra el título', (WidgetTester tester) async {
    await tester.pumpWidget(const MultiplicacionesColumnaApp());
    expect(find.textContaining('MULTIPLICACIONES'), findsWidgets);
  });
}
