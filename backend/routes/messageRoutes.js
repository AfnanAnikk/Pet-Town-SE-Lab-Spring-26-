const express = require('express');
const router = express.Router();
const messageController = require('../controllers/messageController');
const authMiddleware = require('../middleware/authMiddleware');

router.get('/conversations/:userId', messageController.getConversations);
router.get('/:conversationId', messageController.getMessages);
router.post('/', messageController.sendMessage);

module.exports = router;
