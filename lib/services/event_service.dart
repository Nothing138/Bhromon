// services/event_service.dart
// services/event_service.dart - FIXED (AgencyEvent class removed)
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_model.dart'; // ✅ Import from models only

class EventService extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  List<AgencyEvent> _allEvents = [];
  List<AgencyEvent> _agencyEvents = [];
  bool _isLoading = false;
  String? _error;

  List<AgencyEvent> get allEvents => _allEvents;
  List<AgencyEvent> get agencyEvents => _agencyEvents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ========================
  // FETCH ALL EVENTS
  // ========================
  Future<void> fetchAllEvents() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('🔄 Fetching all events...');

      final response = await supabase
          .from('agency_events')
          .select()
          .eq('status', 'active')
          .order('event_date', ascending: true);

      _allEvents = (response as List<dynamic>)
          .map((item) => AgencyEvent.fromJson(item as Map<String, dynamic>))
          .toList();

      print('✅ Fetched ${_allEvents.length} events');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Error fetching events: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========================
  // FETCH AGENCY EVENTS
  // ========================
  Future<void> fetchAgencyEvents(String agencyId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('🔄 Fetching events for agency: $agencyId');

      final response = await supabase
          .from('agency_events')
          .select()
          .eq('agency_id', agencyId)
          .order('event_date', ascending: true);

      _agencyEvents = (response as List<dynamic>)
          .map((item) => AgencyEvent.fromJson(item as Map<String, dynamic>))
          .toList();

      print('✅ Fetched ${_agencyEvents.length} agency events');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Error fetching agency events: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========================
  // CREATE EVENT
  // ========================
  Future<AgencyEvent?> createEvent({
    required String agencyId,
    required String title,
    required String description,
    required String location,
    required DateTime eventDate,
    required double price,
    required int capacity,
    String? imageUrl,
    String category = 'general',
  }) async {
    try {
      print('🔄 Creating event: $title');

      final response = await supabase
          .from('agency_events')
          .insert({
            'agency_id': agencyId,
            'title': title,
            'description': description,
            'location': location,
            'event_date': eventDate.toIso8601String(),
            'price': price,
            'capacity': capacity,
            'image_url': imageUrl,
            'category': category,
            'status': 'active',
          })
          .select()
          .single();

      final event = AgencyEvent.fromJson(response as Map<String, dynamic>);
      print('✅ Event created: ${event.id}');

      // Refresh events
      await fetchAllEvents();
      await fetchAgencyEvents(agencyId);

      return event;
    } catch (e) {
      print('❌ Error creating event: $e');
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ========================
  // UPDATE EVENT
  // ========================
  Future<bool> updateEvent({
    required String eventId,
    required String agencyId,
    required String title,
    required String description,
    required String location,
    required DateTime eventDate,
    required double price,
    required int capacity,
    String? imageUrl,
    String? category,
  }) async {
    try {
      print('🔄 Updating event: $eventId');

      await supabase.from('agency_events').update({
        'title': title,
        'description': description,
        'location': location,
        'event_date': eventDate.toIso8601String(),
        'price': price,
        'capacity': capacity,
        if (imageUrl != null) 'image_url': imageUrl,
        if (category != null) 'category': category,
      }).eq('id', eventId);

      print('✅ Event updated: $eventId');

      // Refresh events
      await fetchAllEvents();
      await fetchAgencyEvents(agencyId);

      return true;
    } catch (e) {
      print('❌ Error updating event: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ========================
  // DELETE EVENT - ✅ FIXED: Now takes eventId and agencyId
  // ========================
  Future<bool> deleteEvent(String eventId, String agencyId) async {
    try {
      print('🔄 Deleting event: $eventId');

      await supabase.from('agency_events').delete().eq('id', eventId);

      print('✅ Event deleted: $eventId');

      // Refresh events
      await fetchAllEvents();
      await fetchAgencyEvents(agencyId);

      return true;
    } catch (e) {
      print('❌ Error deleting event: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ========================
  // CANCEL EVENT
  // ========================
  Future<bool> cancelEvent(String eventId, String agencyId) async {
    try {
      print('🔄 Cancelling event: $eventId');

      await supabase
          .from('agency_events')
          .update({'status': 'cancelled'}).eq('id', eventId);

      print('✅ Event cancelled: $eventId');

      // Refresh events
      await fetchAllEvents();
      await fetchAgencyEvents(agencyId);

      return true;
    } catch (e) {
      print('❌ Error cancelling event: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ========================
  // SEARCH EVENTS
  // ========================
  List<AgencyEvent> searchEvents(String query) {
    if (query.isEmpty) {
      return _allEvents;
    }

    return _allEvents
        .where((event) =>
            event.title.toLowerCase().contains(query.toLowerCase()) ||
            event.description?.toLowerCase().contains(query.toLowerCase()) ==
                true ||
            event.location?.toLowerCase().contains(query.toLowerCase()) == true)
        .toList();
  }

  // ========================
  // FILTER EVENTS BY CATEGORY
  // ========================
  List<AgencyEvent> getEventsByCategory(String category) {
    return _allEvents.where((event) => event.category == category).toList();
  }

  // ========================
  // FILTER EVENTS BY DATE RANGE
  // ========================
  List<AgencyEvent> getEventsByDateRange(DateTime start, DateTime end) {
    return _allEvents
        .where((event) =>
            event.eventDate.isAfter(start) && event.eventDate.isBefore(end))
        .toList();
  }

  // ========================
  // CLEAR ERROR
  // ========================
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
