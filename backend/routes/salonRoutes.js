const express = require('express');
const router = express.Router();
const salonController = require('../controllers/salonController');

// Salon Listing & Profile
router.get('/', salonController.getAllSalons);
router.get('/user/:userId', salonController.getSalonByUserId);
router.get('/:id', salonController.getSalonById);
router.put('/profile', salonController.updateSalonProfile);

// Bookings
router.post('/bookings', salonController.createBooking);
router.get('/bookings/user/:userId', salonController.getUserBookings);
router.get('/bookings/provider/:userId', salonController.getProviderBookings);
router.put('/bookings/:id/status', salonController.updateBookingStatus);

// Vouchers
router.get('/vouchers/provider/:userId', salonController.getVouchers);
router.post('/vouchers/provider/:userId', salonController.createVoucher);
router.delete('/vouchers/:id', salonController.deleteVoucher);
router.post('/vouchers/validate', salonController.validateVoucher);

router.post('/:id/reviews', salonController.addSalonReview);

router.post('/verify', salonController.verifySalon);

module.exports = router;
