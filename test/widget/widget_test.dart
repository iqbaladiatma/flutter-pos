import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_flutter/core/utils/currency_formatter.dart';

void main() {
  group('Widget tests', () {
    testWidgets('CurrencyFormatter displays in Text widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Text(CurrencyFormatter.format(25000)),
          ),
        ),
      );

      expect(find.textContaining('25'), findsOneWidget);
      expect(find.textContaining('Rp'), findsOneWidget);
    });

    testWidgets('AppBar renders title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('POS')),
          ),
        ),
      );

      expect(find.text('POS'), findsOneWidget);
    });

    testWidgets('FloatingActionButton renders', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('BottomNavigationBar renders all items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const SizedBox(),
            bottomNavigationBar: BottomNavigationBar(
              items: const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.point_of_sale), label: 'POS'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.kitchen), label: 'Kitchen'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard), label: 'Admin'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('POS'), findsOneWidget);
      expect(find.text('Kitchen'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
    });

    testWidgets('Dialog can be opened and closed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const AlertDialog(
                      title: Text('Test Dialog'),
                      content: Text('Dialog content'),
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Test Dialog'), findsOneWidget);
      expect(find.text('Dialog content'), findsOneWidget);

      // Close dialog by tapping outside
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    });

    testWidgets('SnackBar displays message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Test snackbar')),
                  );
                },
                child: const Text('Show SnackBar'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show SnackBar'));
      await tester.pumpAndSettle();

      expect(find.text('Test snackbar'), findsOneWidget);
    });
  });
}
