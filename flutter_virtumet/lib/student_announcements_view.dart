import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'aviso_audiencia.dart';

/// Pestaña "Avisos": muestra solo los avisos que el administrador dejó en
/// estado "Activo" (colección `avisos`) y que van dirigidos a [audiencia]
/// ('Estudiantes' por defecto; el panel del entrenador usa 'Entrenadores').
/// Los avisos dirigidos a 'Todos' los ven ambos.
class StudentAnnouncementsView extends StatelessWidget {
  final String audiencia;
  const StudentAnnouncementsView({super.key, this.audiencia = 'Estudiantes'});

  static const navy = Color(0xFF0F2C59);
  static const orange = Color(0xFFFF5500);

  String _fecha(dynamic ts) {
    if (ts is! Timestamp) return '';
    final d = ts.toDate();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AVISOS',
              style: TextStyle(
                  color: orange,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2)),
          const SizedBox(height: 4),
          const Text('Comunicados de la administración',
              style: TextStyle(
                  color: navy, fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            // Un solo filtro: no requiere índice compuesto en Firestore
            stream: FirebaseFirestore.instance
                .collection('avisos')
                .where('estado', isEqualTo: 'Activo')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error al cargar avisos: ${snapshot.error}');
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              // Más recientes primero
              final docs = snapshot.data!.docs
                  .where((d) => avisoDirigidoA(d.data(), audiencia))
                  .toList()
                ..sort((a, b) {
                  final ta = a.data()['creadoEn'];
                  final tb = b.data()['creadoEn'];
                  if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
                  if (ta is Timestamp) return -1;
                  if (tb is Timestamp) return 1;
                  return 0;
                });
              if (docs.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: Text('No hay avisos publicados por ahora.'),
                  ),
                );
              }
              return Column(
                children: docs.map((doc) {
                  final data = doc.data();
                  final prioridad = (data['prioridad'] ?? 'Normal').toString();
                  final color = prioridad == 'Urgente'
                      ? Colors.red
                      : (prioridad == 'Importante' ? orange : navy);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            prioridad == 'Urgente'
                                ? Icons.warning_rounded
                                : Icons.campaign_outlined,
                            color: color,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        (data['titulo'] ?? 'Aviso').toString(),
                                        style: const TextStyle(
                                            color: navy,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                    ),
                                    if (prioridad != 'Normal') ...[
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(prioridad,
                                            style: TextStyle(
                                                color: color,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text((data['mensaje'] ?? '').toString()),
                                if (_fecha(data['creadoEn']).isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(_fecha(data['creadoEn']),
                                      style: const TextStyle(
                                          color: Colors.black45, fontSize: 12)),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
