import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherReviewsView extends StatefulWidget {
  const TeacherReviewsView({super.key});

  @override
  State<TeacherReviewsView> createState() => _TeacherReviewsViewState();
}

class _TeacherReviewsViewState extends State<TeacherReviewsView> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  String _searchQuery = '';

  static const Color orangePrimary = Color(0xFFFF5500);
  static const Color blueDark = Color(0xFF0F2C59);
  static const Color bgLight = Color(0xFFF4F6F9);

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Sesión no iniciada.')),
      );
    }

    final String userId = _currentUser!.uid;

    return Scaffold(
      backgroundColor: bgLight,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Barra superior con botón de retroceso para evitar que te quedes atrapado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: blueDark),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Volver',
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Panel de Reseñas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: blueDark,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabecera idéntica a la vista de estudiante
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Text(
                                'Mis Reseñas y Calificaciones',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: blueDark,
                                ),
                              ),
                              SizedBox(width: 12),
                              Chip(
                                label: Text(
                                  'EN VIVO',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                                backgroundColor: Colors.green,
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Sincronización en tiempo real de las opiniones publicadas para tus deportes.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
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
                            hintText: 'Buscar por deporte o profesor...',
                            hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                            prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
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
                  const SizedBox(height: 24),

                  // StreamBuilder filtrado estrictamente por el profesor logueado
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('reviews')
                        .where('profesorUid', isEqualTo: userId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child: Center(
                            child: CircularProgressIndicator(color: orangePrimary),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Error al cargar las reseñas: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];

                      // Filtrado local según la barra de búsqueda
                      final filteredDocs = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final deporte = (data['deporteNombre'] ?? '').toString().toLowerCase();
                        final profesor = (data['profesorNombre'] ?? '').toString().toLowerCase();
                        final comProf = (data['profesorComment'] ?? '').toString().toLowerCase();
                        final comSport = (data['sportComment'] ?? '').toString().toLowerCase();
                        return deporte.contains(_searchQuery) ||
                               profesor.contains(_searchQuery) ||
                               comProf.contains(_searchQuery) ||
                               comSport.contains(_searchQuery);
                      }).toList();

                      if (filteredDocs.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.rate_review_outlined, size: 40, color: Colors.grey),
                              SizedBox(height: 10),
                              Text(
                                'Aún no tienes reseñas registradas',
                                style: TextStyle(
                                  color: blueDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Las valoraciones enviadas por los estudiantes aparecerán aquí.',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final data = filteredDocs[index].data() as Map<String, dynamic>;
                          final String deporteNombre = data['deporteNombre'] ?? 'Disciplina';
                          final String profesorNombre = data['profesorNombre'] ?? 'Profesor';
                          final int profesorRating = data['profesorRating'] ?? 5;
                          final String profesorComment = data['profesorComment'] ?? '';
                          final int sportRating = data['sportRating'] ?? 5;
                          final String sportComment = data['sportComment'] ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Disciplina: $deporteNombre',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: blueDark,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                                ),
                                // Sección Profesor
                                Text(
                                  '• Profesor ($profesorNombre): ⭐ $profesorRating/5',
                                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                                ),
                                if (profesorComment.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: Text(
                                      '"$profesorComment"',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 14),
                                // Sección Deporte / Instalación
                                Text(
                                  '• Deporte / Instalación: ⭐ $sportRating/5',
                                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                                ),
                                if (sportComment.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: Text(
                                      '"$sportComment"',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}