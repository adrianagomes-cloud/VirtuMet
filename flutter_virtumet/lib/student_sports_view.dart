import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentSportsView extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const StudentSportsView({super.key, this.onBackToHome});

  @override
  State<StudentSportsView> createState() => _StudentSportsViewState();
}

class _StudentSportsViewState extends State<StudentSportsView> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  String _searchQuery = '';
  String _selectedCategory = 'Todas las disciplinas';

  final List<String> _categories = [
    'Todas las disciplinas',
    'De equipo',
    'Individuales',
    'Bienestar',
  ];

  static const Color blueDark = Color(0xFF0F2C59);
  static const Color orangePrimary = Color(0xFFFF5500);

  IconData _getSportIcon(String nombre) {
    final lower = nombre.toLowerCase();
    if (lower.contains('fútbol') || lower.contains('futbol')) {
      return Icons.sports_soccer;
    } else if (lower.contains('baloncesto') || lower.contains('basket')) {
      return Icons.sports_basketball;
    } else if (lower.contains('voleibol') || lower.contains('voley')) {
      return Icons.sports_volleyball;
    } else if (lower.contains('natación') || lower.contains('natacion')) {
      return Icons.pool;
    } else if (lower.contains('tenis')) {
      return Icons.sports_tennis;
    }
    return Icons.fitness_center;
  }

  @override
  Widget build(BuildContext context) {
    final String userEmail = _currentUser?.email ?? '';

    return StreamBuilder<QuerySnapshot>(
      // Resolución en tiempo real del usuario
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, userSnapshot) {
        String nombreEstudiante = 'Estudiante UNIMET';

        if (userSnapshot.hasData && userSnapshot.data!.docs.isNotEmpty) {
          final matches = userSnapshot.data!.docs.where((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final String docEmail =
                (d['correo'] ?? d['email'] ?? '').toString().toLowerCase();
            return doc.id == _currentUser?.uid ||
                docEmail == userEmail.toLowerCase();
          });

          if (matches.isNotEmpty) {
            final data = matches.first.data() as Map<String, dynamic>;
            nombreEstudiante = (data['nombreApellido'] ??
                    data['nombreCompleto'] ??
                    data['nombre'] ??
                    _currentUser?.displayName ??
                    'Estudiante UNIMET')
                .toString()
                .trim();
          }
        }

        return StreamBuilder<QuerySnapshot>(
          // Consulta en vivo de las inscripciones del estudiante
          stream: FirebaseFirestore.instance
              .collection('inscripciones')
              .snapshots(),
          builder: (context, inscripSnapshot) {
            final allInscripciones = inscripSnapshot.data?.docs ?? [];
            final misInscripciones = allInscripciones.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final String estId = (data['estudianteId'] ?? '').toString();
              final String estEmail =
                  (data['correoEstudiante'] ?? data['correo'] ?? '')
                      .toString()
                      .toLowerCase();
              return estId == _currentUser?.uid ||
                  estEmail == userEmail.toLowerCase();
            }).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'OFERTA DEPORTIVA INSTITUCIONAL',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: orangePrimary,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Catálogo Deportivo VirtuMet',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: blueDark,
                            ),
                          ),
                        ],
                      ),
                      if (widget.onBackToHome != null)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Color(0xFFCBD5E1), width: 1.2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: widget.onBackToHome,
                          icon: const Icon(Icons.arrow_back,
                              size: 18, color: blueDark),
                          label: const Text(
                            'Volver a Mi Inicio',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: blueDark,
                                fontSize: 13),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Búsqueda y Filtro de Categorías
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: TextField(
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val.toLowerCase().trim();
                              });
                            },
                            decoration: InputDecoration(
                              hintText:
                                  'Buscar por disciplina, código, entrenador o lugar...',
                              hintStyle: const TextStyle(
                                  fontSize: 13, color: Colors.grey),
                              prefixIcon: const Icon(Icons.search,
                                  size: 20, color: blueDark),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.zero,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Color(0xFFCBD5E1), width: 1.2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Color(0xFFCBD5E1), width: 1.2),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFFCBD5E1), width: 1.2),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            items: _categories.map((cat) {
                              return DropdownMenuItem(
                                value: cat,
                                child: Text(cat,
                                    style: const TextStyle(
                                        fontSize: 13, color: blueDark)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedCategory = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // StreamBuilder en vivo del catálogo 'deportes'
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('deportes')
                        .snapshots(),
                    builder: (context, sportsSnapshot) {
                      if (sportsSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(50),
                            child:
                                CircularProgressIndicator(color: orangePrimary),
                          ),
                        );
                      }

                      final sportsDocs = sportsSnapshot.data?.docs ?? [];

                      final filteredSports = sportsDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final nombre =
                            (data['nombre'] ?? '').toString().toLowerCase();
                        final codigo =
                            (data['codigo'] ?? '').toString().toLowerCase();
                        final entrenador = (data['entrenador'] ?? '')
                            .toString()
                            .toLowerCase();
                        final lugar =
                            (data['lugar'] ?? '').toString().toLowerCase();
                        final categoria = data['categoria'] ?? 'De equipo';

                        final matchesQuery = nombre.contains(_searchQuery) ||
                            codigo.contains(_searchQuery) ||
                            entrenador.contains(_searchQuery) ||
                            lugar.contains(_searchQuery);

                        final matchesCat =
                            _selectedCategory == 'Todas las disciplinas' ||
                                categoria == _selectedCategory;

                        return matchesQuery && matchesCat;
                      }).toList();

                      if (filteredSports.isEmpty) {
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
                              Icon(Icons.sports_soccer_outlined,
                                  size: 48, color: Colors.grey),
                              SizedBox(height: 12),
                              Text(
                                'No hay disciplinas registradas en esta categoría.',
                                style: TextStyle(
                                    color: blueDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15),
                              ),
                            ],
                          ),
                        );
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 400,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: filteredSports.length,
                        itemBuilder: (context, index) {
                          return _buildSportCard(
                            doc: filteredSports[index],
                            misInscripciones: misInscripciones,
                            nombreEstudiante: nombreEstudiante,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSportCard({
    required DocumentSnapshot doc,
    required List<DocumentSnapshot> misInscripciones,
    required String nombreEstudiante,
  }) {
    final String id = doc.id;
    final data = doc.data() as Map<String, dynamic>;

    final String codigo = data['codigo'] ?? 'DE-001';
    final String nombre = data['nombre'] ?? 'Sin Nombre';
    final String horario = data['horario'] ?? 'Por definir';
    final String lugar = data['lugar'] ?? 'Instalaciones UNIMET';
    final String entrenador = data['entrenador'] ?? 'Profesor Asignado';
    final String imageUrl = data['imageUrl'] ?? '';
    final String categoria = data['categoria'] ?? 'De equipo';
    final int cuposMax =
        (data['cuposMaximos'] ?? data['cupoMaximo'] ?? 20) as int;

    final bool yaInscrito = misInscripciones
        .any((i) => (i.data() as Map<String, dynamic>)['deporteId'] == id);

    return StreamBuilder<QuerySnapshot>(
      // Recálculo dinámico de cupos ocupados
      stream: FirebaseFirestore.instance
          .collection('inscripciones')
          .where('deporteId', isEqualTo: id)
          .snapshots(),
      builder: (context, inscripSnap) {
        final int inscritosReales =
            inscripSnap.hasData ? inscripSnap.data!.docs.length : 0;
        final int cuposDisponibles =
            (cuposMax - inscritosReales).clamp(0, cuposMax);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(15)),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            height: 130,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _fallbackHeader(),
                          )
                        : _fallbackHeader(),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: blueDark.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        codigo,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoria.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nombre,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: blueDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      _detailRow(Icons.access_time_rounded, horario),
                      const SizedBox(height: 4),
                      _detailRow(Icons.location_on_outlined, lugar),
                      const SizedBox(height: 4),
                      _detailRow(Icons.person_outline_rounded,
                          'Entrenador: $entrenador'),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: cuposDisponibles > 0
                                  ? Colors.green.withValues(alpha: 0.12)
                                  : Colors.red.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$cuposDisponibles / $cuposMax cupos',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: cuposDisponibles > 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: yaInscrito
                                  ? Colors.grey
                                  : (cuposDisponibles > 0
                                      ? orangePrimary
                                      : Colors.grey),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: (yaInscrito || cuposDisponibles <= 0)
                                ? null
                                : () async {
                                    // Escritura transaccional en Firestore
                                    await FirebaseFirestore.instance
                                        .collection('inscripciones')
                                        .add({
                                      'deporteId': id,
                                      'nombreDeporte': nombre,
                                      'estudianteId': _currentUser?.uid,
                                      'correoEstudiante': _currentUser?.email,
                                      'nombreEstudiante': nombreEstudiante,
                                      'horario': horario,
                                      'lugar': lugar,
                                      'fechaInscripcion':
                                          FieldValue.serverTimestamp(),
                                      'estado': 'Confirmada',
                                    });

                                    await FirebaseFirestore.instance
                                        .collection('deportes')
                                        .doc(id)
                                        .update({
                                      'cuposInscritos':
                                          FieldValue.increment(1),
                                    });

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              '¡Te has inscrito exitosamente en $nombre!'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  },
                            child: Text(
                              yaInscrito
                                  ? 'Inscrito'
                                  : (cuposDisponibles > 0
                                      ? 'Inscribirme'
                                      : 'Agotado'),
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _fallbackHeader() {
    return Container(
      height: 130,
      color: blueDark,
      child: const Center(
        child: Icon(Icons.sports_soccer, color: Colors.white, size: 40),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.black54),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Color(0xFF1F2937)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}