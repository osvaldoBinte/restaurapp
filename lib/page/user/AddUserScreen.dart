import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:restaurapp/page/user/AddUserController.dart';
// import 'add_user_controller.dart'; // Importar el controller

class AddUserScreen extends StatelessWidget {
  // Inicializar el controller
  final AddUserController controller = Get.put(AddUserController());

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
                  'Crear Nuevo Usuario',
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
          onPressed: () => Get.back(), // ✅ Usando Get.back()
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: controller.formKey, // ✅ Usando controller
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
                      Icon(
                        Icons.person_add,
                        size: 48,
                        color: Colors.white,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Nuevo Usuario',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Completa la información del nuevo empleado',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 24),
              
              // Tipo de Usuario
              _buildSectionTitle('Tipo de Usuario'),
              SizedBox(height: 12),
              _buildUserRoleSelector(),
              
              SizedBox(height: 24),
              
              // Información Personal
              _buildSectionTitle('Información Personal'),
              SizedBox(height: 12),
              
              // Nombre completo
              _buildFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nombre Completo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3E1F08),
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: controller.nameController, // ✅ Usando controller
                      decoration: InputDecoration(
                        hintText: 'Ej: Juan Pérez García',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.person, color: Color(0xFF8B4513)),
                      ),
                      validator: controller.validateName, // ✅ Usando validación del controller
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 16),
              
              // Email y Teléfono
              Row(
                children: [
                  Expanded(
                    child: _buildFormCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3E1F08),
                            ),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: controller.emailController, // ✅ Usando controller
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'email@ejemplo.com',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(Icons.email, color: Color(0xFF8B4513)),
                            ),
                            validator: controller.validateEmail, // ✅ Usando validación del controller
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildFormCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Teléfono',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3E1F08),
                            ),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: controller.phoneController, // ✅ Usando controller
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            decoration: InputDecoration(
                              hintText: '9611234567',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(Icons.phone, color: Color(0xFF8B4513)),
                            ),
                            validator: controller.validatePhone, // ✅ Usando validación del controller
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 24),
              
              // Información de Acceso
              _buildSectionTitle('Información de Acceso'),
              SizedBox(height: 12),
              
              // Nombre de usuario
              _buildFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nombre de Usuario',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3E1F08),
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: controller.usernameController, // ✅ Usando controller
                      decoration: InputDecoration(
                        hintText: 'usuario123',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.account_circle, color: Color(0xFF8B4513)),
                      ),
                      validator: controller.validateUsername, // ✅ Usando validación del controller
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 16),
              
              // Contraseña
              _buildFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contraseña',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3E1F08),
                      ),
                    ),
                    SizedBox(height: 8),
                    Obx(() => TextFormField( // ✅ Usando Obx para reactividad
                      controller: controller.passwordController,
                      obscureText: !controller.showPassword.value,
                      decoration: InputDecoration(
                        hintText: 'Mínimo 6 caracteres',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.lock, color: Color(0xFF8B4513)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.showPassword.value ? Icons.visibility : Icons.visibility_off,
                            color: Color(0xFF8B4513),
                          ),
                          onPressed: controller.toggleShowPassword, // ✅ Usando método del controller
                        ),
                      ),
                      validator: controller.validatePassword,
                    )),
                  ],
                ),
              ),
              
              SizedBox(height: 16),
              
              // Confirmar contraseña
              _buildFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confirmar Contraseña',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3E1F08),
                      ),
                    ),
                    SizedBox(height: 8),
                    Obx(() => TextFormField( // ✅ Usando Obx para reactividad
                      controller: controller.confirmPasswordController,
                      obscureText: !controller.showConfirmPassword.value,
                      decoration: InputDecoration(
                        hintText: 'Confirma la contraseña',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.lock_outline, color: Color(0xFF8B4513)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.showConfirmPassword.value ? Icons.visibility : Icons.visibility_off,
                            color: Color(0xFF8B4513),
                          ),
                          onPressed: controller.toggleShowConfirmPassword, // ✅ Usando método del controller
                        ),
                      ),
                      validator: controller.validateConfirmPassword,
                    )),
                  ],
                ),
              ),
              
              SizedBox(height: 16),
              
              // Estado del usuario
              _buildFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado del Usuario',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3E1F08),
                      ),
                    ),
                    SizedBox(height: 8),
                    Obx(() => Row( // ✅ Usando Obx para reactividad
                      children: [
                        Switch(
                          value: controller.isActive.value,
                          onChanged: controller.toggleActive, // ✅ Usando método del controller
                          activeColor: Color(0xFF8B4513),
                        ),
                        SizedBox(width: 12),
                        Text(
                          controller.isActive.value ? 'Activo' : 'Inactivo',
                          style: TextStyle(
                            fontSize: 16,
                            color: controller.isActive.value ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )),
                  ],
                ),
              ),
              
              SizedBox(height: 32),
              
              // Preview Card
              _buildSectionTitle('Vista Previa del Usuario'),
              SizedBox(height: 12),
              _buildPreviewCard(),
              
              SizedBox(height: 32),
              
              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: controller.clearForm, // ✅ Usando método del controller
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
                    child: Obx(() => ElevatedButton( // ✅ Usando Obx para mostrar loading
                      onPressed: controller.isLoading.value ? null : controller.createUser, // ✅ Usando método del controller
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF8B4513),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: controller.isLoading.value
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_add),
                              SizedBox(width: 8),
                              Text(
                                'Crear Usuario',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                    )),
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

  Widget _buildUserRoleSelector() {
    return Obx(() => Row( // ✅ Usando Obx para reactividad
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => controller.changeUserRole(UserRole.principal), // ✅ Usando método del controller
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: controller.selectedRole.value == UserRole.principal ? Color(0xFF8B4513) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: controller.selectedRole.value == UserRole.principal ? Color(0xFF8B4513) : Colors.grey.shade300,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: 40,
                    color: controller.selectedRole.value == UserRole.principal ? Colors.white : Color(0xFF8B4513),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Usuario Principal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: controller.selectedRole.value == UserRole.principal ? Colors.white : Color(0xFF8B4513),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Administrador\nAcceso completo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: controller.selectedRole.value == UserRole.principal ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () => controller.changeUserRole(UserRole.secondary), // ✅ Usando método del controller
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: controller.selectedRole.value == UserRole.secondary ? Color(0xFF8B4513) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: controller.selectedRole.value == UserRole.secondary ? Color(0xFF8B4513) : Colors.grey.shade300,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.person,
                    size: 40,
                    color: controller.selectedRole.value == UserRole.secondary ? Colors.white : Color(0xFF8B4513),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Usuario Secundario',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: controller.selectedRole.value == UserRole.secondary ? Colors.white : Color(0xFF8B4513),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Empleado\nAcceso limitado',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: controller.selectedRole.value == UserRole.secondary ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ));
  }

  Widget _buildPreviewCard() {
    return Obx(() { // ✅ Usando Obx para reactividad
      final preview = controller.userPreview; // ✅ Usando getter del controller
      
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
              // Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: controller.selectedRole.value == UserRole.principal ? Color(0xFF8B4513) : Colors.grey,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  controller.selectedRole.value == UserRole.principal ? Icons.admin_panel_settings : Icons.person,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              SizedBox(width: 16),
              
              // User details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preview['name']!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E1F08),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '@${preview['username']!}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8B4513),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      preview['email']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Role and status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: controller.selectedRole.value == UserRole.principal ? 
                             Color(0xFF8B4513).withOpacity(0.1) : 
                             Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      preview['role']!,
                      style: TextStyle(
                        color: controller.selectedRole.value == UserRole.principal ? Color(0xFF8B4513) : Colors.grey[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: controller.isActive.value ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      preview['status']!,
                      style: TextStyle(
                        color: controller.isActive.value ? Colors.green : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}