import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

Future<void> showDisciplineReviewsDialog(
  BuildContext context, {
  required String deporteId,
  required String deporteNombre,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _DisciplineReviewsDialog(
      deporteId: deporteId,
      deporteNombre: deporteNombre,
    ),
  );
}

class _DisciplineReviewsDialog extends StatelessWidget {
  final String deporteId;
  final String deporteNombre;
  const _DisciplineReviewsDialog({
    required this.deporteId,
    required this.deporteNombre,
  });

  static const Color navy = Color(0xFF0F2C59);
  static const Color orange = Color(0xFFFF5500);
  static const Color star = Color(0xFFE2B714);

  String _fecha(dynamic ts) {
    if (ts is! Timestamp) return '';
    final d = ts.toDate();
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Widget _stars(num rating, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final IconData icon = rating >= i + 1
            ? Icons.star_rounded
            : (rating >= i + 0.5
                ? Icons.star_half_rounded
                : Icons.star_outline_rounded);
        return Icon(icon, color: star, size: size);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? miUid = FirebaseAuth.instance.currentUser?.uid;
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RESEÑAS',
              style: TextStyle(
                  color: orange,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2)),
          const SizedBox(height: 2),
          Text(deporteNombre,
              style: const TextStyle(
                  color: navy, fontWeight: FontWeight.bold, fontSize: 20)),
        ],
      ),
      content: SizedBox(
        width: 560,
        height: 480,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('reviews')
              .where('deporteId', isEqualTo: deporteId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                  child: Text('No se pudieron cargar las reseñas.'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data!.docs.toList()
              ..sort((a, b) {
                final dataA = a.data() as Map<String, dynamic>?;
                final dataB = b.data() as Map<String, dynamic>?;
                final ta = dataA?['createdAt'];
                final tb = dataB?['createdAt'];
                if (ta is Timestamp && tb is Timestamp) {
                  return tb.compareTo(ta);
                }
                if (ta is Timestamp) return -1;
                if (tb is Timestamp) return 1;
                return 0;
              });

            if (docs.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.rate_review_outlined,
                        size: 44, color: Colors.grey),
                    SizedBox(height: 10),
                    Text('Aún no hay reseñas de esta disciplina.',
                        style: TextStyle(
                            color: navy, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Sé el primero en calificarla después de inscribirte.',
                        style: TextStyle(color: Colors.black54, fontSize: 12)),
                  ],
                ),
              );
            }

            final ratings = docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>?;
              return data?['sportRating'];
            }).whereType<num>().toList();

            final double promedio = ratings.isEmpty
                ? 0
                : ratings.reduce((a, b) => a + b) / ratings.length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    children: [
                      Text(promedio.toStringAsFixed(1),
                          style: const TextStyle(
                              color: navy,
                              fontSize: 30,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _stars(promedio, size: 20),
                          const SizedBox(height: 2),
                          Text(
                              '${docs.length} reseña${docs.length == 1 ? '' : 's'}',
                              style: const TextStyle(
                                  color: Colors.black54, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final d = docs[i].data() as Map<String, dynamic>? ?? {};
                      
                      final String estudianteUid = (d['estudianteUid'] ?? '').toString();
                      final bool esMia = miUid != null && estudianteUid == miUid;

                      // Datos del Deporte
                      final num sportRating = (d['sportRating'] is num) ? d['sportRating'] as num : 5;
                      final String sportComment = (d['sportComment'] ?? '').toString().trim();

                      // Datos del Profesor
                      final num profesorRating = (d['profesorRating'] is num) ? d['profesorRating'] as num : 5;
                      final String profesorComment = (d['profesorComment'] ?? '').toString().trim();
                      final String profesorNombre = (d['profesorNombre'] ?? 'Profesor').toString();

                      // Obtenemos el nombre almacenado o consultamos la colección users si falta
                      String nombreDirecto = (d['estudianteNombre'] ?? 
                                              d['nombreEstudiante'] ?? 
                                              d['nombreUsuario'] ?? '').toString().trim();

                      return FutureBuilder<DocumentSnapshot>(
                        future: nombreDirecto.isNotEmpty || estudianteUid.isEmpty
                            ? Future.value(null)
                            : FirebaseFirestore.instance.collection('users').doc(estudianteUid).get(),
                        builder: (context, userSnap) {
                          String nombreFinal = nombreDirecto;
                          if (nombreFinal.isEmpty && userSnap.hasData && userSnap.data != null && userSnap.data!.exists) {
                            final userData = userSnap.data!.data() as Map<String, dynamic>?;
                            nombreFinal = (userData?['nombreApellido'] ?? 
                                           userData?['nombreCompleto'] ?? 
                                           userData?['nombre'] ?? '').toString().trim();
                          }
                          if (nombreFinal.isEmpty) {
                            nombreFinal = 'Estudiante';
                          }

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: esMia
                                      ? orange.withValues(alpha: 0.6)
                                      : const Color(0xFFCBD5E1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      esMia ? 'Tu reseña ($nombreFinal)' : nombreFinal,
                                      style: TextStyle(
                                        color: esMia ? orange : navy,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(_fecha(d['createdAt']),
                                        style: const TextStyle(
                                            color: Colors.black45, fontSize: 11)),
                                  ],
                                ),
                                const Divider(height: 16, color: Color(0xFFE2E8F0)),

                                // Sección Profesor
                                Row(
                                  children: [
                                    Text('• Profesor ($profesorNombre): ',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: navy)),
                                    _stars(profesorRating, size: 13),
                                  ],
                                ),
                                if (profesorComment.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: Text('"$profesorComment"',
                                        style: const TextStyle(fontSize: 12, color: Colors.black87, fontStyle: FontStyle.italic)),
                                  ),
                                ],

                                const SizedBox(height: 8),

                                // Sección Deporte
                                Row(
                                  children: [
                                    const Text('• Deporte / Instalación: ',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: navy)),
                                    _stars(sportRating, size: 13),
                                  ],
                                ),
                                if (sportComment.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: Text('"$sportComment"',
                                        style: const TextStyle(fontSize: 12, color: Colors.black87, fontStyle: FontStyle.italic)),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}