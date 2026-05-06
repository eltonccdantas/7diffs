// Smoke test — verifies the app builds and the welcome dialog appears on launch.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevendiffs/app.dart';

void main() {
  testWidgets('app renders and shows welcome dialog on launch', (tester) async {
    await tester.pumpWidget(const SevenDiffsApp());
    await tester.pump(); // allow postFrameCallback to fire

    // Welcome dialog title should be visible
    expect(find.text('Supported formats'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);
  });

  testWidgets('welcome dialog closes on Got it', (tester) async {
    await tester.pumpWidget(const SevenDiffsApp());
    await tester.pump();

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    expect(find.text('Supported formats'), findsNothing);
  });

  testWidgets('app bar actions are present', (tester) async {
    await tester.pumpWidget(const SevenDiffsApp());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
    expect(find.byIcon(Icons.delete_sweep_outlined), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
  });
}
