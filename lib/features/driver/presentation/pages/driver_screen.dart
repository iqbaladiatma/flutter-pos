import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../../../../shared/models/delivery_assignment_model.dart';
import '../../domain/repositories/driver_repository.dart';
import '../bloc/driver_bloc.dart';
import '../bloc/driver_event.dart';
import '../bloc/driver_state.dart';

/// Driver app screen: status toggle, assignment list, active deliveries,
/// route map, and proof of delivery.
class DriverScreen extends StatelessWidget {
  final String driverId;

  const DriverScreen({super.key, required this.driverId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DriverBloc(repository: getIt<DriverRepository>())
        ..add(DriverLoad(driverId: driverId)),
      child: _DriverView(driverId: driverId),
    );
  }
}

class _DriverView extends StatelessWidget {
  final String driverId;
  const _DriverView({required this.driverId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver', style: AppTextStyles.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<DriverBloc>().add(const DriverRefresh()),
          ),
        ],
      ),
      body: BlocConsumer<DriverBloc, DriverState>(
        listener: (context, state) {
          if (state is DriverError) {
            SnackbarHelper.showError(context, state.message);
          }
          if (state is DriverLoaded && state.errorMessage != null) {
            SnackbarHelper.showError(context, state.errorMessage!);
          }
        },
        builder: (context, state) {
          return switch (state) {
            DriverInitial() => const _LoadingView(),
            DriverLoading() => const _LoadingView(),
            DriverLoaded() => _DriverContent(
                state: state,
                driverId: driverId,
              ),
            DriverError(:final message) => _ErrorView(message: message),
          };
        },
      ),
    );
  }
}

class _DriverContent extends StatelessWidget {
  final DriverLoaded state;
  final String driverId;

  const _DriverContent({required this.state, required this.driverId});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status card
        _StatusCard(state: state, driverId: driverId),
        const SizedBox(height: 16),
        // Active deliveries
        if (state.hasActiveDeliveries) ...[
          const Text('Pengiriman Aktif', style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          ...state.activeAssignments.map(
            (a) => _ActiveDeliveryCard(
              assignment: a,
              state: state,
              driverId: driverId,
            ),
          ),
          const SizedBox(height: 16),
          // Route map
          if (state.latitude != null && state.longitude != null)
            _RouteMap(state: state),
          const SizedBox(height: 16),
        ],
        // Pending assignments
        const Text('Penugasan Menunggu', style: AppTextStyles.titleMedium),
        const SizedBox(height: 8),
        if (!state.hasPendingAssignments && !state.hasActiveDeliveries)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text('Tidak ada penugasan saat ini',
                  style: AppTextStyles.caption),
            ),
          )
        else
          ...state.pendingAssignments.map(
            (a) => _PendingAssignmentCard(
              assignment: a,
              driverId: driverId,
              isUpdating: state.isUpdating,
            ),
          ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final DriverLoaded state;
  final String driverId;

  const _StatusCard({required this.state, required this.driverId});

  @override
  Widget build(BuildContext context) {
    final isActive = state.isActive;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isActive ? Icons.circle : Icons.circle_outlined,
              color: isActive ? AppColors.success : AppColors.error,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isActive ? 'Aktif' : 'Tidak Aktif',
                    style: AppTextStyles.titleMedium,
                  ),
                  Text(
                    state.isOnDelivery
                        ? 'Sedang mengantar'
                        : 'Siap menerima penugasan',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            Switch(
              value: isActive,
              activeThumbColor: AppColors.success,
              onChanged: state.isOnDelivery
                  ? null // Can't toggle off while on delivery
                  : (value) {
                      context.read<DriverBloc>().add(
                            DriverToggleStatus(
                              driverId: driverId,
                              newStatus: value ? 'active' : 'inactive',
                            ),
                          );
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingAssignmentCard extends StatelessWidget {
  final DeliveryAssignmentModel assignment;
  final String driverId;
  final bool isUpdating;

  const _PendingAssignmentCard({
    required this.assignment,
    required this.driverId,
    required this.isUpdating,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_shipping, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pengiriman #${assignment.deliveryId.substring(0, 8)}',
                    style: AppTextStyles.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Detail Pengiriman:', style: AppTextStyles.caption),
            const SizedBox(height: 4),
            // Note: In production, fetch delivery details for full info
            Text('ID: ${assignment.deliveryId}',
                style: AppTextStyles.bodyMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isUpdating
                        ? null
                        : () => context.read<DriverBloc>().add(
                              DriverAcceptAssignment(
                                assignmentId: assignment.id,
                                driverId: driverId,
                              ),
                            ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Terima'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isUpdating
                        ? null
                        : () => context.read<DriverBloc>().add(
                              DriverRejectAssignment(
                                assignmentId: assignment.id,
                                driverId: driverId,
                              ),
                            ),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Tolak'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveDeliveryCard extends StatelessWidget {
  final DeliveryAssignmentModel assignment;
  final DriverLoaded state;
  final String driverId;

  const _ActiveDeliveryCard({
    required this.assignment,
    required this.state,
    required this.driverId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pengiriman #${assignment.deliveryId.substring(0, 8)}',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 12),
            // Status update buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: state.isUpdating
                        ? null
                        : () => context.read<DriverBloc>().add(
                              DriverUpdateDeliveryStatus(
                                deliveryId: assignment.deliveryId,
                                status: 'picked_up',
                              ),
                            ),
                    icon: const Icon(Icons.inventory_2, size: 18),
                    label: const Text('Diambil'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: state.isUpdating
                        ? null
                        : () => context.read<DriverBloc>().add(
                              DriverUpdateDeliveryStatus(
                                deliveryId: assignment.deliveryId,
                                status: 'in_transit',
                              ),
                            ),
                    icon: const Icon(Icons.local_shipping, size: 18),
                    label: const Text('Dijalan'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Proof of delivery
            OutlinedButton.icon(
              onPressed: state.isUpdating
                  ? null
                  : () => _showProofDialog(context, assignment.deliveryId),
              icon: const Icon(Icons.camera_alt, size: 18),
              label: const Text('Upload Bukti Pengiriman'),
            ),
          ],
        ),
      ),
    );
  }

  void _showProofDialog(BuildContext context, String deliveryId) {
    SnackbarHelper.showInfo(
        context, 'Fitur upload foto memerlukan akses kamera (coming soon)');
    // In production, this would use image_picker to take a photo
    // then dispatch DriverUploadProof event
  }
}

class _RouteMap extends StatelessWidget {
  final DriverLoaded state;
  const _RouteMap({required this.state});

  @override
  Widget build(BuildContext context) {
    final driverPos = LatLng(state.latitude!, state.longitude!);

    return SizedBox(
      height: 250,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: driverPos,
            initialZoom: 14,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.postsa.pos',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: driverPos,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.local_shipping,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
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
