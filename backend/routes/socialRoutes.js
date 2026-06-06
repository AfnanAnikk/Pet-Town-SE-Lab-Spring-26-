const express = require('express');
const router = express.Router();
const socialController = require('../controllers/socialController');

// Follows
router.post('/follow', socialController.followUser);
router.post('/unfollow', socialController.unfollowUser);
router.get('/follow-status', socialController.getFollowStatus);
router.get('/counts/:userId', socialController.getFollowCounts);
router.get('/followers/:userId', socialController.getFollowers);
router.get('/following/:userId', socialController.getFollowing);

// Search
router.get('/search', socialController.globalSearch);

// Notifications
router.get('/notifications/unread-count', socialController.getUnreadNotificationsCount);
router.get('/notifications', socialController.getNotifications);

module.exports = router;
