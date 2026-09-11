import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strut/features/admin/widgets/admin_overview_tab.dart';
import 'package:strut/models/admin_stats_model.dart';

AdminStats _stats(Map<String, dynamic> json) => AdminStats.fromJson(json);

Widget _host(Future<AdminStats> Function() load) => ProviderScope(
      overrides: [adminStatsProvider.overrideWith((ref) => load())],
      child: const MaterialApp(home: Scaffold(body: AdminOverviewTab())),
    );

void main() {
  group('AdminStats.fromJson', () {
    test('parses the documented contract', () {
      final stats = _stats({
        'users': {
          'passengers': 1240,
          'drivers': 86,
          'driversVerified': 71,
          'fleetOwners': 4,
        },
        'bookings': {
          'total': 980,
          'confirmed': 812,
          'pending': 96,
          'cancelled': 72,
        },
        'trips': {'total': 410, 'completed': 377, 'cancelled': 33},
        'transactions': {
          'currency': 'ZAR',
          'confirmedAmount': 152430.50,
          'totalAmount': 178900.00,
          'last30DaysAmount': 41250.75,
          'last30DaysCount': 214,
        },
        'generatedAt': '2026-09-06T10:30:00.000Z',
      });

      expect(stats.users.passengers, 1240);
      expect(stats.users.total, 1330); // passengers + drivers + fleet owners
      expect(stats.bookings.confirmed, 812);
      expect(stats.trips.completed, 377);
      expect(stats.transactions.confirmedAmount, 152430.50);
      expect(stats.transactions.currency, 'ZAR');
      expect(stats.generatedAt, isNotNull);
    });

    test('defaults to zero when sections are missing', () {
      final stats = _stats({});

      expect(stats.users.passengers, 0);
      expect(stats.bookings.confirmed, 0);
      expect(stats.trips.completed, 0);
      expect(stats.transactions.confirmedAmount, 0);
      expect(stats.transactions.currency, 'ZAR');
      expect(stats.generatedAt, isNull);
    });

    test('accepts integers where doubles are expected', () {
      final stats = _stats({
        'transactions': {'confirmedAmount': 1500, 'last30DaysAmount': 200},
      });

      expect(stats.transactions.confirmedAmount, 1500.0);
      expect(stats.transactions.last30DaysAmount, 200.0);
    });
  });

  group('AdminOverviewTab', () {
    testWidgets('renders totals and formats money', (tester) async {
      // Tall surface so every section lays out; the default 800x600 viewport
      // leaves the users section below the fold and it never builds.
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_host(() async => _stats({
            'users': {'passengers': 1240, 'drivers': 86, 'driversVerified': 71},
            'bookings': {'confirmed': 812, 'pending': 96},
            'trips': {'completed': 377},
            'transactions': {
              'currency': 'ZAR',
              'confirmedAmount': 152430.50,
              'last30DaysCount': 214,
            },
          })));
      await tester.pumpAndSettle();

      expect(find.text('Total transacted (confirmed)'), findsOneWidget);
      expect(find.text('R 152,430.50'), findsOneWidget);
      expect(find.text('214 bookings'), findsOneWidget);

      // Counts are thousands-separated.
      expect(find.text('1,240'), findsOneWidget);
      expect(find.text('812'), findsOneWidget);
      expect(find.text('377'), findsOneWidget);

      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('Passengers'), findsOneWidget);
      expect(find.text('Verified drivers'), findsOneWidget);
    });

    testWidgets('a 404 reports the endpoint as not deployed', (tester) async {
      await tester.pumpWidget(_host(() async => throw DioException(
            requestOptions: RequestOptions(path: '/admin/stats'),
            response: Response(
              requestOptions: RequestOptions(path: '/admin/stats'),
              statusCode: 404,
            ),
          )));
      await tester.pumpAndSettle();

      expect(find.text('Reporting not available yet'), findsOneWidget);
      expect(find.textContaining('GET /admin/stats'), findsOneWidget);
    });

    testWidgets('other failures show a generic error', (tester) async {
      await tester.pumpWidget(_host(() async => throw DioException(
            requestOptions: RequestOptions(path: '/admin/stats'),
            type: DioExceptionType.connectionError,
          )));
      await tester.pumpAndSettle();

      expect(find.text('Could not load platform totals'), findsOneWidget);
      expect(find.text('Reporting not available yet'), findsNothing);
    });
  });
}
