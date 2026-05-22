const express = require('express');
const router = express.Router();
const marketplaceController = require('../controllers/marketplaceController');

// Stores
router.get('/stores', marketplaceController.getAllStores);
router.get('/stores/:userId', marketplaceController.getStoreByUserId);
router.post('/stores', marketplaceController.createStore);
router.put('/stores/:id', marketplaceController.updateStore);

// Products
router.get('/products', marketplaceController.getAllProducts);
router.get('/stores/:storeId/products', marketplaceController.getStoreProducts);
router.post('/products', marketplaceController.createProduct);
router.put('/products/:id', marketplaceController.updateProduct);

module.exports = router;
