import 'package:flutter/material.dart';

class RestaurantOrdersApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Órdenes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: MaterialColor(0xFF8B4513, {
          50: Color(0xFFF5F2F0),
          100: Color(0xFFE8DDD6),
          200: Color(0xFFD4C2B1),
          300: Color(0xFFBFA78C),
          400: Color(0xFFAF9373),
          500: Color(0xFF8B4513),
          600: Color(0xFF7A3E11),
          700: Color(0xFF66340E),
          800: Color(0xFF522A0B),
          900: Color(0xFF3E1F08),
        }),
        fontFamily: 'Roboto',
        appBarTheme: AppBarTheme(
          backgroundColor: Color.fromARGB(234, 102, 52, 14),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: OrdersScreen(),
    );
  }
}

class OrdersScreen extends StatefulWidget {
  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Order> orders = [
    Order(
      id: '#001',
      customerName: 'María García',
      items: [
        OrderItem('Huevos al gusto', 2, 45.00),
        OrderItem('caldo', 1, 35.00),
      ],
      status: OrderStatus.pending,
      time: '10:30 AM',
      tableNumber: '5',
    ),
    Order(
      id: '#002',
      customerName: 'Carlos López',
      items: [
       OrderItem('Huevos al gusto', 2, 45.00),
        OrderItem('caldo', 1, 35.00),
      ],
      status: OrderStatus.pending,
      time: '10:45 AM',
      tableNumber: '3',
    ),
    Order(
      id: '#003',
      customerName: 'Ana Martínez',
      items: [
       OrderItem('Huevos al gusto', 2, 45.00),
        OrderItem('caldo', 1, 35.00),
      ],
      status: OrderStatus.completed,
      time: '11:00 AM',
      tableNumber: '8',
    ),
    Order(
      id: '#004',
      customerName: 'Roberto Silva',
      items: [
        OrderItem('Huevos al gusto', 2, 45.00),
        OrderItem('caldo', 1, 35.00),
      ],
      status: OrderStatus.completed,
      time: '11:15 AM',
      tableNumber: '2',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F2F0),
      appBar: AppBar(
        title: Text(
          'Órdenes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Status tabs
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStatusTab('Pendientes', OrderStatus.pending),
                SizedBox(width: 8),
                _buildStatusTab('Completados', OrderStatus.completed),
              ],
            ),
          ),
          // Orders list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                return _buildOrderCard(orders[index]);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Color(0xFF8B4513),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatusTab(String title, OrderStatus status) {
    int count = orders.where((order) => order.status == status).length;
    Color color = _getStatusColor(status);
    
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFFAF9F8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFF8B4513),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          order.id,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.customerName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF3E1F08),
                            ),
                          ),
                          Text(
                            'Mesa ${order.tableNumber} • ${order.time}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(order.status).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _getStatusText(order.status),
                      style: TextStyle(
                        color: _getStatusColor(order.status),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              // Items
              Column(
                children: order.items.map((item) {
                  return Container(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Color(0xFF8B4513).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    item.quantity.toString(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Color(0xFF8B4513),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF3E1F08),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF8B4513),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 16),
              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: \$${order.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B4513),
                    ),
                  ),
                  Row(
                    children: [
                      if (order.status == OrderStatus.pending) ...[
                        ElevatedButton(
                          onPressed: () => _updateOrderStatus(order, OrderStatus.completed),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Entregar'),
                        ),
                      ],
                      SizedBox(width: 8),
                      IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.more_vert),
                        color: Color(0xFF8B4513),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.completed:
        return Colors.grey;
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pendiente';
      case OrderStatus.completed:
        return 'Completado';
    }
  }

  void _updateOrderStatus(Order order, OrderStatus newStatus) {
    setState(() {
      order.status = newStatus;
    });
  }
}

enum OrderStatus {
  pending,
  completed,
}

class Order {
  final String id;
  final String customerName;
  final List<OrderItem> items;
  OrderStatus status;
  final String time;
  final String tableNumber;

  Order({
    required this.id,
    required this.customerName,
    required this.items,
    required this.status,
    required this.time,
    required this.tableNumber,
  });

  double get total => items.fold(0, (sum, item) => sum + (item.price * item.quantity));
}

class OrderItem {
  final String name;
  final int quantity;
  final double price;

  OrderItem(this.name, this.quantity, this.price);
}