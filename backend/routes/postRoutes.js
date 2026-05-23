const express = require('express');
const router = express.Router();
const postController = require('../controllers/postController');

router.get('/', postController.getAllPosts);
router.post('/', postController.createPost);

// Saved posts routes MUST come before /:id routes to avoid Express matching 'saved' as :id
router.get('/saved/:userId', postController.getSavedPosts);
router.get('/saved/:userId/status/:postId', postController.isPostSaved);

router.post('/:id/like', postController.likePost);
router.post('/:id/unlike', postController.unlikePost);
router.get('/:id/liked/:userId', postController.isPostLiked);
router.post('/:id/comments', postController.addComment);
router.get('/:id/comments', postController.getComments);
router.delete('/:id', postController.deletePost);

router.post('/:id/save', postController.savePost);
router.post('/:id/unsave', postController.unsavePost);

module.exports = router;
