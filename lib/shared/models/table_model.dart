enum TableStatus { available, occupied, reserved, billPrinted }

class TableModel {
  final String id;
  final String outletId;
  final String name;
  final int capacity;
  final double positionX;
  final double positionY;
  final TableStatus status;
  final String? currentOrderId;

  TableModel({
    required this.id,
    required this.outletId,
    required this.name,
    required this.capacity,
    this.positionX = 0,
    this.positionY = 0,
    this.status = TableStatus.available,
    this.currentOrderId,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    TableStatus status;
    switch (json['status']) {
      case 'occupied':
        status = TableStatus.occupied;
        break;
      case 'reserved':
        status = TableStatus.reserved;
        break;
      case 'bill_printed':
        status = TableStatus.billPrinted;
        break;
      default:
        status = TableStatus.available;
    }

    return TableModel(
      id: json['id'] ?? '',
      outletId: json['outlet_id'] ?? '',
      name: json['name'] ?? '',
      capacity: json['capacity'] ?? 4,
      positionX: (json['position_x'] as num?)?.toDouble() ?? 0,
      positionY: (json['position_y'] as num?)?.toDouble() ?? 0,
      status: status,
      currentOrderId: json['current_order_id'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'outlet_id': outletId,
        'name': name,
        'capacity': capacity,
        'position_x': positionX,
        'position_y': positionY,
        'status': status.name,
        'current_order_id': currentOrderId,
      };
}
