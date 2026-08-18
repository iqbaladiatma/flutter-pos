import 'package:equatable/equatable.dart';

/// Pivot table: maps staff to one or more outlets (many-to-many).
class StaffOutletModel extends Equatable {
  final String id;
  final String staffId;
  final String outletId;
  final String assignedAt;

  const StaffOutletModel({
    required this.id,
    required this.staffId,
    required this.outletId,
    required this.assignedAt,
  });

  factory StaffOutletModel.fromJson(Map<String, dynamic> json) =>
      StaffOutletModel(
        id: json['id'] ?? '',
        staffId: json['staff_id'] ?? '',
        outletId: json['outlet_id'] ?? '',
        assignedAt: json['assigned_at'] ?? DateTime.now().toIso8601String(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'staff_id': staffId,
        'outlet_id': outletId,
        'assigned_at': assignedAt,
      };

  @override
  List<Object?> get props => [id, staffId, outletId, assignedAt];
}
