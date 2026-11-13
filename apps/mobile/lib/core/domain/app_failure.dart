import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_failure.freezed.dart';

/// Typed domain failure hierarchy. Errors are never swallowed; repositories
/// map exceptions into [AppFailure] variants for ViewModels to render.
@freezed
sealed class AppFailure with _$AppFailure {
  const AppFailure._();

  const factory AppFailure.network({required String message, int? statusCode}) =
      NetworkFailure;

  const factory AppFailure.timeout({required String message}) = TimeoutFailure;

  const factory AppFailure.mirrorUnavailable({required String message}) =
      MirrorUnavailableFailure;

  const factory AppFailure.streamPlayback({required String message}) =
      StreamPlaybackFailure;

  const factory AppFailure.storage({required String message}) = StorageFailure;

  const factory AppFailure.notFound({required String message}) =
      NotFoundFailure;

  const factory AppFailure.validation({required String message}) =
      ValidationFailure;

  const factory AppFailure.entitlementRequired({required String message}) =
      EntitlementRequiredFailure;

  const factory AppFailure.unknown({required String message, Object? cause}) =
      UnknownFailure;

  /// User-facing message safe to display in UI error states.
  String get userMessage => switch (this) {
    NetworkFailure(:final message) => message,
    TimeoutFailure(:final message) => message,
    MirrorUnavailableFailure(:final message) => message,
    StreamPlaybackFailure(:final message) => message,
    StorageFailure(:final message) => message,
    NotFoundFailure(:final message) => message,
    ValidationFailure(:final message) => message,
    EntitlementRequiredFailure(:final message) => message,
    UnknownFailure(:final message) => message,
  };
}
