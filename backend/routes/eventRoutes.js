const express = require('express');
const router = express.Router();
const c = require('../controllers/eventController');

// ── Specific named routes (must come before /:id) ─────────────────────────────
router.get('/trending',               c.getTrendingEvents);
router.get('/nearby',                 c.getNearbyEvents);
router.get('/saved/:userId',          c.getSavedEvents);
router.get('/invitations',            c.getInvitations);
router.get('/invitations/:userId',     c.getInvitations); // Support parameter style
router.get('/user/:userId',           c.getEventsByUser);
router.post('/comments/:cid/pin',     c.pinComment);
router.post('/comments/:cid/react',   c.reactToComment);
router.patch('/invitations/:id',      c.respondInvitation);
router.put('/invitations/:id',        c.respondInvitation); // Support both PATCH and PUT

// ── Core event CRUD ───────────────────────────────────────────────────────────
router.get('/',                       c.getAllEvents);
router.post('/',                      c.createEvent);
router.get('/:id',                    c.getEventById);
router.put('/:id',                    c.updateEvent);
router.delete('/:id',                 c.deleteEvent);
router.patch('/:id/status',           c.updateEventStatus);

// ── Participation ─────────────────────────────────────────────────────────────
router.post('/:id/join',              c.joinEvent);
router.post('/:id/leave',             c.leaveEvent);
router.get('/:id/participants',       c.getParticipants);
router.put('/:id/participants/:uid/approve', c.approveParticipant);
router.post('/:id/participants/:uid/approve', c.approveParticipant); // Support client POST
router.get('/:id/status/:userId',     c.getParticipationStatus);
router.get('/:id/participation',      c.getParticipationStatus); // Support client query-parameter style

// ── Bookmarks ─────────────────────────────────────────────────────────────────
router.post('/:id/save',              c.saveEvent);
router.post('/:id/unsave',            c.unsaveEvent);
router.get('/:id/saved/:userId',      c.isEventSaved);
router.get('/:id/saved',              c.isEventSaved); // Support client query-parameter style

// ── Comments ──────────────────────────────────────────────────────────────────
router.get('/:id/comments',           c.getComments);
router.post('/:id/comments',          c.addComment);

// ── Gallery ───────────────────────────────────────────────────────────────────
router.get('/:id/gallery',            c.getGallery);
router.post('/:id/gallery',           c.addGalleryImage);

// ── Invitations ───────────────────────────────────────────────────────────────
router.post('/:id/invite',            c.sendInvitation);

// ── Announcements ─────────────────────────────────────────────────────────────
router.post('/:id/announce',          c.sendAnnouncement);

module.exports = router;
