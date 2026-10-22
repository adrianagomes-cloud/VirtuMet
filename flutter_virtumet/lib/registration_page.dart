import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'student_dashboard_page.dart';
import 'teacher_dashboard_page.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  String _selectedRole = 'Estudiante'; // 'Estudiante' o 'Entrenador'
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Controladores - Estudiante
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _edadController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _carnetController = TextEditingController();
  final TextEditingController _carreraController = TextEditingController();
  final TextEditingController _fechaNacimientoController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Controladores - Entrenador
  final TextEditingController _nombreCoachController = TextEditingController();
  final TextEditingController _disciplinaController = TextEditingController();
  final TextEditingController _certificacionController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _edadController.dispose();
    _pesoController.dispose();
    _carnetController.dispose();
    _carreraController.dispose();
    _fechaNacimientoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nombreCoachController.dispose();
    _disciplinaController.dispose();
    _certificacionController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos obligatorios (*).'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    try {
      // 1. Crear usuario en Firebase Auth
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String uid = userCredential.user!.uid;

      // 2. Preparar los datos según el rol
      final Map<String, dynamic> userData = {
        'uid': uid,
        'rol': _selectedRole,
        'correo': email,
        'fechaCreacion': FieldValue.serverTimestamp(),
      };

      if (_selectedRole == 'Estudiante') {
        userData.addAll({
          'nombre': _nombreController.text.trim(),
          'apellido': _apellidoController.text.trim(),
          'edad': int.tryParse(_edadController.text.trim()) ?? 0,
          'peso': double.tryParse(_pesoController.text.trim()) ?? 0.0,
          'carnet': _carnetController.text.trim(),
          'carrera': _carreraController.text.trim(),
          'fechaNacimiento': _fechaNacimientoController.text.trim(),
        });
      } else {
        userData.addAll({
          'nombreApellido': _nombreCoachController.text.trim(),
          'disciplinaExperiencia': _disciplinaController.text.trim(),
          'certificacion': _certificacionController.text.trim(),
          'estadoValidacion': 'Pendiente',
        });
      }

      // 3. Guardar en Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set(userData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Cuenta creada con éxito en VirtuMet!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // 4. Redirigir al panel correspondiente según el rol
      if (_selectedRole == 'Estudiante') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const StudentDashboardPage()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const TeacherDashboardPage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Error al registrar el usuario.';
      if (e.code == 'email-already-in-use') {
        mensaje = 'El correo ya está registrado en la plataforma.';
      } else if (e.code == 'weak-password') {
        mensaje = 'La contraseña debe tener al menos 6 caracteres.';
      } else if (e.code == 'invalid-email') {
        mensaje = 'El formato del correo institucional no es válido.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      body: Stack(
        children: [
          // 1. ESTRUCTURA PRINCIPAL DE LA PÁGINA
          SafeArea(
            child: Row(
              children: [
                if (isDesktop)
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 60, vertical: 50),
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(
                            'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?auto=format&fit=crop&w=1600&q=80',
                          ),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Color(0xEB0A192F),
                            BlendMode.darken,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 48),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5500),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Text(
                              'ÚNETE A LA ÉLITE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          const Spacer(),
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                              children: [
                                TextSpan(
                                  text: 'TU CAMINO AL\n',
                                  style: TextStyle(color: Colors.white),
                                ),
                                TextSpan(
                                  text: 'ÉXITO DEPORTIVO\n',
                                  style: TextStyle(color: Color(0xFFFF5500)),
                                ),
                                TextSpan(
                                  text: 'COMIENZA AQUÍ.',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          const SizedBox(
                            width: 480,
                            child: Text(
                              'Regístrate para acceder al catálogo completo de disciplinas, torneos inter-facultades y seguimiento de tus créditos deportivos.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 36),
                          _buildFeatureItem(
                              'ACCESO A INSTALACIONES DE PRIMER NIVEL'),
                          const SizedBox(height: 14),
                          _buildFeatureItem(
                              'INSCRIPCIÓN SIMPLIFICADA A DISCIPLINAS'),
                          const SizedBox(height: 14),
                          _buildFeatureItem(
                              'GESTIÓN DE FICHA MÉDICA DIGITAL'),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),

                // Formulario de Registro
                Expanded(
                  flex: 1,
                  child: Container(
                    color: const Color(0xFFF8F9FA),
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 520),
                          padding: const EdgeInsets.all(36),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: ChoiceChip(
                                        label: const Center(
                                            child: Text('ESTUDIANTE')),
                                        selected: _selectedRole == 'Estudiante',
                                        selectedColor: const Color(0xFFFF5500),
                                        labelStyle: TextStyle(
                                          color: _selectedRole == 'Estudiante'
                                              ? Colors.white
                                              : Colors.black87,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        onSelected: (selected) {
                                          if (selected) {
                                            setState(() =>
                                                _selectedRole = 'Estudiante');
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ChoiceChip(
                                        label: const Center(
                                            child: Text('ENTRENADOR')),
                                        selected: _selectedRole == 'Entrenador',
                                        selectedColor: const Color(0xFFFF5500),
                                        labelStyle: TextStyle(
                                          color: _selectedRole == 'Entrenador'
                                              ? Colors.white
                                              : Colors.black87,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        onSelected: (selected) {
                                          if (selected) {
                                            setState(() =>
                                                _selectedRole = 'Entrenador');
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                Text(
                                  _selectedRole == 'Estudiante'
                                      ? 'REGISTRO DE ESTUDIANTE'
                                      : 'REGISTRO DE ENTRENADOR',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F2C59),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _selectedRole == 'Estudiante'
                                      ? 'Completa tus datos para crear tu perfil de atleta universitario.'
                                      : 'Completa tus datos para crear tu perfil de entrenador institucional.',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 13),
                                ),
                                const SizedBox(height: 24),

                                if (_selectedRole == 'Estudiante') ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          label: 'NOMBRE',
                                          hint: 'juan',
                                          controller: _nombreController,
                                          icon: Icons.person_outline,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildTextField(
                                          label: 'APELLIDO',
                                          hint: 'perez',
                                          controller: _apellidoController,
                                          icon: Icons.person_outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          label: 'EDAD *',
                                          hint: '20',
                                          controller: _edadController,
                                          icon: Icons.calendar_today_outlined,
                                          keyboardType: TextInputType.number,
                                          validator: (v) => v == null || v.isEmpty
                                              ? 'Requerido'
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildTextField(
                                          label: 'PESO (KG) *',
                                          hint: '72.5',
                                          controller: _pesoController,
                                          icon: Icons.monitor_weight_outlined,
                                          keyboardType: TextInputType.number,
                                          validator: (v) => v == null || v.isEmpty
                                              ? 'Requerido'
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    label: 'NÚMERO DE CARNET',
                                    hint: '2024111001',
                                    controller: _carnetController,
                                    icon: Icons.badge_outlined,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    label: 'CARRERA UNIVERSITARIA',
                                    hint: 'Ingenieria de sistemas',
                                    controller: _carreraController,
                                    icon: Icons.school_outlined,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    label: 'FECHA DE NACIMIENTO',
                                    hint: '15/05/2004',
                                    controller: _fechaNacimientoController,
                                    icon: Icons.event_outlined,
                                  ),
                                ] else ...[
                                  _buildTextField(
                                    label: 'NOMBRE Y APELLIDO *',
                                    hint: 'Carlos Rivas',
                                    controller: _nombreCoachController,
                                    icon: Icons.person_outline,
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Requerido'
                                        : null,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    label: 'DISCIPLINA Y EXPERIENCIA *',
                                    hint: 'Fútbol Sala - 8 años',
                                    controller: _disciplinaController,
                                    icon: Icons.sports_soccer_outlined,
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Requerido'
                                        : null,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    label: 'CERTIFICACIÓN *',
                                    hint: 'Licencia CONMEBOL B',
                                    controller: _certificacionController,
                                    icon: Icons.verified_outlined,
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Requerido'
                                        : null,
                                  ),
                                ],

                                const SizedBox(height: 16),
                                _buildTextField(
                                  label: 'CORREO INSTITUCIONAL *',
                                  hint: 'juan.perez@correo.unimet.ve',
                                  controller: _emailController,
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Ingresa tu correo';
                                    }
                                    if (!v.contains('@')) {
                                      return 'Correo no válido';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  label: 'CONTRASEÑA *',
                                  hint: '••••••••',
                                  controller: _passwordController,
                                  icon: Icons.lock_outline,
                                  obscureText: _obscurePassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() =>
                                          _obscurePassword = !_obscurePassword);
                                    },
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Ingresa una contraseña';
                                    }
                                    if (v.length < 6) {
                                      return 'Mínimo 6 caracteres';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 28),

                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF5500),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed:
                                        _isLoading ? null : _handleRegister,
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'CREAR CUENTA',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.8,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(Icons.arrow_forward,
                                                  size: 18),
                                            ],
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        '¿Ya tienes cuenta? ',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const LoginPage(),
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          'Inicia sesión aquí',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFFF5500),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. BOTÓN FLOTANTE "VOLVER AL INICIO"
          Positioned(
            top: 24,
            left: 24,
            child: SafeArea(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacementNamed(context, '/');
                    }
                  },
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'VOLVER AL INICIO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F2C59),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF3F5F8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: Icon(icon, color: Colors.grey, size: 20),
            suffixIcon: suffixIcon,
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildFeatureItem(String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFFF5500).withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            color: Color(0xFFFF5500),
            size: 14,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}