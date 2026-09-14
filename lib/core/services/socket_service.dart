import 'dart:async';
import 'dart:developer' as developer;

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../constants/api_endpoints.dart';
import '../storage/secure_storage_service.dart';

class SocketService {
  final SecureStorageService secureStorage;
  io.Socket? _socket;

  /// Guards against two callers racing `connect()`. Without this, a page and a
  /// bloc that both connect on mount can each build a socket, and the loser's
  /// handlers are registered against a socket nobody keeps.
  Future<void>? _connecting;

  /// Handlers registered by callers. Kept so they can be re-attached to a
  /// socket rebuilt after a token change, and so [on] works even when it is
  /// called before the socket exists.
  final Map<String, List<Function(dynamic)>> _handlers = {};

  String? _connectedWithToken;

  SocketService(this.secureStorage);

  bool get isConnected => _socket?.connected ?? false;

  /// Opens the real-time connection, authenticating as the current customer.
  ///
  /// The server reads the JWT from `handshake.auth.token` or
  /// `handshake.query.token` (see backend `app/socket/socketManager.js`).
  /// It never looks at request headers — an `extraHeaders` token is not sent
  /// over the websocket transport at all, so a socket authenticated that way
  /// connects as an anonymous client and is never joined to the
  /// `customer:<id>` room that every server-side event is addressed to.
  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;
    if (_connecting != null) return _connecting;

    final completer = Completer<void>();
    _connecting = completer.future;
    try {
      final token = await secureStorage.getCustomerToken();

      // A token change means the old socket is authenticated as someone else.
      if (_socket != null && _connectedWithToken != token) {
        _disposeSocket();
      }

      if (_socket == null) {
        _socket = io.io(
          ApiEndpoints.defaultSocketUrl,
          io.OptionBuilder()
              .setTransports(['websocket', 'polling'])
              .disableAutoConnect()
              .enableReconnection()
              .setAuth(token != null && token.isNotEmpty ? {'token': token} : {})
              .setQuery(
                token != null && token.isNotEmpty ? {'token': token} : {},
              )
              .build(),
        );
        _connectedWithToken = token;

        _socket?.onConnect((_) {
          developer.log(
            '[SocketService] Connected as customer',
            name: 'SocketService',
          );
        });

        _socket?.onDisconnect((_) {
          developer.log(
            '[SocketService] Disconnected from server',
            name: 'SocketService',
          );
        });

        _socket?.onConnectError((err) {
          developer.log(
            '[SocketService] Connect error: $err',
            name: 'SocketService',
          );
        });

        // Re-attach anything registered before the socket existed.
        _handlers.forEach((event, handlers) {
          for (final handler in handlers) {
            _socket?.on(event, handler);
          }
        });
      }

      _socket?.connect();
    } catch (e) {
      developer.log(
        '[SocketService] Connection error: $e',
        name: 'SocketService',
      );
    } finally {
      completer.complete();
      _connecting = null;
    }
  }

  /// Registers [handler] for [event]. Safe to call before [connect] completes —
  /// the handler is stored and attached as soon as the socket exists.
  void on(String event, Function(dynamic) handler) {
    _handlers.putIfAbsent(event, () => []).add(handler);
    _socket?.on(event, handler);
  }

  /// Removes every handler for [event]. Call this before re-registering so
  /// repeated page mounts do not stack duplicate listeners.
  void off(String event) {
    _handlers.remove(event);
    _socket?.off(event);
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  void _disposeSocket() {
    _socket?.clearListeners();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connectedWithToken = null;
  }

  void disconnect() {
    _disposeSocket();
  }

  /// Tears the connection down and forgets every handler. Used on logout so
  /// the next customer does not inherit the previous session's listeners.
  void reset() {
    _handlers.clear();
    _disposeSocket();
  }
}
