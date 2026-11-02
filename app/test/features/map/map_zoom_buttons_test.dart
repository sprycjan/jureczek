import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/features/map/presentation/map_tools.dart';

void main() {
  testWidgets('+ przybliża, − oddala', (tester) async {
    final calls = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: MapZoomButtons(
              zoomInTooltip: 'Przybliż',
              zoomOutTooltip: 'Oddal',
              onZoomIn: () => calls.add('in'),
              onZoomOut: () => calls.add('out'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.add));
    await tester.tap(find.byIcon(Icons.remove));
    expect(calls, ['in', 'out']);
    expect(find.byTooltip('Przybliż'), findsOneWidget);
    expect(find.byTooltip('Oddal'), findsOneWidget);
  });
}
