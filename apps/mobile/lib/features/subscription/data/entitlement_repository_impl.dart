import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/features/subscription/domain/entitlement.dart';
import 'package:peksoft_radio/features/subscription/domain/entitlement_repository.dart';

/// Phase 2 stub returning [EntitlementTier.free] by default.
///
/// Phase 4/5 will replace this with server-verified Google Play / Paystack
/// entitlement sync.
class EntitlementRepositoryImpl implements EntitlementRepository {
  const EntitlementRepositoryImpl({
    Entitlement defaultEntitlement = const Entitlement(),
  }) : _entitlement = defaultEntitlement;

  final Entitlement _entitlement;

  @override
  Future<Result<Entitlement>> getEntitlement() async =>
      Success<Entitlement>(_entitlement);

  @override
  Future<Result<Entitlement>> refreshEntitlement() async =>
      Success<Entitlement>(_entitlement);
}
