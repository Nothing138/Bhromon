// services/event_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/event_model.dart';

class EventService extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  List<AgencyEvent> _allEvents = [];
  List<AgencyEvent> _agencyEvents = [];
  bool _isLoading = false;

  List<AgencyEvent> get allEvents => _allEvents;
  List<AgencyEvent> get agencyEvents => _agencyEvents;
  bool get isLoading => _isLoading;

  // ========================
  // FETCH ALL EVENTS (For Feed)
  // ========================
  Future<void> fetchAllEvents() async {
    try {
      _isLoading = true;
      notifyListeners();

      print('🔄 Fetching all events...');

      final response = await supabase
          .from('agency_events')
          .select(
            '''
            *,
            travel_agencies (
              agency_name,
              owner_email
            )
            ''',
          )
          .eq('status', 'active')
          .order('event_date', ascending: true)
          .limit(50);

      _allEvents = (response as List).map((json) {
        final agency = json['travel_agencies'] as Map<String, dynamic>?;
        return AgencyEvent.fromJson({
          ...json as Map<String, dynamic>,
          'agency_name': agency?['agency_name'],
          'agency_email': agency?['owner_email'],
        });
      }).toList();

      print('✅ Fetched ${_allEvents.length} events');
    } catch (e) {
      print('❌ Error fetching events: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========================
  // FETCH AGENCY SPECIFIC EVENTS
  // ========================
  Future<void> fetchAgencyEvents(String agencyId) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('🔄 Fetching events for agency: $agencyId');

      final response = await supabase
          .from('agency_events')
          .select(
            '''
            *,
            travel_agencies (
              agency_name,
              owner_email
            )
            ''',
          )
          .eq('agency_id', agencyId)
          .order('event_date', ascending: true);

      _agencyEvents = (response as List).map((json) {
        final agency = json['travel_agencies'] as Map<String, dynamic>?;
        return AgencyEvent.fromJson({
          ...json as Map<String, dynamic>,
          'agency_name': agency?['agency_name'],
          'agency_email': agency?['owner_email'],
        });
      }).toList();

      print('✅ Fetched ${_agencyEvents.length} agency events');
    } catch (e) {
      print('❌ Error fetching agency events: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========================
  // CREATE EVENT
  // ========================
  Future<AgencyEvent?> createEvent({
    required String agencyId,
    required CreateEventRequest request,
  }) async {
    try {
      print('🔄 Creating event: ${request.title}');

      final response = await supabase
          .from('agency_events')
          .insert({
            'agency_id': agencyId,
            'title': request.title.trim(),
            'description': request.description?.trim(),
            'location': request.location?.trim(),
            'event_date': request.eventDate.toIso8601String(),
            'image_url': request.imageUrl,
            'price': request.price,
            'capacity': request.capacity,
            'category': request.category,
            'status': 'active',
          })
          .select()
          .single();

      final event = AgencyEvent.fromJson(response as Map<String, dynamic>);
      print('✅ Event created: ${event.id}');

      // Refresh agency events
      await fetchAgencyEvents(agencyId);

      return event;
    } catch (e) {
      print('❌ Error creating event: $e');
      throw Exception('Failed to create event: $e');
    }
  }

  // ========================
  // UPDATE EVENT
  // ========================
  Future<void> updateEvent({
    required String eventId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      print('🔄 Updating event: $eventId');

      await supabase.from('agency_events').update(updates).eq('id', eventId);

      print('✅ Event updated');

      // Refresh all events
      await fetchAllEvents();
    } catch (e) {
      print('❌ Error updating event: $e');
      throw Exception('Failed to update event: $e');
    }
  }

  // ========================
  // DELETE EVENT
  // ========================
  Future<void> deleteEvent({
    required String eventId,
    required String agencyId,
  }) async {
    try {
      print('🔄 Deleting event: $eventId');

      await supabase.from('agency_events').delete().eq('id', eventId);

      print('✅ Event deleted');

      // Refresh
      await fetchAgencyEvents(agencyId);
      await fetchAllEvents();
    } catch (e) {
      print('❌ Error deleting event: $e');
      throw Exception('Failed to delete event: $e');
    }
  }

  // ========================
  // CANCEL EVENT
  // ========================
  Future<void> cancelEvent({
    required String eventId,
    required String agencyId,
  }) async {
    try {
      await updateEvent(
        eventId: eventId,
        updates: {'status': 'cancelled'},
      );
      await fetchAgencyEvents(agencyId);
    } catch (e) {
      print('❌ Error cancelling event: $e');
      throw Exception('Failed to cancel event: $e');
    }
  }

  // ========================
  // GET UPCOMING EVENTS
  // ========================
  List<AgencyEvent> getUpcomingEvents() {
    return _allEvents.where((event) => event.isUpcoming).toList();
  }

  // ========================
  // SEARCH EVENTS
  // ========================
  List<AgencyEvent> searchEvents(String query) {
    return _allEvents
        .where((event) =>
            event.title.toLowerCase().contains(query.toLowerCase()) ||
            event.location?.toLowerCase().contains(query.toLowerCase()) == true)
        .toList();
  }

  // ========================
  // FILTER BY CATEGORY
  // ========================
  List<AgencyEvent> getEventsByCategory(String category) {
    return _allEvents.where((event) => event.category == category).toList();
  }
}
