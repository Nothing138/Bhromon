// models/event_model.dart
class EventModel {
  final String id;
  final String agencyId;
  final String title;
  final String description;
  final String location;
  final DateTime eventDate;
  final String? imageUrl;
  final double price;
  final int capacity;
  final int bookedCount;
  final String category;
  final String status; // 'active', 'cancelled', 'completed'
  final DateTime createdAt;
  final DateTime updatedAt;

  EventModel({
    required this.id,
    required this.agencyId,
    required this.title,
    required this.description,
    required this.location,
    required this.eventDate,
    this.imageUrl,
    required this.price,
    required this.capacity,
    required this.bookedCount,
    required this.category,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] ?? '',
      agencyId: json['agency_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      eventDate: DateTime.parse(
          json['event_date'] ?? DateTime.now().toIso8601String()),
      imageUrl: json['image_url'],
      price: (json['price'] ?? 0).toDouble(),
      capacity: json['capacity'] ?? 0,
      bookedCount: json['booked_count'] ?? 0,
      category: json['category'] ?? 'general',
      status: json['status'] ?? 'active',
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agency_id': agencyId,
      'title': title,
      'description': description,
      'location': location,
      'event_date': eventDate.toIso8601String(),
      'image_url': imageUrl,
      'price': price,
      'capacity': capacity,
      'booked_count': bookedCount,
      'category': category,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isUpcoming =>
      eventDate.isAfter(DateTime.now()) && status == 'active';
  bool get isPast => eventDate.isBefore(DateTime.now()) || status != 'active';
  bool get isFull => bookedCount >= capacity;
  int get availableSeats => capacity - bookedCount;

  String get formattedDate {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${eventDate.day} ${months[eventDate.month - 1]} ${eventDate.year}';
  }

  String get formattedTime {
    final hours = eventDate.hour.toString().padLeft(2, '0');
    final minutes = eventDate.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}
