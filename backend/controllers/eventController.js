const db = require('../config/db');
const jwt = require('jsonwebtoken');
const JWT_SECRET = process.env.JWT_SECRET || 'your_super_secret_key';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────
function getUserIdFromRequest(req) {
  if (!req) return undefined;
  // 1. Check body
  if (req.body) {
    if (req.body.user_id) return req.body.user_id;
    if (req.body.userId) return req.body.userId;
    if (req.body.organizerUserId) return req.body.organizerUserId;
  }
  // 2. Check query
  if (req.query) {
    if (req.query.user_id) return req.query.user_id;
    if (req.query.userId) return req.query.userId;
    if (req.query.requester_id) return req.query.requester_id;
  }
  // 3. Check route params
  if (req.params) {
    if (req.params.userId) return req.params.userId;
    if (req.params.uid) return req.params.uid;
  }
  // 4. Fallback: Decode JWT token from headers
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    if (token) {
      const decoded = jwt.verify(token, JWT_SECRET);
      return decoded.user && decoded.user.id;
    }
  } catch (err) {
    // ignore
  }
  return undefined;
}

async function assertOrganizer(eventId, userId, res) {
  const [eventRows] = await db.execute('SELECT user_id FROM events WHERE id = ?', [eventId]);
  if (!eventRows.length) {
    res.status(404).json({ message: 'Event not found' });
    return false;
  }
  if (!userId || eventRows[0].user_id.toString() !== userId.toString()) {
    res.status(403).json({ message: 'Unauthorized' });
    return false;
  }
  return true;
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. GET /  — list all events with optional filters
// ─────────────────────────────────────────────────────────────────────────────
exports.getAllEvents = async (req, res) => {
  try {
    // Accept both camelCase (Flutter) and snake_case query params
    const petType   = req.query.petType   || req.query.pet_type;
    const dateFrom  = req.query.dateFrom  || req.query.date_from;
    const dateTo    = req.query.dateTo    || req.query.date_to;
    const { status, category, location, search, limit = 20, offset = 0 } = req.query;

    let sql = `
      SELECT e.*,
             u.username            AS organizer_name,
             u.display_name        AS organizer_display_name,
             u.profile_picture_url AS organizer_avatar
      FROM events e
      JOIN users u ON e.user_id = u.id
      WHERE 1=1
    `;
    const params = [];

    if (status)   { params.push(status);             sql += ` AND e.status = ?`; }
    if (category) { params.push(category);           sql += ` AND e.category = ?`; }
    if (petType)  { params.push(petType);            sql += ` AND e.pet_type = ?`; }
    if (location) { params.push(`%${location}%`);   sql += ` AND e.location ILIKE ?`; }
    if (dateFrom) { params.push(dateFrom);           sql += ` AND e.start_datetime >= ?`; }
    if (dateTo)   { params.push(dateTo);             sql += ` AND e.start_datetime <= ?`; }
    if (search)   { params.push(`%${search}%`);      sql += ` AND (e.title ILIKE ? OR e.description ILIKE ?)`; params.push(`%${search}%`); }

    sql += ` ORDER BY e.start_datetime ASC LIMIT ? OFFSET ?`;
    params.push(parseInt(limit), parseInt(offset));

    const [rows] = await db.execute(sql, params);
    res.json({ success: true, data: rows });
  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// 2. GET /trending — top 10 by engagement
// ─────────────────────────────────────────────────────────────────────────────
exports.getTrendingEvents = async (req, res) => {
  try {
    const [rows] = await db.execute(`
      SELECT e.*,
             u.username            AS organizer_name,
             u.display_name        AS organizer_display_name,
             u.profile_picture_url AS organizer_avatar,
             (e.going_count + e.interested_count) AS engagement_score
      FROM events e
      JOIN users u ON e.user_id = u.id
      WHERE e.status IN ('upcoming', 'ongoing')
      ORDER BY engagement_score DESC
      LIMIT 10
    `);
    res.json({ success: true, data: rows });
  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// 3. GET /nearby — filter by lat/lon/radius using Haversine
// ─────────────────────────────────────────────────────────────────────────────
exports.getNearbyEvents = async (req, res) => {
  try {
    const { lat, lon, radius_km = 10 } = req.query;
    if (!lat || !lon) {
      return res.status(400).json({ message: 'lat and lon are required' });
    }

    const [rows] = await db.execute(`
      SELECT e.*,
             u.username        AS organizer_name,
             u.display_name    AS organizer_display_name,
             u.profile_picture_url AS organizer_avatar,
             (
               6371 * acos(
                 cos(radians(?)) * cos(radians(e.latitude)) *
                 cos(radians(e.longitude) - radians(?)) +
                 sin(radians(?)) * sin(radians(e.latitude))
               )
             ) AS distance_km
      FROM events e
      JOIN users u ON e.user_id = u.id
      WHERE e.status IN ('upcoming', 'ongoing')
        AND e.latitude IS NOT NULL
        AND e.longitude IS NOT NULL
      HAVING distance_km <= ?
      ORDER BY distance_km ASC
    `, [parseFloat(lat), parseFloat(lon), parseFloat(lat), parseFloat(radius_km)]);

    res.json({ success: true, data: rows });
  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// 4. GET /:id — get single event with organizer info
// ─────────────────────────────────────────────────────────────────────────────
exports.getEventById = async (req, res) => {
  const { id } = req.params;
  try {
    const [rows] = await db.execute(`
      SELECT e.*,
             u.username        AS organizer_name,
             u.display_name    AS organizer_display_name,
             u.profile_picture_url AS organizer_avatar,
             u.email           AS organizer_email
      FROM events e
      JOIN users u ON e.user_id = u.id
      WHERE e.id = ?
    `, [id]);

    if (!rows.length) {
      return res.status(404).json({ success: false, message: 'Event not found' });
    }
    res.json({ success: true, data: rows[0] });
  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// 5. GET /user/:userId — events by a specific user
// ─────────────────────────────────────────────────────────────────────────────
exports.getEventsByUser = async (req, res) => {
  const { userId } = req.params;
  try {
    const [rows] = await db.execute(`
      SELECT e.*,
             u.username        AS organizer_name,
             u.display_name    AS organizer_display_name,
             u.profile_picture_url AS organizer_avatar
      FROM events e
      JOIN users u ON e.user_id = u.id
      WHERE e.user_id = ?
      ORDER BY e.start_datetime DESC
    `, [userId]);
    res.json({ success: true, data: rows });
  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// 6. POST / — create event
// ─────────────────────────────────────────────────────────────────────────────
exports.createEvent = async (req, res) => {
  const user_id = getUserIdFromRequest(req);
  const {
    title, description, cover_image_url, category,
    start_datetime, end_datetime, location, latitude, longitude,
    max_participants, contact_info, requires_registration, visibility, status,
  } = req.body;
  const pet_type = req.body.pet_type || req.body.petType;

  if (!user_id || !title || !start_datetime) {
    return res.status(400).json({ message: 'user_id, title, and start_datetime are required' });
  }

  try {
    const [result] = await db.execute(
      `INSERT INTO events
        (user_id, title, description, cover_image_url, category, pet_type,
         start_datetime, end_datetime, location, latitude, longitude,
         max_participants, contact_info, requires_registration, visibility, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        user_id, title, description || null, cover_image_url || null,
        category || null, pet_type || null, start_datetime, end_datetime || null,
        location || null, latitude || null, longitude || null,
        max_participants || 0, contact_info || null,
        requires_registration || false, visibility || 'public', status || 'upcoming',
      ]
    );
    res.status(201).json({ success: true, message: 'Event created', data: { eventId: result.insertId } });
  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// 7. PUT /:id — update event (organizer only)
// ─────────────────────────────────────────────────────────────────────────────
exports.updateEvent = async (req, res) => {
  const { id } = req.params;
  const user_id = getUserIdFromRequest(req);
  const {
    title, description, cover_image_url, category,
    start_datetime, end_datetime, location, latitude, longitude,
    max_participants, contact_info, requires_registration, visibility, status,
  } = req.body;
  const pet_type = req.body.pet_type || req.body.petType;

  try {
    if (!(await assertOrganizer(id, user_id, res))) return;

    await db.execute(
      `UPDATE events
       SET title = ?, description = ?, cover_image_url = ?, category = ?, pet_type = ?,
           start_datetime = ?, end_datetime = ?, location = ?, latitude = ?, longitude = ?,
           max_participants = ?, contact_info = ?, requires_registration = ?, visibility = ?,
           status = ?, updated_at = CURRENT_TIMESTAMP
       WHERE id = ?`,
      [
        title, description || null, cover_image_url || null, category || null,
        pet_type || null, start_datetime, end_datetime || null, location || null,
        latitude || null, longitude || null, max_participants || 0, contact_info || null,
        requires_registration || false, visibility || 'public', status || 'upcoming', id,
      ]
    );
    res.json({ message: 'Event updated' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// 8. DELETE /:id — delete event (organizer only)
// ─────────────────────────────────────────────────────────────────────────────
exports.deleteEvent = async (req, res) => {
  const { id } = req.params;
  const user_id = getUserIdFromRequest(req);

  try {
    if (!(await assertOrganizer(id, user_id, res))) return;

    await db.execute('DELETE FROM events WHERE id = ?', [id]);
    res.json({ message: 'Event deleted' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// 9. PUT /:id/status — update status only (organizer only)
// ─────────────────────────────────────────────────────────────────────────────
exports.updateEventStatus = async (req, res) => {
  const { id } = req.params;
  const user_id = getUserIdFromRequest(req);
  const { status } = req.body;

  if (!status) {
    return res.status(400).json({ message: 'status is required' });
  }

  try {
    if (!(await assertOrganizer(id, user_id, res))) return;

    await db.execute(
      'UPDATE events SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
      [status, id]
    );
    res.json({ message: 'Event status updated' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// 10. POST /:id/join — join event
// ─────────────────────────────────────────────────────────────────────────────
exports.joinEvent = async (req, res) => {
  const eventId = req.params.id;
  const user_id = getUserIdFromRequest(req);
  const { status: participantStatus = 'going' } = req.body;

  if (!user_id) {
    return res.status(400).json({ message: 'user_id is required' });
  }

  try {
    // Fetch event details
    const [eventRows] = await db.execute(
      'SELECT user_id, title, requires_registration, visibility, max_participants, going_count, interested_count FROM events WHERE id = ?',
      [eventId]
    );
    if (!eventRows.length) {
      return res.status(404).json({ message: 'Event not found' });
    }
    const event = eventRows[0];

    // Check max participants (0 = unlimited)
    if (event.max_participants > 0) {
      const [countRows] = await db.execute(
        "SELECT COUNT(*) AS cnt FROM event_participants WHERE event_id = ? AND status != 'cancelled' AND approved = TRUE",
        [eventId]
      );
      if (parseInt(countRows[0].cnt) >= event.max_participants) {
        return res.status(409).json({ message: 'Event is full' });
      }
    }

    // Check if already joined
    const [existing] = await db.execute(
      'SELECT id, status FROM event_participants WHERE event_id = ? AND user_id = ?',
      [eventId, user_id]
    );
    if (existing.length > 0) {
      return res.status(409).json({ message: 'Already joined this event', current: existing[0] });
    }

    // Determine approval: private events with registration required → pending
    const needsApproval = event.requires_registration && event.visibility === 'private';
    const approved = !needsApproval;

    await db.execute(
      'INSERT INTO event_participants (event_id, user_id, status, approved) VALUES (?, ?, ?, ?)',
      [eventId, user_id, participantStatus, approved]
    );

    // Increment count
    const countField = participantStatus === 'going' ? 'going_count' : 'interested_count';
    await db.execute(`UPDATE events SET ${countField} = ${countField} + 1 WHERE id = ?`, [eventId]);

    // Notify organizer (only if different user)
    if (event.user_id.toString() !== user_id.toString()) {
      await db.execute(
        'INSERT INTO notifications (user_id, type, reference_id, message) VALUES (?, ?, ?, ?)',
        [event.user_id, 'event_join', parseInt(eventId), `Someone joined your event "${event.title}"!`]
      );
    }

    res.status(201).json({
      message: approved ? 'Joined event' : 'Join request submitted, pending approval',
      approved,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// 11. POST /:id/leave — leave event
// ─────────────────────────────────────────────────────────────────────────────
exports.leaveEvent = async (req, res) => {
  const eventId = req.params.id;
  const user_id = getUserIdFromRequest(req);

  if (!user_id) {
    return res.status(400).json({ message: 'user_id is required' });
  }

  try {
    const [existing] = await db.execute(
      'SELECT id, status FROM event_participants WHERE event_id = ? AND user_id = ?',
      [eventId, user_id]
    );
    if (!existing.length) {
      return res.status(404).json({ message: 'Participation not found' });
    }

    const participantStatus = existing[0].status;
    await db.execute(
      'DELETE FROM event_participants WHERE event_id = ? AND user_id = ?',
      [eventId, user_id]
    );

    // Decrement appropriate counter
    if (participantStatus === 'going') {
      await db.execute('UPDATE events SET going_count = GREATEST(going_count - 1, 0) WHERE id = ?', [eventId]);
    } else if (participantStatus === 'interested') {
      await db.execute('UPDATE events SET interested_count = GREATEST(interested_count - 1, 0) WHERE id = ?', [eventId]);
    }

    res.json({ message: 'Left event' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// 12. GET /:id/participants — list participants
// ─────────────────────────────────────────────────────────────────────────────
exports.getParticipants = async (req, res) => {
  const eventId = req.params.id;
  const requester_id = getUserIdFromRequest(req); // support body/query/headers

  try {
    const [eventRows] = await db.execute(
      'SELECT user_id, visibility FROM events WHERE id = ?',
      [eventId]
    );
    if (!eventRows.length) {
      return res.status(404).json({ message: 'Event not found' });
    }
    const event = eventRows[0];

    // For private events, only organizer can see the full list
    if (event.visibility === 'private') {
      if (!requester_id || event.user_id.toString() !== requester_id.toString()) {
        return res.status(403).json({ message: 'Unauthorized: only organizer can view participants of private events' });
      }
    }

    const [rows] = await db.execute(`
      SELECT ep.id, ep.event_id, ep.user_id, ep.status, ep.approved, ep.created_at,
             u.username, u.display_name, u.profile_picture_url, u.email
      FROM event_participants ep
      JOIN users u ON ep.user_id = u.id
      WHERE ep.event_id = ?
      ORDER BY ep.created_at ASC
    `, [eventId]);

    res.json({ success: true, data: rows });
  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};
// ─────────────────────────────────────────────────────────────────────────────
exports.approveParticipant = async (req, res) => {
  const { id: eventId, uid } = req.params;
  const user_id = getUserIdFromRequest(req);

  try {
    if (!(await assertOrganizer(eventId, user_id, res))) return;

    const [result] = await db.execute(
      'UPDATE event_participants SET approved = TRUE WHERE event_id = ? AND user_id = ?',
      [eventId, uid]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ message: 'Participant not found' });
    }

    // Notify the participant
    await db.execute(
      'INSERT INTO notifications (user_id, type, reference_id, message) VALUES (?, ?, ?, ?)',
      [uid, 'event_approved', parseInt(eventId), 'Your participation in an event has been approved!']
    );

    res.json({ message: 'Participant approved' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// 14. GET /:id/status/:userId — get participation status for a user
// ─────────────────────────────────────────────────────────────────────────────
exports.getParticipationStatus = async (req, res) => {
  const eventId = req.params.id;
  const userId = req.params.userId || getUserIdFromRequest(req);
  try {
    const [rows] = await db.execute(
      'SELECT status, approved FROM event_participants WHERE event_id = ? AND user_id = ?',
      [eventId, userId]
    );
    if (!rows.length) {
      return res.json({ status: null, approved: null, joined: false });
    }
    res.json({ ...rows[0], joined: true });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// 15. POST /:id/save — save event
// ─────────────────────────────────────────────────────────────────────────────
exports.saveEvent = async (req, res) => {
  const eventId = req.params.id;
  const user_id = getUserIdFromRequest(req);

  if (!user_id) {
    return res.status(400).json({ message: 'user_id is required' });
  }

  try {
    await db.execute(
      'INSERT INTO event_saves (event_id, user_id) VALUES (?, ?) ON CONFLICT (event_id, user_id) DO NOTHING',
      [eventId, user_id]
    );
    res.json({ message: 'Event saved' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// 16. POST /:id/unsave — unsave event
// ─────────────────────────────────────────────────────────────────────────────
exports.unsaveEvent = async (req, res) => {
  const eventId = req.params.id;
  const user_id = getUserIdFromRequest(req);

  if (!user_id) {
    return res.status(400).json({ message: 'user_id is required' });
  }

  try {
    await db.execute(
      'DELETE FROM event_saves WHERE event_id = ? AND user_id = ?',
      [eventId, user_id]
    );
    res.json({ message: 'Event unsaved' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// 17. GET /saved/:userId — get all saved events for a user
// ─────────────────────────────────────────────────────────────────────────────
exports.getSavedEvents = async (req, res) => {
  const { userId } = req.params;
  try {
    const [rows] = await db.execute(`
      SELECT e.*,
             u.username        AS organizer_name,
             u.display_name    AS organizer_display_name,
             u.profile_picture_url AS organizer_avatar,
             es.created_at     AS saved_at
      FROM events e
      JOIN event_saves es ON e.id = es.event_id
      JOIN users u ON e.user_id = u.id
      WHERE es.user_id = ?
      ORDER BY es.created_at DESC
    `, [userId]);
    res.json({ success: true, data: rows });
  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// 18. GET /:id/saved/:userId — check if event is saved
// ─────────────────────────────────────────────────────────────────────────────
exports.isEventSaved = async (req, res) => {
  const eventId = req.params.id;
  const userId = req.params.userId || getUserIdFromRequest(req);
  try {
    const [rows] = await db.execute(
      'SELECT 1 FROM event_saves WHERE event_id = ? AND user_id = ?',
      [eventId, userId]
    );
    res.json({ isSaved: rows.length > 0 });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// 19. GET /:id/comments — get comments (threaded: top-level + replies)
// ─────────────────────────────────────────────────────────────────────────────
exports.getComments = async (req, res) => {
  const eventId = req.params.id;
  try {
    // Fetch all comments for this event
    const [allComments] = await db.execute(`
      SELECT c.id, c.event_id, c.user_id, c.parent_id, c.text, c.is_pinned, c.created_at,
             u.username, u.display_name, u.profile_picture_url,
             (SELECT COUNT(*) FROM event_comment_reactions r WHERE r.comment_id = c.id) AS reaction_count
      FROM event_comments c
      JOIN users u ON c.user_id = u.id
      WHERE c.event_id = ?
      ORDER BY c.is_pinned DESC, c.created_at ASC
    `, [eventId]);

    // Build tree: top-level first, then nest replies
    const topLevel = [];
    const replyMap = {};

    for (const comment of allComments) {
      comment.replies = [];
      if (comment.parent_id === null || comment.parent_id === undefined) {
        topLevel.push(comment);
        replyMap[comment.id] = comment;
      }
    }

    for (const comment of allComments) {
      if (comment.parent_id !== null && comment.parent_id !== undefined) {
        if (replyMap[comment.parent_id]) {
          replyMap[comment.parent_id].replies.push(comment);
        } else {
          // orphaned reply — add to top level
          topLevel.push(comment);
        }
      }
    }

    res.json(topLevel);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// 20. POST /:id/comments — add a comment or reply
// ─────────────────────────────────────────────────────────────────────────────
exports.addComment = async (req, res) => {
  const eventId = req.params.id;
  const user_id = getUserIdFromRequest(req);
  const { text } = req.body;
  const parent_id = req.body.parent_id || req.body.parentId;

  if (!user_id || !text) {
    return res.status(400).json({ message: 'user_id and text are required' });
  }

  try {
    const [result] = await db.execute(
      'INSERT INTO event_comments (event_id, user_id, text, parent_id) VALUES (?, ?, ?, ?)',
      [eventId, user_id, text, parent_id || null]
    );

    // Notify event organizer
    const [eventRows] = await db.execute('SELECT user_id, title FROM events WHERE id = ?', [eventId]);
    if (eventRows.length && eventRows[0].user_id.toString() !== user_id.toString()) {
      await db.execute(
        'INSERT INTO notifications (user_id, type, reference_id, message) VALUES (?, ?, ?, ?)',
        [eventRows[0].user_id, 'event_comment', parseInt(eventId), `Someone commented on your event "${eventRows[0].title}"`]
      );
    }

    res.status(201).json({ message: 'Comment added', commentId: result.insertId });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// 21. POST /comments/:cid/pin — pin a comment (organizer only)
// ─────────────────────────────────────────────────────────────────────────────
exports.pinComment = async (req, res) => {
  const { cid } = req.params;
  const user_id = getUserIdFromRequest(req);

  try {
    // Get the comment's event
    const [commentRows] = await db.execute(
      'SELECT event_id FROM event_comments WHERE id = ?',
      [cid]
    );
    if (!commentRows.length) {
      return res.status(404).json({ message: 'Comment not found' });
    }
    const eventId = commentRows[0].event_id;

    if (!(await assertOrganizer(eventId, user_id, res))) return;

    await db.execute('UPDATE event_comments SET is_pinned = TRUE WHERE id = ?', [cid]);
    res.json({ message: 'Comment pinned' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// 22. POST /comments/:cid/react — react to a comment
// ─────────────────────────────────────────────────────────────────────────────
exports.reactToComment = async (req, res) => {
  const { cid } = req.params;
  const user_id = getUserIdFromRequest(req);
  const { reaction = 'like' } = req.body;

  if (!user_id) {
    return res.status(400).json({ message: 'user_id is required' });
  }

  try {
    await db.execute(
      'INSERT INTO event_comment_reactions (comment_id, user_id, reaction) VALUES (?, ?, ?) ON CONFLICT (comment_id, user_id) DO NOTHING',
      [cid, user_id, reaction]
    );

    const [countRows] = await db.execute(
      'SELECT COUNT(*) AS reaction_count FROM event_comment_reactions WHERE comment_id = ?',
      [cid]
    );

    res.json({ message: 'Reaction added', reaction_count: parseInt(countRows[0].reaction_count) });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// 23. GET /:id/gallery — get event gallery images
// ─────────────────────────────────────────────────────────────────────────────
exports.getGallery = async (req, res) => {
  const eventId = req.params.id;
  try {
    const [rows] = await db.execute(`
      SELECT g.id, g.event_id, g.image_url, g.uploaded_by, g.created_at,
             u.username, u.display_name, u.profile_picture_url
      FROM event_gallery g
      JOIN users u ON g.uploaded_by = u.id
      WHERE g.event_id = ?
      ORDER BY g.created_at DESC
    `, [eventId]);
    res.json({ success: true, data: rows });
  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// 24. POST /:id/gallery — upload image to gallery
// ─────────────────────────────────────────────────────────────────────────────
exports.addGalleryImage = async (req, res) => {
  const eventId = req.params.id;
  const user_id = getUserIdFromRequest(req);
  const { image_url } = req.body;

  if (!user_id || !image_url) {
    return res.status(400).json({ message: 'user_id and image_url are required' });
  }

  try {
    const [result] = await db.execute(
      'INSERT INTO event_gallery (event_id, image_url, uploaded_by) VALUES (?, ?, ?)',
      [eventId, image_url, user_id]
    );
    res.status(201).json({ message: 'Image added to gallery', galleryId: result.insertId });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// 25. POST /:id/invite — send invitation to a user
// ─────────────────────────────────────────────────────────────────────────────
exports.sendInvitation = async (req, res) => {
  const eventId = req.params.id;
  const inviter_id = req.body.inviter_id || req.body.inviterId || getUserIdFromRequest(req);
  const invitee_id = req.body.invitee_id || req.body.inviteeId;

  if (!inviter_id || !invitee_id) {
    return res.status(400).json({ message: 'inviter_id and invitee_id are required' });
  }

  try {
    // Get event details for notification
    const [eventRows] = await db.execute('SELECT title FROM events WHERE id = ?', [eventId]);
    if (!eventRows.length) {
      return res.status(404).json({ message: 'Event not found' });
    }

    await db.execute(
      'INSERT INTO event_invitations (event_id, inviter_id, invitee_id) VALUES (?, ?, ?) ON CONFLICT (event_id, invitee_id) DO NOTHING',
      [eventId, inviter_id, invitee_id]
    );

    // Notify the invitee
    await db.execute(
      'INSERT INTO notifications (user_id, type, reference_id, message) VALUES (?, ?, ?, ?)',
      [invitee_id, 'event_invitation', parseInt(eventId), `You have been invited to the event "${eventRows[0].title}"!`]
    );

    res.status(201).json({ message: 'Invitation sent' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// 26. GET /invitations/:userId — get invitations for a user
// ─────────────────────────────────────────────────────────────────────────────
exports.getInvitations = async (req, res) => {
  const userId = req.params.userId || getUserIdFromRequest(req);
  try {
    const [rows] = await db.execute(`
      SELECT ei.id, ei.event_id, ei.inviter_id, ei.invitee_id, ei.status, ei.created_at,
             e.title, e.start_datetime, e.location, e.cover_image_url, e.status AS event_status,
             u.username AS inviter_name, u.display_name AS inviter_display_name, u.profile_picture_url AS inviter_avatar
      FROM event_invitations ei
      JOIN events e ON ei.event_id = e.id
      JOIN users u ON ei.inviter_id = u.id
      WHERE ei.invitee_id = ?
      ORDER BY ei.created_at DESC
    `, [userId]);
    res.json({ success: true, data: rows });
  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// 27. PUT /invitations/:id — respond to an invitation
// ─────────────────────────────────────────────────────────────────────────────
exports.respondInvitation = async (req, res) => {
  const { id } = req.params;
  const user_id = getUserIdFromRequest(req);
  const { status } = req.body;

  if (!status || !['accepted', 'declined'].includes(status)) {
    return res.status(400).json({ message: 'status must be "accepted" or "declined"' });
  }

  try {
    const [invRows] = await db.execute(
      'SELECT invitee_id, event_id FROM event_invitations WHERE id = ?',
      [id]
    );
    if (!invRows.length) {
      return res.status(404).json({ message: 'Invitation not found' });
    }
    if (invRows[0].invitee_id.toString() !== user_id.toString()) {
      return res.status(403).json({ message: 'Unauthorized' });
    }

    await db.execute(
      'UPDATE event_invitations SET status = ? WHERE id = ?',
      [status, id]
    );

    res.json({ message: `Invitation ${status}` });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// 28. POST /:id/announce — send announcement to all participants (organizer only)
// ─────────────────────────────────────────────────────────────────────────────
exports.sendAnnouncement = async (req, res) => {
  const eventId = req.params.id;
  const user_id = getUserIdFromRequest(req);
  const { message } = req.body;

  if (!user_id || !message) {
    return res.status(400).json({ message: 'user_id and message are required' });
  }

  try {
    if (!(await assertOrganizer(eventId, user_id, res))) return;

    // Fetch event title for notification
    const [eventRows] = await db.execute('SELECT title FROM events WHERE id = ?', [eventId]);
    const eventTitle = eventRows[0].title;

    // Insert as a pinned comment from organizer
    await db.execute(
      'INSERT INTO event_comments (event_id, user_id, text, is_pinned) VALUES (?, ?, ?, TRUE)',
      [eventId, user_id, message]
    );

    // Get all participants
    const [participants] = await db.execute(
      "SELECT DISTINCT user_id FROM event_participants WHERE event_id = ? AND user_id != ?",
      [eventId, user_id]
    );

    // Send notification to each participant
    for (const participant of participants) {
      await db.execute(
        'INSERT INTO notifications (user_id, type, reference_id, message) VALUES (?, ?, ?, ?)',
        [participant.user_id, 'event_announcement', parseInt(eventId), `Announcement for "${eventTitle}": ${message}`]
      );
    }

    res.json({ message: 'Announcement sent', recipients: participants.length });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// 29. GET /:id/invitations — get invitations for a specific event
// ─────────────────────────────────────────────────────────────────────────────
exports.getEventInvitations = async (req, res) => {
  const eventId = req.params.id;
  try {
    const [rows] = await db.execute(`
      SELECT ei.id, ei.event_id, ei.inviter_id, ei.invitee_id, ei.status, ei.created_at,
             u.username AS invitee_name, u.display_name AS invitee_display_name, u.profile_picture_url AS invitee_avatar
      FROM event_invitations ei
      JOIN users u ON ei.invitee_id = u.id
      WHERE ei.event_id = ?
    `, [eventId]);
    res.json({ success: true, data: rows });
  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

