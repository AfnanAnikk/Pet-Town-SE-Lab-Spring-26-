const express = require('express');
const router = express.Router();
const socialController = require('../controllers/socialController');

// Follows
router.post('/follow', socialController.followUser);
router.post('/unfollow', socialController.unfollowUser);
router.get('/follow-status', socialController.getFollowStatus);

// Search
router.get('/search', socialController.globalSearch);

// Notifications
router.get('/notifications', socialController.getNotifications);

module.exports = router;
