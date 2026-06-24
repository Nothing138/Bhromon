// services/event_service.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_model.dart';

class EventService extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  List<EventModel> _allEvents = [];
  List<EventModel> _upcomingEvents = [];
  List<EventModel> _pastEvents = [];
  bool _isLoading = false;
  String? _error;

  List<EventModel> get allEvents => _allEvents;
  List<EventModel> get upcomingEvents => _upcomingEvents;
  List<EventModel> get pastEvents => _pastEvents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch all events for the current agency
  Future<void> fetchAllEvents() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get current user (agency)
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Fetch agency_id from travel_agencies table
      final agencyResponse = await supabase
          .from('travel_agencies')
          .select('id')
          .eq('user_id', user.id)
          .single();

      final agencyId = agencyResponse['id'];

      // Fetch all events for this agency
      final response = await supabase
          .from('agency_events')
          .select()
          .eq('agency_id', agencyId)
          .order('event_date', ascending: true);

      _allEvents = (response as List)
          .map((event) => EventModel.fromJson(event))
          .toList();

      _filterEvents();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new event
  Future<bool> createEvent({
    required String title,
    required String description,
    required String location,
    required DateTime eventDate,
    required double price,
    required int capacity,
    required String category,
    String? imageUrl,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get agency_id
      final agencyResponse = await supabase
          .from('travel_agencies')
          .select('id')
          .eq('user_id', user.id)
          .single();

      final agencyId = agencyResponse['id'];

      // Insert event
      await supabase.from('agency_events').insert({
        'agency_id': agencyId,
        'title': title,
        'description': description,
        'location': location,
        'event_date': eventDate.toIso8601String(),
        'price': price,
        'capacity': capacity,
        'category': category,
        'image_url': imageUrl,
        'status': 'active',
        'booked_count': 0,
      });

      await fetchAllEvents();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update event
  Future<bool> updateEvent({
    required String eventId,
    required String title,
    required String description,
    required String location,
    required DateTime eventDate,
    required double price,
    required int capacity,
    required String category,
    String? imageUrl,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await supabase.from('agency_events').update({
        'title': title,
        'description': description,
        'location': location,
        'event_date': eventDate.toIso8601String(),
        'price': price,
        'capacity': capacity,
        'category': category,
        'image_url': imageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', eventId);

      await fetchAllEvents();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete event
  Future<bool> deleteEvent(String eventId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await supabase.from('agency_events').delete().eq('id', eventId);

      await fetchAllEvents();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Cancel event (change status to cancelled)
  Future<bool> cancelEvent(String eventId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await supabase
          .from('agency_events')
          .update({'status': 'cancelled'}).eq('id', eventId);

      await fetchAllEvents();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Mark event as completed
  Future<bool> completeEvent(String eventId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await supabase
          .from('agency_events')
          .update({'status': 'completed'}).eq('id', eventId);

      await fetchAllEvents();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Filter events into upcoming and past
  void _filterEvents() {
    final now = DateTime.now();
    _upcomingEvents = _allEvents
        .where(
            (event) => event.eventDate.isAfter(now) && event.status == 'active')
        .toList();
    _pastEvents = _allEvents
        .where((event) =>
            event.eventDate.isBefore(now) || event.status != 'active')
        .toList();
  }

  // Get event by ID
  Future<EventModel?> getEventById(String eventId) async {
    try {
      final response = await supabase
          .from('agency_events')
          .select()
          .eq('id', eventId)
          .single();

      return EventModel.fromJson(response);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
