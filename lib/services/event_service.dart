// lib/services/event_service.dart
import '../models/event.dart';
import '../database/database_helper.dart';

class EventService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<int> addEvent(Event event) async {
    return await _databaseHelper.insertEvent(event);
  }

  Future<List<Event>> getEvents() async {
    return await _databaseHelper.getEvents();
  }

  Future<List<Event>> getEventsByCategory(String category) async {
    return await _databaseHelper.getEventsByCategory(category);
  }

  Future<List<Event>> getUserEvents(int userId) async {
    return await _databaseHelper.getEventsByUser(userId);
  }

  Future<void> updateEvent(Event event) async {
    await _databaseHelper.updateEvent(event);
  }

  Future<void> deleteEvent(int eventId) async {
    await _databaseHelper.deleteEvent(eventId);
  }

  Future<void> addParticipant(int eventId, int userId) async {
    final events = await _databaseHelper.getEvents();
    final event = events.firstWhere((e) => e.id == eventId);
    // VÉRIFICATION DE LA LIMITE - AJOUT IMPORTANT
    if (event.maxParticipants > 0 && event.participants.length >= event.maxParticipants) {
      throw Exception('L\'événement a atteint le nombre maximum de participants');
    }
    if (!event.participants.contains(userId)) {
      final updatedParticipants = List<int>.from(event.participants)..add(userId);
      final updatedEvent = Event(
        id: event.id,
        title: event.title,
        date: event.date,
        location: event.location,
        description: event.description,
        category: event.category,
        latitude: event.latitude,
        longitude: event.longitude,
        participants: updatedParticipants,
        createdBy: event.createdBy,
        createdAt: event.createdAt,
        maxParticipants:event.maxParticipants,
        price:event.price,

      );

      await _databaseHelper.updateEvent(updatedEvent);
    }
  }

  Future<List<int>> getParticipants(int eventId) async {
    final events = await _databaseHelper.getEvents();
    final event = events.firstWhere((e) => e.id == eventId);
    return event.participants;
  }
  // Ajoutez cette méthode dans lib/services/event_service.dart
  Future<void> removeParticipant(int eventId, int userId) async {
    final events = await _databaseHelper.getEvents();
    final event = events.firstWhere((e) => e.id == eventId);

    if (event.participants.contains(userId)) {
      final updatedParticipants = List<int>.from(event.participants)..remove(userId);
      final updatedEvent = Event(
        id: event.id,
        title: event.title,
        date: event.date,
        location: event.location,
        description: event.description,
        category: event.category,
        latitude: event.latitude,
        longitude: event.longitude,
        participants: updatedParticipants,
        createdBy: event.createdBy,
        createdAt: event.createdAt,
        maxParticipants:event.maxParticipants,
        price:event.price,
      );

      await _databaseHelper.updateEvent(updatedEvent);
    }
  }
}