import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/printer/thermal_printer_service.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../domain/entities/kitchen_ticket.dart';
import '../../domain/repositories/kitchen_repository.dart';
import '../../services/kitchen_audio_service.dart';
import '../bloc/kitchen_bloc.dart';
import '../bloc/kitchen_event.dart';
import '../bloc/kitchen_state.dart';

/// Kitchen Display System (KDS) screen.
///
/// Displays a kanban board of active kitchen tickets with real-time
/// updates, audio alerts, and quick status actions.
class KitchenScreen extends StatelessWidget {
  final String outletId;

  const KitchenScreen({super.key, required this.outletId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => KitchenBloc(repository: getIt<KitchenRepository>())
        ..add(KitchenStartWatching(outletId: outletId)),
      child: _KitchenView(outletId: outletId),
    );
  }
}

class _KitchenView extends StatefulWidget {
  final String outletId;
  const _KitchenView({required this.outletId});

  @override
  State<_KitchenView> createState() => _KitchenViewState();
}

class _KitchenViewState extends State<_KitchenView> {
  int? _previousNewTicketCount;
  bool _audioEnabled = true;

  @override
  void dispose() {
    context.read<KitchenBloc>().add(const KitchenStopWatching());
    super.dispose();
  }

  void _checkForNewTickets(KitchenLoaded state) {
    if (!_audioEnabled) return;
    final currentNewCount =
        state.tickets.where((t) => t.isNew).length;
    if (_previousNewTicketCount != null &&
        currentNewCount > _previousNewTicketCount!) {
      KitchenAudioService.instance.playNewOrderChime();
    }
    _previousNewTicketCount = currentNewCount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.restaurant, color: AppColors.primaryLight),
            SizedBox(width: 10),
            Text('Kitchen Display', style: AppTextStyles.titleLarge),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_audioEnabled ? Icons.volume_up : Icons.volume_off),
            tooltip: _audioEnabled ? 'Nonaktifkan suara' : 'Aktifkan suara',
            onPressed: () {
              setState(() => _audioEnabled = !_audioEnabled);
              KitchenAudioService.instance.setEnabled(_audioEnabled);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => context.read<KitchenBloc>()
                .add(KitchenLoadTickets(outletId: widget.outletId)),
          ),
        ],
      ),
      body: BlocConsumer<KitchenBloc, KitchenState>(
        listener: (context, state) {
          if (state is KitchenError) {
            SnackbarHelper.showError(context, state.message);
          }
          if (state is KitchenLoaded) {
            _checkForNewTickets(state);
          }
        },
        builder: (context, state) {
          return switch (state) {
            KitchenInitial() => const _EmptyView(),
            KitchenLoading() => const Center(child: CircularProgressIndicator()),
            KitchenLoaded(:final tickets) => _KanbanBoard(
                tickets: tickets,
                onMarkPreparing: (orderId) => _updateStatus(
                    context, orderId, 'preparing'),
                onMarkReady: (orderId) =>
                    _updateStatus(context, orderId, 'ready'),
                onMarkCompleted: (orderId) =>
                    _updateStatus(context, orderId, 'completed'),
                onPrintLabel: (ticket) => _printLabel(context, ticket),
              ),
            KitchenError(:final message) => _ErrorView(message: message),
          };
        },
      ),
    );
  }

  void _updateStatus(BuildContext context, String orderId, String status) {
    context
        .read<KitchenBloc>()
        .add(KitchenUpdateStatus(orderId: orderId, newStatus: status));
  }

  void _printLabel(BuildContext context, KitchenTicket ticket) {
    final printer = ThermalPrinterService();
    if (!printer.isKitchenConnected && !printer.isReceiptConnected) {
      SnackbarHelper.showWarning(context, 'Printer dapur belum terhubung');
      return;
    }
    final kitchenItems = ticket.items
        .map((item) => {
              'qty': item.quantity,
              'name': item.productName,
              'note': item.notes,
            })
        .toList();
    printer.printKitchenLabel(
      orderNumber: ticket.orderNumber,
      orderType: ticket.orderType.name,
      kitchenItems: kitchenItems,
      tableNumber: ticket.tableNumber,
    );
    SnackbarHelper.showSuccess(context, 'Label dapur dicetak');
  }
}

class _KanbanBoard extends StatelessWidget {
  final List<KitchenTicket> tickets;
  final void Function(String orderId) onMarkPreparing;
  final void Function(String orderId) onMarkReady;
  final void Function(String orderId) onMarkCompleted;
  final void Function(KitchenTicket ticket) onPrintLabel;

  const _KanbanBoard({
    required this.tickets,
    required this.onMarkPreparing,
    required this.onMarkReady,
    required this.onMarkCompleted,
    required this.onPrintLabel,
  });

  @override
  Widget build(BuildContext context) {
    final pending = tickets.where((t) => t.isNew).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final preparing = tickets.where((t) => t.isPreparing).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final ready = tickets.where((t) => t.isReady).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _KanbanColumn(
            title: 'ANTRIAN BARU',
            color: AppColors.warning,
            tickets: pending,
            actionLabel: 'MULAI MASAK',
            onAction: onMarkPreparing,
            onPrintLabel: onPrintLabel,
          ),
          _KanbanColumn(
            title: 'SEDANG DIMASAK',
            color: AppColors.primary,
            tickets: preparing,
            actionLabel: 'SELESAI',
            onAction: onMarkReady,
            onPrintLabel: onPrintLabel,
          ),
          _KanbanColumn(
            title: 'SIAP DIANTAR',
            color: AppColors.success,
            tickets: ready,
            actionLabel: 'SELESAIKAN',
            onAction: onMarkCompleted,
            onPrintLabel: onPrintLabel,
          ),
        ],
      ),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final String title;
  final Color color;
  final List<KitchenTicket> tickets;
  final String actionLabel;
  final void Function(String orderId) onAction;
  final void Function(KitchenTicket ticket) onPrintLabel;

  const _KanbanColumn({
    required this.title,
    required this.color,
    required this.tickets,
    required this.actionLabel,
    required this.onAction,
    required this.onPrintLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Column header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: AppTextStyles.titleMedium.copyWith(color: Colors.white)),
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 12,
                  child: Text(
                    '${tickets.length}',
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          // Tickets
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              child: tickets.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Tidak ada pesanan',
                            style: AppTextStyles.caption),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: tickets.length,
                      itemBuilder: (ctx, i) => _TicketCard(
                        ticket: tickets[i],
                        actionLabel: actionLabel,
                        onAction: () => onAction(tickets[i].id),
                        onPrintLabel: () => onPrintLabel(tickets[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final KitchenTicket ticket;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback onPrintLabel;

  const _TicketCard({
    required this.ticket,
    required this.actionLabel,
    required this.onAction,
    required this.onPrintLabel,
  });

  String _formatElapsed(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins}m ${secs}s';
  }

  Color _elapsedColor(int seconds) {
    if (seconds > 600) return AppColors.error; // > 10 min
    if (seconds > 300) return AppColors.warning; // > 5 min
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: order # + elapsed time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('#${ticket.orderNumber}',
                    style: AppTextStyles.titleMedium),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _elapsedColor(ticket.elapsedSeconds)
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatElapsed(ticket.elapsedSeconds),
                    style: TextStyle(
                      color: _elapsedColor(ticket.elapsedSeconds),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Order type + table
            Row(
              children: [
                Icon(
                  ticket.orderType.name == 'dine_in'
                      ? Icons.table_restaurant
                      : ticket.orderType.name == 'delivery'
                          ? Icons.delivery_dining
                          : Icons.shopping_bag,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  ticket.orderType.name == 'dine_in'
                      ? 'Dine-in${ticket.tableNumber != null ? " • Meja ${ticket.tableNumber}" : ""}'
                      : ticket.orderType.name == 'delivery'
                          ? 'Delivery'
                          : 'Takeaway',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            const Divider(),
            // Items
            ...ticket.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${item.quantity}x ',
                          style: AppTextStyles.titleMedium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName,
                                style: AppTextStyles.bodyMedium),
                            if (item.variantName != null)
                              Text('Varian: ${item.variantName}',
                                  style: AppTextStyles.caption),
                            if (item.notes != null &&
                                item.notes!.isNotEmpty)
                              Text('Note: ${item.notes}',
                                  style: AppTextStyles.caption.copyWith(
                                      color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
            // Actions
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onAction,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(actionLabel, style: const TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.print, size: 20),
                  tooltip: 'Cetak label dapur',
                  onPressed: onPrintLabel,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 64, color: AppColors.primary),
          SizedBox(height: 16),
          Text('Menunggu pesanan...', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(message,
                style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
