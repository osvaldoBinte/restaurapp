import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(AddFoodApp());
}

class AddFoodApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agregar Comida - El Jobo',
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
      ),
      home: AddFoodScreen(),
    );
  }
}

class AddFoodScreen extends StatefulWidget {
  @override
  _AddFoodScreenState createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? selectedCategory;
  String selectedEmoji = '🍽️';
  bool isAvailable = true;
  
  final List<String> categories = [
    'Quesadillas',
    'Bebidas',
    'Extras',
    'Postres',
  ];
  
  final List<String> emojis = [
    '🍽️', '🌮', '🥙', '🌯', '🍖', '🥩', '🐷', '🌶️', '🍄',
    '☕', '🥤', '🍺', '🥛', '🍫', '🍹', '🧊', '🫖',
    '🧀', '🥑', '🍌', '🫘', '🍲', '🥛', '🌶️',
    '🍰', '🍮', '🍑', '🧁', '🍯', '🍪', '🎂', '🥧',
    '🍕', '🍔', '🌭', '🥪', '🍳', '🥚', '🍞', '🥖'
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
                  'Agregar Nueva Comida',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [Color(0xFF8B4513), Color(0xFF7A3E11)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
  children: [
    Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.restaurant_menu,
          size: 48,
          color: Colors.white,
        ),
       Positioned(
  bottom: 0,
  right: 0,
  child: Container(
    width: 24,
    height: 24,
    decoration: BoxDecoration(
      color: Color.fromARGB(255, 0, 0, 0),
      shape: BoxShape.circle,
    ),
    child: Icon(
      Icons.add_a_photo,
      size: 16,
      color: Colors.white, // O el color que desees
    ),
  ),
),

      ],
    ),
    SizedBox(height: 12),
    Text(
      'Nueva Comida',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    Text(
      'Completa la información del nuevo platillo',
      style: TextStyle(
        fontSize: 14,
        color: Colors.white70,
      ),
      textAlign: TextAlign.center,
    ),
  ],
)

                ),
              ),
              
              SizedBox(height: 24),
              
              // Información Básica
              _buildSectionTitle('Información Básica'),
              SizedBox(height: 12),
              
              // Nombre del platillo
              _buildFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nombre del Platillo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3E1F08),
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Ej: Quesadilla de Pollo',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.restaurant, color: Color(0xFF8B4513)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el nombre del platillo';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 16),
              
              // Precio
              _buildFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Precio',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3E1F08),
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      decoration: InputDecoration(
                        hintText: '0.00',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.attach_money, color: Color(0xFF8B4513)),
                        suffixText: 'MXN',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el precio';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) {
                          return 'Por favor ingresa un precio válido';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              
              // Categorización
              _buildSectionTitle('Categorización'),
              SizedBox(height: 12),
              
              // Categoría
              _buildFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Categoría',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3E1F08),
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCategory,
                          hint: Text('Seleccionar categoría'),
                          isExpanded: true,
                          items: categories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Row(
                                children: [
                                  Icon(_getCategoryIcon(category), 
                                       color: Color(0xFF8B4513), size: 20),
                                  SizedBox(width: 12),
                                  Text(category),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCategory = value;
                            });
                          },
                        ),
                      ),
                    ),
                    if (selectedCategory == null)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Por favor selecciona una categoría',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              SizedBox(height: 16),
              
              // Emoji
              _buildFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ícono del Platillo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3E1F08),
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      height: 120,
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 8,
                          childAspectRatio: 1,
                        ),
                        itemCount: emojis.length,
                        itemBuilder: (context, index) {
                          final emoji = emojis[index];
                          final isSelected = selectedEmoji == emoji;
                          
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedEmoji = emoji;
                              });
                            },
                            child: Container(
                              margin: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: isSelected ? Color(0xFF8B4513) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? Color(0xFF8B4513) : Colors.grey.shade300,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  emoji,
                                  style: TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              
              // Detalles Adicionales
              _buildSectionTitle('Detalles Adicionales'),
              SizedBox(height: 12),
              
              // Descripción
              _buildFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Descripción (Opcional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3E1F08),
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Ingredientes o descripción del platillo...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 16),
              
              // Disponibilidad
              _buildFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Disponibilidad',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3E1F08),
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Switch(
                          value: isAvailable,
                          onChanged: (value) {
                            setState(() {
                              isAvailable = value;
                            });
                          },
                          activeColor: Color(0xFF8B4513),
                        ),
                        SizedBox(width: 12),
                        Text(
                          isAvailable ? 'Disponible' : 'No disponible',
                          style: TextStyle(
                            fontSize: 16,
                            color: isAvailable ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 32),
              
              // Preview Card
              _buildSectionTitle('Vista Previa'),
              SizedBox(height: 12),
              _buildPreviewCard(),
              
              SizedBox(height: 32),
              
              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _clearForm(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Color(0xFF8B4513)),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Limpiar',
                        style: TextStyle(
                          color: Color(0xFF8B4513),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => _saveFood(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF8B4513),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save),
                          SizedBox(width: 8),
                          Text(
                            'Guardar Platillo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF8B4513),
      ),
    );
  }

  Widget _buildFormCard({required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: child,
      ),
    );
  }

  Widget _buildPreviewCard() {
    final name = _nameController.text.isNotEmpty ? _nameController.text : 'Nombre del platillo';
    final price = _priceController.text.isNotEmpty ? double.tryParse(_priceController.text) ?? 0.0 : 0.0;
    
    return Card(
      elevation: 4,
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
                  selectedEmoji,
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
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3E1F08),
                    ),
                  ),
                  SizedBox(height: 4),
                  if (selectedCategory != null)
                    Text(
                      selectedCategory!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  SizedBox(height: 4),
                  Text(
                    '\$${price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B4513),
                    ),
                  ),
                ],
              ),
            ),
            
            // Status indicator
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isAvailable ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isAvailable ? 'Disponible' : 'No disponible',
                style: TextStyle(
                  color: isAvailable ? Colors.green : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Quesadillas':
        return Icons.local_pizza;
      case 'Bebidas':
        return Icons.local_drink;
      case 'Extras':
        return Icons.add_circle;
      case 'Postres':
        return Icons.cake;
      default:
        return Icons.restaurant;
    }
  }

  void _clearForm() {
    setState(() {
      _nameController.clear();
      _priceController.clear();
      _descriptionController.clear();
      selectedCategory = null;
      selectedEmoji = '🍽️';
      isAvailable = true;
    });
  }

  void _saveFood() {
    if (_formKey.currentState!.validate() && selectedCategory != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('¡Éxito!'),
            ],
          ),
          content: Text(
            '${_nameController.text} ha sido agregado al menú de ${selectedCategory}.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _clearForm();
              },
              child: Text('Agregar Otro'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF8B4513),
                foregroundColor: Colors.white,
              ),
              child: Text('Terminar'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor completa todos los campos requeridos'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}