// models/event_model.dart
class AgencyEvent {
  final String id;
  final String agencyId;
  final String title;
  final String? description;
  final String? location;
  final DateTime eventDate;
  final String? imageUrl;
  final double price;
  final int? capacity;
  final int bookedCount;
  final String category;
  final String status; // 'active', 'cancelled', 'completed'
  final DateTime createdAt;
  final DateTime updatedAt;

  // Agency info (for display)
  final String? agencyName;
  final String? agencyEmail;

  AgencyEvent({
    required this.id,
    required this.agencyId,
    required this.title,
    this.description,
    this.location,
    required this.eventDate,
    this.imageUrl,
    this.price = 0,
    this.capacity,
    this.bookedCount = 0,
    this.category = 'general',
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
    this.agencyName,
    this.agencyEmail,
  });

  factory AgencyEvent.fromJson(Map<String, dynamic> json) {
    return AgencyEvent(
      id: json['id'] as String? ?? '',
      agencyId: json['agency_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      location: json['location'] as String?,
      eventDate: json['event_date'] != null
          ? DateTime.parse(json['event_date'] as String)
          : DateTime.now(),
      imageUrl: json['image_url'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      capacity: json['capacity'] as int?,
      bookedCount: (json['booked_count'] as int?) ?? 0,
      category: json['category'] as String? ?? 'general',
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      agencyName: json['agency_name'] as String?,
      agencyEmail: json['agency_email'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
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
        'agency_name': agencyName,
        'agency_email': agencyEmail,
      };

  bool get isFull => capacity != null && bookedCount >= capacity!;
  bool get isUpcoming => eventDate.isAfter(DateTime.now());
  bool get isCompleted => eventDate.isBefore(DateTime.now());

  // Get remaining capacity
  int get remainingCapacity =>
      capacity != null ? (capacity! - bookedCount).clamp(0, capacity!) : -1;

  AgencyEvent copyWith({
    String? id,
    String? agencyId,
    String? title,
    String? description,
    String? location,
    DateTime? eventDate,
    String? imageUrl,
    double? price,
    int? capacity,
    int? bookedCount,
    String? category,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? agencyName,
    String? agencyEmail,
  }) {
    return AgencyEvent(
      id: id ?? this.id,
      agencyId: agencyId ?? this.agencyId,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      eventDate: eventDate ?? this.eventDate,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      capacity: capacity ?? this.capacity,
      bookedCount: bookedCount ?? this.bookedCount,
      category: category ?? this.category,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      agencyName: agencyName ?? this.agencyName,
      agencyEmail: agencyEmail ?? this.agencyEmail,
    );
  }
}

// Request model for creating events
class CreateEventRequest {
  final String title;
  final String? description;
  final String? location;
  final DateTime eventDate;
  final String? imageUrl;
  final double price;
  final int? capacity;
  final String category;

  CreateEventRequest({
    required this.title,
    this.description,
    this.location,
    required this.eventDate,
    this.imageUrl,
    this.price = 0,
    this.capacity,
    this.category = 'general',
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'location': location,
        'event_date': eventDate.toIso8601String(),
        'image_url': imageUrl,
        'price': price,
        'capacity': capacity,
        'category': category,
      };
}
