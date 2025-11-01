// lib/modules/events/widgets/event_carousel.dart
import 'package:flutter/material.dart';
import '../../../../models/event.dart';
import '../../../../utils/categories.dart';

class EventCarousel extends StatelessWidget {
  final String category;
  final List<Event> events;
  final Function(Event) onEventTap;
  final Function(Event) onEditEvent;
  final int currentUserId; // AJOUTÉ

  const EventCarousel({
    Key? key,
    required this.category,
    required this.events,
    required this.onEventTap,
    required this.onEditEvent,
    required this.currentUserId, // AJOUTÉ
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                EventCategories.categoryIcons[category] ?? '📅',
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(width: 8),
              Text(
                category,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              SizedBox(width: 8),
              Chip(
                label: Text('${events.length}'),
                backgroundColor: Colors.blue[100],
              ),
            ],
          ),
        ),

        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 8),
            itemCount: events.length,
            itemBuilder: (context, index) {
              return _buildEventCard(events[index], context);
            },
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEventCard(Event event, BuildContext context) {
    final isParticipating = event.participants.contains(currentUserId);
    final isCreator = event.createdBy == currentUserId;
    final isFull = event.isFull;

    return Container(
      width: 280,
      margin: EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => onEventTap(event),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec titre et menu
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Indicateur de participation
            if (isFull)
          Padding(
      padding: EdgeInsets.only(right: 8),
      child: Icon(Icons.error, size: 16, color: Colors.red),
    ),
    if (isParticipating)
    Padding(
    padding: EdgeInsets.only(right: 8),
    child: Icon(Icons.check_circle, size: 16, color: Colors.green),
    ),
    if (isCreator)
    PopupMenuButton<String>(
    icon: Icon(Icons.more_vert, size: 18),
    onSelected: (value) {
    if (value == 'edit') onEditEvent(event);
    },
    itemBuilder: (context) => [
    PopupMenuItem(value: 'edit', child: Text('Modifier')),
    ],
    ),
    ],
    ),
    SizedBox(height: 8),

    // Date
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      _formatDate(event.date),
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                SizedBox(height: 4),

                // Lieu
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),

                // Description
                Expanded(
                  child: Text(
                    event.description,
                    style: TextStyle(fontSize: 13),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: 8),

                // Participants et statut
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.people, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          '${event.participants.length}',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    // Badge statut
                    if (isCreator)
                      _buildStatusBadge('Créateur', Colors.orange)
                    else if (isParticipating)
                      _buildStatusBadge('Participant', Colors.green)
                    else
                      _buildStatusBadge('Rejoindre', Colors.blue),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}