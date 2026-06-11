const db = require('../config/db');
const { checkMessageSafety } = require('../services/messageModerationService');

exports.getConversations = async (req, res) => {
  const userId = req.params.userId;

  try {
    const query = `
      SELECT 
        c.id as conversation_id, 
        c.last_message_at,
        u.id as other_user_id, 
        u.username as other_user_name, 
        u.email as other_user_email,
        COALESCE(s.profile_picture_url, u.profile_picture_url) as other_user_profile_picture_url,
        (SELECT text FROM messages WHERE conversation_id = c.id ORDER BY created_at DESC LIMIT 1) as last_message,
        (SELECT is_read FROM messages WHERE conversation_id = c.id ORDER BY created_at DESC LIMIT 1) as is_read,
        (SELECT sender_id FROM messages WHERE conversation_id = c.id ORDER BY created_at DESC LIMIT 1) as last_sender_id
      FROM conversations c
      JOIN users u 
        ON (c.user1_id = u.id OR c.user2_id = u.id)
      LEFT JOIN salons s
        ON s.user_id = u.id
      WHERE (c.user1_id = ? OR c.user2_id = ?) 
        AND u.id != ?
      ORDER BY c.last_message_at DESC
    `;

    const [conversations] = await db.execute(query, [userId, userId, userId]);
    res.json(conversations);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error fetching conversations' });
  }
};

exports.getMessages = async (req, res) => {
  const conversationId = req.params.conversationId;
  try {
    const [messages] = await db.execute(
      'SELECT * FROM messages WHERE conversation_id = ? ORDER BY created_at ASC',
      [conversationId]
    );
    res.json(messages);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error fetching messages' });
  }
};

exports.sendMessage = async (req, res) => {
  const { senderId, receiverId, text, imageUrl } = req.body;
  try {
    // Find or create conversation
    let [convs] = await db.execute(
      'SELECT id FROM conversations WHERE (user1_id = ? AND user2_id = ?) OR (user1_id = ? AND user2_id = ?)',
      [senderId, receiverId, receiverId, senderId]
    );

    let conversationId;
    if (convs.length > 0) {
      conversationId = convs[0].id;
      // Update last message time
      await db.execute('UPDATE conversations SET last_message_at = CURRENT_TIMESTAMP WHERE id = ?', [conversationId]);
    } else {
      const [resConv] = await db.execute(
        'INSERT INTO conversations (user1_id, user2_id) VALUES (?, ?)',
        [senderId, receiverId]
      );
      conversationId = resConv.insertId;
    }

    // Insert message
    const [msgRes] = await db.execute(
      'INSERT INTO messages (conversation_id, sender_id, text, image_url) VALUES (?, ?, ?, ?)',
      [conversationId, senderId, text || '', imageUrl || null]
    );

    const [newMsg] = await db.execute('SELECT * FROM messages WHERE id = ?', [msgRes.insertId]);
    
    if (text && text.trim().length > 0) {
      try {
        const moderation = await checkMessageSafety(text.trim());

        if (moderation.isRisky) {
          await db.execute(
            `INSERT INTO message_moderation_alerts 
            (message_id, conversation_id, sender_id, receiver_id, snippet, reason, label, confidence)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
            [
              msgRes.insertId,
              conversationId,
              senderId,
              receiverId,
              text.trim().slice(0, 300),
              moderation.reason,
              moderation.label,
              moderation.confidence
            ]
          );
        }
      } catch (moderationError) {
        console.error('Message moderation failed:', moderationError.message);
      }
    }

    // Emit to receiver and sender room using Socket.IO attached to req
    if (req.io) {
      req.io.to(`user_${receiverId}`).emit('receive_message', newMsg[0]);
      req.io.to(`user_${senderId}`).emit('receive_message', newMsg[0]);
    }

    res.status(201).json(newMsg[0]);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error sending message' });
  }
};
