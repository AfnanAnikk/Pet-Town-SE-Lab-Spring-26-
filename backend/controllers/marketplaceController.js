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
  const { name, description, category, bannerColor, location } = req.body;
  try {
    await db.execute(
      'UPDATE stores SET name = ?, description = ?, category = ?, banner_color = ?, location = ? WHERE id = ?',
      [name, description, category, bannerColor, location, req.params.id]
    );
    res.json({ message: 'Store updated successfully' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error updating store' });
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
