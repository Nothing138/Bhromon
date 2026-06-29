// services/booking_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingService {
  final supabase = Supabase.instance.client;

  ///  Create new booking
  Future<Map<String, dynamic>> createBooking({
    required String eventId,
    required String userId,
    required int bookingCount,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required double totalPrice,
    String? bookingNotes,
  }) async {
    try {
      debugPrint('📝 Creating booking...');
      debugPrint('   Event: $eventId');
      debugPrint('   User: $userId');
      debugPrint('   Count: $bookingCount');
      debugPrint('   Total: $totalPrice');

      final response = await supabase
          .from('event_bookings')
          .insert({
            'event_id': eventId,
            'user_id': userId,
            'booking_count': bookingCount,
            'customer_name': customerName,
            'customer_email': customerEmail,
            'customer_phone': customerPhone,
            'total_price': totalPrice,
            'booking_notes': bookingNotes ?? '',
            'status': 'confirmed',
          })
          .select()
          .single();

      debugPrint(' Booking created: ${response['id']}');

      //  Update event booked_count
      await _updateEventBookedCount(eventId, bookingCount);

      return response as Map<String, dynamic>;
    } catch (e) {
      debugPrint(' Booking error: $e');
      throw Exception('Failed to create booking: $e');
    }
  }

  ///  Update event booked_count
  Future<void> _updateEventBookedCount(String eventId, int addedCount) async {
    try {
      final event = await supabase
          .from('agency_events')
          .select('booked_count, capacity')
          .eq('id', eventId)
          .single();

      final currentBooked = (event['booked_count'] as int? ?? 0);
      final newBooked = currentBooked + addedCount;

      await supabase
          .from('agency_events')
          .update({'booked_count': newBooked}).eq('id', eventId);

      debugPrint(' Event booked count updated: $newBooked');
    } catch (e) {
      debugPrint('Failed to update booked count: $e');
    }
  }

  ///  Get user's bookings
  Future<List<Map<String, dynamic>>> getUserBookings(String userId) async {
    try {
      final bookings = await supabase
          .from('event_bookings')
          .select('*, agency_events(*)')
          .eq('user_id', userId)
          .order('booked_at', ascending: false);

      return List<Map<String, dynamic>>.from(bookings);
    } catch (e) {
      debugPrint(' Error fetching user bookings: $e');
      return [];
    }
  }

  ///  Get event bookings (for agency)
  Future<List<Map<String, dynamic>>> getEventBookings(String eventId) async {
    try {
      final bookings = await supabase
          .from('event_bookings')
          .select('*, profiles(*)')
          .eq('event_id', eventId)
          .eq('status', 'confirmed')
          .order('booked_at', ascending: false);

      return List<Map<String, dynamic>>.from(bookings);
    } catch (e) {
      debugPrint(' Error fetching event bookings: $e');
      return [];
    }
  }

  /// 📊 Get booking stats for event
  Future<Map<String, dynamic>> getEventBookingStats(String eventId) async {
    try {
      final event = await supabase
          .from('agency_events')
          .select('booked_count, capacity, price')
          .eq('id', eventId)
          .single();

      final bookedCount = event['booked_count'] as int? ?? 0;
      final capacity = event['capacity'] as int?;
      final price = (event['price'] as num? ?? 0).toDouble();

      // Calculate occupancy percentage
      double occupancyPercent = 0;
      if (capacity != null && capacity > 0) {
        occupancyPercent = (bookedCount / capacity) * 100;
      }

      return {
        'booked_count': bookedCount,
        'capacity': capacity,
        'price': price,
        'occupancy_percent': occupancyPercent,
        'available_seats': capacity != null ? (capacity - bookedCount) : null,
        'is_full': capacity != null ? bookedCount >= capacity : false,
      };
    } catch (e) {
      debugPrint(' Error fetching booking stats: $e');
      return {};
    }
  }

  ///  Cancel booking
  Future<void> cancelBooking(String bookingId) async {
    try {
      // Get booking details first
      final booking = await supabase
          .from('event_bookings')
          .select('event_id, booking_count')
          .eq('id', bookingId)
          .single();

      final eventId = booking['event_id'] as String;
      final count = booking['booking_count'] as int;

      // Update booking status
      await supabase
          .from('event_bookings')
          .update({'status': 'cancelled'}).eq('id', bookingId);

      // Decrease event booked_count
      final event = await supabase
          .from('agency_events')
          .select('booked_count')
          .eq('id', eventId)
          .single();

      final currentBooked = (event['booked_count'] as int? ?? 0);
      final newBooked = (currentBooked - count).clamp(0, currentBooked);

      await supabase
          .from('agency_events')
          .update({'booked_count': newBooked}).eq('id', eventId);

      debugPrint(' Booking cancelled: $bookingId');
    } catch (e) {
      debugPrint(' Error cancelling booking: $e');
      throw Exception('Failed to cancel booking: $e');
    }
  }

  ///  Check if event is available for booking
  Future<bool> isEventAvailableForBooking(String eventId) async {
    try {
      final event = await supabase
          .from('agency_events')
          .select('event_date, capacity, booked_count, status')
          .eq('id', eventId)
          .single();

      // ① Check if event date is in future
      final eventDate = DateTime.parse(event['event_date'] as String);
      if (eventDate.isBefore(DateTime.now())) {
        debugPrint('⏰ Event date has passed');
        return false;
      }

      // ② Check if event is active
      if (event['status'] != 'active') {
        debugPrint('Event is not active');
        return false;
      }

      // ③ Check capacity
      final capacity = event['capacity'] as int?;
      if (capacity != null) {
        final booked = (event['booked_count'] as int? ?? 0);
        if (booked >= capacity) {
          debugPrint('🚫 Event is full');
          return false;
        }
      }

      debugPrint(' Event is available for booking');
      return true;
    } catch (e) {
      debugPrint(' Error checking availability: $e');
      return false;
    }
  }

  /// 📱 Stream user bookings (real-time)
  Stream<List<Map<String, dynamic>>> streamUserBookings(String userId) {
    try {
      return supabase
          .from('event_bookings')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('booked_at', ascending: false)
          .map((bookingsList) {
            return List<Map<String, dynamic>>.from(bookingsList);
          })
          .handleError((error) {
            debugPrint(' Stream error: $error');
            return [];
          });
    } catch (e) {
      debugPrint(' Error creating stream: $e');
      return Stream.value([]);
    }
  }

  ///  CHECK IF USER ALREADY BOOKED THIS EVENT
  Future<bool> hasUserBookedEvent(String eventId, String userId) async {
    try {
      final booking = await supabase
          .from('event_bookings')
          .select('id')
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .eq('status', 'confirmed');

      return booking.isNotEmpty;
    } catch (e) {
      debugPrint(' Error checking booking: $e');
      return false;
    }
  }

  ///  STREAM EVENT DETAILS (for real-time seat updates)
  Stream<Map<String, dynamic>?> streamEventDetails(String eventId) {
    try {
      return supabase
          .from('agency_events')
          .stream(primaryKey: ['id'])
          .eq('id', eventId)
          .map((eventsList) {
            if (eventsList.isNotEmpty) {
              return Map<String, dynamic>.from(eventsList.first);
            }
            return null;
          })
          .handleError((error) {
            debugPrint(' Event stream error: $error');
            return null;
          });
    } catch (e) {
      debugPrint(' Error creating event stream: $e');
      return Stream.value(null);
    }
  }
}
