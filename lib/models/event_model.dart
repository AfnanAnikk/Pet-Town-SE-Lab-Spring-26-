// lib/models/event_model.dart
// Pet Town – Event Feature Data Models

class EventModel {
  final int id;
  final int userId;
  final String title;
  final String description;
  final String? coverImageUrl;
  final String category;
  final String petType;
  final DateTime startDatetime;
  final DateTime? endDatetime;
  final String location;
  final double? latitude;
  final double? longitude;
  final int maxParticipants;
  final String? contactInfo;
  final bool requiresRegistration;
  final String visibility;
  final String status;
  final int interestedCount;
  final int goingCount;
  final String? organizerName;
  final String? organizerAvatarUrl;
  final DateTime createdAt;

  const EventModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    this.coverImageUrl,
    required this.category,
    required this.petType,
    required this.startDatetime,
    this.endDatetime,
    required this.location,
    this.latitude,
    this.longitude,
    required this.maxParticipants,
    this.contactInfo,
    required this.requiresRegistration,
    required this.visibility,
    required this.status,
    required this.interestedCount,
    required this.goingCount,
    this.organizerName,
    this.organizerAvatarUrl,
    required this.createdAt,
  });

  // Accepts both camelCase (API layer) and snake_case (raw PostgreSQL rows)
  factory EventModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) => v != null ? DateTime.parse(v as String) : null;
    double? parseDouble(dynamic v) => v != null ? (v as num).toDouble() : null;
    int parseI(dynamic a, [dynamic b, int fallback = 0]) =>
        (a as num?)?.toInt() ?? (b as num?)?.toInt() ?? fallback;

    return EventModel(
      id: parseI(json['id']),
      userId: parseI(json['userId'], json['user_id']),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      coverImageUrl: json['coverImageUrl'] as String? ?? json['cover_image_url'] as String?,
      category: json['category'] as String? ?? 'Other',
      petType: json['petType'] as String? ?? json['pet_type'] as String? ?? 'All',
      startDatetime:
          parseDate(json['startDatetime'] ?? json['start_datetime']) ?? DateTime.now(),
      endDatetime: parseDate(json['endDatetime'] ?? json['end_datetime']),
      location: json['location'] as String? ?? '',
      latitude: parseDouble(json['latitude']),
      longitude: parseDouble(json['longitude']),
      maxParticipants: parseI(json['maxParticipants'], json['max_participants']),
      contactInfo: json['contactInfo'] as String? ?? json['contact_info'] as String?,
      requiresRegistration:
          json['requiresRegistration'] as bool? ?? json['requires_registration'] as bool? ?? false,
      visibility: json['visibility'] as String? ?? 'public',
      status: json['status'] as String? ?? 'upcoming',
      interestedCount: parseI(json['interestedCount'], json['interested_count']),
      goingCount: parseI(json['goingCount'], json['going_count']),
      organizerName:
          json['organizerName'] as String? ?? json['organizer_name'] as String?,
      organizerAvatarUrl:
          json['organizerAvatarUrl'] as String? ?? json['organizer_avatar_url'] as String?,
      createdAt: parseDate(json['createdAt'] ?? json['created_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'description': description,
        if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
        'category': category,
        'petType': petType,
        'startDatetime': startDatetime.toIso8601String(),
        if (endDatetime != null) 'endDatetime': endDatetime!.toIso8601String(),
        'location': location,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'maxParticipants': maxParticipants,
        if (contactInfo != null) 'contactInfo': contactInfo,
        'requiresRegistration': requiresRegistration,
        'visibility': visibility,
        'status': status,
        'interestedCount': interestedCount,
        'goingCount': goingCount,
        if (organizerName != null) 'organizerName': organizerName,
        if (organizerAvatarUrl != null) 'organizerAvatarUrl': organizerAvatarUrl,
        'createdAt': createdAt.toIso8601String(),
      };

  EventModel copyWith({
    int? id,
    int? userId,
    String? title,
    String? description,
    String? coverImageUrl,
    String? category,
    String? petType,
    DateTime? startDatetime,
    DateTime? endDatetime,
    String? location,
    double? latitude,
    double? longitude,
    int? maxParticipants,
    String? contactInfo,
    bool? requiresRegistration,
    String? visibility,
    String? status,
    int? interestedCount,
    int? goingCount,
    String? organizerName,
    String? organizerAvatarUrl,
    DateTime? createdAt,
  }) =>
      EventModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        description: description ?? this.description,
        coverImageUrl: coverImageUrl ?? this.coverImageUrl,
        category: category ?? this.category,
        petType: petType ?? this.petType,
        startDatetime: startDatetime ?? this.startDatetime,
        endDatetime: endDatetime ?? this.endDatetime,
        location: location ?? this.location,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        maxParticipants: maxParticipants ?? this.maxParticipants,
        contactInfo: contactInfo ?? this.contactInfo,
        requiresRegistration: requiresRegistration ?? this.requiresRegistration,
        visibility: visibility ?? this.visibility,
        status: status ?? this.status,
        interestedCount: interestedCount ?? this.interestedCount,
        goingCount: goingCount ?? this.goingCount,
        organizerName: organizerName ?? this.organizerName,
        organizerAvatarUrl: organizerAvatarUrl ?? this.organizerAvatarUrl,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}


// ─────────────────────────────────────────────────────────────────────────────

class EventCommentModel {
  final int id;
  final int eventId;
  final int userId;
  final int? parentId;
  final String text;
  final bool isPinned;
  final String authorName;
  final String? authorAvatarUrl;
  final DateTime createdAt;
  final int reactionCount;
  final List<EventCommentModel> replies;

  const EventCommentModel({
    required this.id,
    required this.eventId,
    required this.userId,
    this.parentId,
    required this.text,
    required this.isPinned,
    required this.authorName,
    this.authorAvatarUrl,
    required this.createdAt,
    required this.reactionCount,
    required this.replies,
  });

  factory EventCommentModel.fromJson(Map<String, dynamic> json) {
    final rawReplies = json['replies'];
    final List<EventCommentModel> parsedReplies = rawReplies is List
        ? rawReplies.map((r) => EventCommentModel.fromJson(r as Map<String, dynamic>)).toList()
        : [];

    return EventCommentModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      eventId: (json['eventId'] as num?)?.toInt() ?? (json['event_id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? (json['user_id'] as num?)?.toInt() ?? 0,
      parentId: json['parentId'] != null
          ? (json['parentId'] as num).toInt()
          : json['parent_id'] != null
              ? (json['parent_id'] as num).toInt()
              : null,
      text: json['text'] as String? ?? '',
      isPinned: json['isPinned'] as bool? ?? json['is_pinned'] as bool? ?? false,
      authorName: json['authorName'] as String?
          ?? json['author_name'] as String?
          ?? json['username'] as String?
          ?? json['display_name'] as String?
          ?? 'Anonymous',
      authorAvatarUrl: json['authorAvatarUrl'] as String?
          ?? json['author_avatar_url'] as String?
          ?? json['profile_picture_url'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
      reactionCount: (json['reactionCount'] as num?)?.toInt()
          ?? (json['reaction_count'] as num?)?.toInt() ?? 0,
      replies: parsedReplies,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'eventId': eventId,
        'userId': userId,
        if (parentId != null) 'parentId': parentId,
        'text': text,
        'isPinned': isPinned,
        'authorName': authorName,
        if (authorAvatarUrl != null) 'authorAvatarUrl': authorAvatarUrl,
        'createdAt': createdAt.toIso8601String(),
        'reactionCount': reactionCount,
        'replies': replies.map((r) => r.toJson()).toList(),
      };
}

// ─────────────────────────────────────────────────────────────────────────────

class EventParticipantModel {
  final int userId;
  final String status;
  final bool approved;
  final String? name;
  final String? avatarUrl;

  const EventParticipantModel({
    required this.userId,
    required this.status,
    required this.approved,
    this.name,
    this.avatarUrl,
  });

  factory EventParticipantModel.fromJson(Map<String, dynamic> json) =>
      EventParticipantModel(
        userId: (json['userId'] as num?)?.toInt() ?? (json['user_id'] as num?)?.toInt() ?? 0,
        status: json['status'] as String? ?? 'interested',
        approved: json['approved'] as bool? ?? false,
        name: json['name'] as String?
            ?? json['username'] as String?
            ?? json['display_name'] as String?,
        avatarUrl: json['avatarUrl'] as String?
            ?? json['avatar_url'] as String?
            ?? json['profile_picture_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'status': status,
        'approved': approved,
        if (name != null) 'name': name,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      };
}

// ─────────────────────────────────────────────────────────────────────────────

class EventInvitationModel {
  final int id;
  final int eventId;
  final String eventTitle;
  final String? eventCoverUrl;
  final DateTime eventStartDatetime;
  final String inviterName;
  final String? inviterAvatarUrl;
  final String status;
  final DateTime createdAt;

  const EventInvitationModel({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    this.eventCoverUrl,
    required this.eventStartDatetime,
    required this.inviterName,
    this.inviterAvatarUrl,
    required this.status,
    required this.createdAt,
  });

  factory EventInvitationModel.fromJson(Map<String, dynamic> json) =>
      EventInvitationModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        eventId: (json['eventId'] as num?)?.toInt() ?? (json['event_id'] as num?)?.toInt() ?? 0,
        eventTitle: json['eventTitle'] as String? ?? json['event_title'] as String? ?? '',
        eventCoverUrl: json['eventCoverUrl'] as String? ?? json['event_cover_url'] as String?,
        eventStartDatetime: (() {
          final v = json['eventStartDatetime'] ?? json['event_start_datetime'];
          return v != null ? DateTime.parse(v as String) : DateTime.now();
        })(),
        inviterName: json['inviterName'] as String?
            ?? json['inviter_name'] as String?
            ?? 'Someone',
        inviterAvatarUrl: json['inviterAvatarUrl'] as String?
            ?? json['inviter_avatar_url'] as String?,
        status: json['status'] as String? ?? 'pending',
        createdAt: (() {
          final v = json['createdAt'] ?? json['created_at'];
          return v != null ? DateTime.parse(v as String) : DateTime.now();
        })(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'eventId': eventId,
        'eventTitle': eventTitle,
        if (eventCoverUrl != null) 'eventCoverUrl': eventCoverUrl,
        'eventStartDatetime': eventStartDatetime.toIso8601String(),
        'inviterName': inviterName,
        if (inviterAvatarUrl != null) 'inviterAvatarUrl': inviterAvatarUrl,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };
}
