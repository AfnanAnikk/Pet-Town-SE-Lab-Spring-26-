import 'package:flutter/foundation.dart';

class CartItem {
  final dynamic product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get price {
    return double.parse(product['price'].toString());
  }
}

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<CartItem> _items = [];
  int? _currentStoreId; // Only allow one store at a time like Foodpanda

  List<CartItem> get items => _items;
  int? get storeId => _currentStoreId;

  void addItem(dynamic product) {
    int sId = product['store_id'];
    
    if (_items.isNotEmpty && _currentStoreId != sId) {
      // Trying to add from a different store - for MVP just clear it or ignore
      // Foodpanda normally warns you. Let's just clear for simplicity
      _items.clear();
    }
    
    _currentStoreId = sId;

    final existingIndex = _items.indexWhere((i) => i.product['id'] == product['id']);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }
    notifyListeners();
  }

  void removeItem(int productId) {
    _items.removeWhere((i) => i.product['id'] == productId);
    if (_items.isEmpty) {
      _currentStoreId = null;
    }
    notifyListeners();
  }

  void updateQuantity(int productId, int quantity) {
    final existingIndex = _items.indexWhere((i) => i.product['id'] == productId);
    if (existingIndex >= 0) {
      if (quantity <= 0) {
        removeItem(productId);
      } else {
        _items[existingIndex].quantity = quantity;
        notifyListeners();
      }
    }
  }

  void clearCart() {
    _items.clear();
    _currentStoreId = null;
    notifyListeners();
  }

  double get subtotal {
    return _items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }
  
  double get totalQuantity {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }
}
