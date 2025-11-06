class Photo {
  int? id;
  String url;
  String legend;
  String user;
  int likes;
  int comments;
  DateTime? createdAt;
  int? eventId; // new

  Photo({this.id, required this.url, required this.legend, required this.user, this.likes = 0, this.comments = 0, this.createdAt, this.eventId});

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'url': url,
      'legend': legend,
      'user': user,
      'likes': likes,
      'comments': comments,
      'createdAt': createdAt?.toIso8601String(),
      'event_id': eventId,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory Photo.fromMap(Map<String, dynamic> m) => Photo(
        id: m['id'] as int?,
        url: m['url'] as String? ?? '',
        legend: m['legend'] as String? ?? '',
        user: m['user'] as String? ?? '',
        likes: m['likes'] as int? ?? 0,
        comments: m['comments'] as int? ?? 0,
        createdAt: m['createdAt'] != null ? DateTime.tryParse(m['createdAt'] as String) : null,
        eventId: m['event_id'] as int?,
      );
}
