const express = require('express');
const router = express.Router();
const adoptionController = require('../controllers/adoptionController');

router.get('/', adoptionController.getAllAdoptions);
router.post('/', adoptionController.createAdoption);
router.get('/:id', adoptionController.getAdoptionById);
router.post('/:id/request', adoptionController.requestAdoption);

router.get('/user/:userId', adoptionController.getUserAdoptions);
router.get('/requests/:userId', adoptionController.getUserAdoptionRequests);
router.get('/owner-requests/:userId', adoptionController.getOwnerAdoptionRequests);

module.exports = router;
