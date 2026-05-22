const express = require('express');
const router = express.Router();
const messageController = require('../controllers/messagesController');
const authMiddleware = require('../middleware/authMiddleware');

router.get('/conversations/:userId', authMiddleware, messageController.getConversations);
router.get('/:conversationId', authMiddleware, messageController.getMessages);
router.post('/', authMiddleware, messageController.sendMessage);

module.exports = router;
