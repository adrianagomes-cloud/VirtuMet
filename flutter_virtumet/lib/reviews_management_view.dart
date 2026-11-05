import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 1. FORMULARIO PARA QUE EL ESTUDIANTE CALIFIQUE AL PROFESOR Y AL DEPORTE
class EnviarResenaPage extends StatefulWidget {
  final String deporteId;
  final String deporteNombre;
  final String profesorUid;
  final String profesorNombre;

  const EnviarResenaPage({
    super.key,
    required this.deporteId,
    required this.deporteNombre,
    required this.profesorUid,
    required this.profesorNombre,
  });

  @override
  State<EnviarResenaPage> createState() => _EnviarResenaPageState();
}

class _EnviarResenaPageState extends State<EnviarResenaPage> {
  static const Color orangePrimary = Color(0xFFFF5500);
  static const Color blueDark = Color(0xFF0F2C59);

  int _estrellasDeporte = 5;
  int _estrellasProfesor = 5;
  final _comentarioDeporteCtrl = TextEditingController();
  final _comentarioProfesorCtrl = TextEditingController();
  bool _isSending = false;

  Future<void> _enviarResena() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSending = true);

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      final nombreEstudiante = userData?['nombreApellido'] ?? userData?['nombre'] ?? 'Estudiante';

      await FirebaseFirestore.instance.collection('reseñas').add({
        'estudianteId': user.uid,
        'estudianteNombre': nombreEstudiante,
        'deporteId': widget.deporteId,
        'deporteNombre': widget.deporteNombre,
        'profesorUid': widget.profesorUid,
        'profesorNombre': widget.profesorNombre,
        'calificacionDeporte': _estrellasDeporte,
        'comentarioDeporte': _comentarioDeporteCtrl.text.trim(),
        'calificacionProfesor': _estrellasProfesor,
        'comentarioProfesor': _comentarioProfesorCtrl.text.trim(),
        'creadoEn': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Reseña enviada con éxito!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar reseña: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Widget _buildStarSelector(int currentVal, Function(int) onSelected) {
    return Row(
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < currentVal ? Icons.star : Icons.star_border,
            color: Colors.amber,
          ),
          onPressed: () => onSelected(index + 1),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calificar ${widget.deporteNombre}', style: const TextStyle(color: blueDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: blueDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Calificación del Profesor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: blueDark)),
            Text('Profesor asignado: ${widget.profesorNombre}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            _buildStarSelector(_estrellasProfesor, (val) => setState(() => _estrellasProfesor = val)),
            TextField(
              controller: _comentarioProfesorCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Comentario sobre el desempeño del profesor...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Calificación de la Disciplina / Deporte', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: blueDark)),
            Text('Disciplina: ${widget.deporteNombre}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            _buildStarSelector(_estrellasDeporte, (val) => setState(() => _estrellasDeporte = val)),
            TextField(
              controller: _comentarioDeporteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Comentario sobre las instalaciones o dinámica del deporte...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: orangePrimary, foregroundColor: Colors.white),
                onPressed: _isSending ? null : _enviarResena,
                child: _isSending 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('Enviar Reseñas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 2. VISTA PARA QUE EL PROFESOR VEA LAS RESEÑAS DE SUS CLASES CON COMENTARIOS
class TeacherReviewsView extends StatelessWidget {
  final String profesorUid;

  const TeacherReviewsView({super.key, required this.profesorUid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reseñas y Calificaciones Recibidas', style: TextStyle(color: Color(0xFF0F2C59), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF0F2C59)),
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFF4F6F9),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reseñas')
            .where('profesorUid', isEqualTo: profesorUid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('Aún no tienes reseñas registradas por los estudiantes.', style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String comentarioProfesor = (data['comentarioProfesor'] ?? '').toString().trim();
              final String comentarioDeporte = (data['comentarioDeporte'] ?? '').toString().trim();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Disciplina: ${data['deporteNombre']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F2C59))),
                      Text('Estudiante: ${data['estudianteNombre']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const Divider(height: 20),
                      Text('• Profesor: ⭐ ${data['calificacionProfesor']}/5', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F2C59))),
                      const SizedBox(height: 2),
                      Text(
                        comentarioProfesor.isNotEmpty ? '  "$comentarioProfesor"' : '  (Sin comentario para el profesor)',
                        style: TextStyle(fontStyle: FontStyle.italic, color: comentarioProfesor.isNotEmpty ? Colors.black87 : Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Text('• Deporte: ⭐ ${data['calificacionDeporte']}/5', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F2C59))),
                      const SizedBox(height: 2),
                      Text(
                        comentarioDeporte.isNotEmpty ? '  "$comentarioDeporte"' : '  (Sin comentario para el deporte)',
                        style: TextStyle(fontStyle: FontStyle.italic, color: comentarioDeporte.isNotEmpty ? Colors.black87 : Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// 3. VISTA PARA QUE EL ADMINISTRADOR VEA LOS COMENTARIOS Y ELIMINE RESEÑAS
class AdminReviewsView extends StatelessWidget {
  const AdminReviewsView({super.key});

  void _eliminarResena(BuildContext context, String docId) async {
    await FirebaseFirestore.instance.collection('reseñas').doc(docId).delete();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reseña eliminada con éxito')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Administración de Reseñas', style: TextStyle(color: Color(0xFF0F2C59), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF0F2C59)),
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('reseñas').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text('No hay reseñas registradas en la plataforma.', style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;

              final String comentarioProfesor = (data['comentarioProfesor'] ?? '').toString().trim();
              final String comentarioDeporte = (data['comentarioDeporte'] ?? '').toString().trim();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${data['deporteNombre']} (Profe: ${data['profesorNombre']})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F2C59)),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _eliminarResena(context, docId),
                            tooltip: 'Eliminar reseña',
                          ),
                        ],
                      ),
                      Text('Estudiante: ${data['estudianteNombre']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const Divider(height: 20),
                      Text('• Profesor: ⭐ ${data['calificacionProfesor']}/5', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F2C59))),
                      const SizedBox(height: 2),
                      Text(
                        comentarioProfesor.isNotEmpty ? '  "$comentarioProfesor"' : '  (Sin comentario)',
                        style: TextStyle(fontStyle: FontStyle.italic, color: comentarioProfesor.isNotEmpty ? Colors.black87 : Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Text('• Deporte: ⭐ ${data['calificacionDeporte']}/5', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F2C59))),
                      const SizedBox(height: 2),
                      Text(
                        comentarioDeporte.isNotEmpty ? '  "$comentarioDeporte"' : '  (Sin comentario)',
                        style: TextStyle(fontStyle: FontStyle.italic, color: comentarioDeporte.isNotEmpty ? Colors.black87 : Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}