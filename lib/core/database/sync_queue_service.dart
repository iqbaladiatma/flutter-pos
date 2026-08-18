import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import '../network/connectivity_service.dart';
import '../network/supabase_service.dart';

/// Type of sync operation queued for replay.
enum SyncOperation {
  insertOrder,
  updateOrderStatus,
  insertOrderPayment,
  genericInsert,
  genericUpdate,
}

/// Service that manages the offline sync queue.
///
/// When offline, operations are enqueued via [enqueue]. When connectivity
/// is restored, [processQueue] replays each operation against Supabase
/// with exponential backoff retry.
class SyncQueueService {
  SyncQueueService({
    required AppDatabase database,
    ConnectivityService? connectivityService,
    SupabaseService? supabaseService,
  })  : _db = database,
        _connectivity = connectivityService ?? ConnectivityService.instance,
        _supabase = supabaseService ?? SupabaseService() {
    _init();
  }

  final AppDatabase _db;
  final ConnectivityService _connectivity;
  final SupabaseService _supabase;

  StreamSubscription<bool>? _connectivitySub;
  bool _isProcessing = false;

  /// Stream that emits the count of pending sync operations.
  final _pendingCountController = StreamController<int>.broadcast();
  Stream<int> get pendingCountStream => _pendingCountController.stream;

  void _init() {
    // Listen for connectivity changes — trigger sync when back online.
    _connectivitySub = _connectivity.isOnlineStream.listen((isOnline) {
      if (isOnline) {
        processQueue();
      }
    });
  }

  /// Disposes resources. Call in app shutdown.
  void dispose() {
    _connectivitySub?.cancel();
    _pendingCountController.close();
  }

  /// Enqueues a sync operation for later replay.
  Future<void> enqueue({
    required SyncOperation operation,
    required String table,
    required Map<String, dynamic> payload,
  }) async {
    await _db.enqueueSync(SyncQueueCompanion.insert(
      id: _generateId(),
      operation: operation.name,
      table_: table,
      payloadJson: jsonEncode(payload),
    ));
    await _refreshPendingCount();

    // Try to process immediately if online.
    if (await _connectivity.isOnline) {
      processQueue();
    }
  }

  /// Processes all pending sync operations in FIFO order.
  ///
  /// Stops when the queue is empty or when an operation fails after
  /// exceeding the max retry count. Failed operations get scheduled
  /// for retry with exponential backoff.
  Future<void> processQueue() async {
    if (_isProcessing) return;
    if (!await _connectivity.isOnline) return;
    if (!_supabase.isReady) return;

    _isProcessing = true;
    try {
      final pending = await _db.getPendingSyncOperations();

      for (final op in pending) {
        final success = await _processOperation(op);
        if (success) {
          await _db.dequeueSync(op.id);
        } else {
          // Schedule retry with exponential backoff.
          final backoff = _calculateBackoff(op.retryCount);
          await _db.markSyncFailed(
            id: op.id,
            error: 'Operation failed (attempt ${op.retryCount + 1})',
            nextRetryAt: DateTime.now().add(backoff),
          );
          // Stop processing — will retry after backoff.
          break;
        }
      }
      await _refreshPendingCount();
    } finally {
      _isProcessing = false;
    }
  }

  /// Executes a single sync operation against Supabase.
  Future<bool> _processOperation(SyncQueueData op) async {
    try {
      final payload = jsonDecode(op.payloadJson) as Map<String, dynamic>;
      final client = _supabase.client;

      switch (op.operation) {
        case 'insertOrder':
          // Insert order header + items.
          final orderData = await client
              .from(op.table_)
              .insert(payload['order'] as Map<String, dynamic>)
              .select()
              .single();
          final orderId = orderData['id'];
          final items = payload['items'] as List;
          if (items.isNotEmpty) {
            final itemInserts = items.map((item) {
              final m = item as Map<String, dynamic>;
              return {...m, 'order_id': orderId};
            }).toList();
            await client.from('order_items').insert(itemInserts);
          }
          break;

        case 'updateOrderStatus':
          await client
              .from(op.table_)
              .update(payload)
              .eq('id', payload['id'] as String);
          break;

        case 'genericInsert':
          await client.from(op.table_).insert(payload);
          break;

        case 'genericUpdate':
          await client
              .from(op.table_)
              .update(payload)
              .eq('id', payload['id'] as String);
          break;

        default:
          if (kDebugMode) {
            // ignore: avoid_print
            print('Unknown sync operation: ${op.operation}');
          }
          return false;
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Sync operation failed: $e');
      }
      return false;
    }
  }

  /// Exponential backoff: 2^retry * 1s, capped at 5 minutes.
  Duration _calculateBackoff(int retryCount) {
    final seconds = pow(2, retryCount).toInt();
    return Duration(seconds: min(seconds, 300));
  }

  Future<void> _refreshPendingCount() async {
    final count = await _db.getPendingSyncCount();
    _pendingCountController.add(count);
  }

  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}-${_randomString(8)}';
  }

  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)])
        .join();
  }
}
