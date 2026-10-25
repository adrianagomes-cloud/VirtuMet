import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_dashboard_page.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  static const Color orangePrimary = Color(0xFFFF5500);
  static const Color blueDark = Color(0xFF0F2C59);
  static const Color bgLight = Color(0xFFF4F6F9);

  final User? _currentUser = FirebaseAuth.instance.currentUser;

  late TextEditingController _nombreCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _carreraCtrl;
  late TextEditingController _carnetCtrl;
  late TextEditingController _biografiaCtrl;
  late TextEditingController _correoCtrl;

  bool _isInitialized = false;
  bool _isSaving = false;
  String _fotoUrl = '';

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController();
    _telefonoCtrl = TextEditingController();
    _carreraCtrl = TextEditingController();
    _carnetCtrl = TextEditingController();
    _biografiaCtrl = TextEditingController();
    _correoCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _carreraCtrl.dispose();
    _carnetCtrl.dispose();
    _biografiaCtrl.dispose();
    _correoCtrl.dispose();
    super.dispose();
  }

  // ===========================================================================
  // MODAL PARA CAMBIAR FOTO DE PERFIL DE ESTUDIANTE
  // ===========================================================================
  void _showChangeProfilePictureDialog(BuildContext context, String currentUrl) {
    final urlCtrl = TextEditingController(text: currentUrl);
    String selectedAvatar = currentUrl;

    final List<Map<String, String>> sampleAvatars = [
      {
        'label': 'Fútbol',
        'url':
            'https://images.unsplash.com/photo-1614632537197-38a17061c2bd?auto=format&fit=crop&w=300&q=80',
      },
      {
        'label': 'Baloncesto',
        'url':
            'https://images.unsplash.com/photo-1519861531473-9200262188bf?auto=format&fit=crop&w=300&q=80',
      },
      {
        'label': 'Voleibol',
        'url':
            'https://images.unsplash.com/photo-1612872087720-bb876e2e67d1?auto=format&fit=crop&w=300&q=80',
      },
      {
        'label': 'Tenis',
        'url':
            'https://images.unsplash.com/photo-1595435934249-5df7ed86e1c0?auto=format&fit=crop&w=300&q=80',
      },
      {
        'label': 'Estudiante 1',
        'url':
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80',
      },
      {
        'label': 'Estudiante 2',
        'url':
            'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=300&q=80',
      },
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.add_a_photo_outlined, color: blueDark),
                  SizedBox(width: 10),
                  Text(
                    'Cambiar foto de perfil',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: blueDark,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Ingresa la URL de una imagen:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: blueDark),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: urlCtrl,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'https://...',
                          filled: true,
                          fillColor: const Color(0xFFF8F9FA),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedAvatar = val.trim();
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'O selecciona un avatar de muestra:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: blueDark),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: sampleAvatars.map((item) {
                          final String url = item['url']!;
                          final bool isSelected = selectedAvatar == url;

                          return InkWell(
                            onTap: () {
                              setDialogState(() {
                                selectedAvatar = url;
                                urlCtrl.text = url;
                              });
                            },
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? orangePrimary
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 26,
                                backgroundColor: blueDark,
                                backgroundImage: NetworkImage(url),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar',
                      style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orangePrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final String finalUrl = urlCtrl.text.trim().isEmpty
                        ? selectedAvatar
                        : urlCtrl.text.trim();

                    setState(() => _fotoUrl = finalUrl);

                    final uid = _currentUser?.uid;
                    if (uid != null && uid.isNotEmpty) {
                      try {
                        await _currentUser?.updatePhotoURL(finalUrl);
                      } catch (_) {}

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .set({
                        'fotoUrl': finalUrl,
                        'photoUrl': finalUrl,
                        'actualizadoEn': FieldValue.serverTimestamp(),
                      }, SetOptions(merge: true));
                    }

                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Aplicar Foto',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // GUARDAR DATOS VINCULADOS ÚNICAMENTE AL UID DEL ESTUDIANTE
  // ===========================================================================
  Future<void> _saveProfileData() async {
    final uid = _currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final String nuevoNombre = _nombreCtrl.text.trim();
      final String correoEstudiante = _currentUser?.email ?? '';

      try {
        await _currentUser?.updateDisplayName(nuevoNombre);
        if (_fotoUrl.isNotEmpty) {
          await _currentUser?.updatePhotoURL(_fotoUrl);
        }
      } catch (_) {}

      final Map<String, dynamic> updateData = {
        'nombre': nuevoNombre,
        'nombreApellido': nuevoNombre,
        'nombreCompleto': nuevoNombre,
        'telefono': _telefonoCtrl.text.trim(),
        'carrera': _carreraCtrl.text.trim(),
        'carnet': _carnetCtrl.text.trim(),
        'biografia': _biografiaCtrl.text.trim(),
        'correo': correoEstudiante,
        'email': correoEstudiante,
        'rol': 'Estudiante',
        'actualizadoEn': FieldValue.serverTimestamp(),
      };

      if (_fotoUrl.isNotEmpty) {
        updateData['fotoUrl'] = _fotoUrl;
        updateData['photoUrl'] = _fotoUrl;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(updateData, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Perfil de estudiante actualizado con éxito!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al guardar datos: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String uid = _currentUser?.uid ?? '';
    final String authEmail = _currentUser?.email ?? '';

    return StreamBuilder<DocumentSnapshot>(
      // LECTURA DIRECTA POR EL UID DEL ESTUDIANTE CONECTADO
      stream: uid.isNotEmpty
          ? FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .snapshots()
          : const Stream.empty(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !_isInitialized) {
          return const Scaffold(
            backgroundColor: bgLight,
            body: Center(
                child: CircularProgressIndicator(color: orangePrimary)),
          );
        }

        final Map<String, dynamic> data =
            (snapshot.hasData && snapshot.data!.data() != null)
                ? (snapshot.data!.data() as Map<String, dynamic>)
                : {};

        final String nombreRegistrado = (data['nombreApellido'] ??
                data['nombreCompleto'] ??
                data['nombre'] ??
                _currentUser?.displayName ??
                'Estudiante UNIMET')
            .toString()
            .trim();

        if (!_isInitialized) {
          _nombreCtrl.text = nombreRegistrado;
          _correoCtrl.text = authEmail;
          _telefonoCtrl.text = (data['telefono'] ?? '').toString();
          _carreraCtrl.text =
              (data['carrera'] ?? 'Ingeniería de Sistemas · UNIMET').toString();
          _carnetCtrl.text = (data['carnet'] ?? '').toString();
          _biografiaCtrl.text = (data['biografia'] ?? '').toString();
          _fotoUrl = (data['fotoUrl'] ??
                  data['photoUrl'] ??
                  _currentUser?.photoURL ??
                  'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=500&q=80')
              .toString();
          _isInitialized = true;
        }

        return Scaffold(
          backgroundColor: bgLight,
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blueDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StudentDashboardPage(),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text(
                    'Volver al Dashboard',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TARJETA DE AVATAR LATERAL
                    Container(
                      width: 300,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFFCBD5E1), width: 1.2),
                      ),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 65,
                                backgroundColor: blueDark,
                                backgroundImage: NetworkImage(_fotoUrl),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: orangePrimary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt,
                                    color: Colors.white, size: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _nombreCtrl.text.isNotEmpty
                                ? _nombreCtrl.text
                                : nombreRegistrado,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: blueDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _carreraCtrl.text.isNotEmpty
                                ? _carreraCtrl.text
                                : 'Ingeniería de Sistemas · UNIMET',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.green.withValues(alpha: 0.5)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle,
                                    color: Colors.green, size: 14),
                                SizedBox(width: 6),
                                Text(
                                  'Atleta Activo',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            onPressed: () => _showChangeProfilePictureDialog(
                                context, _fotoUrl),
                            icon: const Icon(Icons.upload,
                                size: 16, color: blueDark),
                            label: const Text(
                              'Cambiar foto',
                              style: TextStyle(
                                  color: blueDark,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 30),

                    // FORMULARIO DE DATOS
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFFCBD5E1), width: 1.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: blueDark.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.person_outline,
                                      color: blueDark),
                                ),
                                const SizedBox(width: 12),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Perfil de Estudiante / Atleta',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: blueDark,
                                      ),
                                    ),
                                    Text(
                                      'Información académica y datos institucionales en VirtuMet.',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 30),

                            Row(
                              children: [
                                Expanded(
                                  child: _buildFormField(
                                    label: 'Nombre completo *',
                                    controller: _nombreCtrl,
                                    hint: 'Nombre y Apellido',
                                    onChanged: (val) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildFormField(
                                    label: 'Correo Institucional *',
                                    controller: _correoCtrl,
                                    hint: 'estudiante@correo.unimet.edu.ve',
                                    readOnly: true,
                                    helper:
                                        'Email verificado del estudiante registrado.',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            Row(
                              children: [
                                Expanded(
                                  child: _buildFormField(
                                    label: 'Teléfono *',
                                    controller: _telefonoCtrl,
                                    hint: '+58 412 000 0000',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildFormField(
                                    label: 'Carnet UNIMET / Cédula',
                                    controller: _carnetCtrl,
                                    hint: '2024000001',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            _buildFormField(
                              label: 'Carrera / Escuela',
                              controller: _carreraCtrl,
                              hint: 'Ingeniería de Sistemas',
                              onChanged: (val) => setState(() {}),
                            ),
                            const SizedBox(height: 16),

                            _buildFormField(
                              label: 'Biografía Deportiva / Intereses',
                              controller: _biografiaCtrl,
                              hint:
                                  'Escribe aquí tu experiencia deportiva o intereses...',
                              maxLines: 3,
                            ),
                            const SizedBox(height: 24),

                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: orangePrimary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: _isSaving ? null : _saveProfileData,
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.save, size: 18),
                                label: Text(
                                  _isSaving
                                      ? 'Guardando...'
                                      : 'Guardar Cambios',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool readOnly = false,
    String? helper,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: blueDark,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: readOnly,
          maxLines: maxLines,
          onChanged: onChanged,
          style: TextStyle(
            fontSize: 13,
            color: readOnly ? Colors.black54 : blueDark,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
            filled: true,
            fillColor: readOnly
                ? const Color(0xFFF1F5F9)
                : const Color(0xFFF8F9FA),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 4),
          Text(
            helper,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ],
    );
  }
}