import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'student_sports_view.dart';
import 'student_profile_page.dart';
import 'reviews_management_view.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // 0: Inicio, 1: Catálogo Deportivo, 2: Mis Actividades, 3: Comunidad, 4: Mis Reseñas
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

  Widget _buildStars(String ratingStr) {
    final double val = double.tryParse(ratingStr) ?? 5.0;
    final int stars = val.round().clamp(1, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < stars ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String authUid = _currentUser?.uid ?? '';
    final String authEmail = (_currentUser?.email ?? '').toLowerCase();

    return StreamBuilder<DocumentSnapshot>(
      stream: authUid.isNotEmpty
          ? FirebaseFirestore.instance
              .collection('users')
              .doc(authUid)
              .snapshots()
          : const Stream.empty(),
      builder: (context, userSnapshot) {
        String nombreEstudiante = _currentUser?.displayName ?? 'Estudiante UNIMET';
        String fotoUrl = _currentUser?.photoURL ?? '';

        if (userSnapshot.hasData && userSnapshot.data!.data() != null) {
          final data = userSnapshot.data!.data() as Map<String, dynamic>;
          nombreEstudiante = (data['nombreApellido'] ??
                  data['nombreCompleto'] ??
                  data['nombre'] ??
                  _currentUser?.displayName ??
                  'Estudiante UNIMET')
              .toString()
              .trim();
          fotoUrl = (data['fotoUrl'] ??
                  data['photoUrl'] ??
                  _currentUser?.photoURL ??
                  '')
              .toString()
              .trim();
        }

        final String primerNombre = nombreEstudiante.isNotEmpty
            ? nombreEstudiante.split(' ').first.toUpperCase()
            : 'ESTUDIANTE';

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
              final bool matchEmail =
                  authEmail.isNotEmpty && estEmail == authEmail;

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
                      child: _selectedIndex == 1
                          ? StudentSportsView(
                              key: const ValueKey(1),
                              onBackToHome: () =>
                                  setState(() => _selectedIndex = 0),
                            )
                          : _selectedIndex == 4
                              ? _buildMyReviewsView(authUid, authEmail)
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
                                                    constraints.maxWidth > 850;
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

  // BARRA DE NAVEGACIÓN SUPERIOR CON LA PESTAÑA "MIS RESEÑAS"
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
          _navLink('Catálogo Deportivo', targetIndex: 1),
          _navLink('Mis Actividades', targetIndex: 2),
          _navLink('Comunidad', targetIndex: 3),
          _navLink('Mis Reseñas', targetIndex: 4),
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
        ],
      ),
    );
  }

  Widget _buildStatsRow(int totalInscritas) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('eventos').snapshots(),
      builder: (context, eventsSnapshot) {
        final int totalEventos = eventsSnapshot.data?.docs.length ?? 0;

        return Row(
          children: [
            _statCard(
              'DISCIPLINAS INSCRITAS',
              totalInscritas.toString().padLeft(2, '0'),
              Icons.people_outline,
              isLive: true,
            ),
            const SizedBox(width: 24),
            _statCard(
              'ACTIVIDADES HOY',
              totalInscritas > 0 ? '01' : '00',
              Icons.calendar_today_outlined,
              isLive: true,
            ),
            const SizedBox(width: 24),
            _statCard(
              'PRÓXIMOS EVENTOS',
              totalEventos.toString().padLeft(2, '0'),
              Icons.emoji_events_outlined,
              isLive: true,
            ),
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
                      deporteId, deporteNombre, horario, lugar, imageUrl);
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
      String deporteId, String deporteNombre, String horario, String lugar, String imageUrl) {
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
          TextButton.icon(
            onPressed: () async {
              final sportDoc = await FirebaseFirestore.instance.collection('deportes').doc(deporteId).get();
              final sportData = sportDoc.data() as Map<String, dynamic>?;
              final profesorUid = sportData?['entrenadorUid'] ?? '';
              final profesorNombre = sportData?['entrenador'] ?? 'Profesor';

              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EnviarResenaPage(
                    deporteId: deporteId,
                    deporteNombre: deporteNombre,
                    profesorUid: profesorUid,
                    profesorNombre: profesorNombre,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.star_rate, color: Colors.amber, size: 18),
            label: const Text('Calificar', style: TextStyle(color: blueDark, fontSize: 11)),
          ),
          const SizedBox(width: 8),
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

  // BARRA LATERAL DERECHA (CON EVENTOS EN TIEMPO REAL IGUAL A MAESTROS)
  Widget _buildRightSidebar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCriticalAlertsCard(),
        const SizedBox(height: 24),
        _buildUpcomingEventsCard(),
      ],
    );
  }

  Widget _buildCriticalAlertsCard() {
    return Container(
      width: double.infinity,
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
              Text(
                'AVISOS CRÍTICOS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _alertItem('Solicitud de cambio de horario: Voleibol'),
          _alertItem('Mantenimiento Cancha 1: Mañana 08:00'),
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
              color: orangePrimary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEventsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events_outlined,
                  color: orangePrimary, size: 20),
              SizedBox(width: 8),
              Text(
                'PRÓXIMOS EVENTOS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: blueDark,
                ),
              ),
              Spacer(),
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
          const SizedBox(height: 4),
          const Text(
            'Calendario institucional UNIMET en tiempo real',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const Divider(height: 24),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('eventos')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: orangePrimary,
                    ),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'No hay eventos agendados.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                );
              }

              return Column(
                children: docs.take(4).map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final String titulo =
                      (data['titulo'] ?? 'Evento').toString();
                  final String deporte =
                      (data['deporte'] ?? 'General').toString();
                  final String fechaKey =
                      (data['fechaKey'] ?? '').toString();
                  final String hora = (data['hora'] ?? '').toString();

                  String labelFecha = fechaKey;
                  if (fechaKey.length >= 10) {
                    final parts = fechaKey.split('-');
                    if (parts.length == 3) {
                      labelFecha = '${parts[2]}/${parts[1]}';
                    }
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: bgLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: blueDark,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.event,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                titulo,
                                style: const TextStyle(
                                  color: blueDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$deporte • $labelFecha ${hora.isNotEmpty ? "($hora)" : ""}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  // ===========================================================================
  // VISTA PESTAÑA "MIS RESEÑAS" (TIEMPO REAL + ORDENADO POR DEPORTE INSCRITO)
  // ===========================================================================
  Widget _buildMyReviewsView(String authUid, String authEmail) {
    return SingleChildScrollView(
      key: const ValueKey(4),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Mis Reseñas y Calificaciones',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: blueDark,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
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
            'Opiniones y valoraciones publicadas organizadas por cada deporte en el que estás inscrito.',
            style: TextStyle(fontSize: 13, color: textGrey),
          ),
          const SizedBox(height: 28),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('resenas').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: orangePrimary),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              // FILTRAR RESEÑAS DEL ESTUDIANTE ACTUAL
              final misResenas = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final String estUid = (data['estudianteUid'] ?? data['uid'] ?? '').toString();
                final String estEmail = (data['estudianteEmail'] ?? data['correo'] ?? '').toString().toLowerCase();

                return (authUid.isNotEmpty && estUid == authUid) ||
                    (authEmail.isNotEmpty && estEmail == authEmail);
              }).toList();

              if (misResenas.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: cardDecoration,
                  child: const Column(
                    children: [
                      Icon(Icons.rate_review_outlined, size: 48, color: textGrey),
                      SizedBox(height: 12),
                      Text(
                        'Aún no has publicado opiniones para tus deportes.',
                        style: TextStyle(
                          color: blueDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Haz clic en el botón "Calificar" junto a tu deporte inscrito en el Inicio para agregar tu reseña.',
                        style: TextStyle(color: textGrey, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: misResenas.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final data = misResenas[index].data() as Map<String, dynamic>;

                  final String disciplina = (data['deporte'] ??
                          data['disciplina'] ??
                          data['deporteNombre'] ??
                          'Disciplina')
                      .toString();
                  final String profesorNombre = (data['profesorNombre'] ??
                          data['entrenador'] ??
                          data['nombreProfesor'] ??
                          'Profesor')
                      .toString();
                  final String ratingProfesor = (data['ratingProfesor'] ??
                          data['calificacionProfesor'] ??
                          '5')
                      .toString();
                  final String comentarioProfesor = (data['comentarioProfesor'] ??
                          data['resenaProfesor'] ??
                          '')
                      .toString();
                  final String ratingDeporte = (data['ratingDeporte'] ??
                          data['calificacionDeporte'] ??
                          '5')
                      .toString();
                  final String comentarioDeporte = (data['comentarioDeporte'] ??
                          data['resenaDeporte'] ??
                          '')
                      .toString();

                  return Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: orangePrimary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(_getSportIcon(disciplina),
                                      color: orangePrimary, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      disciplina,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: blueDark,
                                      ),
                                    ),
                                    Text(
                                      'Profesor asignado: $profesorNombre',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: textGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.green.withValues(alpha: 0.3)),
                              ),
                              child: const Text(
                                'Reseña Registrada',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24, color: Color(0xFFE2E8F0)),

                        // EVALUACIÓN PROFESOR
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Evaluación del Profesor: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: blueDark,
                                    ),
                                  ),
                                  _buildStars(ratingProfesor),
                                  const SizedBox(width: 6),
                                  Text(
                                    '($ratingProfesor/5)',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: blueDark,
                                    ),
                                  ),
                                ],
                              ),
                              if (comentarioProfesor.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    '"$comentarioProfesor"',
                                    style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // EVALUACIÓN DEPORTE
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7F4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFFFFE0D6), width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Evaluación de la Disciplina: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: blueDark,
                                    ),
                                  ),
                                  _buildStars(ratingDeporte),
                                  const SizedBox(width: 6),
                                  Text(
                                    '($ratingDeporte/5)',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: blueDark,
                                    ),
                                  ),
                                ],
                              ),
                              if (comentarioDeporte.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
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
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return const SizedBox.shrink();
  }
}