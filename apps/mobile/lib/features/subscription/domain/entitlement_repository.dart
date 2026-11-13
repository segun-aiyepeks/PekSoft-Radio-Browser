import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/features/subscription/domain/entitlement.dart';

/// Repository for querying the current user's subscription entitlement.
abstract interface class EntitlementRepository {
  Future<Result<Entitlement>> getEntitlement();

  Future<Result<Entitlement>> refreshEntitlement();
}
