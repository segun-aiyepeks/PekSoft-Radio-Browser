import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peksoft_radio/core/database/app_database.dart';
import 'package:peksoft_radio/core/di/providers.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/core/network/api_client.dart';
import 'package:peksoft_radio/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:peksoft_radio/features/catalog/domain/genre.dart';
import 'package:peksoft_radio/features/library/data/library_repository_impl.dart';
import 'package:peksoft_radio/features/library/data/sync_repository_impl.dart';
import 'package:peksoft_radio/features/library/domain/sync_repository.dart';
import 'package:peksoft_radio/features/station/data/report_queue_repository_impl.dart';
import 'package:peksoft_radio/features/station/domain/report_queue_repository.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';
import 'package:peksoft_radio/features/subscription/data/entitlement_repository_impl.dart';

import 'helpers/fake_auth_repository.dart';
import 'helpers/fake_sync_repository.dart';

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => handler(options);
}

ResponseBody _jsonResponse(int statusCode, Map<String, dynamic> body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );
}

void main() {
  group('Milestone 4.6 Mobile Auth, ApiClient & SyncRepository', () {
    test(
      'ApiClient attaches ID token, silently refreshes on 401, and retries once',
      () async {
        final List<String?> seenAuthHeaders = <String?>[];
        final List<bool> refreshFlags = <bool>[];
        int attempts = 0;

        final Dio dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
        dio.httpClientAdapter = _StubAdapter((RequestOptions options) async {
          attempts++;
          seenAuthHeaders.add(options.headers['Authorization'] as String?);
          if (attempts == 1) {
            return _jsonResponse(401, <String, dynamic>{
              'error': <String, dynamic>{'message': 'Expired token'},
            });
          }
          return _jsonResponse(200, <String, dynamic>{
            'user': <String, dynamic>{'id': 'u1'},
          });
        });

        final ApiClient client = ApiClient(
          dio: dio,
          getIdToken: ({bool forceRefresh = false}) async {
            refreshFlags.add(forceRefresh);
            return forceRefresh ? 'fresh-token-2' : 'stale-token-1';
          },
        );

        final Result<Map<String, dynamic>> res = await client.getMe();
        expect(res, isA<Success<Map<String, dynamic>>>());
        expect(attempts, 2);
        expect(seenAuthHeaders, <String?>[
          'Bearer stale-token-1',
          'Bearer fresh-token-2',
        ]);
        expect(refreshFlags, <bool>[false, true]);
      },
    );

    test(
      'SyncRepositoryImpl merges guest favourites and flushes queued reports',
      () async {
        final AppDatabase db = AppDatabase.inMemory();
        addTearDown(db.close);
        final LibraryRepositoryImpl library = LibraryRepositoryImpl(
          database: db,
          entitlementRepository: const EntitlementRepositoryImpl(),
        );
        final DriftReportQueueRepository reports = DriftReportQueueRepository(
          database: db,
        );

        const Station guestFav = Station(
          id: 'guest-st-1',
          name: 'Guest Jazz FM',
          streamUrl: 'https://stream.example.com/jazz.mp3',
          countryCode: 'US',
          countryName: 'United States',
          genres: <Genre>[],
          isWorking: true,
        );
        await library.addFavourite(guestFav);
        await reports.enqueueReport(
          station: const Station(
            id: 'dead-st-1',
            name: 'Dead FM',
            streamUrl: 'https://stream.example.com/dead.mp3',
            countryCode: 'NG',
            countryName: 'Nigeria',
            genres: <Genre>[],
            isWorking: false,
          ),
          reason: 'DEAD_STREAM',
        );

        Map<String, dynamic>? capturedSyncPayload;
        Map<String, dynamic>? capturedReportPayload;

        final Dio dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
        dio.httpClientAdapter = _StubAdapter((RequestOptions options) async {
          if (options.path == '/v1/me') {
            return _jsonResponse(200, <String, dynamic>{
              'user': <String, dynamic>{'id': 'u1'},
            });
          }
          if (options.path == '/v1/sync') {
            capturedSyncPayload = options.data as Map<String, dynamic>;
            return _jsonResponse(200, <String, dynamic>{
              'appliedCount': 1,
              'rejected': <dynamic>[],
              'changes': <String, dynamic>{
                'favorites': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'stationId': 'remote-st-2',
                    'stationName': 'FIP Remote',
                    'streamUrl': 'https://stream.example.com/fip.mp3',
                    'countryCode': 'FR',
                    'isDeleted': false,
                  },
                ],
              },
            });
          }
          if (options.path == '/v1/reports') {
            capturedReportPayload = options.data as Map<String, dynamic>;
            return _jsonResponse(201, <String, dynamic>{
              'report': <String, dynamic>{'id': 'r1'},
            });
          }
          return _jsonResponse(404, <String, dynamic>{});
        });

        final SyncRepositoryImpl syncRepo = SyncRepositoryImpl(
          apiClient: ApiClient(
            dio: dio,
            getIdToken: ({bool forceRefresh = false}) async => 'token',
          ),
          libraryRepository: library,
          reportQueueRepository: reports,
        );

        final Result<SyncSummary> res = await syncRepo.syncOnSignIn();
        expect(res, isA<Success<SyncSummary>>());
        final SyncSummary summary = (res as Success<SyncSummary>).data;
        expect(summary.pushedFavorites, 1);
        expect(summary.pulledFavorites, 1);
        expect(summary.flushedReports, 1);

        expect((capturedSyncPayload!['favorites'] as List<dynamic>).length, 1);
        expect(capturedReportPayload!['stationId'], 'dead-st-1');
        final Result<List<PendingStationReport>> pendingAfter = await reports
            .getPendingReports();
        expect(
          (pendingAfter as Success<List<PendingStationReport>>).data,
          isEmpty,
        );

        final Result<List<Station>> favsAfter = await library.getFavourites();
        final List<Station> mergedFavs =
            (favsAfter as Success<List<Station>>).data;
        expect(
          mergedFavs.map((s) => s.id),
          containsAll(<String>['guest-st-1', 'remote-st-2']),
        );
      },
    );

    test(
      'AuthViewModel handles sign-up verification, reset, Google linking, sign out, and deleteAccount',
      () async {
        final FakeAuthRepository authRepo = FakeAuthRepository(
          googleRequiresLink: true,
        );
        final FakeSyncRepository syncRepo = FakeSyncRepository();
        bool deleteMeCalled = false;

        final Dio dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
        dio.httpClientAdapter = _StubAdapter((RequestOptions options) async {
          if (options.method == 'DELETE' && options.path == '/v1/me') {
            deleteMeCalled = true;
            return _jsonResponse(204, <String, dynamic>{});
          }
          return _jsonResponse(200, <String, dynamic>{});
        });

        final ProviderContainer container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(authRepo),
            syncRepositoryProvider.overrideWithValue(syncRepo),
            apiClientProvider.overrideWithValue(
              ApiClient(dio: dio, getIdToken: authRepo.getIdToken),
            ),
          ],
        );
        addTearDown(() {
          container.dispose();
          authRepo.dispose();
        });

        final AuthViewModel vm = container.read(authViewModelProvider.notifier);

        // Email sign-up -> verification email sent & sync triggered
        expect(
          await vm.signUpWithEmail('new@example.com', 'secret123', 'Segun'),
          isTrue,
        );
        expect(
          container.read(authViewModelProvider).verificationEmailSent,
          isTrue,
        );
        expect(syncRepo.syncOnSignInCalls, 1);

        // Reload verification status
        expect(await vm.reloadVerificationStatus(), isTrue);
        expect(container.read(authViewModelProvider).emailVerified, isTrue);

        // Sign out
        await vm.signOut();
        expect(authRepo.signedOutCalled, isTrue);
        expect(container.read(authViewModelProvider).isAuthenticated, isFalse);

        // Google sign-in with shared email triggers linking flow
        expect(await vm.signInWithGoogle(), isFalse);
        expect(
          container.read(authViewModelProvider).pendingLinkEmail,
          'shared@example.com',
        );

        // Complete linking with password
        expect(
          await vm.signInWithEmail('shared@example.com', 'secret123'),
          isTrue,
        );
        expect(authRepo.linkedCredentialCalled, isTrue);
        expect(container.read(authViewModelProvider).pendingLinkEmail, isNull);
        expect(syncRepo.syncOnSignInCalls, 2);

        // Forgot password
        expect(await vm.sendPasswordReset('shared@example.com'), isTrue);
        expect(authRepo.passwordResetSent, isTrue);

        // Delete account calls DELETE /v1/me and clears auth state
        expect(await vm.deleteAccount(), isTrue);
        expect(deleteMeCalled, isTrue);
        expect(container.read(authViewModelProvider).isAuthenticated, isFalse);
      },
    );
  });
}
