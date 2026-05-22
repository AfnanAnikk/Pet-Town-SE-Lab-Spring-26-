const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');

// Finance
router.get('/finance', adminController.getFinanceStats);

// Dashboard
router.get('/dashboard', adminController.getDashboardStats);

// Vets
router.get('/vets/verifications', adminController.getVetVerifications);
router.post('/vets/verifications/:id/approve', adminController.approveVet);
router.post('/vets/verifications/:id/deny', adminController.denyVet);

// Stores
router.get('/stores/verifications', adminController.getStoreVerifications);
router.post('/stores/verifications/:id/approve', adminController.approveStore);
router.post('/stores/verifications/:id/deny', adminController.denyStore);

// Marketplace Orders
router.get('/orders', adminController.getMarketplaceOrders);

// Adoptions
router.get('/adoptions', adminController.getAdoptions);
router.post('/adoptions', adminController.addAdoption);
router.put('/adoptions/:id/status', adminController.updateAdoptionStatus);

module.exports = router;
