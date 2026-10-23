import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'login_page.dart';
import 'teacher_dashboard_page.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // Colores corporativos VirtuMet
  static const Color orangePrimary = Color(0xFFFF5500);
  static const Color blueDark = Color(0xFF0F2C59);
  static const Color navyHeader = Color(0xFF0A192F);
  static const Color bgLight = Color(0xFFF4F6F9);

  // Controladores de formulario
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _especialidadController = TextEditingController();
  final TextEditingController _ubicacionController = TextEditingController();
  final TextEditingController _biografiaController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  String _photoUrl = '';
  String _cedula = 'V-00000000';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_currentUser == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _nombreController.text = data['nombreApellido'] ?? data['nombre'] ?? '';
          _emailController.text = data['email'] ?? _currentUser.email ?? '';
          _telefonoController.text = data['telefono'] ?? '';
          _especialidadController.text =
              data['especialidad'] ?? 'Fútbol Sala y Baloncesto';
          _ubicacionController.text =
              data['ubicacion'] ?? 'Campus Principal · UNIMET';
          _biografiaController.text = data['biografia'] ??
              'Entrenador con más de 8 años de experiencia impulsando el alto rendimiento deportivo universitario.';
          _photoUrl = data['photoUrl'] ?? '';
          _cedula = data['cedula'] ?? 'V-20123456';
          _isLoading = false;
        });
      } else {
        setState(() {
          _emailController.text = _currentUser.email ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // FUNCIÓN PARA SELECCIONAR IMAGEN DESDE LA COMPUTADORA
  Future<void> _pickImageFromComputer() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) return; // El usuario canceló la selección

      setState(() => _isUploadingImage = true);

      final bytes = await pickedFile.readAsBytes();
      final String fileName =
          'profile_${_currentUser?.uid ?? "user"}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Subir archivo a Firebase Storage
      final storageRef =
          FirebaseStorage.instance.ref().child('profiles/$fileName');
      final uploadTask = await storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final String downloadUrl = await uploadTask.ref.getDownloadURL();

      // Guardar URL en Firestore y actualizar vista
      setState(() {
        _photoUrl = downloadUrl;
        _isUploadingImage = false;
      });

      if (_currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser.uid)
            .set({'photoUrl': downloadUrl}, SetOptions(merge: true));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Foto subida y actualizada con éxito desde tu equipo!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al subir la imagen: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // DIÁLOGO Y OPCIONES PARA CAMBIAR LA FOTO DE PERFIL
  Future<void> _changeProfilePhoto() async {
    final TextEditingController urlController =
        TextEditingController(text: _photoUrl);

    final List<String> avatarPresets = [
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500&auto=format&fit=crop&q=80',
      'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=500&auto=format&fit=crop&q=80',
    ];

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          title: const Row(
            children: [
              Icon(Icons.add_a_photo_outlined, color: blueDark),
              SizedBox(width: 10),
              Text(
                'Cambiar foto de perfil',
                style: TextStyle(
                  color: blueDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BOTÓN SELECCIONAR DESDE COMPUTADORA
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blueDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _pickImageFromComputer();
                    },
                    icon: const Icon(Icons.computer_rounded, size: 20),
                    label: const Text(
                      'Subir desde mi Computadora',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('O',
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),

                const Text(
                  'Ingresa la URL de una imagen:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: blueDark,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: urlController,
                  style: const TextStyle(fontSize: 13, color: blueDark),
                  decoration: InputDecoration(
                    hintText: 'https://ejemplo.com/mi-foto.jpg',
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFFF8F9FA),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: orangePrimary, width: 1.5),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'O selecciona un avatar de muestra:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: blueDark,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: avatarPresets.map((presetUrl) {
                    return InkWell(
                      onTap: () {
                        urlController.text = presetUrl;
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: orangePrimary, width: 2),
                          image: DecorationImage(
                            image: NetworkImage(presetUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: orangePrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                final newUrl = urlController.text.trim();
                setState(() {
                  _photoUrl = newUrl;
                });

                if (_currentUser != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(_currentUser.uid)
                      .set({'photoUrl': newUrl}, SetOptions(merge: true));
                }

                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Foto de perfil actualizada correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Aplicar Foto',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveProfileData() async {
    if (_currentUser == null) return;

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .set({
        'nombreApellido': _nombreController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'especialidad': _especialidadController.text.trim(),
        'ubicacion': _ubicacionController.text.trim(),
        'biografia': _biografiaController.text.trim(),
        'photoUrl': _photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Perfil de Entrenador actualizado exitosamente!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar datos: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _navigateToDashboard() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TeacherDashboardPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: bgLight,
        body: Center(
          child: CircularProgressIndicator(color: orangePrimary),
        ),
      );
    }

    final String nombreHeader = _nombreController.text.isEmpty
        ? 'Entrenador'
        : _nombreController.text;

    return Scaffold(
      backgroundColor: bgLight,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTopNavbar(context, nombreHeader),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: _navigateToDashboard,
                    icon: const Icon(Icons.arrow_back, size: 16, color: blueDark),
                    label: const Text(
                      'VOLVER AL DASHBOARD',
                      style: TextStyle(
                        color: blueDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Tu información, siempre al día',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: blueDark,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Actualiza tus datos personales, especialidad deportiva y contacto. Los campos con * son obligatorios.',
                            style: TextStyle(fontSize: 13, color: Colors.black54),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orangePrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 1,
                        ),
                        onPressed: _isSaving ? null : _saveProfileData,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined, size: 20),
                        label: const Text(
                          'Guardar Cambios',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final bool isDesktop = constraints.maxWidth > 900;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: isDesktop ? 1 : 1,
                            child: _buildAvatarCard(),
                          ),
                          if (isDesktop) const SizedBox(width: 28),
                          if (isDesktop)
                            Expanded(
                              flex: 2,
                              child: _buildFormCard(),
                            ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  if (MediaQuery.of(context).size.width <= 900) ...[
                    _buildFormCard(),
                  ],
                ],
              ),
            ),

            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // BARRA SUPERIOR (NAVBAR)
  // ===========================================================================
  Widget _buildTopNavbar(BuildContext context, String nombre) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
      color: Colors.white,
      child: Row(
        children: [
          Image.asset(
            'lib/assets/Logo.png',
            height: 58,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: blueDark,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.fitness_center,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 8),
                const Text(
                  'VirtuMet',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: blueDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
          _navLink('Mis Disciplinas', onTap: _navigateToDashboard),
          _navLink('Nómina y Asistencia', onTap: _navigateToDashboard),
          _navLink('Anuncios'),
          _navLink('Comunidad'),
          const Spacer(),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: blueDark.withValues(alpha: 0.08),
                  border: Border.all(
                    color: orangePrimary.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  image: _photoUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(_photoUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _photoUrl.isEmpty
                    ? const Icon(Icons.person_outline, size: 18, color: blueDark)
                    : null,
              ),
              const SizedBox(width: 10),
              Text(
                nombre,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: blueDark, fontSize: 13),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.grey),
                onPressed: _handleLogout,
                tooltip: 'Cerrar Sesión',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navLink(String title, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: InkWell(
        onTap: onTap,
        child: Text(
          title,
          style: const TextStyle(
            color: blueDark,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TARJETA DE AVATAR CON INDICADOR DE CARGA
  // ===========================================================================
  Widget _buildAvatarCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: orangePrimary, width: 3),
                  image: _photoUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(_photoUrl), fit: BoxFit.cover)
                      : null,
                  color: blueDark.withValues(alpha: 0.08),
                ),
                child: _isUploadingImage
                    ? const Center(
                        child: CircularProgressIndicator(color: orangePrimary),
                      )
                    : (_photoUrl.isEmpty
                        ? const Icon(Icons.person_rounded,
                            size: 70, color: blueDark)
                        : null),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: InkWell(
                  onTap: _changeProfilePhoto,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: orangePrimary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _nombreController.text.isEmpty
                ? 'Entrenador UNIMET'
                : _nombreController.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: blueDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _especialidadController.text.isEmpty
                ? 'Entrenador de Deportes'
                : _especialidadController.text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.check_circle_rounded, size: 14, color: Colors.green),
                SizedBox(width: 6),
                Text(
                  'Entrenador activo',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: blueDark,
              side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _changeProfilePhoto,
            icon: const Icon(Icons.upload_outlined, size: 18),
            label: const Text('Cambiar foto',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),

          const SizedBox(height: 12),
          const Text(
            'JPG o PNG · máximo 5 MB\nRecomendado: 800 × 800 px',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Colors.grey, height: 1.3),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'IDENTIFICADOR INSTITUCIONAL',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 0.5),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _cedula,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold, color: blueDark),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // FORMULARIO DE INFORMACIÓN PERSONAL
  // ===========================================================================
  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: blueDark.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_outline,
                    color: blueDark, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Información personal',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: blueDark,
                    ),
                  ),
                  Text(
                    'Datos de contacto y perfil profesional en VirtuMet.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  label: 'Nombre completo *',
                  controller: _nombreController,
                  hint: 'Ingresa tu nombre y apellido',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInputField(
                  label: 'Correo electrónico *',
                  controller: _emailController,
                  hint: 'entrenador@unimet.edu.ve',
                  readOnly: true,
                  helperText:
                      'Usaremos este correo para notificaciones institucionales.',
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  label: 'Teléfono *',
                  controller: _telefonoController,
                  hint: '+58 412 000 0000',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInputField(
                  label: 'Especialidad / Disciplinas',
                  controller: _especialidadController,
                  hint: 'Ej: Fútbol Sala Varonil / Baloncesto',
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _buildInputField(
            label: 'Ubicación / Campus',
            controller: _ubicacionController,
            hint: 'Ej: Campus Principal · UNIMET',
            helperText: 'Lugar habitual donde diriges los entrenamientos.',
          ),

          const SizedBox(height: 20),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Biografía / Experiencia',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: blueDark,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _biografiaController,
                maxLines: 4,
                style: const TextStyle(fontSize: 13, color: blueDark),
                decoration: InputDecoration(
                  hintText:
                      'Escribe un resumen sobre tu trayectoria deportiva...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFFF8F9FA),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: orangePrimary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Máximo 280 caracteres · visible en la ficha de entrenador.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool readOnly = false,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: blueDark,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          style: TextStyle(
            fontSize: 13,
            color: readOnly ? Colors.grey.shade700 : blueDark,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
            filled: true,
            fillColor:
                readOnly ? const Color(0xFFF1F5F9) : const Color(0xFFF8F9FA),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: orangePrimary, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // PIE DE PÁGINA
  // ===========================================================================
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 50),
      color: navyHeader,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      'lib/assets/Logo.png',
                      height: 45,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Text(
                        'VIRTUMET',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Plataforma digital para la gestión y promoción del deporte universitario en la Universidad Metropolitana.',
                      style: TextStyle(
                          color: Colors.white60, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ASISTENCIA',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _footerLinkItem('Soporte'),
                        _footerLinkItem('Preguntas Frecuentes'),
                        _footerLinkItem('Contacto'),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),
            ],
          ),
          const SizedBox(height: 30),
          const Divider(color: Colors.white12),
          const SizedBox(height: 16),
          const Text(
            '© 2026 VirtuMet UNIMET. Todos los derechos reservados.',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _footerLinkItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {},
        child: Text(
          text,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ),
    );
  }
}