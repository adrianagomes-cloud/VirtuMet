import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'admin_sports_view.dart';
import 'admin_users_view.dart';
import 'admin_fichas_view.dart';
import 'admin_stats_view.dart';
import 'admin_events_view.dart';
import 'reviews_management_view.dart'; 

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  
  int _selectedIndex = 0;
  final String _searchQuery = '';

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
      body: Column(
        children: [
          _buildTopNavbar(context, adminEmail),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
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
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height - 100,
                      child: AdminReviewsView(),
                    ),
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
                ],
              ),
            ),
          ),
        ],
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
              errorBuilder: (_, _, _) => const Row(
                children: [
                  Icon(Icons.fitness_center, color: blueDark, size: 22),
                  SizedBox(width: 8),
                  Text(
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
          _navLink('Reseñas', targetIndex: 6),

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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid() => Container();
  Widget _buildSportsManagementCard() => Container();
  Widget _buildCriticalAlertsCard() => Container();
  Widget _buildUpcomingEventsCard() => Container();
}