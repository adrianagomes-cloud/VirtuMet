import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'student_sports_view.dart';
import 'student_profile_page.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // 0: Inicio / Dashboard, 1: Catálogo Deportivo, 2: Mis Actividades, 3: Comunidad
  int _selectedIndex = 0;

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
    if (name.trim().isEmpty) return 'AT';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

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
    final String authUid = _currentUser?.uid ?? '';
    final String authEmail = (_currentUser?.email ?? '').toLowerCase();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, userSnapshot) {
        String nombreEstudiante = 'Estudiante UNIMET';
        String fotoUrl = '';
        String userDocEmail = authEmail;

        if (userSnapshot.hasData && userSnapshot.data!.docs.isNotEmpty) {
          final docs = userSnapshot.data!.docs;
          final matches = docs.where((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final String docEmail =
                (d['correo'] ?? d['email'] ?? '').toString().toLowerCase();
            return doc.id == authUid ||
                (authEmail.isNotEmpty && docEmail == authEmail);
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
            fotoUrl =
                (data['fotoUrl'] ?? data['photoUrl'] ?? '').toString().trim();
            userDocEmail =
                (data['correo'] ?? data['email'] ?? authEmail).toString().toLowerCase();
          }
        }

        final String primerNombre = nombreEstudiante.isNotEmpty
            ? nombreEstudiante.split(' ').first.toUpperCase()
            : 'ESTUDIANTE';

        // ESCUCHA EN TIEMPO REAL DE LA COLECCIÓN 'INSCRIPCIONES'
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('inscripciones')
              .snapshots(),
          builder: (context, inscripcionesSnapshot) {
            final allInscripciones = inscripcionesSnapshot.data?.docs ?? [];

            final misInscripciones = allInscripciones.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final String estId = (data['estudianteId'] ?? '').toString();
              final String estEmail =
                  (data['correoEstudiante'] ?? data['correo'] ?? '')
                      .toString()
                      .toLowerCase();

              final bool matchUid = authUid.isNotEmpty && estId == authUid;
              final bool matchEmail = (authEmail.isNotEmpty && estEmail == authEmail) ||
                  (userDocEmail.isNotEmpty && estEmail == userDocEmail);

              return matchUid || matchEmail;
            }).toList();

            final int totalInscritas = misInscripciones.length;

            return Scaffold(
              backgroundColor: bgLight,
              body: Column(
                children: [
                  _buildTopNavigationBar(nombreEstudiante, fotoUrl),

                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeInOut,
                      switchOutCurve: Curves.easeInOut,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.02, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _selectedIndex == 1
                          ? StudentSportsView(
                              key: const ValueKey(1),
                              onBackToHome: () =>
                                  setState(() => _selectedIndex = 0),
                            )
                          : SingleChildScrollView(
                              key: const ValueKey(0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHeroBanner(
                                      primerNombre, totalInscritas),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 40.0, vertical: 32.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildStatsRow(totalInscritas),
                                        const SizedBox(height: 32),
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
                                                  child: _buildMainContent(
                                                      misInscripciones,
                                                      nombreEstudiante),
                                                ),
                                                if (isDesktop) ...[
                                                  const SizedBox(width: 32),
                                                  Expanded(
                                                    flex: 1,
                                                    child: _buildRightSidebar(),
                                                  ),
                                                ],
                                              ],
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 40),
                                        _buildFooter(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTopNavigationBar(String nombreEstudiante, String fotoUrl) {
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
              errorBuilder: (_, _, _) => Row(
                children: const [
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
          const SizedBox(width: 48),
          _navLink('Inicio', targetIndex: 0),
          _navLink('Catálogo Deportivo', targetIndex: 1),
          _navLink('Mis Actividades', targetIndex: 2),
          _navLink('Comunidad', targetIndex: 3),
          const Spacer(),
          Row(
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StudentProfilePage(),
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
                        backgroundImage: fotoUrl.isNotEmpty
                            ? NetworkImage(fotoUrl)
                            : null,
                        child: fotoUrl.isEmpty
                            ? Text(
                                _getInitials(nombreEstudiante),
                                style: const TextStyle(
                                    color: orangePrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        nombreEstudiante,
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

  Widget _navLink(String title, {required int targetIndex}) {
    final bool isSelected = _selectedIndex == targetIndex;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = targetIndex;
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  Widget _buildHeroBanner(String primerNombre, int totalInscritas) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 64),
      decoration: BoxDecoration(
        color: blueDark,
        image: DecorationImage(
          image: const NetworkImage(
              'https://images.unsplash.com/photo-1546519638-68e109498ffc?q=80&w=1200'),
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
            child: const Text('PORTAL DE ESTUDIANTE',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
          ),
          const SizedBox(height: 16),
          Text(
            '¡BUENAS TARDES, $primerNombre!',
            style: const TextStyle(
                color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            totalInscritas > 0
                ? 'Tienes $totalInscritas disciplina(s) inscrita(s) activas. Revisa tu agenda y prepárate para entrenar.'
                : 'Aún no tienes disciplinas inscritas. Explora el catálogo deportivo e inscríbete.',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              ElevatedButton(
                onPressed: () => setState(() => _selectedIndex = 1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangePrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Explorar Catálogo →',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Ver Mis Actividades'),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatsRow(int totalInscritas) {
    return Row(
      children: [
        _statCard('DISCIPLINAS INSCRITAS',
            totalInscritas.toString().padLeft(2, '0'), Icons.people_outline,
            isLive: true),
        const SizedBox(width: 24),
        _statCard('ACTIVIDADES HOY', totalInscritas > 0 ? '01' : '00',
            Icons.calendar_today_outlined,
            isLive: true),
        const SizedBox(width: 24),
        _statCard('PRÓXIMOS EVENTOS', '05', Icons.emoji_events_outlined),
        const SizedBox(width: 24),
        _statCard('PORCENTAJE ASISTENCIA', '95%', Icons.show_chart),
      ],
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
                style: TextStyle(
                    color: textGrey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: blueDark,
                    fontSize: 32,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // CONTENIDO DE DEPORTES INSCRITOS CON RENDERIZADO INMEDIATO E IMAGEN EN TIEMPO REAL
  // ===========================================================================
  Widget _buildMainContent(
      List<DocumentSnapshot> misInscripciones, String nombreEstudiante) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Deportes Inscritos',
          style: TextStyle(
            color: blueDark,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Disciplinas asignadas e inscritas en el sistema',
          style: TextStyle(color: textGrey, fontSize: 13),
        ),
        const SizedBox(height: 20),
        if (misInscripciones.isEmpty)
          _buildEmptyStateContainer()
        else
          Column(
            children: misInscripciones.map((inscripcionDoc) {
              final data = inscripcionDoc.data() as Map<String, dynamic>;
              final String deporteId = (data['deporteId'] ?? '').toString();

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('deportes')
                    .doc(deporteId)
                    .snapshots(),
                builder: (context, sportSnapshot) {
                  Map<String, dynamic> sportData = {};
                  if (sportSnapshot.hasData &&
                      sportSnapshot.data!.exists &&
                      sportSnapshot.data!.data() != null) {
                    sportData =
                        sportSnapshot.data!.data() as Map<String, dynamic>;
                  }

                  final String deporteNombre = sportData['nombre'] ??
                      data['nombreDeporte'] ??
                      'Disciplina';
                  final String horario = sportData['horario'] ??
                      data['horario'] ??
                      'Lunes / Miércoles 5:30 - 7:00 PM';
                  final String lugar = sportData['lugar'] ??
                      data['lugar'] ??
                      'Cancha Techada UNIMET';
                  final String imageUrl = (sportData['imageUrl'] ??
                          data['imageUrl'] ??
                          '')
                      .toString()
                      .trim();

                  return _activityCard(
                      deporteNombre, horario, lugar, imageUrl);
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildEmptyStateContainer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports,
            size: 28,
            color: blueDark.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 14),
          const Text(
            'No tienes deportes ni disciplinas inscritas en el sistema',
            style: TextStyle(
              color: blueDark,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityCard(
      String deporteNombre, String horario, String lugar, String imageUrl) {
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
                      child: Icon(_getSportIcon(deporteNombre),
                          color: blueDark, size: 30),
                    ),
                  )
                : Container(
                    width: 68,
                    height: 68,
                    color: bgLight,
                    child: Icon(_getSportIcon(deporteNombre),
                        color: blueDark, size: 30),
                  ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deporteNombre,
                  style: const TextStyle(
                      color: blueDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '$horario · $lugar',
                  style: const TextStyle(color: textGrey, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                SizedBox(width: 6),
                Text('Inscrito',
                    style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightSidebar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: blueDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.campaign_outlined, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('AVISOS CRÍTICOS',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 24),
          _alertItem('Inscripciones de disciplinas activas este semestre'),
          const SizedBox(height: 16),
          _alertItem('Mantenimiento Cancha Principal: Mañana 08:00 AM'),
          const SizedBox(height: 32),
          const Text('VER TODAS LAS ALERTAS >',
              style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _alertItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: CircleAvatar(radius: 3, backgroundColor: Colors.orange),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, height: 1.4)),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Text('© 2026 VirtuMet · Bienestar y deporte universitario',
          style: const TextStyle(color: textGrey, fontSize: 12)),
    );
  }
}