import 'thread_session.dart';

class ThreadSessionConnectionCoordinator {
  const ThreadSessionConnectionCoordinator();

  ThreadSession onStreamDisconnected(
    ThreadSession current, {
    required String message,
  }) {
    if (current.requiresSharedStateRecovery ||
        current.connectionStatus == ConnectionStatus.degraded) {
      return current.copyWith(
        connectionStatus: ConnectionStatus.degraded,
        lastErrorMessage: message,
      );
    }

    return current.copyWith(
      connectionStatus: ConnectionStatus.reconnecting,
      lastErrorMessage: message,
    );
  }

  ThreadSession onReconnectSucceeded(
    ThreadSession current, {
    required DateTime recoveredAt,
  }) {
    final nextStatus =
        current.requiresSharedStateRecovery ||
            current.connectionStatus == ConnectionStatus.degraded
        ? ConnectionStatus.degraded
        : ConnectionStatus.online;

    return current.copyWith(
      connectionStatus: nextStatus,
      lastErrorMessage: null,
      lastEventAt: recoveredAt,
    );
  }
}
