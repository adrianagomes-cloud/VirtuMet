import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'admin_sports_view.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  
  // Índice para controlar la sección activa:
  // 0: Resumen / Inicio
  // 1: Disciplinas (AdminSportsView)
  // 2: Usuarios
  // 3: Fichas e Inscripciones
  // 4: Eventos
  // 5: Reportes y Avisos
  int _selectedIndex = 0;
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
            // BARRA SUPERIOR (NAVBAR) GLOBAL
            _buildTopNavbar(context, adminEmail),

            // CONTENIDO DINÁMICO SEGÚN LA PESTAÑA SELECCIONADA
            if (_selectedIndex == 1) ...[
              // VISTA COMPLETA DE GESTIÓN DE DISCIPLINAS
              const AdminSportsView(),
            ] else ...[
              // VISTA PRINCIPAL (RESUMEN / DASHBOARD HOME)
              _buildHeroBanner(nombreAdmin),

              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // MÉTRICAS / KPIS EN TIEMPO REAL
                    _buildKpiGrid(),
                    const SizedBox(height: 32),

                    // DISPOSICIÓN PRINCIPAL EN GRID
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final bool isDesktop = constraints.maxWidth > 900;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // SECCIÓN IZQUIERDA: RESUMEN RÁPIDO DE DISCIPLINAS EN TIEMPO REAL
                            Expanded(
                              flex: isDesktop ? 2 : 1,
                              child: _buildSportsManagementCard(),
                            ),
                            if (isDesktop) const SizedBox(width: 28),

                            // SECCIÓN DERECHA: ALERTAS Y ESTADO
                            if (isDesktop)
                              Expanded(
                                flex: 1,
                                child: Column(
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

            // PIE DE PÁGINA INSTITUCIONAL GLOBAL
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. BARRA SUPERIOR (NAVBAR)
  // ===========================================================================
  Widget _buildTopNavbar(BuildContext context, String email) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
      color: Colors.white,
      child: Row(
        children: [
          // LOGO DE VIRTUMET (AL HACER CLIC REGRESA AL INICIO)
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

          // ENLACES DE NAVEGACIÓN
          _navLink('Disciplinas', targetIndex: 1),
          _navLink('Usuarios', targetIndex: 2),
          _navLink('Fichas e Inscripciones', targetIndex: 3),
          _navLink('Eventos', targetIndex: 4),
          _navLink('Reportes y Avisos', targetIndex: 5),

          const Spacer(),

          // USUARIO Y CERRAR SESIÓN
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

  // ===========================================================================
  // 2. HERO BANNER
  // ===========================================================================
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

  // ===========================================================================
  // 3. TARJETAS KPI DE MÉTRICAS EN TIEMPO REAL (FIRESTORE)
  // ===========================================================================
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

  // ===========================================================================
  // 4. LISTA PRINCIPAL (100% FIRESTORE SIN MOCK NI DEFAULT DATA)
  // ===========================================================================
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

          // STREAMBUILDER CONECTADO DIRECTAMENTE A FIRESTORE
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

              // Si la colección de Firestore está vacía
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

              // Filtro dinámico por texto de búsqueda
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

                  return _sportAdminRow(
                    nombre,
                    entrenador,
                    lugar,
                    atletas,
                    estado,
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
      int atletas, String estado) {
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
            child: const Icon(Icons.sports_soccer, color: blueDark, size: 22),
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

  // ===========================================================================
  // 5. TARJETAS LATERALES
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
          _alertItem('Revisión urgente de ficha: Estudiante V-28123456'),
          _alertItem('Solicitud de cancha techada pendiente por aprobar'),
          const SizedBox(height: 14),
          const Text(
            'VER TODAS LAS ALERTAS >',
            style: TextStyle(
              color: orangePrimary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
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
            'Calendario Institucional UNIMET',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          _eventItem('Torneo Inter-Facultades', 'OCT 28', Colors.green),
          _eventItem('Cierre de Inscripciones', 'NOV 02', orangePrimary),
          _eventItem('Exhibición de Natación', 'NOV 05', Colors.blue),
          const SizedBox(height: 14),
          const Text(
            'VER CALENDARIO COMPLETO',
            style: TextStyle(
                color: blueDark, fontSize: 11, fontWeight: FontWeight.bold),
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
          Row(
            children: [
              Container(width: 4, height: 16, color: tagColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: blueDark,
                ),
              ),
            ],
          ),
          Text(
            date,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatusCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: navyHeader,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ESTADO DEL SISTEMA',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Text(
                '99.9%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Operativo',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Servicios de Firebase Auth y Firestore sincronizados correctamente.',
            style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 6. PIE DE PÁGINA
  // ===========================================================================
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
                          'SOPORTE ADMINISTRATIVO',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _footerLinkItem('Manual de Administrador'),
                        _footerLinkItem('Auditoría del Sistema'),
                        _footerLinkItem('Contacto DIDE'),
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