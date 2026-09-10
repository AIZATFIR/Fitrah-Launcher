/// Centralized Typed Application Errors for Sadar & Focus Clock
/// As specified in PRD 3 Section 14.
library;

sealed class AppError implements Exception {
  final String message;
  final String? code;
  final Object? cause;

  const AppError(this.message, {this.code, this.cause});

  @override
  String toString() => '[$runtimeType${code != null ? ' ($code)' : ''}] $message';
}

class ValidationError extends AppError {
  const ValidationError(super.message, {super.code, super.cause});
}

class StorageError extends AppError {
  const StorageError(super.message, {super.code, super.cause});
}

class NetworkError extends AppError {
  const NetworkError(super.message, {super.code, super.cause});
}

class SyncError extends AppError {
  const SyncError(super.message, {super.code, super.cause});
}

class PlatformError extends AppError {
  const PlatformError(super.message, {super.code, super.cause});
}

class TimerStateError extends AppError {
  const TimerStateError(super.message, {super.code, super.cause});
}
