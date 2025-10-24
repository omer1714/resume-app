import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resume_app/main.dart'; // adjust if AboutTab is in another file

void main() {
  testWidgets('AboutTab shows name and summary', (WidgetTester tester) async {
    final fakeData = {
      "name": "Omer Cheema",
      "title": "Software Developer",
      "summary": "4+ years of experience in App and Web Development",
      "links": []
    };

    // Build widget
    await tester.pumpWidget(
      MaterialApp(
        home: AboutTab(fakeData),
      ),
    );

    // Verify content
    expect(find.text('Omer Cheema'), findsOneWidget);
    expect(find.text('Software Developer'), findsOneWidget);
    expect(find.textContaining('4+ years'), findsOneWidget);
  });
}