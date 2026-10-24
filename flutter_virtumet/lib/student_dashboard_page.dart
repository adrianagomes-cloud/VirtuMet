import 'package:flutter/material.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({Key? key}) : super(key: key);

  @override
  _StudentDashboardPageState createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  final Color blueDark = const Color(0xFF1B2A47);
  final Color orangePrimary = const Color(0xFFF0652B);
  final Color bgLight = const Color(0xFFF8F9FA);
  final Color textGrey = const Color(0xFF6C757D);

  BoxDecoration get cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: Column(
        children: [
          _buildTopNavigationBar(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroBanner(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsRow(),
                        const SizedBox(height: 32),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildMainContent(),
                            ),
                            const SizedBox(width: 32),
                            Expanded(
                              flex: 1,
                              child: _buildRightSidebar(),
                            ),
                          ],
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
        ],
      ),
    );
  }

  Widget _buildTopNavigationBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
        
        Image.asset(
          'lib/assets/Logo.png',
          height: 40, 
        ),
          const SizedBox(width: 48),
          
          _navLink('Inicio', isSelected: true),
          _navLink('Catálogo Deportivo'),
          _navLink('Mis Actividades'),
          _navLink('Comunidad'),
          const Spacer(),
          
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: orangePrimary.withValues(alpha: 0.2),
                child: Text('AM', style: TextStyle(color: orangePrimary, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Text('Andrea Méndez', style: TextStyle(color: blueDark, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 24),
              IconButton(
                icon: const Icon(Icons.logout, size: 20),
                color: textGrey,
                onPressed: () {
                  
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navLink(String title, {bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: TextStyle(
          color: isSelected ? blueDark : textGrey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 64),
      decoration: BoxDecoration(
        color: blueDark,
        image: DecorationImage(
          image: const NetworkImage('https://images.unsplash.com/photo-1546519638-68e109498ffc?q=80&w=1200'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.5), BlendMode.darken),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: orangePrimary, borderRadius: BorderRadius.circular(20)),
            child: const Text('PORTAL DE ESTUDIANTE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
          const SizedBox(height: 16),
          const Text('¡BUENAS TARDES, ANDREA!', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Tienes 1 actividad programada para hoy. Revisa tu agenda y prepárate para entrenar.', style: TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 24),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangePrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Explorar Catálogo →', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Ver Mis Actividades'),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _statCard('DISCIPLINAS INSCRITAS', '03', Icons.people_outline, isLive: true),
        const SizedBox(width: 24),
        _statCard('ACTIVIDADES HOY', '01', Icons.calendar_today_outlined, isLive: true),
        const SizedBox(width: 24),
        _statCard('PRÓXIMOS EVENTOS', '05', Icons.emoji_events_outlined),
        const SizedBox(width: 24),
        _statCard('PORCENTAJE ASISTENCIA', '92%', Icons.show_chart),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, {bool isLive = false}) {
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                    child: const Text('ACTIVO', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(title, style: TextStyle(color: textGrey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: blueDark, fontSize: 32, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tu próxima actividad', style: TextStyle(color: blueDark, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Disciplinas asignadas en el sistema', style: TextStyle(color: textGrey, fontSize: 13)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: cardDecoration,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: bgLight, borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.sports_soccer, color: blueDark, size: 32),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fútbol sala', style: TextStyle(color: blueDark, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Hoy · 5:30-7:00 PM · Cancha techada', style: TextStyle(color: textGrey, fontSize: 13)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangePrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Ver detalles', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
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
          Row(
            children: [
              const Icon(Icons.campaign_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('AVISOS CRÍTICOS', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 24),
          _alertItem('Inscripciones de voleibol cierran mañana'),
          const SizedBox(height: 16),
          _alertItem('Mantenimiento Cancha 1: Mañana 08:00'),
          const SizedBox(height: 32),
          const Text('VER TODAS LAS ALERTAS >', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
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
          child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Text('© 2025 VirtuMet · Bienestar y deporte universitario', style: TextStyle(color: textGrey, fontSize: 12)),
    );
  }
}