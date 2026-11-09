import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'admin_sports_view.dart';
import 'admin_users_view.dart';
import 'admin_fichas_view.dart';
import 'admin_stats_view.dart';
import 'admin_events_view.dart';
import 'admin_reviews_view.dart'; // <-- Vista de reseñas del administrador
import 'admin_announcements_view.dart'; // Avisos administrables (CRUD)

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  
  // Índice de sección activa:
  // 0: Resumen / Inicio
  // 1: Disciplinas
  // 2: Usuarios
  // 3: Fichas e Inscripciones
  // 4: Eventos (AdminEventsView)
  // 5: Reportes y Avisos
  // 6: Reseñas (AdminReviewsView)
  // 7: Avisos (AdminAnnouncementsView)
  int _selectedIndex = 0;
  String _searchQuery = '';

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
    final String adminEmail =
        _currentUser?.email ?? 'admin@correo.unimet.edu.ve';
    final String nombreAdmin = adminEmail.split('@').first.toUpperCase();

    return Scaffold(
      backgroundColor: bgLight,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTopNavbar(context, adminEmail),

            if (_selectedIndex == 1) ...[
              const AdminSportsView(),
            ] else if (_selectedIndex == 2) ...[
              const AdminUsersView(),
            ] else if (_selectedIndex == 3) ...[
              const AdminFichasView(),
            ] else if (_selectedIndex == 4) ...[
              const AdminEventsView(),
            ] else if (_selectedIndex == 5) ...[
              const AdminStatsView(),
            ] else if (_selectedIndex == 6) ...[
              const AdminReviewsView(), // <-- Integración exacta de la vista de reseñas
            ] else if (_selectedIndex == 7) ...[
              const AdminAnnouncementsView(),
            ] else ...[
              _buildHeroBanner(nombreAdmin),

              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildKpiGrid(),
                    const SizedBox(height: 32),

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final bool isDesktop = constraints.maxWidth > 900;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: isDesktop ? 2 : 1,
                              child: _buildSportsManagementCard(),
                            ),
                            if (isDesktop) const SizedBox(width: 28),

                            if (isDesktop)
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _buildCriticalAlertsCard(),
                                    const SizedBox(height: 24),
                                    _buildUpcomingEventsCard(),
                                    const SizedBox(height: 24),
                                    _buildSystemStatusCard(),
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

            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavbar(BuildContext context, String email) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
      color: Colors.white,
      child: Row(
        children: [
          InkWell(
            onTap: () => setState(() => _selectedIndex = 0),
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'lib/assets/Logo.png',
              height: 58,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: blueDark,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.fitness_center,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'VirtuMet',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: blueDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 40),

          _navLink('Disciplinas', targetIndex: 1),
          _navLink('Usuarios', targetIndex: 2),
          _navLink('Fichas e Inscripciones', targetIndex: 3),
          _navLink('Eventos', targetIndex: 4),
          _navLink('Reportes y Avisos', targetIndex: 5),
          _navLink('Reseñas', targetIndex: 6), // <-- Pestaña de Reseñas restaurada en la barra
          _navLink('Avisos', targetIndex: 7),

          const Spacer(),

          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: blueDark.withValues(alpha: 0.08),
                  border: Border.all(
                    color: orangePrimary.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
                child: const Icon(Icons.admin_panel_settings_outlined,
                    size: 18, color: blueDark),
              ),
              const SizedBox(width: 10),
              Text(
                email,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: blueDark,
                  fontSize: 13,
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

  Widget _navLink(String title, {required int targetIndex}) {
    final bool isSelected = _selectedIndex == targetIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = targetIndex;
          });
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
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
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(String nombreAdmin) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 48),
      decoration: const BoxDecoration(
        color: navyHeader,
        image: DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?auto=format&fit=crop&w=1600&q=80',
          ),
          fit: BoxFit.cover,
          alignment: Alignment.center,
          colorFilter: ColorFilter.mode(
            Color(0xB3000000),
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
              'PANEL DE ADMINISTRADOR',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '¡HOLA DE NUEVO, $nombreAdmin!',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  offset: Offset(0, 2),
                  blurRadius: 6.0,
                  color: Colors.black45,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bienvenido al centro de control del sistema VirtuMet. Gestiona usuarios, aprueba solicitudes y monitorea las disciplinas en tiempo real.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w500,
              shadows: [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 4.0,
                  color: Colors.black45,
                ),
              ],
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
                  elevation: 2,
                ),
                onPressed: () {
                  setState(() => _selectedIndex = 2);
                },
                icon: const Icon(Icons.people_alt_rounded, size: 20),
                label: const Text(
                  'Gestionar Usuarios →',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
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
                onPressed: () {
                  setState(() => _selectedIndex = 1);
                },
                child: const Text(
                  'Ver Disciplinas',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, usersSnapshot) {
        int totalMaestros = 0;
        int totalEstudiantes = 0;

        if (usersSnapshot.hasData && usersSnapshot.data != null) {
          for (var doc in usersSnapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final String rol =
                (data['rol'] ?? data['role'] ?? '').toString().toLowerCase().trim();

            if (rol == 'entrenador' || rol == 'profesor' || rol == 'maestro') {
              totalMaestros++;
            } else if (rol == 'estudiante' || rol == 'atleta' || rol == 'alumno') {
              totalEstudiantes++;
            }
          }
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('deportes').snapshots(),
          builder: (context, sportsSnapshot) {
            final int totalDeportes = sportsSnapshot.data?.docs.length ?? 0;
            final bool isLoading = !usersSnapshot.hasData;

            return Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  _kpiCard(
                    Icons.school_outlined,
                    'TOTAL MAESTROS / ENTRENADORES',
                    isLoading ? '...' : totalMaestros.toString().padLeft(2, '0'),
                    'EN VIVO',
                    Colors.green,
                    accentColor: blueDark,
                  ),
                  _kpiCard(
                    Icons.groups_outlined,
                    'TOTAL ESTUDIANTES / ATLETAS',
                    isLoading ? '...' : totalEstudiantes.toString(),
                    'EN VIVO',
                    Colors.green,
                    accentColor: orangePrimary,
                  ),
                  _kpiCard(
                    Icons.sports_soccer_outlined,
                    'DISCIPLINAS ACTIVAS',
                    !sportsSnapshot.hasData
                        ? '...'
                        : totalDeportes.toString().padLeft(2, '0'),
                    'EN VIVO',
                    Colors.green,
                    accentColor: blueDark,
                    onTap: () => setState(() => _selectedIndex = 1),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _kpiCard(
    IconData icon,
    String label,
    String value,
    String? badge,
    Color? badgeColor, {
    required Color accentColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: blueDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSportsManagementCard() {
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
            offset: const Offset(0, 4),
          )
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
                  Text(
                    'Disciplinas en Plataforma',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: blueDark,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Monitoreo general de deportes y entrenadores asignados',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
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
                    hintText: 'Buscar disciplina...',
                    hintStyle:
                        const TextStyle(fontSize: 12, color: Colors.grey),
                    prefixIcon:
                        const Icon(Icons.search, size: 18, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF3F5F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('deportes').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(30.0),
                  child: Center(
                    child: CircularProgressIndicator(color: orangePrimary),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return Container(
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
                        'No hay disciplinas registradas en la plataforma.',
                        style: TextStyle(
                          color: blueDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Haz clic en la pestaña "Disciplinas" arriba para crear la primera.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }

              final filteredDocs = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['nombre'] ?? '').toString().toLowerCase();
                final coach = (data['entrenador'] ?? '').toString().toLowerCase();
                final place = (data['lugar'] ?? '').toString().toLowerCase();

                return name.contains(_searchQuery) ||
                    coach.contains(_searchQuery) ||
                    place.contains(_searchQuery);
              }).toList();

              if (filteredDocs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(
                    child: Text(
                      'No se encontraron coincidencias con tu búsqueda.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                );
              }

              return Column(
                children: filteredDocs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final String nombre = data['nombre'] ?? 'Sin Nombre';
                  final String entrenador = data['entrenador'] ?? 'Sin Entrenador';
                  final String lugar = data['lugar'] ?? 'Instalaciones UNIMET';
                  final int atletas = (data['cuposInscritos'] ?? 0) as int;
                  final String estado = (data['estado'] ?? 'ACTIVA').toString().toUpperCase();
                  final String imageUrl = (data['imageUrl'] ?? '').toString();

                  return _sportAdminRow(
                    nombre,
                    entrenador,
                    lugar,
                    atletas,
                    estado,
                    imageUrl,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _sportAdminRow(String nombre, String entrenador, String lugar,
      int atletas, String estado, String imageUrl) {
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
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 48,
              height: 48,
              color: Colors.white,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.sports_soccer, color: blueDark, size: 22),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.sports_soccer, color: blueDark, size: 22),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: blueDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Entrenador: $entrenador  •  $lugar  •  $atletas Atletas inscritos',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            onPressed: () {
              setState(() => _selectedIndex = 1);
            },
            child: const Text(
              'EDITAR / GESTIONAR',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: blueDark,
              ),
            ),
          ),
        ],
      ),
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
          _buildAlertasReales(),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => setState(() => _selectedIndex = 5),
            child: const Text(
              'VER TODAS LAS ALERTAS >',
              style: TextStyle(
                color: orangePrimary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Avisos críticos calculados en tiempo real desde Firestore (sin textos
  /// fijos): disciplinas fuera de servicio, cupos agotados o casi llenos
  /// (>= 80 %) e inscripciones activas sin pago registrado. Las inscripciones
  /// canceladas no cuentan. Muestra como máximo 4 avisos.
  Widget _buildAlertasReales() {
    final db = FirebaseFirestore.instance;
    return StreamBuilder<QuerySnapshot>(
      stream: db.collection('deportes').snapshots(),
      builder: (context, sportsSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: db.collection('inscripciones').snapshots(),
          builder: (context, inscSnap) {
            if (!sportsSnap.hasData || !inscSnap.hasData) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Cargando avisos...',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              );
            }

            // Inscritos activos por disciplina y total sin pago
            final Map<String, int> porDeporte = {};
            int sinPago = 0;
            for (final d in inscSnap.data!.docs) {
              final m = d.data() as Map<String, dynamic>;
              if (m['estado'] == 'Cancelada') continue;
              if (m['pagado'] != true) sinPago++;
              final id = m['deporteId']?.toString();
              if (id != null) porDeporte[id] = (porDeporte[id] ?? 0) + 1;
            }

            final List<String> avisos = [];
            for (final d in sportsSnap.data!.docs) {
              final m = d.data() as Map<String, dynamic>;
              final String nombre = (m['nombre'] ?? 'Disciplina').toString();
              final String estado = (m['estado'] ?? 'Activo').toString();
              final int cupo =
                  ((m['cuposMaximos'] ?? m['cupoMaximo'] ?? 0) as num).toInt();
              final int inscritos = porDeporte[d.id] ?? 0;

              if (estado != 'Activo') {
                avisos.add('$nombre está en estado: $estado');
              } else if (cupo > 0 && inscritos >= cupo) {
                avisos.add('Cupo agotado en $nombre ($inscritos/$cupo)');
              } else if (cupo > 0 && inscritos / cupo >= 0.8) {
                avisos.add('Cupo casi lleno en $nombre ($inscritos/$cupo)');
              }
            }
            if (sinPago > 0) {
              avisos.add('$sinPago inscripción(es) activa(s) sin pago registrado');
            }

            if (avisos.isEmpty) {
              return _alertItem('Sin avisos críticos por ahora.');
            }
            return Column(
              children: [for (final a in avisos.take(4)) _alertItem(a)],
            );
          },
        );
      },
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
          const Text(
            'PRÓXIMOS EVENTOS',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: blueDark),
          ),
          const SizedBox(height: 2),
          const Text(
            'Calendario Institucional UNIMET (En vivo)',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          
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
                  child: Text(
                    'No hay eventos agendados.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                );
              }

              return Column(
                children: docs.take(4).map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final String titulo = (data['titulo'] ?? 'Evento').toString();
                  final String deporte = (data['deporte'] ?? 'General').toString();
                  final String fechaKey = (data['fechaKey'] ?? '').toString();
                  final String hora = (data['hora'] ?? '').toString();

                  String labelFecha = fechaKey;
                  if (fechaKey.length >= 10) {
                    final parts = fechaKey.split('-');
                    if (parts.length == 3) {
                      labelFecha = '${parts[2]}/${parts[1]}';
                    }
                  }

                  return _eventItem(
                    '$titulo ($deporte)',
                    '$labelFecha ${hora.isNotEmpty ? '• $hora' : ''}',
                    orangePrimary,
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 14),
          InkWell(
            onTap: () => setState(() => _selectedIndex = 4),
            child: const Text(
              'VER CALENDARIO COMPLETO',
              style: TextStyle(
                  color: blueDark, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
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
          Expanded(
            child: Row(
              children: [
                Container(width: 4, height: 16, color: tagColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: blueDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            date,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ESTADO DEL SISTEMA',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: blueDark,
                ),
              ),
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Servicios Firestore y Autenticación operando con normalidad.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: const Text(
        '© 2026 Samán Deportivo · Universidad Metropolitana',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }
}