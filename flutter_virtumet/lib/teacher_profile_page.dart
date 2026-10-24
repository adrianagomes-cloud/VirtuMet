import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'teacher_dashboard_page.dart';

class TeacherProfilePage extends StatefulWidget {
  const TeacherProfilePage({super.key});

  @override
  State<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage> {
  static const Color orangePrimary = Color(0xFFFF5500);
  static const Color blueDark = Color(0xFF0F2C59);
  static const Color bgLight = Color(0xFFF4F6F9);

  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // Controladores de texto
  late TextEditingController _nombreCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _especialidadCtrl;
  late TextEditingController _ubicacionCtrl;
  late TextEditingController _biografiaCtrl;

  bool _isInitialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController();
    _telefonoCtrl = TextEditingController();
    _especialidadCtrl = TextEditingController();
    _ubicacionCtrl = TextEditingController();
    _biografiaCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _especialidadCtrl.dispose();
    _ubicacionCtrl.dispose();
    _biografiaCtrl.dispose();
    super.dispose();
  }

  // ===========================================================================
  // MODAL PARA CAMBIAR FOTO (AVATARES DE DEPORTES Y ENTRENADORES)
  // ===========================================================================
  void _showChangeProfilePictureDialog(
      BuildContext context, String currentUrl, String docId) {
    final urlCtrl = TextEditingController(text: currentUrl);
    String selectedAvatar = currentUrl;

    final List<Map<String, String>> sampleAvatars = [
      // Pelotas y deportes
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
        'label': 'Fitness',
        'url':
            'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?auto=format&fit=crop&w=300&q=80',
      },
      {
        'label': 'Atletismo',
        'url':
            'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?auto=format&fit=crop&w=300&q=80',
      },
      // Personas y entrenadores
      {
        'label': 'Entrenadora 1',
        'url':
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80',
      },
      {
        'label': 'Entrenador 1',
        'url':
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=300&q=80',
      },
      {
        'label': 'Entrenador 2',
        'url':
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=300&q=80',
      },
      {
        'label': 'Entrenadora 2',
        'url':
            'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=300&q=80',
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
                          enabledBorder: OutlineInputBorder(
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  onPressed: () async {
                    final String finalUrl = urlCtrl.text.trim().isEmpty
                        ? selectedAvatar
                        : urlCtrl.text.trim();

                    if (docId.isNotEmpty && docId != 'temp_id') {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(docId)
                          .update({'fotoUrl': finalUrl, 'photoUrl': finalUrl});
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
  // GUARDAR CAMBIOS EN FIRESTORE
  // ===========================================================================
  Future<void> _saveProfileData(String docId) async {
    setState(() => _isSaving = true);
    try {
      final String nuevoNombre = _nombreCtrl.text.trim();

      if (docId.isNotEmpty && docId != 'temp_id') {
        await FirebaseFirestore.instance.collection('users').doc(docId).update({
          'nombre': nuevoNombre,
          'nombreApellido': nuevoNombre,
          'nombreCompleto': nuevoNombre,
          'telefono': _telefonoCtrl.text.trim(),
          'especialidad': _especialidadCtrl.text.trim(),
          'ubicacion': _ubicacionCtrl.text.trim(),
          'biografia': _biografiaCtrl.text.trim(),
          'actualizadoEn': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Información de perfil actualizada exitosamente!'),
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
    final String userEmail =
        _currentUser?.email ?? 'entrenador@unimet.edu.ve';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !_isInitialized) {
          return const Scaffold(
            backgroundColor: bgLight,
            body: Center(
                child: CircularProgressIndicator(color: orangePrimary)),
          );
        }

        DocumentSnapshot? userDoc;
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final docs = snapshot.data!.docs;
          final matches = docs.where((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final String docEmail =
                (d['correo'] ?? d['email'] ?? '').toString().toLowerCase();
            return doc.id == _currentUser?.uid ||
                docEmail == userEmail.toLowerCase();
          });

          userDoc = matches.isNotEmpty ? matches.first : docs.first;
        }

        final Map<String, dynamic> data =
            userDoc != null ? (userDoc.data() as Map<String, dynamic>) : {};

        final String nombreRegistrado = (data['nombreApellido'] ??
                data['nombreCompleto'] ??
                data['nombre'] ??
                _currentUser?.displayName ??
                '')
            .toString()
            .trim();

        final String fotoUrl = (data['fotoUrl'] ??
                data['photoUrl'] ??
                'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=500&q=80')
            .toString();

        final String especialidad = (data['especialidad'] ??
                data['disciplinas'] ??
                'Fútbol Sala y Baloncesto')
            .toString();

        final String docId = userDoc?.id ?? _currentUser?.uid ?? 'temp_id';

        if (!_isInitialized) {
          _nombreCtrl.text = nombreRegistrado;
          _telefonoCtrl.text =
              (data['telefono'] ?? '+58 412 000 0000').toString();
          _especialidadCtrl.text = especialidad;
          _ubicacionCtrl.text =
              (data['ubicacion'] ?? 'Campus Principal · UNIMET').toString();
          _biografiaCtrl.text = (data['biografia'] ??
                  'Entrenador con más de 8 años de experiencia impulsando el alto rendimiento deportivo universitario.')
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
                // =============================================================
                // BOTÓN: VOLVER AL DASHBOARD DE MAESTRO
                // =============================================================
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blueDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 1,
                  ),
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TeacherDashboardPage(),
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

                // ESTRUCTURA PRINCIPAL DE LA PÁGINA
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // COLUMNA IZQUIERDA: TARJETA DE PERFIL Y AVATAR
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
                                backgroundImage: NetworkImage(fotoUrl),
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
                            nombreRegistrado.isNotEmpty
                                ? nombreRegistrado
                                : 'Entrenador UNIMET',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: blueDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            especialidad,
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
                                  'Entrenador activo',
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
                                context, fotoUrl, docId),
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

                    // COLUMNA DERECHA: FORMULARIO CON NOMBRE REGISTRADO
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
                                      'Información personal',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: blueDark,
                                      ),
                                    ),
                                    Text(
                                      'Datos de contacto y perfil profesional en VirtuMet.',
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
                                    hint: 'ingresa tu nombre y apellido',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildFormField(
                                    label: 'Correo electrónico *',
                                    controller:
                                        TextEditingController(text: userEmail),
                                    hint: 'admin@correo.unimet.ve',
                                    readOnly: true,
                                    helper:
                                        'Usaremos este correo para notificaciones institucionales.',
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
                                    label: 'Especialidad / Disciplinas',
                                    controller: _especialidadCtrl,
                                    hint: 'Fútbol Sala y Baloncesto',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            _buildFormField(
                              label: 'Ubicación / Campus',
                              controller: _ubicacionCtrl,
                              hint: 'Campus Principal · UNIMET',
                              helper:
                                  'Lugar habitual donde diriges los entrenamientos.',
                            ),
                            const SizedBox(height: 16),

                            _buildFormField(
                              label: 'Biografía / Experiencia',
                              controller: _biografiaCtrl,
                              hint: 'Escribe tu experiencia deportiva...',
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
                                onPressed: _isSaving
                                    ? null
                                    : () => _saveProfileData(docId),
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