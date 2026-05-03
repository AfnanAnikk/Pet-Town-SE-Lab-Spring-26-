const express = require('express');
const router = express.Router();
const vetController = require('../controllers/vetController');

router.get('/', vetController.getAllVets);
router.get('/user/:userId', vetController.getVetByUserId);
router.post('/verify', vetController.verifyVet);
router.get('/:id', vetController.getVetById);
router.put('/profile', vetController.updateVetProfile);

module.exports = router;
