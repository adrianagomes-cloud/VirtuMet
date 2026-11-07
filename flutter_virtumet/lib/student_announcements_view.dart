import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentAnnouncementsView extends StatelessWidget {
  const StudentAnnouncementsView({super.key});

  static const navy = Color(0xFF0F2C59);
  static const orange = Color(0xFFFF5500);

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
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('avisos')
                .where('estado', isEqualTo: 'Activo')
                .orderBy('creadoEn', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error al cargar avisos: ${snapshot.error}');
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Card(
                    child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Text('No hay avisos publicados.')));
              }
              return Column(
                children: docs.map((document) {
                  final data = document.data() as Map<String, dynamic>;
                  final priority = (data['prioridad'] ?? 'Normal').toString();
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(
                        priority == 'Urgente'
                            ? Icons.warning_rounded
                            : Icons.campaign_outlined,
                        color: priority == 'Urgente' ? Colors.red : orange,
                      ),
                      title: Text((data['titulo'] ?? 'Aviso').toString(),
                          style: const TextStyle(
                              color: navy, fontWeight: FontWeight.bold)),
                      subtitle: Text((data['mensaje'] ?? '').toString()),
                      isThreeLine: true,
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
