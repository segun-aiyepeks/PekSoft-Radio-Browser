import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/features/library/domain/sync_repository.dart';

class FakeSyncRepository implements SyncRepository {
  int syncOnSignInCalls = 0;
  int syncNowCalls = 0;

  @override
  Future<Result<SyncSummary>> syncOnSignIn() async {
    syncOnSignInCalls++;
    return Success<SyncSummary>(SyncSummary(syncedAt: DateTime.now()));
  }

  @override
  Future<Result<SyncSummary>> syncNow() async {
    syncNowCalls++;
    return Success<SyncSummary>(SyncSummary(syncedAt: DateTime.now()));
  }
}
