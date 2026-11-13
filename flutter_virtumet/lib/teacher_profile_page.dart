import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
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

  late TextEditingController _nombreCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _especialidadCtrl;
  late TextEditingController _ubicacionCtrl;
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
    _especialidadCtrl = TextEditingController();
    _ubicacionCtrl = TextEditingController();
    _biografiaCtrl = TextEditingController();
    _correoCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _especialidadCtrl.dispose();
    _ubicacionCtrl.dispose();
    _biografiaCtrl.dispose();
    _correoCtrl.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'ENT';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  ImageProvider? _getProfileImageProvider(String url) {
    if (url.trim().isEmpty) return null;
    if (url.startsWith('data:image')) {
      try {
        final base64Str = url.split(',').last;
        final Uint8List bytes = base64Decode(base64Str);
        return MemoryImage(bytes);
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(url);
  }

  Future<String> _uploadProfileBytes(
      String uid, Uint8List bytes, String? fileName) async {
    try {
      final path =
          'perfiles/${uid}_${DateTime.now().millisecondsSinceEpoch}_${fileName ?? 'perfil.jpg'}';
      final ref = FirebaseStorage.instance.ref().child(path);
      final uploadTask = await ref
          .putData(
            bytes,
            SettableMetadata(contentType: 'image/jpeg'),
          )
          .timeout(const Duration(seconds: 8));
      return await uploadTask.ref.getDownloadURL();
    } catch (_) {
      if (bytes.lengthInBytes > 750 * 1024) {
        throw Exception(
            'La imagen pesa más de 750 KB. Elige una foto más ligera o usa un enlace URL.');
      }
      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    }
  }

  // ===========================================================================
  // MODAL PARA CAMBIAR FOTO DE PERFIL (DESDE COMPUTADORA O ENLACE URL)
  // ===========================================================================
  void _showChangeProfilePictureDialog(
      BuildContext context, String currentUrl) {
    final urlCtrl = TextEditingController(
      text: currentUrl.startsWith('data:image') ? '' : currentUrl,
    );
    final ImagePicker picker = ImagePicker();

    Uint8List? pickedBytes;
    String? pickedFileName;
    bool useUrlMode = false;
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickFromComputer() async {
              try {
                final XFile? file = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 800,
                  maxHeight: 800,
                  imageQuality: 80,
                );
                if (file == null) return;
                final bytes = await file.readAsBytes();
                setDialogState(() {
                  pickedBytes = bytes;
                  pickedFileName = file.name;
                  useUrlMode = false;
                });
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('No se pudo seleccionar la imagen: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.add_a_photo_outlined, color: blueDark),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Cambiar foto de perfil',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: blueDark,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: isUploading ? null : () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            useUrlMode
                                ? 'Enlace URL de imagen'
                                : 'Subir foto desde mi computadora',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: blueDark,
                            ),
                          ),
                          TextButton(
                            onPressed: isUploading
                                ? null
                                : () {
                                    setDialogState(() {
                                      useUrlMode = !useUrlMode;
                                    });
                                  },
                            child: Text(
                              useUrlMode
                                  ? 'Subir archivo desde dispositivo'
                                  : 'Usar enlace URL de imagen',
                              style: const TextStyle(
                                fontSize: 12,
                                color: orangePrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (!useUrlMode)
                        InkWell(
                          onTap: isUploading ? null : pickFromComputer,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            height: 210,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                                width: 1.5,
                              ),
                            ),
                            child: pickedBytes != null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 62,
                                        backgroundColor: blueDark,
                                        backgroundImage:
                                            MemoryImage(pickedBytes!),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 5),
                                        decoration: BoxDecoration(
                                          color:
                                              blueDark.withValues(alpha: 0.08),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: const Text(
                                          'Haz clic para elegir otra foto',
                                          style: TextStyle(
                                            color: blueDark,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.cloud_upload_outlined,
                                          size: 42, color: orangePrimary),
                                      SizedBox(height: 10),
                                      Text(
                                        'Haz clic para seleccionar una foto de perfil',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: blueDark,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Formatos JPG o PNG desde tu computadora o galería',
                                        style: TextStyle(
                                            fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: urlCtrl,
                              style: const TextStyle(fontSize: 12),
                              decoration: InputDecoration(
                                hintText: 'https://ejemplo.com/mi-foto.jpg',
                                filled: true,
                                fillColor: const Color(0xFFF8F9FA),
                                prefixIcon: const Icon(Icons.link,
                                    color: Colors.grey, size: 18),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFCBD5E1)),
                                ),
                              ),
                              onChanged: (_) => setDialogState(() {}),
                            ),
                            if (urlCtrl.text.trim().isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Center(
                                child: CircleAvatar(
                                  radius: 52,
                                  backgroundColor: blueDark,
                                  backgroundImage:
                                      NetworkImage(urlCtrl.text.trim()),
                                ),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUploading ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancelar',
                      style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orangePrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isUploading
                      ? null
                      : () async {
                          final uid = _currentUser?.uid ?? '';
                          if (uid.isEmpty) return;

                          if (!useUrlMode && pickedBytes == null) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Selecciona una foto desde tu computadora.'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          if (useUrlMode && urlCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text('Ingresa un enlace URL válido.'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isUploading = true);

                          try {
                            final String finalUrl = !useUrlMode
                                ? await _uploadProfileBytes(
                                    uid, pickedBytes!, pickedFileName)
                                : urlCtrl.text.trim();

                            setState(() => _fotoUrl = finalUrl);

                            if (!finalUrl.startsWith('data:image')) {
                              try {
                                await _currentUser?.updatePhotoURL(finalUrl);
                              } catch (_) {}
                            }

                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .set({
                              'fotoUrl': finalUrl,
                              'photoUrl': finalUrl,
                              'actualizadoEn': FieldValue.serverTimestamp(),
                            }, SetOptions(merge: true));

                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      '¡Foto de perfil actualizada con éxito!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isUploading = false);
                            if (mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: Text('Error al subir la foto: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  icon: isUploading
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check, size: 16),
                  label: Text(
                    isUploading ? 'Guardando...' : 'Aplicar Foto',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // GUARDAR DATOS VINCULADOS ÚNICAMENTE AL UID DEL ENTRENADOR
  // ===========================================================================
  Future<void> _saveProfileData() async {
    final uid = _currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final String nuevoNombre = _nombreCtrl.text.trim();
      final String correoEntrenador = _currentUser?.email ?? '';

      try {
        await _currentUser?.updateDisplayName(nuevoNombre);
        if (_fotoUrl.isNotEmpty && !_fotoUrl.startsWith('data:image')) {
          await _currentUser?.updatePhotoURL(_fotoUrl);
        }
      } catch (_) {}

      final Map<String, dynamic> updateData = {
        'nombre': nuevoNombre,
        'nombreApellido': nuevoNombre,
        'nombreCompleto': nuevoNombre,
        'telefono': _telefonoCtrl.text.trim(),
        'especialidad': _especialidadCtrl.text.trim(),
        'ubicacion': _ubicacionCtrl.text.trim(),
        'biografia': _biografiaCtrl.text.trim(),
        'correo': correoEntrenador,
        'email': correoEntrenador,
        'rol': 'Entrenador',
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
            content: Text('¡Perfil de entrenador actualizado con éxito!'),
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
                'Entrenador UNIMET')
            .toString()
            .trim();

        if (!_isInitialized) {
          _nombreCtrl.text = nombreRegistrado;
          _correoCtrl.text = authEmail;
          _telefonoCtrl.text = (data['telefono'] ?? '').toString();
          _especialidadCtrl.text =
              (data['especialidad'] ?? 'Fútbol Sala y Baloncesto').toString();
          _ubicacionCtrl.text =
              (data['ubicacion'] ?? 'Campus Principal · UNIMET').toString();
          _biografiaCtrl.text = (data['biografia'] ?? '').toString();
          _fotoUrl = (data['fotoUrl'] ??
                  data['photoUrl'] ??
                  _currentUser?.photoURL ??
                  '')
              .toString()
              .trim();
          _isInitialized = true;
        }

        final ImageProvider? avatarImage = _getProfileImageProvider(_fotoUrl);
        final String displayNombre = _nombreCtrl.text.isNotEmpty
            ? _nombreCtrl.text
            : nombreRegistrado;

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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TARJETA DE FOTO DE PERFIL LATERAL
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
                          InkWell(
                            onTap: () => _showChangeProfilePictureDialog(
                                context, _fotoUrl),
                            borderRadius: BorderRadius.circular(70),
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 65,
                                  backgroundColor:
                                      orangePrimary.withValues(alpha: 0.16),
                                  backgroundImage: avatarImage,
                                  child: avatarImage == null
                                      ? Text(
                                          _getInitials(displayNombre),
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: orangePrimary,
                                          ),
                                        )
                                      : null,
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
                          ),
                          const SizedBox(height: 16),
                          Text(
                            displayNombre,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: blueDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _especialidadCtrl.text.isNotEmpty
                                ? _especialidadCtrl.text
                                : 'Fútbol Sala y Baloncesto',
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
                                  'Entrenador Activo',
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
                                      'Perfil de Entrenador',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: blueDark,
                                      ),
                                    ),
                                    Text(
                                      'Datos institucionales y de contacto en VirtuMet.',
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
                                    label: 'Correo Electrónico *',
                                    controller: _correoCtrl,
                                    hint: 'entrenador@correo.unimet.edu.ve',
                                    readOnly: true,
                                    helper:
                                        'Email verificado del entrenador registrado.',
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
                                    label: 'Especialidad / Disciplina',
                                    controller: _especialidadCtrl,
                                    hint: 'Fútbol Sala',
                                    onChanged: (val) => setState(() {}),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              label: 'Ubicación / Campus',
                              controller: _ubicacionCtrl,
                              hint: 'Campus Principal · UNIMET',
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              label: 'Biografía / Experiencia',
                              controller: _biografiaCtrl,
                              hint: 'Escribe tu experiencia profesional...',
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