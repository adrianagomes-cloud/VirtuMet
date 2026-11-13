import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'attendance_page.dart';
import 'teacher_profile_page.dart';
import 'teacher_reviews_view.dart';
import 'student_announcements_view.dart';
import 'aviso_audiencia.dart';
import 'community_view.dart';

class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  int _selectedIndex = 0; // 0: Inicio, 1: Avisos, 2: Comunidad, 3: Mis Disciplinas, 4: Mis Reseñas
  String _searchQuery = '';

  static const Color blueDark = Color(0xFF0F2C59);
  static const Color orangePrimary = Color(0xFFFF5500);
  static const Color bgLight = Color(0xFFF4F6F9);
  static const Color textGrey = Color(0xFF6C757D);

  BoxDecoration get cardDecoration => BoxDecoration(
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
      );

  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'ENT';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
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

    final String userId = _currentUser!.uid;
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
            _currentUser?.displayName ??
            'Entrenador UNIMET';
        final String nombreUsuario =
            rawNombre.trim().isEmpty ? 'Entrenador UNIMET' : rawNombre.trim();
        final String photoUrl = userData?['fotoUrl'] ??
            userData?['photoUrl'] ??
            _currentUser?.photoURL ??
            '';

        final String primerNombre = nombreUsuario.isNotEmpty
            ? nombreUsuario.split(' ').first.toUpperCase()
            : 'ENTRENADOR';

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
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
              stream: FirebaseFirestore.instance
                  .collection('deportes')
                  .snapshots(),
              builder: (context, sportsSnapshot) {
                final allSportsDocs = sportsSnapshot.data?.docs ?? [];

                final mySportsDocs = allSportsDocs.where((doc) {
                  final sData = doc.data() as Map<String, dynamic>;
                  final String entNombre = (sData['entrenador'] ?? '')
                      .toString()
                      .trim()
                      .toLowerCase();
                  final String entUid = (sData['entrenadorUid'] ??
                          sData['entrenadorId'] ??
                          '')
                      .toString()
                      .trim();

                  return entUid == userId ||
                      (nombreUsuario.isNotEmpty &&
                          entNombre == nombreUsuario.toLowerCase());
                }).toList();

                final int sesionesCount = mySportsDocs.length;

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
                        completedSportIds.add(data['deporteId'].toString());
                      }
                    }

                    return Scaffold(
                      backgroundColor: bgLight,
                      body: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildTopNavigationBar(
                                context, userId, nombreUsuario, photoUrl),

                            if (_selectedIndex == 4)
                              const TeacherReviewsView()
                            else if (_selectedIndex == 3)
                              _buildMyDisciplinesView(
                                  mySportsDocs, completedSportIds)
                            else if (_selectedIndex == 2)
                              const CommunityView(userRole: 'teacher')
                            else if (_selectedIndex == 1)
                              const StudentAnnouncementsView(
                                  audiencia: 'Entrenadores')
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHeroBanner(primerNombre, sesionesCount),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 40.0, vertical: 32.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildStatsRow(
                                          totalAtletas: totalAtletasMostrar,
                                          sesionesHoy: sesionesCount,
                                        ),
                                        const SizedBox(height: 32),
                                        LayoutBuilder(
                                          builder: (context, constraints) {
                                            final bool isDesktop =
                                                constraints.maxWidth > 850;
                                            return Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  flex: isDesktop ? 2 : 1,
                                                  child: _buildSessionsList(
                                                    mySportsDocs,
                                                    completedSportIds,
                                                  ),
                                                ),
                                                if (isDesktop) ...[
                                                  const SizedBox(width: 32),
                                                  Expanded(
                                                    flex: 1,
                                                    child: Column(
                                                      children: [
                                                        _buildCriticalAlertsCard(
                                                            mySportsDocs),
                                                        const SizedBox(
                                                            height: 24),
                                                        _buildUpcomingEventsCard(),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            _buildFooter(),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMyDisciplinesView(
      List<QueryDocumentSnapshot> mySportsDocs, Set<String> completedSportIds) {
    final filteredSportsDocs = mySportsDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['nombre'] ?? '').toString().toLowerCase();
      final location = (data['lugar'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) || location.contains(_searchQuery);
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mis Disciplinas Asignadas',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: blueDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Gestiona tus grupos deportivos y registra la asistencia de tus atletas',
                    style: TextStyle(fontSize: 14, color: textGrey),
                  ),
                ],
              ),
              SizedBox(
                width: 240,
                height: 42,
                child: TextField(
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.toLowerCase().trim();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar disciplina o lugar...',
                    hintStyle: const TextStyle(fontSize: 12, color: textGrey),
                    prefixIcon:
                        const Icon(Icons.search, size: 18, color: textGrey),
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
          if (filteredSportsDocs.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
              decoration: cardDecoration,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sports_outlined,
                      size: 48, color: blueDark.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  const Text(
                    'No tienes disciplinas asignadas actualmente en tu cuenta.',
                    style: TextStyle(
                      color: blueDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
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
              final String imageUrl = (data['imageUrl'] ?? '').toString();
              final int inscritos = (data['cuposInscritos'] ?? 0) as int;
              final bool isCompleted = completedSportIds.contains(deporteId);

              return _sessionCard(
                deporteId,
                nombre,
                horario,
                lugar,
                imageUrl,
                inscritos,
                isCompleted,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTopNavigationBar(
      BuildContext context, String userId, String nombre, String photoUrl) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => setState(() => _selectedIndex = 0),
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'lib/assets/Logo.png',
              height: 40,
              errorBuilder: (_, __, ___) => const Row(
                children: [
                  Icon(Icons.fitness_center, color: blueDark, size: 24),
                  SizedBox(width: 8),
                  Text('VirtuMet',
                      style: TextStyle(
                          color: blueDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 36),

          _navLink('Inicio', targetIndex: 0),
          _navLink('Mis Disciplinas', targetIndex: 3),
          _navLink('Avisos', targetIndex: 1),
          _navLink('Comunidad', targetIndex: 2),
          _navLink('Mis Reseñas', targetIndex: 4),

          const Spacer(),
          Row(
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TeacherProfilePage(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: orangePrimary.withValues(alpha: 0.2),
                        backgroundImage: photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl.isEmpty
                            ? Text(
                                _getInitials(nombre),
                                style: const TextStyle(
                                    color: orangePrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        nombre,
                        style: const TextStyle(
                            color: blueDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.logout, size: 20),
                color: textGrey,
                onPressed: _handleLogout,
                tooltip: 'Cerrar Sesión',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navLink(String title, {int? targetIndex, VoidCallback? onTap}) {
    final bool isSelected = targetIndex != null && _selectedIndex == targetIndex;

    return InkWell(
      onTap: onTap ??
          () {
            if (targetIndex != null) {
              setState(() {
                _selectedIndex = targetIndex;
              });
            }
          },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            border: isSelected
                ? const Border(
                    bottom: BorderSide(color: orangePrimary, width: 2.5))
                : null,
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? orangePrimary : blueDark,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(String primerNombre, int sesionesCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 64),
      decoration: BoxDecoration(
        color: blueDark,
        image: DecorationImage(
          image: const NetworkImage(
              'https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&w=1600&q=80'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.5), BlendMode.darken),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: orangePrimary, borderRadius: BorderRadius.circular(20)),
            child: const Text('PANEL DE ENTRENADOR',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
          ),
          const SizedBox(height: 16),
          Text(
            '¡HOLA DE NUEVO, $primerNombre!',
            style: const TextStyle(
                color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tienes $sesionesCount ${sesionesCount == 1 ? 'sesión programada' : 'sesiones programadas'} para hoy en el sistema. Revisa tus atletas y registra tu asistencia.',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow({required int totalAtletas, required int sesionesHoy}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('eventos').snapshots(),
      builder: (context, eventsSnapshot) {
        final int totalEventos = eventsSnapshot.data?.docs.length ?? 0;

        return Row(
          children: [
            _statCard('TOTAL ATLETAS', totalAtletas.toString().padLeft(2, '0'),
                Icons.people_outline,
                isLive: true),
            const SizedBox(width: 24),
            _statCard('SESIONES HOY', sesionesHoy.toString().padLeft(2, '0'),
                Icons.calendar_today_outlined,
                isLive: true),
            const SizedBox(width: 24),
            _statCard('PRÓXIMOS EVENTOS', totalEventos.toString().padLeft(2, '0'),
                Icons.emoji_events_outlined,
                isLive: true),
          ],
        );
      },
    );
  }

  Widget _statCard(String title, String value, IconData icon,
      {bool isLive = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: orangePrimary, size: 24),
                if (isLive)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4)),
                    child: const Text('ACTIVO',
                        style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(title,
                style: const TextStyle(
                    color: textGrey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: blueDark,
                    fontSize: 32,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionsList(
      List<QueryDocumentSnapshot> sportsDocs, Set<String> completedSportIds) {
    final filteredSportsDocs = sportsDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['nombre'] ?? '').toString().toLowerCase();
      final location = (data['lugar'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) || location.contains(_searchQuery);
    }).toList();

    return Column(
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
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: blueDark)),
                SizedBox(height: 2),
                Text('Disciplinas asignadas en el sistema',
                    style: TextStyle(fontSize: 13, color: textGrey)),
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
                  hintStyle: const TextStyle(fontSize: 12, color: textGrey),
                  prefixIcon:
                      const Icon(Icons.search, size: 18, color: textGrey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (filteredSportsDocs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            decoration: BoxDecoration(
                color: const Color(0xFFF0F4F8),
                borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sports,
                    size: 28, color: blueDark.withValues(alpha: 0.5)),
                const SizedBox(width: 14),
                const Text(
                  'No tienes disciplinas asignadas en la base de datos.',
                  style: TextStyle(
                      color: blueDark,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
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
            final String imageUrl = (data['imageUrl'] ?? '').toString();
            final int inscritos = (data['cuposInscritos'] ?? 0) as int;

            final bool isCompleted = completedSportIds.contains(deporteId);

            return _sessionCard(deporteId, nombre, horario, lugar, imageUrl,
                inscritos, isCompleted);
          }),
      ],
    );
  }

  Widget _sessionCard(
      String id,
      String nombre,
      String horario,
      String lugar,
      String imageUrl,
      int inscritos,
      bool isCompleted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: cardDecoration,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 68,
                    height: 68,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 68,
                      height: 68,
                      color: bgLight,
                      child: Icon(_getSportIcon(nombre),
                          color: blueDark, size: 30),
                    ),
                  )
                : Container(
                    width: 68,
                    height: 68,
                    color: bgLight,
                    child: Icon(_getSportIcon(nombre),
                        color: blueDark, size: 30),
                  ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: blueDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$horario · $lugar',
                  style: const TextStyle(fontSize: 13, color: textGrey),
                ),
                const SizedBox(height: 2),
                Text(
                  '$inscritos Atletas Inscritos',
                  style: const TextStyle(
                    fontSize: 12,
                    color: orangePrimary,
                    fontWeight: FontWeight.bold,
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 14),
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
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriticalAlertsCard(List<QueryDocumentSnapshot> mySportsDocs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
          color: blueDark, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: orangePrimary, size: 20),
              SizedBox(width: 8),
              Text('AVISOS',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('avisos')
                .where('estado', isEqualTo: 'Activo')
                .snapshots(),
            builder: (context, avisosSnap) {
              final List<String> comunicados = [];

              if (avisosSnap.hasData && avisosSnap.data != null) {
                final docs = avisosSnap.data!.docs;
                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (!avisoDirigidoA(data, 'Entrenadores')) continue;
                  final titulo = data['titulo'] ?? 'Aviso';
                  final mensaje = data['mensaje'] ?? '';
                  comunicados.add('$titulo: $mensaje');
                }
              }

              for (var doc in mySportsDocs) {
                final data = doc.data() as Map<String, dynamic>;
                final String estado = (data['estado'] ?? 'Activo').toString();
                final String nombre = (data['nombre'] ?? 'Disciplina').toString();
                if (estado != 'Activo') {
                  comunicados.add('$nombre: disciplina en estado $estado');
                }
              }

              if (comunicados.isEmpty) {
                return _alertItem('Sin avisos por ahora.');
              }

              return Column(
                children:
                    comunicados.take(4).map((a) => _alertItem(a)).toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
              },
              child: const Text(
                'VER TODOS LOS AVISOS >',
                style: TextStyle(
                  color: orangePrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
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
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events_outlined,
                  color: orangePrimary, size: 20),
              SizedBox(width: 8),
              Text('PRÓXIMOS EVENTOS',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: blueDark)),
              Spacer(),
              Text('EN VIVO',
                  style: TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Calendario institucional UNIMET en tiempo real',
              style: TextStyle(fontSize: 11, color: textGrey)),
          const Divider(height: 24),
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('eventos').snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Text('No hay eventos próximos',
                    style: TextStyle(fontSize: 12, color: textGrey));
              }
              return Column(
                children: docs.take(3).map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final String titulo = (data['titulo'] ?? '').toString();
                  final String fecha =
                      (data['fechaKey'] ?? data['fecha'] ?? '').toString();

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(titulo,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: blueDark)),
                    subtitle: Text(fecha,
                        style: const TextStyle(
                            fontSize: 11, color: textGrey)),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text('© 2026 Samán Deportivo · UNIMET',
            style: TextStyle(color: textGrey, fontSize: 12)),
      ),
    );
  }
}