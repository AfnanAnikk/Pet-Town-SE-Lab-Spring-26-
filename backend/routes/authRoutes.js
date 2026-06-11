const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

router.post('/register', authController.register);
router.post('/login', authController.login);
router.get('/profile/:id', authController.getProfile);
router.put('/profile/:id', authController.updateProfile);
router.get('/users', authController.getAllUsers);
router.post('/forgot-password', authController.forgotPassword);
router.post('/reset-password', authController.resetPassword);




module.exports = router;
