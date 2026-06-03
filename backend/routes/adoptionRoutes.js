const express = require('express');
const router = express.Router();
const adoptionController = require('../controllers/adoptionController');

router.get('/', adoptionController.getAllAdoptions);
router.post('/', adoptionController.createAdoption);

router.get('/user/:userId', adoptionController.getUserAdoptions);
router.get('/requests/:userId', adoptionController.getUserAdoptionRequests);
router.get('/owner-requests/:userId', adoptionController.getOwnerAdoptionRequests);
router.put('/requests/:requestId/status', adoptionController.updateAdoptionRequestStatus);

router.get('/:id', adoptionController.getAdoptionById);
router.post('/:id/request', adoptionController.requestAdoption);

module.exports = router;    