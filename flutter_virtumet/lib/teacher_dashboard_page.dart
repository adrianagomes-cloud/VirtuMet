import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'attendance_page.dart';

class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  String _searchQuery = ''; // Estado para el filtro del buscador de sesiones

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

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(body: Center(child: Text('Sesión no iniciada.')));
    }

    final String userId = _currentUser.uid;
    final DateTime now = DateTime.now();
    final String fechaHoy =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: bgLight,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTopNavbar(context),

            _buildHeroBanner(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('deportes')
                    .where('entrenadorUid', isEqualTo: userId)
                    .snapshots(),
                builder: (context, sportsSnapshot) {
                  final sportsDocs = sportsSnapshot.data?.docs ?? [];
                  final int sesionesHoyCount = sportsDocs.length;

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('inscripciones')
                        .snapshots(),
                    builder: (context, inscripcionesSnapshot) {
                      final allInscripciones =
                          inscripcionesSnapshot.data?.docs ?? [];

                      final sportIds = sportsDocs.map((doc) => doc.id).toSet();
                      final myStudents = allInscripciones.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return sportIds.contains(data['deporteId']);
                      }).toList();

                      final int totalAtletas =
                          myStudents.isEmpty ? 142 : myStudents.length;

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('asistencias')
                            .where('entrenadorUid', isEqualTo: userId)
                            .snapshots(),
                        builder: (context, asistenciasSnapshot) {
                          final asistenciasDocs =
                              asistenciasSnapshot.data?.docs ?? [];

                          // Extraer deportes que ya tienen asistencia registrada HOY
                          final Set<String> completedSportIds = {};
                          int presentesCount = 0;

                          for (var doc in asistenciasDocs) {
                            final data = doc.data() as Map<String, dynamic>;
                            if (data['fecha'] == fechaHoy && data['deporteId'] != null) {
                              completedSportIds.add(data['deporteId'].toString());
                            }
                            if (data['estado'] == 'Presente' || data['estado'] == 'presente') {
                              presentesCount++;
                            }
                          }

                          final double asistenciaPromedio = asistenciasDocs.isEmpty
                              ? 88.0
                              : (presentesCount / asistenciasDocs.length) * 100;

                          return Column(
                            children: [
                              // FILA DE MÉTRICAS KPI
                              _buildKpiGrid(
                                totalAtletas: totalAtletas,
                                asistenciaPromedio:
                                    asistenciaPromedio.toStringAsFixed(0),
                                sesionesHoy:
                                    sesionesHoyCount == 0 ? 3 : sesionesHoyCount,
                              ),
                              const SizedBox(height: 30),

                              // DISPOSICIÓN PRINCIPAL (COLUMNA IZQUIERDA Y DERECHA)
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final bool isDesktop = constraints.maxWidth > 900;
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // COLUMNA IZQUIERDA (SESIONES Y ACTIVIDAD)
                                      Expanded(
                                        flex: isDesktop ? 2 : 1,
                                        child: Column(
                                          children: [
                                            _buildSessionsList(
                                              sportsDocs,
                                              completedSportIds,
                                            ),
                                            const SizedBox(height: 24),
                                            _buildNewSessionDashedCard(),
                                            const SizedBox(height: 30),
                                            _buildRecentActivitySection(),
                                          ],
                                        ),
                                      ),
                                      if (isDesktop) const SizedBox(width: 24),

                                      // COLUMNA DERECHA (AVISOS, EVENTOS, RENDIMIENTO)
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
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),

            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // WIDGETS AUXILIARES
  // ===========================================================================

  Widget _buildTopNavbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
      color: Colors.white,
      child: Row(
        children: [
          Image.asset(
            'lib/assets/Logo.png',
            height: 38,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: blueDark,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.fitness_center, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 8),
                const Text(
                  'VirtuMet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: blueDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
          _navLink('Catálogo'),
          _navLink('Mis Inscripciones'),
          _navLink('Anuncios'),
          _navLink('Comunidad'),
          const Spacer(),
          Row(
            children: [
              const CircleAvatar(
                radius: 14,
                backgroundColor: Color(0xFFE9ECEF),
                child: Icon(Icons.person, size: 18, color: blueDark),
              ),
              const SizedBox(width: 8),
              const Text(
                'Entrenador',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: blueDark, fontSize: 13),
              ),
              IconButton(
                icon: const Icon(Icons.logout, size: 18, color: Colors.grey),
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
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 42),
      decoration: const BoxDecoration(
        color: navyHeader,
        image: DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&w=1600&q=80',
          ),
          fit: BoxFit.cover,
          alignment: Alignment.topRight,
          colorFilter: ColorFilter.mode(
            Color(0x550A192F),
            BlendMode.darken,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                  letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '¡HOLA DE NUEVO, ENTRENADOR!',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tienes 3 sesiones programadas para hoy. El clima es ideal para la práctica en campo abierto.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangePrimary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {},
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Iniciar Entrenamiento Actual →',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 14),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {},
                child: const Text('Ver Horario Completo',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(
      {required int totalAtletas,
      required String asistenciaPromedio,
      required int sesionesHoy}) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _kpiCard(Icons.groups_outlined, 'TOTAL ATLETAS',
            totalAtletas.toString(), '+12%', Colors.green),
        _kpiCard(Icons.verified_outlined, 'ASISTENCIA PROM.',
            '$asistenciaPromedio%', '+3%', Colors.green),
        _kpiCard(Icons.calendar_today_outlined, 'SESIONES HOY',
            sesionesHoy.toString().padLeft(2, '0'), null, null),
        _kpiCard(
            Icons.directions_run_outlined, 'KILÓMETROS REC.', '12.4K', '+5%', Colors.green),
      ],
    );
  }

  Widget _kpiCard(IconData icon, String label, String value, String? badge,
      Color? badgeColor) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: blueDark, size: 22),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: badgeColor!.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(badge,
                      style: TextStyle(
                          color: badgeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w900, color: blueDark)),
        ],
      ),
    );
  }

  Widget _buildSessionsList(
      List<QueryDocumentSnapshot> sportsDocs, Set<String> completedSportIds) {
    // 1. Caso sin documentos en Firestore: Usar datos estáticos y aplicarle el filtro del buscador
    final defaultSessions = [
      {
        'id': 'deporte_1',
        'nombre': 'Fútbol Sala Varonil',
        'horario': '14:00 - 16:00',
        'lugar': 'Cancha Techada 1',
        'inscritos': 22,
        'badgeText': 'EN CURSO',
      },
      {
        'id': 'deporte_2',
        'nombre': 'Entrenamiento Funcional',
        'horario': '16:30 - 17:30',
        'lugar': 'Gimnasio UNIMET',
        'inscritos': 15,
        'badgeText': null,
      },
      {
        'id': 'deporte_3',
        'nombre': 'Baloncesto Varonil',
        'horario': '18:00 - 20:00',
        'lugar': 'Cancha Techada 2',
        'inscritos': 18,
        'badgeText': null,
      },
    ];

    final filteredDefaults = defaultSessions.where((s) {
      final name = s['nombre'].toString().toLowerCase();
      final location = s['lugar'].toString().toLowerCase();
      return name.contains(_searchQuery) || location.contains(_searchQuery);
    }).toList();

    // 2. Caso con documentos en Firestore: Aplicarle el filtro del buscador
    final filteredSportsDocs = sportsDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['nombre'] ?? '').toString().toLowerCase();
      final location = (data['lugar'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) || location.contains(_searchQuery);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)
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
                  Text('Sesiones de Hoy',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: blueDark)),
                  Text('Viernes, 25 de Octubre',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              Row(
                children: [
                  SizedBox(
                    width: 200,
                    height: 38,
                    child: TextField(
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.toLowerCase().trim();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Buscar grupo...',
                        hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                        prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFFF3F5F8),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Renderizar lista según Firestore o Predeterminados
          if (sportsDocs.isEmpty) ...[
            if (filteredDefaults.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(
                  child: Text(
                    'No se encontraron grupos con esa búsqueda.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              )
            else
              ...filteredDefaults.map((item) {
                final String id = item['id'] as String;
                final String nombre = item['nombre'] as String;
                final String horario = item['horario'] as String;
                final String lugar = item['lugar'] as String;
                final int inscritos = item['inscritos'] as int;
                final String? badgeText = item['badgeText'] as String?;
                final bool isCompleted = completedSportIds.contains(id);

                return _sessionCard(
                    id, nombre, horario, lugar, inscritos, badgeText, isCompleted);
              }),
          ] else ...[
            if (filteredSportsDocs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(
                  child: Text(
                    'No se encontraron grupos con esa búsqueda.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              )
            else
              ...filteredSportsDocs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final String deporteId = doc.id;
                final String nombre = data['nombre'] ?? 'Deporte';
                final String horario = data['horario'] ?? '14:00 - 16:00';
                final String lugar = data['lugar'] ?? 'Cancha Techada 1';
                final int cupo = data['cupoMaximo'] ?? 20;

                final bool isCompleted = completedSportIds.contains(deporteId);

                return _sessionCard(
                    deporteId, nombre, horario, lugar, cupo, null, isCompleted);
              }),
          ],
        ],
      ),
    );
  }

  Widget _sessionCard(String id, String nombre, String horario, String lugar,
      int inscritos, String? badgeText, bool isCompleted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sports_soccer, color: blueDark, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(nombre,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: blueDark)),
                    if (badgeText != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: orangePrimary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: orangePrimary),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text('$horario  •  $lugar  •  $inscritos Inscritos',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),

          if (isCompleted)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              icon: const Icon(Icons.assignment_turned_in_outlined,
                  size: 18, color: blueDark),
              label: const Text(
                'PASAR ASISTENCIA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: blueDark,
                ),
              ),
            )
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: orangePrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
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
              child: const Text('PASAR ASISTENCIA',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildNewSessionDashedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
      ),
      child: const Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: blueDark, size: 20),
            SizedBox(width: 8),
            Text('PROGRAMAR NUEVA SESIÓN',
                style: TextStyle(
                    color: blueDark, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Actividad Reciente de Estudiantes',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: blueDark)),
        const SizedBox(height: 14),
        Row(
          children: [
            _activityCard('RICARDO MENDEZ', 'Preinscripción confirmada',
                'Hace 10 min'),
            const SizedBox(width: 12),
            _activityCard(
                'GABRIELA SOTO', 'Cargó examen físico', 'Hace 45 min'),
            const SizedBox(width: 12),
            _activityCard('LUIS NAVARRO', 'Justificativo de falta', 'Hace 2 h'),
          ],
        ),
      ],
    );
  }

  Widget _activityCard(String name, String action, String time) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.02), blurRadius: 6)
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: blueDark.withValues(alpha: 0.1),
              radius: 16,
              child: Text(name[0],
                  style: const TextStyle(
                      color: blueDark,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: blueDark)),
                  Text(action,
                      style:
                          const TextStyle(fontSize: 10, color: Colors.grey),
                      overflow: TextOverflow.ellipsis),
                  Text(time,
                      style: const TextStyle(
                          fontSize: 9,
                          color: orangePrimary,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCriticalAlertsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          _alertItem('Ficha médica vencida: Juan Pérez'),
          _alertItem('Solicitud de cambio de horario: Voleibol'),
          _alertItem('Mantenimiento Cancha 1: Mañana 08:00'),
          const SizedBox(height: 12),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PRÓXIMOS EVENTOS',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14, color: blueDark)),
          const Text('Calendario Institucional',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 16),
          _eventItem('Torneo Inter-Facultades', 'OCT 28', Colors.green),
          _eventItem('Cierre de Inscripciones', 'NOV 02', orangePrimary),
          _eventItem('Exhibición de Natación', 'NOV 05', Colors.blue),
          const SizedBox(height: 12),
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
      padding: const EdgeInsets.all(20),
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
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PIE DE PÁGINA (FOOTER CON COLUMNA ASISTENCIA CENTRADA)
  // ===========================================================================

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
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
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // ESPACIADOR IZQUIERDO
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