const express = require('express');
const router = express.Router();
const marketplaceController = require('../controllers/marketplaceController');

// Stores
router.get('/stores', marketplaceController.getAllStores);
router.get('/stores/:userId', marketplaceController.getStoreByUserId);
router.post('/stores', marketplaceController.createStore);
router.put('/stores/:id', marketplaceController.updateStore);

router.post('/stores/verify', marketplaceController.verifyStore);

// Products
router.get('/products', marketplaceController.getAllProducts);
router.get('/stores/:storeId/products', marketplaceController.getStoreProducts);
router.post('/products', marketplaceController.createProduct);
router.put('/products/:id', marketplaceController.updateProduct);

// Coupons
router.get('/stores/:storeId/coupons', marketplaceController.getStoreCoupons);
router.post('/coupons', marketplaceController.createCoupon);
router.put('/coupons/:id', marketplaceController.updateCoupon);
router.delete('/coupons/:id', marketplaceController.deleteCoupon);
router.post('/coupons/validate', marketplaceController.validateCoupon);

module.exports = router;
