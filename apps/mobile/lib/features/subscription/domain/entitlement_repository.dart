import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/features/subscription/domain/entitlement.dart';

/// Repository for querying and refreshing the current user's subscription
/// entitlement from the backend (`GET /v1/entitlements`) with local offline
/// caching and client-side 24-hour rewarded-ad pass support.
abstract interface class EntitlementRepository {
  Future<Result<Entitlement>> getEntitlement();

  Future<Result<Entitlement>> refreshEntitlement();

  Future<Result<Entitlement>> grantTemporaryRewardedPass({
    Duration duration = const Duration(hours: 24),
  });
}
