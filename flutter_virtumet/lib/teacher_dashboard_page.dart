import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'attendance_page.dart';
import 'teacher_profile_page.dart';

class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  String _searchQuery = '';

  // Colores corporativos de VirtuMet
  static const Color orangePrimary = Color(0xFFFF5500);
  static const Color blueDark = Color(0xFF0F2C59);
  static const Color navyHeader = Color(0xFF0A192F);
  static const Color bgLight = Color(0xFFF4F6F9);

  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  IconData _getSportIcon(String sportName) {
    final name = sportName.toLowerCase();
    if (name.contains('baloncesto') || name.contains('basquet')) {
      return Icons.sports_basketball;
    } else if (name.contains('fútbol') || name.contains('futbol')) {
      return Icons.sports_soccer;
    } else if (name.contains('voleibol') || name.contains('voley')) {
      return Icons.sports_volleyball;
    } else if (name.contains('tenis')) {
      return Icons.sports_tennis;
    } else if (name.contains('natación') || name.contains('natacion')) {
      return Icons.pool;
    } else if (name.contains('entrenamiento') ||
        name.contains('gimnasio') ||
        name.contains('funcional')) {
      return Icons.fitness_center;
    } else if (name.contains('atletismo') || name.contains('running')) {
      return Icons.directions_run;
    }
    return Icons.sports;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Sesión no iniciada.')),
      );
    }

    final String userId = _currentUser.uid;
    final DateTime now = DateTime.now();
    final String fechaHoy =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;

        final String rawNombre = userData?['nombreApellido'] ??
            userData?['nombreCompleto'] ??
            userData?['nombre'] ??
            'Entrenador';
        final String nombreUsuario =
            rawNombre.trim().isEmpty ? 'Entrenador' : rawNombre.trim();
        final String photoUrl = userData?['photoUrl'] ?? '';

        return Scaffold(
          backgroundColor: bgLight,
          body: SingleChildScrollView(
            child: Column(
              children: [
                // 1. BARRA SUPERIOR (NAVBAR)
                _buildTopNavbar(context, nombreUsuario, photoUrl),

                // 2. CONSULTAS EN TIEMPO REAL A FIRESTORE
                StreamBuilder<QuerySnapshot>(
                  // Consulta 1: Todos los usuarios para registrar estudiantes/atletas activos
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .snapshots(),
                  builder: (context, usersSnapshot) {
                    int totalEstudiantesConectados = 0;

                    if (usersSnapshot.hasData && usersSnapshot.data != null) {
                      for (var doc in usersSnapshot.data!.docs) {
                        final uData = doc.data() as Map<String, dynamic>;
                        final String rol = (uData['rol'] ??
                                uData['role'] ??
                                uData['tipo'] ??
                                '')
                            .toString()
                            .toLowerCase()
                            .trim();

                        if (rol.contains('estudiante') ||
                            rol.contains('atleta') ||
                            rol.contains('alumno') ||
                            rol.contains('jugador')) {
                          totalEstudiantesConectados++;
                        }
                      }
                    }

                    return StreamBuilder<QuerySnapshot>(
                      // Consulta 2: Deportes/disciplinas asignadas a este maestro
                      stream: FirebaseFirestore.instance
                          .collection('deportes')
                          .snapshots(),
                      builder: (context, sportsSnapshot) {
                        final allSportsDocs = sportsSnapshot.data?.docs ?? [];

                        // Filtra las disciplinas correspondientes al maestro conectado
                        final mySportsDocs = allSportsDocs.where((doc) {
                          final sData = doc.data() as Map<String, dynamic>;
                          final String entNombre = (sData['entrenador'] ?? '')
                              .toString()
                              .trim()
                              .toLowerCase();
                          final String entUid =
                              (sData['entrenadorUid'] ?? '').toString().trim();

                          return entUid == userId ||
                              (nombreUsuario.isNotEmpty &&
                                  entNombre == nombreUsuario.toLowerCase());
                        }).toList();

                        final int sesionesCount = mySportsDocs.length;

                        // Conteo dinámico de alumnos inscritos en las disciplinas del profesor
                        int atletasEnMisDeportes = 0;
                        for (var sDoc in mySportsDocs) {
                          final sData = sDoc.data() as Map<String, dynamic>;
                          atletasEnMisDeportes +=
                              (sData['cuposInscritos'] ?? 0) as int;
                        }

                        final int totalAtletasMostrar = atletasEnMisDeportes > 0
                            ? atletasEnMisDeportes
                            : totalEstudiantesConectados;

                        return StreamBuilder<QuerySnapshot>(
                          // Consulta 3: Asistencias registradas hoy
                          stream: FirebaseFirestore.instance
                              .collection('asistencias')
                              .snapshots(),
                          builder: (context, asistenciasSnapshot) {
                            final asistenciasDocs =
                                asistenciasSnapshot.data?.docs ?? [];
                            final Set<String> completedSportIds = {};

                            for (var doc in asistenciasDocs) {
                              final data = doc.data() as Map<String, dynamic>;
                              if (data['fecha'] == fechaHoy &&
                                  data['deporteId'] != null) {
                                completedSportIds
                                    .add(data['deporteId'].toString());
                              }
                            }

                            return Column(
                              children: [
                                // HERO BANNER DINÁMICO
                                _buildHeroBanner(nombreUsuario, sesionesCount),

                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 50, vertical: 30),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // MÉTRICAS / KPIS EN TIEMPO REAL
                                      _buildKpiGrid(
                                        totalAtletas: totalAtletasMostrar,
                                        sesionesHoy: sesionesCount,
                                      ),
                                      const SizedBox(height: 32),

                                      // DISPOSICIÓN PRINCIPAL DE PANTALLA
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          final bool isDesktop =
                                              constraints.maxWidth > 900;
                                          return Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                flex: isDesktop ? 2 : 1,
                                                child: Column(
                                                  children: [
                                                    _buildSessionsList(
                                                      mySportsDocs,
                                                      completedSportIds,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (isDesktop)
                                                const SizedBox(width: 28),
                                              if (isDesktop)
                                                Expanded(
                                                  flex: 1,
                                                  child: Column(
                                                    children: [
                                                      _buildCriticalAlertsCard(),
                                                      const SizedBox(height: 24),
                                                      _buildUpcomingEventsCard(),
                                                      const SizedBox(height: 24),
                                                      _buildWeeklyPerformanceCard(),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                ),

                // 3. PIE DE PÁGINA
                _buildFooter(),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 1. BARRA SUPERIOR (NAVBAR)
  // ===========================================================================
  Widget _buildTopNavbar(
      BuildContext context, String nombre, String photoUrl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
      color: Colors.white,
      child: Row(
        children: [
          Image.asset(
            'lib/assets/Logo.png',
            height: 58,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Text(
              'VirtuMet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: blueDark,
              ),
            ),
          ),
          const SizedBox(width: 40),
          _navLink('Mis Disciplinas'),
          _navLink('Nómina y Asistencia'),
          _navLink('Anuncios'),
          _navLink('Comunidad'),
          const Spacer(),
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TeacherProfilePage(),
                    ),
                  );
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: blueDark.withValues(alpha: 0.08),
                          border: Border.all(
                            color: orangePrimary.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                          image: photoUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(photoUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: photoUrl.isEmpty
                            ? const Icon(Icons.person_outline,
                                size: 18, color: blueDark)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        nombre,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: blueDark,
                            fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.logout_rounded,
                    size: 18, color: Colors.grey),
                onPressed: _handleLogout,
                tooltip: 'Cerrar Sesión',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navLink(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text(
        title,
        style: const TextStyle(
          color: blueDark,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. HERO BANNER REACTIVO CON CONTEO REAL DE SESIONES
  // ===========================================================================
  Widget _buildHeroBanner(String nombre, int sesionesCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 48),
      decoration: const BoxDecoration(
        color: navyHeader,
        image: DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&w=1600&q=80',
          ),
          fit: BoxFit.cover,
          alignment: Alignment.topRight,
          colorFilter: ColorFilter.mode(
            Color(0x33000000),
            BlendMode.darken,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: orangePrimary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'PANEL DE ENTRENADOR',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '¡HOLA DE NUEVO, ${nombre.toUpperCase()}!',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tienes $sesionesCount ${sesionesCount == 1 ? 'sesión programada' : 'sesiones programadas'} para hoy en el sistema. Revisa el listado de atletas e ingresa a registrar sus asistencias.',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangePrimary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {},
                icon: const Icon(Icons.people_alt_rounded, size: 20),
                label: const Text('Ver Nómina de Atletas →',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const SizedBox(width: 14),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white, width: 1.5),
                  backgroundColor: Colors.black26,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {},
                child: const Text('Ver Horario Completo',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. MÉTRICAS KPIS EN TIEMPO REAL
  // ===========================================================================
  Widget _buildKpiGrid({required int totalAtletas, required int sesionesHoy}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 20,
        runSpacing: 20,
        children: [
          _kpiCard(
            Icons.groups_outlined,
            'TOTAL ATLETAS',
            totalAtletas.toString(),
            'EN VIVO',
            Colors.green,
            accentColor: orangePrimary,
          ),
          _kpiCard(
            Icons.calendar_today_outlined,
            'SESIONES HOY',
            sesionesHoy.toString().padLeft(2, '0'),
            'EN VIVO',
            Colors.green,
            accentColor: blueDark,
          ),
          _kpiCard(
            Icons.event_available_outlined,
            'PRÓXIMOS EVENTOS',
            '02',
            null,
            null,
            accentColor: orangePrimary,
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(
    IconData icon,
    String label,
    String value,
    String? badge,
    Color? badgeColor, {
    required Color accentColor,
  }) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: badgeColor!.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(badge,
                      style: TextStyle(
                          color: badgeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w900, color: blueDark)),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. LISTA DE SESIONES / DISCIPLINAS OBTENIDAS DE FIRESTORE
  // ===========================================================================
  Widget _buildSessionsList(
      List<QueryDocumentSnapshot> sportsDocs, Set<String> completedSportIds) {
    final filteredSportsDocs = sportsDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['nombre'] ?? '').toString().toLowerCase();
      final location = (data['lugar'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) || location.contains(_searchQuery);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sesiones Asignadas',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: blueDark)),
                  SizedBox(height: 2),
                  Text('Disciplinas asignadas en el sistema',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              SizedBox(
                width: 220,
                height: 40,
                child: TextField(
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.toLowerCase().trim();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar grupo...',
                    hintStyle:
                        const TextStyle(fontSize: 12, color: Colors.grey),
                    prefixIcon:
                        const Icon(Icons.search, size: 18, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF3F5F8),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (filteredSportsDocs.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: bgLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(Icons.sports_outlined, size: 40, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    'No tienes disciplinas ni sesiones asignadas en la base de datos.',
                    style: TextStyle(
                        color: blueDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ],
              ),
            )
          else
            ...filteredSportsDocs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final String deporteId = doc.id;
              final String nombre = data['nombre'] ?? 'Deporte';
              final String horario = data['horario'] ?? 'Por definir';
              final String lugar = data['lugar'] ?? 'Instalaciones UNIMET';
              final int inscritos = (data['cuposInscritos'] ?? 0) as int;

              final bool isCompleted = completedSportIds.contains(deporteId);

              return _sessionCard(
                  deporteId, nombre, horario, lugar, inscritos, null, isCompleted);
            }),
        ],
      ),
    );
  }

  Widget _sessionCard(String id, String nombre, String horario, String lugar,
      int inscritos, String? badgeText, bool isCompleted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_getSportIcon(nombre), color: blueDark, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: blueDark)),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                    children: [
                      TextSpan(text: '$horario  •  $lugar  •  '),
                      TextSpan(
                        text: '$inscritos Inscritos',
                        style: const TextStyle(
                          color: orangePrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isCompleted ? Colors.green : orangePrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AttendancePage(
                    deporteId: id,
                    deporteNombre: nombre,
                  ),
                ),
              );
            },
            child: Text(
              isCompleted ? 'ASISTENCIA REGISTRADA' : 'PASAR ASISTENCIA',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. CARDS LATERALES
  // ===========================================================================
  Widget _buildCriticalAlertsCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: blueDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: orangePrimary, size: 20),
              SizedBox(width: 8),
              Text('AVISOS CRÍTICOS',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          _alertItem('Solicitud de cambio de horario: Voleibol'),
          _alertItem('Mantenimiento Cancha 1: Mañana 08:00'),
          const SizedBox(height: 14),
          const Text('VER TODAS LAS ALERTAS >',
              style: TextStyle(
                  color: orangePrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _alertItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                  color: orangePrimary, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildUpcomingEventsCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PRÓXIMOS EVENTOS',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14, color: blueDark)),
          const SizedBox(height: 2),
          const Text('Calendario Institucional',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 16),
          _eventItem('Torneo Inter-Facultades', 'OCT 28', Colors.green),
          _eventItem('Cierre de Inscripciones', 'NOV 02', orangePrimary),
          _eventItem('Exhibición de Natación', 'NOV 05', Colors.blue),
          const SizedBox(height: 14),
          const Text('VER CALENDARIO COMPLETO',
              style: TextStyle(
                  color: blueDark, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _eventItem(String title, String date, Color tagColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 4, height: 16, color: tagColor),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: blueDark)),
            ],
          ),
          Text(date,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildWeeklyPerformanceCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: navyHeader,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RENDIMIENTO SEMANAL',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Row(
            children: [
              Text('92%',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900)),
              SizedBox(width: 8),
              Text('Meta alcanzada',
                  style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Has completado 12 de las 13 sesiones programadas esta semana. ¡Excelente ritmo!',
            style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 50),
      color: navyHeader,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      'lib/assets/Logo.png',
                      height: 38,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Text(
                        'VIRTUMET',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Plataforma digital para la gestión y promoción del deporte universitario en la Universidad Metropolitana.',
                      style: TextStyle(
                          color: Colors.white60, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 1),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ASISTENCIA',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _footerLinkItem('Soporte'),
                        _footerLinkItem('Preguntas Frecuentes'),
                        _footerLinkItem('Contacto'),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
          const SizedBox(height: 30),
          const Divider(color: Colors.white12),
          const SizedBox(height: 16),
          const Text(
            '© 2026 VirtuMet UNIMET. Todos los derechos reservados.',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _footerLinkItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {},
        child: Text(
          text,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ),
    );
  }
}