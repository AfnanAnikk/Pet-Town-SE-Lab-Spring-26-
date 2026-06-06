const db = require('../config/db');

// --- Stores ---

exports.getAllStores = async (req, res) => {
  try {
    const [stores] = await db.execute('SELECT * FROM stores');
    res.json(stores);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error fetching stores' });
  }
};

exports.getStoreByUserId = async (req, res) => {
  try {
    const [stores] = await db.execute('SELECT * FROM stores WHERE user_id = ?', [req.params.userId]);
    if (stores.length === 0) {
      return res.status(404).json({ message: 'Store not found' });
    }
    res.json(stores[0]);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error fetching store' });
  }
};

exports.createStore = async (req, res) => {
  const { userId, name, description, category, bannerUrl, location, contactInfo } = req.body;
  try {
    const [result] = await db.execute(
      'INSERT INTO stores (user_id, name, description, category, banner_color, location, banner_url, contact_info) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [userId, name, description || '', category || 'General', '#3293B3', location || '', bannerUrl || null, contactInfo || '']
    );
    const [newStore] = await db.execute('SELECT * FROM stores WHERE id = ?', [result.insertId]);
    res.status(201).json(newStore[0]);
  } catch (error) {
    console.error(error);
    if (error.code === '23505' || error.code === 'ER_DUP_ENTRY') {
      return res.status(400).json({ message: 'User already has a store' });
    }
    res.status(500).json({ message: 'Server error creating store' });
  }
};

exports.updateStore = async (req, res) => {
  const { name, description, category, bannerColor, bannerUrl, location, contactInfo } = req.body;

  try {
    await db.execute(
      `UPDATE stores 
       SET name = ?, 
           description = ?, 
           category = ?, 
           banner_color = COALESCE(?, banner_color), 
           banner_url = COALESCE(?, banner_url),
           location = ?,
           contact_info = ?
       WHERE id = ?`,
      [
        name,
        description,
        category || 'General',
        bannerColor || null,
        bannerUrl || null,
        location || '',
        contactInfo || '',
        req.params.id,
      ]
    );

    res.json({ message: 'Store updated successfully' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error updating store' });
  }
};

exports.verifyStore = async (req, res) => {
  const { userId, ownerName, nidNumber, tradeLicense } = req.body;
  try {
    const [stores] = await db.execute('SELECT id FROM stores WHERE user_id = ?', [userId]);
    if (stores.length === 0) return res.status(404).json({ message: 'Store not found for this user' });
    const storeId = stores[0].id;

    await db.execute(
      'INSERT INTO store_verifications (store_id, owner_name, nid_number, trade_license) VALUES (?, ?, ?, ?)',
      [storeId, ownerName, nidNumber, tradeLicense]
    );

    await db.execute('UPDATE stores SET is_verified = TRUE WHERE id = ?', [storeId]);
    res.status(201).json({ message: 'Store verification submitted' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error verifying store' });
  }
};

// --- Products ---

exports.getAllProducts = async (req, res) => {
  try {
    const [products] = await db.execute(
      'SELECT p.*, s.name as store_name FROM products p JOIN stores s ON p.store_id = s.id WHERE p.is_active = TRUE'
    );
    res.json(products);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error fetching products' });
  }
};

exports.getStoreProducts = async (req, res) => {
  try {
    const [products] = await db.execute('SELECT * FROM products WHERE store_id = ?', [req.params.storeId]);
    res.json(products);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error fetching store products' });
  }
};

exports.createProduct = async (req, res) => {
  const { storeId, name, description, category, price, originalPrice, quantity, discountPercent, imagePath } = req.body;
  try {
    const [result] = await db.execute(
      'INSERT INTO products (store_id, name, description, category, price, original_price, quantity, discount_percent, image_path) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [storeId, name, description || '', category || '', price, originalPrice || price, quantity || 0, discountPercent || 0, imagePath || 'assets/images/p1.png']
    );
    const [newProduct] = await db.execute('SELECT * FROM products WHERE id = ?', [result.insertId]);
    res.status(201).json(newProduct[0]);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error creating product' });
  }
};

exports.updateProduct = async (req, res) => {
  const { name, description, category, price, originalPrice, quantity, discountPercent, isActive } = req.body;
  try {
    await db.execute(
      'UPDATE products SET name = ?, description = ?, category = ?, price = ?, original_price = ?, quantity = ?, discount_percent = ?, is_active = ? WHERE id = ?',
      [name, description, category, price, originalPrice, quantity, discountPercent, isActive, req.params.id]
    );
    res.json({ message: 'Product updated successfully' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error updating product' });
  }
};

// --- Coupons/Vouchers ---

exports.getStoreCoupons = async (req, res) => {
  try {
    const [coupons] = await db.execute('SELECT * FROM coupons WHERE store_id = ? ORDER BY id DESC', [req.params.storeId]);
    res.json(coupons);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error fetching store coupons' });
  }
};

exports.createCoupon = async (req, res) => {
  const { storeId, code, discountPercent, minOrderAmount, maxUses, expiresAt } = req.body;
  try {
    const [result] = await db.execute(
      'INSERT INTO coupons (store_id, code, discount_percent, min_order_amount, max_uses, expires_at) VALUES (?, ?, ?, ?, ?, ?)',
      [storeId, code, discountPercent, minOrderAmount || 0, maxUses || 100, expiresAt || null]
    );
    const [newCoupon] = await db.execute('SELECT * FROM coupons WHERE id = ?', [result.insertId]);
    res.status(201).json(newCoupon[0]);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error creating coupon' });
  }
};

exports.updateCoupon = async (req, res) => {
  const { code, discountPercent, minOrderAmount, maxUses, expiresAt, isActive } = req.body;
  try {
    await db.execute(
      'UPDATE coupons SET code = ?, discount_percent = ?, min_order_amount = ?, max_uses = ?, expires_at = ?, is_active = ? WHERE id = ?',
      [code, discountPercent, minOrderAmount, maxUses, expiresAt || null, isActive, req.params.id]
    );
    res.json({ message: 'Coupon updated successfully' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error updating coupon' });
  }
};

exports.deleteCoupon = async (req, res) => {
  try {
    await db.execute('DELETE FROM coupons WHERE id = ?', [req.params.id]);
    res.json({ message: 'Coupon deleted successfully' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error deleting coupon' });
  }
};

exports.validateCoupon = async (req, res) => {
  const { storeId, code, orderAmount } = req.body;
  try {
    if (!storeId || !code) {
      return res.status(400).json({ valid: false, message: 'Store ID and coupon code are required' });
    }
    const [coupons] = await db.execute(
      'SELECT * FROM coupons WHERE store_id = ? AND LOWER(code) = LOWER(?)',
      [storeId, code.trim()]
    );
    if (coupons.length === 0) {
      return res.json({ valid: false, message: 'Invalid coupon code for this shop' });
    }
    const coupon = coupons[0];
    if (coupon.is_active === false || coupon.is_active === 0) {
      return res.json({ valid: false, message: 'This coupon is currently inactive' });
    }
    if (coupon.expires_at && new Date(coupon.expires_at) < new Date()) {
      return res.json({ valid: false, message: 'This coupon has expired' });
    }
    if (coupon.max_uses > 0 && coupon.used_count >= coupon.max_uses) {
      return res.json({ valid: false, message: 'This coupon has reached its usage limit' });
    }
    if (orderAmount !== undefined && parseFloat(orderAmount) < parseFloat(coupon.min_order_amount)) {
      return res.json({ valid: false, message: `Minimum order amount to use this coupon is ৳${coupon.min_order_amount}` });
    }
    res.json({ valid: true, coupon });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error validating coupon' });
  }
};
