import 'package:flutter/material.dart';



class OrderScreen extends StatefulWidget {
  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  int selectedCategoryIndex = 0;
  List<CartItem> cartItems = [];
  String? selectedTable;

  final List<Category> categories = [
    Category(
      name: 'Quesadillas',
      icon: Icons.local_pizza,
      items: [
        MenuItem('1 Pieza (1 carne)', 50.00, '🌮'),
        MenuItem('Cochito', 50.00, '🐷'),
        MenuItem('Chorizo', 50.00, '🌶️'),
        MenuItem('Bisteck', 50.00, '🥩'),
        MenuItem('Pastor', 50.00, '🍖'),
        MenuItem('Champiñón', 50.00, '🍄'),
        MenuItem('Combinadas (2 carnes)', 60.00, '🌮🌮'),
      ],
    ),
    Category(
      name: 'Bebidas',
      icon: Icons.local_drink,
      items: [
        MenuItem('Aguas Naturales de Temporada', 35.00, '🥤'),
        MenuItem('Refrescos Embotellados', 35.00, '🥤'),
        MenuItem('Café con Leche', 35.00, '☕'),
        MenuItem('Chocolate', 35.00, '🍫'),
        MenuItem('Café', 25.00, '☕'),
        MenuItem('Cerveza', 35.00, '🍺'),
        MenuItem('Chocomilk', 60.00, '🥛'),
        MenuItem('Tascalate con Leche', 60.00, '🥛'),
      ],
    ),
    Category(
      name: 'Extras',
      icon: Icons.add_circle,
      items: [
        MenuItem('Plátanos Fritos', 45.00, '🍌'),
        MenuItem('Queso', 30.00, '🧀'),
        MenuItem('Crema', 30.00, '🥛'),
        MenuItem('Frijoles Refritos', 40.00, '🫘'),
        MenuItem('Guacamole', 60.00, '🥑'),
        MenuItem('Litro de Molé', 100.00, '🍲'),
        MenuItem('Litro de Crema', 100.00, '🥛'),
      ],
    ),
    Category(
      name: 'Postres',
      icon: Icons.cake,
      items: [
        MenuItem('Plátanos Fritos con Lechera', 45.00, '🍌'),
        MenuItem('Duraznos en Almíbar con Rompope', 35.00, '🍑'),
        MenuItem('Carlota', 35.00, '🍰'),
        MenuItem('Flan', 45.00, '🍮'),
        MenuItem('Duraznos Conserva', 150.00, '🍑'),
        MenuItem('Plátanos Hechos en Horno de Barro', 45.00, '🍌'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F2F0),
      appBar: AppBar(
        backgroundColor: Color(0xFF8B4513),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'EJ',
                style: TextStyle(
                  color: Color(0xFF8B4513),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comedor "El Jobo"',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Nueva Orden',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () => _showCart(),
              ),
              if (cartItems.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${cartItems.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Table Selection
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Icon(Icons.table_restaurant, color: Color(0xFF8B4513)),
                SizedBox(width: 12),
                Text(
                  'Seleccionar Mesa:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3E1F08),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFF8B4513)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedTable,
                        hint: Text('Seleccionar mesa'),
                        isExpanded: true,
                        items: List.generate(20, (index) => index + 1)
                            .map((table) => DropdownMenuItem(
                                  value: table.toString(),
                                  child: Text('Mesa $table'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedTable = value;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Categories
          Container(
            height: 80,
            padding: EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 8),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategoryIndex == index;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategoryIndex = index;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Color(0xFF8B4513) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          category.icon,
                          color: isSelected ? Colors.white : Color(0xFF8B4513),
                          size: 18,
                        ),
                        SizedBox(height: 2),
                        Text(
                          category.name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Color(0xFF8B4513),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Menu Items
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: categories[selectedCategoryIndex].items.length,
              itemBuilder: (context, index) {
                final item = categories[selectedCategoryIndex].items[index];
                return _buildMenuItem(item);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: cartItems.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showCart(),
              backgroundColor: Color(0xFF8B4513),
              icon: Icon(Icons.shopping_cart, color: Colors.white),
              label: Text(
                'Ver Orden (\$${_getTotal().toStringAsFixed(2)})',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Widget _buildMenuItem(MenuItem item) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFFAF9F8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            // Item emoji/icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Color(0xFF8B4513).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  item.emoji,
                  style: TextStyle(fontSize: 28),
                ),
              ),
            ),
            SizedBox(width: 16),
            
            // Item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3E1F08),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '\$${item.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B4513),
                    ),
                  ),
                ],
              ),
            ),
            
            // Add to cart button
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF8B4513),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: () => _addToCart(item),
                icon: Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart(MenuItem item) {
    setState(() {
      final existingItemIndex = cartItems.indexWhere((cartItem) => cartItem.item.name == item.name);
      
      if (existingItemIndex >= 0) {
        cartItems[existingItemIndex].quantity++;
      } else {
        cartItems.add(CartItem(item: item, quantity: 1));
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} agregado al carrito'),
        duration: Duration(seconds: 1),
        backgroundColor: Color(0xFF8B4513),
      ),
    );
  }

  double _getTotal() {
    return cartItems.fold(0, (sum, cartItem) => sum + (cartItem.item.price * cartItem.quantity));
  }

  void _showCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tu Orden',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B4513),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Cart items
            Expanded(
              child: cartItems.isEmpty
                  ? Center(
                      child: Text(
                        'Tu carrito está vacío',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final cartItem = cartItems[index];
                        return _buildCartItem(cartItem, index);
                      },
                    ),
            ),
            
            // Footer
            if (cartItems.isNotEmpty)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFF5F2F0),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3E1F08),
                          ),
                        ),
                        Text(
                          '\$${_getTotal().toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B4513),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _confirmOrder(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF8B4513),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Confirmar Orden',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(CartItem cartItem, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFF5F2F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            cartItem.item.emoji,
            style: TextStyle(fontSize: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cartItem.item.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3E1F08),
                  ),
                ),
                Text(
                  '\$${cartItem.item.price.toStringAsFixed(2)} c/u',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => _decreaseQuantity(index),
                icon: Icon(Icons.remove_circle, color: Colors.red),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  cartItem.quantity.toString(),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () => _increaseQuantity(index),
                icon: Icon(Icons.add_circle, color: Color(0xFF8B4513)),
              ),
            ],
          ),
          Text(
            '\$${(cartItem.item.price * cartItem.quantity).toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B4513),
            ),
          ),
        ],
      ),
    );
  }

  void _increaseQuantity(int index) {
    setState(() {
      cartItems[index].quantity++;
    });
  }

  void _decreaseQuantity(int index) {
    setState(() {
      if (cartItems[index].quantity > 1) {
        cartItems[index].quantity--;
      } else {
        cartItems.removeAt(index);
      }
    });
  }

  void _confirmOrder() {
    if (selectedTable == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor selecciona una mesa'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¡Orden Confirmada!'),
        content: Text('La orden para la Mesa $selectedTable ha sido enviada a cocina.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                cartItems.clear();
                selectedTable = null;
              });
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}

class Category {
  final String name;
  final IconData icon;
  final List<MenuItem> items;

  Category({required this.name, required this.icon, required this.items});
}

class MenuItem {
  final String name;
  final double price;
  final String emoji;

  MenuItem(this.name, this.price, this.emoji);
}

class CartItem {
  final MenuItem item;
  int quantity;

  CartItem({required this.item, required this.quantity});
}