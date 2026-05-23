const db = require('../config/db');

exports.createOrder = async (req, res) => {
  const { userId, storeId, items, totalPrice, deliveryAddress, paymentMethod, tipAmount, couponCode } = req.body;
  try {
    // Insert main order
    const [orderRes] = await db.execute(
      'INSERT INTO orders (user_id, store_id, total_price, delivery_address, payment_method, tip_amount, coupon_code) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [userId, storeId, totalPrice, deliveryAddress || '', paymentMethod || 'Cash', tipAmount || 0, couponCode || null]
    );
    const orderId = orderRes.insertId;

    // Insert order items
    for (const item of items) {
      await db.execute(
        'INSERT INTO order_items (order_id, product_id, quantity, price) VALUES (?, ?, ?, ?)',
        [orderId, item.productId, item.quantity, item.price]
      );
      // Reduce product stock
      await db.execute('UPDATE products SET quantity = quantity - ? WHERE id = ?', [item.quantity, item.productId]);
    }

    if (couponCode) {
      await db.execute('UPDATE coupons SET used_count = used_count + 1 WHERE store_id = ? AND LOWER(code) = LOWER(?)', [storeId, couponCode.trim()]);
    }

    res.status(201).json({ message: 'Order placed successfully', orderId });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: error.message || 'Server error creating order' });
  }
};

exports.getStoreOrders = async (req, res) => {
  try {
    const [orders] = await db.execute(`
      SELECT o.*, u.username as customer_name 
      FROM orders o 
      JOIN users u ON o.user_id = u.id 
      WHERE o.store_id = ? 
      ORDER BY o.created_at DESC
    `, [req.params.storeId]);
    
    // Fetch items for each order (inefficient for large sets, but fine for MVP)
    for (let order of orders) {
      const [items] = await db.execute(`
        SELECT oi.*, p.name as product_name 
        FROM order_items oi 
        JOIN products p ON oi.product_id = p.id 
        WHERE oi.order_id = ?
      `, [order.id]);
      order.items = items;
    }
    
    res.json(orders);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error fetching store orders' });
  }
};

exports.updateOrderStatus = async (req, res) => {
  const { status } = req.body;
  try {
    await db.execute('UPDATE orders SET status = ? WHERE id = ?', [status, req.params.id]);
    res.json({ message: 'Order status updated' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error updating order status' });
  }
};
