// models/event_booking_model.dart
class EventBookingModel {
  final String id;
  final String eventId;
  final String userId;
  final int bookingCount;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final double totalPrice;
  final String status; // 'pending', 'confirmed', 'cancelled'
  final String? bookingNotes;
  final DateTime bookedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventBookingModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.bookingCount,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.totalPrice,
    required this.status,
    this.bookingNotes,
    required this.bookedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventBookingModel.fromJson(Map<String, dynamic> json) {
    return EventBookingModel(
      id: json['id'] ?? '',
      eventId: json['event_id'] ?? '',
      userId: json['user_id'] ?? '',
      bookingCount: json['booking_count'] ?? 0,
      customerName: json['customer_name'] ?? '',
      customerEmail: json['customer_email'] ?? '',
      customerPhone: json['customer_phone'] ?? '',
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      bookingNotes: json['booking_notes'],
      bookedAt:
          DateTime.parse(json['booked_at'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'user_id': userId,
      'booking_count': bookingCount,
      'customer_name': customerName,
      'customer_email': customerEmail,
      'customer_phone': customerPhone,
      'total_price': totalPrice,
      'status': status,
      'booking_notes': bookingNotes,
      'booked_at': bookedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ========================
  // STATUS CHECKS
  // ========================
  bool get isConfirmed => status == 'confirmed';
  bool get isPending => status == 'pending';
  bool get isCancelled => status == 'cancelled';

  // ========================
  // CALCULATED PROPERTIES
  // ========================
  double get pricePerSeat => totalPrice / bookingCount;
  String get bookingRef => id.substring(0, 8).toUpperCase();
  int get daysAgo {
    return DateTime.now().difference(bookedAt).inDays;
  }

  // ========================
  // FORMATTING - DATE & TIME
  // ========================
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
    return '${bookedAt.day} ${months[bookedAt.month - 1]} ${bookedAt.year}';
  }

  String get formattedTime {
    final hours = bookedAt.hour.toString().padLeft(2, '0');
    final minutes = bookedAt.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  String get formattedDateTime {
    return '$formattedDate at $formattedTime';
  }

  String get relativeTime {
    if (daysAgo == 0) {
      return 'Today';
    } else if (daysAgo == 1) {
      return 'Yesterday';
    } else if (daysAgo < 7) {
      return '$daysAgo days ago';
    } else {
      return formattedDate;
    }
  }

  // ========================
  // FORMATTING - PRICE
  // ========================
  String get formattedTotalPrice => '৳${totalPrice.toStringAsFixed(2)}';
  String get formattedPricePerSeat => '৳${pricePerSeat.toStringAsFixed(2)}';

  // ========================
  // FORMATTING - CUSTOMER INFO
  // ========================
  String get customerInitials {
    final nameParts = customerName.trim().split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return nameParts[0].substring(0, 2).toUpperCase();
  }

  String get maskedEmail {
    if (customerEmail.isEmpty) return 'N/A';
    final parts = customerEmail.split('@');
    final localPart = parts[0];
    if (localPart.length <= 2) return customerEmail;
    return '${localPart.substring(0, 2)}***@${parts[1]}';
  }

  String get maskedPhone {
    if (customerPhone.isEmpty) return 'N/A';
    if (customerPhone.length < 4) return customerPhone;
    return '${customerPhone.substring(0, 3)}***${customerPhone.substring(customerPhone.length - 2)}';
  }

  // ========================
  // STATUS DESCRIPTIONS
  // ========================
  String get statusDescription {
    switch (status) {
      case 'confirmed':
        return 'Payment received & booking confirmed';
      case 'pending':
        return 'Awaiting confirmation';
      case 'cancelled':
        return 'Booking has been cancelled';
      default:
        return 'Unknown status';
    }
  }

  // ========================
  // SEAT INFORMATION
  // ========================
  String get formattedSeats {
    return '$bookingCount ${bookingCount == 1 ? 'Seat' : 'Seats'}';
  }

  // ========================
  // SUMMARY
  // ========================
  String get summaryText {
    return '$customerName booked $formattedSeats for $formattedTotalPrice';
  }
}
