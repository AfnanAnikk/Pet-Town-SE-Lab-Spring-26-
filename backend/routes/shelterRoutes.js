const express = require('express');
const router = express.Router();
const shelterController = require('../controllers/shelterController');

router.get('/', shelterController.getAllShelters);
router.get('/:id', shelterController.getShelterById);
router.post('/:id/book', shelterController.bookShelter);

router.get('/bookings/:userId', shelterController.getUserShelterBookings);

module.exports = router;
