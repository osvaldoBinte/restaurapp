import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool isEditing = false;
  bool notificationsEnabled = true;
  bool soundEnabled = true;
  bool darkModeEnabled = false;
  
  // Controllers para los campos editables
  final _nameController = TextEditingController(text: 'María García López');
  final _emailController = TextEditingController(text: 'maria.garcia@eljobo.com');
  final _phoneController = TextEditingController(text: '9611234567');
  final _usernameController = TextEditingController(text: 'maria_garcia');
  
  // Datos del usuario (simulados)
  final String userRole = 'Usuario Principal';
  final String joinDate = '15 de Enero, 2024';
  final String shift = 'Matutino (6:00 AM - 2:00 PM)';
  final int ordersProcessed = 247;
  final double averageRating = 4.8;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F2F0),
      body: CustomScrollView(
        slivers: [
          // App Bar con imagen de perfil
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            backgroundColor: Color(0xFF8B4513),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF8B4513), Color(0xFF7A3E11)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 60),
                    // Avatar del usuario
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 58,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    // Información básica
                    Text(
                      _nameController.text,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        userRole,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isEditing ? Icons.save : Icons.edit,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    isEditing = !isEditing;
                  });
                  if (!isEditing) {
                    _saveProfile();
                  }
                },
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  switch (value) {
                    case 'logout':
                      _showLogoutDialog();
                      break;
                    case 'delete':
                      _showDeleteAccountDialog();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Cerrar Sesión'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Eliminar Cuenta'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Contenido del perfil
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Estadísticas rápidas
                 // _buildStatsSection(),
                  
                  SizedBox(height: 24),
                  
                  // Información Personal
                  _buildPersonalInfoSection(),
                  
                
                  SizedBox(height: 24),
                  
                  
                  // Seguridad
                  _buildSecuritySection(),
                  
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estadísticas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B4513),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Órdenes\nProcesadas',
                    ordersProcessed.toString(),
                    Icons.restaurant_menu,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 16),
                
                Expanded(
                  child: _buildStatCard(
                    'Días\nActivo',
                    '156',
                    Icons.calendar_today,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return _buildSection(
      title: 'Información Personal',
      icon: Icons.person,
      children: [
        _buildEditableField(
          'Nombre Completo',
          _nameController,
          Icons.person_outline,
        ),
        SizedBox(height: 16),
        _buildEditableField(
          'Email',
          _emailController,
          Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: 16),
        _buildEditableField(
          'Teléfono',
          _phoneController,
          Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: 16),
        _buildEditableField(
          'Nombre de Usuario',
          _usernameController,
          Icons.account_circle_outlined,
        ),
      ],
    );
  }



  Widget _buildSecuritySection() {
    return _buildSection(
      title: 'Opciones',
      icon: Icons.security,
      children: [
        ListTile(
          leading: Icon(Icons.lock_outline, color: Color(0xFF8B4513)),
          title: Text('Cambiar Contraseña'),
          subtitle: Text('Última modificación: hace 30 días'),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showChangePasswordDialog(),
        ),
        Divider(),
        ListTile(
          leading: Icon(Icons.privacy_tip, color: Color(0xFF8B4513)),
          title: Text('Avisos de privacidad'),
          subtitle: Text('Ver los avisos de privacidad'),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showSessionHistory(),
        ),
        Divider(),
        ListTile(
          leading: Icon(Icons.logout, color: Color(0xFF8B4513)),
          title: Text('cerrar sesion'),
          subtitle: Text('cerrar sesion'),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _showBiometricSettings(),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Color(0xFF8B4513)),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B4513),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3E1F08),
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: isEditing,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Color(0xFF8B4513)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isEditing ? Color(0xFF8B4513) : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF8B4513)),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            fillColor: isEditing ? Colors.white : Colors.grey.shade50,
            filled: true,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF8B4513), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF3E1F08),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    IconData icon,
    Function(bool) onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: Color(0xFF8B4513)),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Color(0xFF8B4513),
      ),
    );
  }

  void _saveProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Perfil actualizado correctamente'),
        backgroundColor: Color(0xFF8B4513),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cambiar Contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Contraseña actual',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Nueva contraseña',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirmar nueva contraseña',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Contraseña actualizada')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF8B4513)),
            child: Text('Actualizar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSessionHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Historial de Sesiones'),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.phone_android, color: Colors.green),
                title: Text('Dispositivo Actual'),
                subtitle: Text('Android • Ahora'),
              ),
              ListTile(
                leading: Icon(Icons.laptop, color: Colors.blue),
                title: Text('Computadora Web'),
                subtitle: Text('Chrome • hace 2 horas'),
              ),
              ListTile(
                leading: Icon(Icons.tablet, color: Colors.orange),
                title: Text('Tablet'),
                subtitle: Text('Safari • hace 1 día'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showBiometricSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Autenticación Biométrica'),
        content: Text('¿Deseas activar la autenticación con huella dactilar para acceder más rápido?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Ahora no'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Autenticación biométrica activada')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF8B4513)),
            child: Text('Activar', style: TextStyle(color: Colors.white)),
          ),
        ],
      )
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cerrar Sesión'),
        content: Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Aquí iría la lógica de logout
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Cuenta'),
        content: Text('Esta acción es irreversible. ¿Estás seguro de que quieres eliminar tu cuenta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Aquí iría la lógica de eliminación
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}