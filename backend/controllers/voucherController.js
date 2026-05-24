const db = require('../config/db');

exports.getVetVouchers = async (req, res) => {
  try {
    const [vouchers] = await db.execute('SELECT * FROM vet_vouchers WHERE vet_id = ? ORDER BY id DESC', [req.params.vetId]);
    res.json(vouchers);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error fetching vet vouchers' });
  }
};

exports.getAvailableVetVouchers = async (req, res) => {
  try {
    // Active, non-expired, and max_uses not reached
    const [vouchers] = await db.execute(
      `SELECT * FROM vet_vouchers 
       WHERE vet_id = ? 
         AND is_active = TRUE 
         AND (expires_at IS NULL OR expires_at > NOW())
         AND (max_uses IS NULL OR used_count < max_uses)
       ORDER BY id DESC`,
      [req.params.vetId]
    );
    res.json(vouchers);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error fetching available vet vouchers' });
  }
};

exports.createVetVoucher = async (req, res) => {
  const { vetId, code, discountPercent, maxUses, expiresAt } = req.body;
  try {
    const [result] = await db.execute(
      'INSERT INTO vet_vouchers (vet_id, code, discount_percent, max_uses, expires_at) VALUES (?, ?, ?, ?, ?)',
      [vetId, code, discountPercent, maxUses || 100, expiresAt || null]
    );
    const [newVoucher] = await db.execute('SELECT * FROM vet_vouchers WHERE id = ?', [result.insertId]);
    res.status(201).json(newVoucher[0]);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error creating vet voucher' });
  }
};

exports.updateVetVoucher = async (req, res) => {
  const { code, discountPercent, maxUses, expiresAt, isActive } = req.body;
  try {
    await db.execute(
      'UPDATE vet_vouchers SET code = ?, discount_percent = ?, max_uses = ?, expires_at = ?, is_active = ? WHERE id = ?',
      [code, discountPercent, maxUses, expiresAt || null, isActive, req.params.id]
    );
    res.json({ message: 'Voucher updated successfully' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error updating vet voucher' });
  }
};

exports.deleteVetVoucher = async (req, res) => {
  try {
    await db.execute('DELETE FROM vet_vouchers WHERE id = ?', [req.params.id]);
    res.json({ message: 'Voucher deleted successfully' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error deleting vet voucher' });
  }
};

exports.validateVetVoucher = async (req, res) => {
  const { vetId, code } = req.body;
  try {
    if (!vetId || !code) {
      return res.status(400).json({ valid: false, message: 'Vet ID and voucher code are required' });
    }
    const [vouchers] = await db.execute(
      'SELECT * FROM vet_vouchers WHERE vet_id = ? AND LOWER(code) = LOWER(?)',
      [vetId, code.trim()]
    );
    if (vouchers.length === 0) {
      return res.json({ valid: false, message: 'Invalid voucher code for this vet/service provider' });
    }
    const voucher = vouchers[0];
    if (voucher.is_active === false || voucher.is_active === 0) {
      return res.json({ valid: false, message: 'This voucher is currently inactive' });
    }
    if (voucher.expires_at && new Date(voucher.expires_at) < new Date()) {
      return res.json({ valid: false, message: 'This voucher has expired' });
    }
    if (voucher.max_uses > 0 && voucher.used_count >= voucher.max_uses) {
      return res.json({ valid: false, message: 'This voucher has reached its usage limit' });
    }
    res.json({ valid: true, voucher });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error validating voucher' });
  }
};
