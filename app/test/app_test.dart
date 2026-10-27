import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/app.dart';

void main() {
  testWidgets('bez tokenu pokazuje komunikat zamiast mapy', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: JureczekApp(accessToken: '')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Brak tokenu Mapbox'), findsOneWidget);
  });
}
