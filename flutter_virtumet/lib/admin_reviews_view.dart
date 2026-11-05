import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminReviewsView extends StatefulWidget {
  const AdminReviewsView({super.key});

  static const Color orangePrimary = Color(0xFFFF5500);
  static const Color blueDark = Color(0xFF0F2C59);
  static const Color bgLight = Color(0xFFF4F6F9);

  @override
  State<AdminReviewsView> createState() => _AdminReviewsViewState();
}

class _AdminReviewsViewState extends State<AdminReviewsView> {
  String _searchQuery = '';

  Future<void> _deleteReview(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Reseña'),
        content: const Text(
            '¿Estás seguro de que deseas eliminar esta reseña de la plataforma?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('resenas')
          .doc(docId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reseña eliminada con éxito.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AdminReviewsView.bgLight,
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ENCABEZADO Y BUSCADOR
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Moderación de Reseñas',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AdminReviewsView.blueDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.circle, color: Colors.green, size: 8),
                            SizedBox(width: 6),
                            Text(
                              'EN VIVO',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sincronización en tiempo real de las opiniones publicadas por los estudiantes.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
              SizedBox(
                width: 280,
                height: 40,
                child: TextField(
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.toLowerCase().trim();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar por deporte o estudiante...',
                    hintStyle:
                        const TextStyle(fontSize: 12, color: Colors.grey),
                    prefixIcon:
                        const Icon(Icons.search, size: 18, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // STREAMBUILDER EN TIEMPO REAL
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('resenas')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 50),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AdminReviewsView.orangePrimary,
                    ),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.rate_review_outlined,
                          size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'No hay reseñas registradas actualmente.',
                        style: TextStyle(
                          color: AdminReviewsView.blueDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Cualquier nueva reseña que envíe un alumno aparecerá aquí en tiempo real.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }

              // FILTRADO LOCAL EN TIEMPO REAL
              final filteredDocs = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final disciplina = (data['deporte'] ??
                        data['disciplina'] ??
                        data['deporteNombre'] ??
                        '')
                    .toString()
                    .toLowerCase();
                final estudiante = (data['estudiante'] ??
                        data['estudianteNombre'] ??
                        data['nombreEstudiante'] ??
                        '')
                    .toString()
                    .toLowerCase();

                return disciplina.contains(_searchQuery) ||
                    estudiante.contains(_searchQuery);
              }).toList();

              if (filteredDocs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'No se encontraron reseñas con ese criterio de búsqueda.',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mostrando ${filteredDocs.length} ${filteredDocs.length == 1 ? 'reseña' : 'reseñas'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredDocs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      final String disciplina = (data['deporte'] ??
                              data['disciplina'] ??
                              data['deporteNombre'] ??
                              'Sin disciplina')
                          .toString();

                      final String estudiante = (data['estudiante'] ??
                              data['estudianteNombre'] ??
                              data['nombreEstudiante'] ??
                              'Estudiante')
                          .toString();

                      final String ratingProfesor = (data['ratingProfesor'] ??
                              data['calificacionProfesor'] ??
                              '5')
                          .toString();

                      final String comentarioProfesor =
                          (data['comentarioProfesor'] ??
                                  data['resenaProfesor'] ??
                                  '')
                              .toString();

                      final String ratingDeporte = (data['ratingDeporte'] ??
                              data['calificacionDeporte'] ??
                              '5')
                          .toString();

                      final String comentarioDeporte =
                          (data['comentarioDeporte'] ??
                                  data['resenaDeporte'] ??
                                  '')
                              .toString();

                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7F4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFFFE0D6),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Disciplina: $disciplina',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AdminReviewsView.blueDark,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Estudiante: $estudiante',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.redAccent, size: 22),
                                  tooltip: 'Eliminar reseña',
                                  onPressed: () => _deleteReview(doc.id),
                                ),
                              ],
                            ),
                            const Divider(
                                height: 20, color: Color(0xFFFFE0D6)),

                            // SECCIÓN EVALUACIÓN AL PROFESOR
                            Row(
                              children: [
                                const Text(
                                  '• Profesor: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AdminReviewsView.blueDark,
                                  ),
                                ),
                                const Icon(Icons.star,
                                    color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '$ratingProfesor/5',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AdminReviewsView.blueDark,
                                  ),
                                ),
                              ],
                            ),
                            if (comentarioProfesor.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 12, top: 4, bottom: 8),
                                child: Text(
                                  '"$comentarioProfesor"',
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 6),

                            // SECCIÓN EVALUACIÓN AL DEPORTE
                            Row(
                              children: [
                                const Text(
                                  '• Deporte: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AdminReviewsView.blueDark,
                                  ),
                                ),
                                const Icon(Icons.star,
                                    color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '$ratingDeporte/5',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AdminReviewsView.blueDark,
                                  ),
                                ),
                              ],
                            ),
                            if (comentarioDeporte.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 12, top: 4),
                                child: Text(
                                  '"$comentarioDeporte"',
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}