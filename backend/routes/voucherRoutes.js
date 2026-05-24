const express = require('express');
const router = express.Router();
const voucherController = require('../controllers/voucherController');

router.get('/vet/:vetId', voucherController.getVetVouchers);
router.get('/vet/:vetId/available', voucherController.getAvailableVetVouchers);
router.post('/', voucherController.createVetVoucher);
router.put('/:id', voucherController.updateVetVoucher);
router.delete('/:id', voucherController.deleteVetVoucher);
router.post('/validate', voucherController.validateVetVoucher);

module.exports = router;
