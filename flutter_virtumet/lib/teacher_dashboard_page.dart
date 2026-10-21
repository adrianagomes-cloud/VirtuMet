import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const _navy = Color(0xFF0F2C59);
const _orange = Color(0xFFFF5A1F);
const _background = Color(0xFFF4F7FC);
const _muted = Color(0xFF71809A);

class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  final _searchController = TextEditingController();
  String _search = '';
  Map<String, dynamic> _teacherData = {};

  final _sessions = const [
    _Session(
      title: 'Fútbol Sala Varonil',
      time: '14:00 - 16:00',
      place: 'Cancha Techada 1',
      students: '22 Inscritos',
      active: true,
    ),
    _Session(
      title: 'Entrenamiento Funcional',
      time: '16:30 - 17:30',
      place: 'Gimnasio UNIMET',
      students: '15 Inscritos',
    ),
    _Session(
      title: 'Baloncesto Varonil',
      time: '18:00 - 20:00',
      place: 'Cancha Techada 2',
      students: '18 Inscritos',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!mounted || !snapshot.exists) return;
    setState(() => _teacherData = snapshot.data() ?? {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 760;
    final filtered = _sessions
        .where((session) => session.title.toLowerCase().contains(_search))
        .toList();

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              compact: compact,
              onProfile: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TeacherProfilePage(data: _teacherData),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  compact ? 16 : 48,
                  24,
                  compact ? 16 : 48,
                  36,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroCard(compact: compact),
                        const SizedBox(height: 24),
                        _StatsGrid(compact: compact),
                        const SizedBox(height: 28),
                        if (compact)
                          Column(
                            children: [
                              _SessionsSection(
                                sessions: filtered,
                                searchController: _searchController,
                                onSearch: (value) => setState(
                                  () => _search = value.toLowerCase(),
                                ),
                                onAttendance: _showAttendance,
                              ),
                              const SizedBox(height: 20),
                              const _AlertsCard(),
                              const SizedBox(height: 20),
                              const _EventsCard(),
                            ],
                          )
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: _SessionsSection(
                                  sessions: filtered,
                                  searchController: _searchController,
                                  onSearch: (value) => setState(
                                    () => _search = value.toLowerCase(),
                                  ),
                                  onAttendance: _showAttendance,
                                ),
                              ),
                              const SizedBox(width: 20),
                              const Expanded(flex: 2, child: _AlertsCard()),
                            ],
                          ),
                        const SizedBox(height: 28),
                        _RecentStudents(compact: compact),
                        const SizedBox(height: 22),
                        if (!compact)
                          Row(
                            children: const [
                              Expanded(child: _EventsCard()),
                              SizedBox(width: 20),
                              Expanded(child: _WeeklyCard()),
                            ],
                          )
                        else
                          const _WeeklyCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const _Footer(),
          ],
        ),
      ),
    );
  }

  void _showAttendance(_Session session) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Pasar asistencia',
          style: TextStyle(color: _navy, fontWeight: FontWeight.w800),
        ),
        content: Text('¿Deseas abrir la asistencia de ${session.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _orange),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text('Sesión de ${session.title} preparada.'),
                ),
              );
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.compact, required this.onProfile});
  final bool compact;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFDCE3EE))),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: _navy,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sports_soccer,
              color: Colors.white,
              size: 19,
            ),
          ),
          const SizedBox(width: 9),
          const Text(
            'VirtuMet',
            style: TextStyle(
              color: _navy,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 25),
            _NavItem(label: 'Catálogo', active: true),
            const _NavItem(label: 'Mis Inscripciones'),
            const _NavItem(label: 'Anuncios'),
            const _NavItem(label: 'Comunidad'),
          ],
          const Spacer(),
          if (!compact)
            const Text(
              'Entrenador',
              style: TextStyle(
                color: _navy,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(width: 16),
          IconButton(
            tooltip: 'Notificaciones',
            onPressed: () {},
            icon: const Icon(Icons.notifications_none, color: _navy),
          ),
          InkWell(
            onTap: onProfile,
            borderRadius: BorderRadius.circular(22),
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFD9E2F1),
              child: Icon(Icons.person, color: _navy),
            ),
          ),
          const SizedBox(width: 8),
          if (!compact)
            const Icon(Icons.keyboard_arrow_down, color: _muted, size: 18),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.label, this.active = false});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: active ? _orange : Colors.transparent,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : _muted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 180),
      padding: EdgeInsets.all(compact ? 24 : 30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(colors: [_navy, Color(0xFF284F78)]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'PANEL DE INSTRUCTOR',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              children: [
                TextSpan(
                  text: '¡HOLA DE NUEVO, ',
                  style: TextStyle(color: Color(0xFFFFFFFF)),
                ),
                TextSpan(
                  text: 'ENTRENADOR!',
                  style: TextStyle(color: Color(0xFFFF9670)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tienes 3 sesiones programadas para hoy. El clima es ideal para la práctica en campo abierto.',
            style: TextStyle(
              color: Color(0xFFDDE7F3),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: _orange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                ),
                icon: const Icon(Icons.play_arrow, size: 16),
                label: const Text('Iniciar Sesión Actual'),
              ),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0x7799B4D2)),
                ),
                child: const Text('Ver Horario Completo'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const stats = [
      ('TOTAL ATLETAS', '142', '+12%', Icons.groups_outlined),
      ('ASISTENCIA PROM.', '88%', '+3%', Icons.assignment_turned_in_outlined),
      ('SESIONES HOY', '03', '', Icons.calendar_today_outlined),
      ('KILÓMETROS REC.', '12.4K', '+5%', Icons.route_outlined),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: compact ? 2 : 4,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: compact ? 1.7 : 2.5,
      ),
      itemBuilder: (_, index) {
        final stat = stats[index];
        return _Panel(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(stat.$4, color: _navy, size: 20),
                  const Spacer(),
                  if (stat.$3.isNotEmpty)
                    Text(
                      '↗ ${stat.$3}',
                      style: const TextStyle(
                        color: Color(0xFF0FA77A),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                stat.$1,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stat.$2,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SessionsSection extends StatelessWidget {
  const _SessionsSection({
    required this.sessions,
    required this.searchController,
    required this.onSearch,
    required this.onAttendance,
  });
  final List<_Session> sessions;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final ValueChanged<_Session> onAttendance;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sesiones de Hoy',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Viernes, 25 de Octubre',
                  style: TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: 180,
              height: 36,
              child: TextField(
                controller: searchController,
                onChanged: onSearch,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, size: 17),
                  hintText: 'Buscar grupo...',
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...sessions.map(
          (session) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SessionTile(
              session: session,
              onAttendance: () => onAttendance(session),
            ),
          ),
        ),
        InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(7),
          child: Container(
            height: 92,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFFBFCBDB),
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_month_outlined, color: _navy, size: 20),
                SizedBox(height: 8),
                Text(
                  'PROGRAMAR NUEVA SESIÓN',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.onAttendance});
  final _Session session;
  final VoidCallback onAttendance;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(
            session.active ? Icons.schedule : Icons.calendar_today_outlined,
            color: session.active ? _orange : _navy,
            size: 21,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        session.title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _navy,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (session.active) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEEE8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'EN CURSO',
                          style: TextStyle(
                            color: _orange,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '${session.time}   •   ${session.place}   •   ${session.students}',
                  style: const TextStyle(color: _muted, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onAttendance,
            style: OutlinedButton.styleFrom(
              foregroundColor: session.active ? Colors.white : _navy,
              backgroundColor: session.active ? _orange : Colors.transparent,
              side: BorderSide(
                color: session.active ? _orange : const Color(0xFFB7C7DD),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            ),
            icon: const Icon(Icons.fact_check_outlined, size: 14),
            label: const Text(
              'PASAR ASISTENCIA',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 5),
          const Icon(Icons.more_vert, color: _muted, size: 18),
        ],
      ),
    );
  }
}

class _AlertsCard extends StatelessWidget {
  const _AlertsCard();
  @override
  Widget build(BuildContext context) => Container(
    height: 310,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _navy,
      borderRadius: BorderRadius.circular(7),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFFFF9670), size: 17),
            SizedBox(width: 7),
            Text(
              'AVISOS CRÍTICOS',
              style: TextStyle(
                color: Color(0xFFFF9670),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        ...[
          'Ficha médica vencida: Juan Pérez',
          'Solicitud de cambio de horario: Voleibol',
          'Mantenimiento Cancha 1: Mañana 08:00',
        ].map(
          (text) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF274A78),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.circle, color: _orange, size: 6),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        const Text(
          'VER TODAS LAS ALERTAS   ›',
          style: TextStyle(
            color: Color(0xFFFF9670),
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _RecentStudents extends StatelessWidget {
  const _RecentStudents({required this.compact});
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final names = ['RICARDO MENDEZ', 'GABRIELA SOTO', 'LUIS NAVARRO'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actividad Reciente de Estudiantes',
          style: TextStyle(
            color: _navy,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: names.map((name) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: name == names.last ? 0 : 12),
                child: _Panel(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 15,
                        backgroundColor: Color(0xFFD9E2F1),
                        child: Icon(Icons.person, color: _navy, size: 17),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _navy,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Text(
                              'Marcó asistencia',
                              style: TextStyle(color: _muted, fontSize: 8),
                            ),
                            const Text(
                              'Hace 10 min',
                              style: TextStyle(color: _orange, fontSize: 8),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _EventsCard extends StatelessWidget {
  const _EventsCard();
  @override
  Widget build(BuildContext context) => _Panel(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PRÓXIMOS EVENTOS',
          style: TextStyle(
            color: _navy,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Text(
          'Calendario institucional',
          style: TextStyle(color: _muted, fontSize: 10),
        ),
        const SizedBox(height: 14),
        const _EventLine(
          color: Color(0xFF0FA77A),
          label: 'Torneo Inter-Facultades',
          date: 'OCT 28',
        ),
        const _EventLine(
          color: _orange,
          label: 'Cierre de Inscripciones',
          date: 'NOV 02',
        ),
        const _EventLine(
          color: Colors.lightBlue,
          label: 'Exhibición de Natación',
          date: 'NOV 05',
        ),
        const Divider(height: 22),
        const Center(
          child: Text(
            'VER CALENDARIO COMPLETO',
            style: TextStyle(
              color: _navy,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class _EventLine extends StatelessWidget {
  const _EventLine({
    required this.color,
    required this.label,
    required this.date,
  });
  final Color color;
  final String label;
  final String date;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Container(width: 20, height: 3, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: _navy,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(date, style: const TextStyle(color: _muted, fontSize: 9)),
      ],
    ),
  );
}

class _WeeklyCard extends StatelessWidget {
  const _WeeklyCard();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _navy,
      borderRadius: BorderRadius.circular(7),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RENDIMIENTO SEMANAL',
          style: TextStyle(
            color: Color(0xFFFF9670),
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Row(
          children: [
            Text(
              '92%',
              style: TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(width: 9),
            Text(
              'Meta alcanzada',
              style: TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: const LinearProgressIndicator(
            value: .92,
            minHeight: 5,
            backgroundColor: Color(0xFF35537B),
            color: _orange,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Has completado 12 de las 13 sesiones programadas esta semana.',
          style: TextStyle(color: Colors.white70, fontSize: 9),
        ),
      ],
    ),
  );
}

class _Footer extends StatelessWidget {
  const _Footer();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
    color: Colors.white,
    child: const Row(
      children: [
        Icon(Icons.sports_soccer, color: _navy, size: 18),
        SizedBox(width: 8),
        Text(
          'VirtuMet Platform',
          style: TextStyle(
            color: _navy,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
        Spacer(),
        Text(
          'CENTRO DE AYUDA      REPORTAR INCIDENCIA      PRIVACIDAD DOCENTE      SOPORTE IT',
          style: TextStyle(color: _muted, fontSize: 8),
        ),
      ],
    ),
  );
}

class TeacherProfilePage extends StatelessWidget {
  const TeacherProfilePage({super.key, required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        elevation: 0,
        title: const Text(
          'Perfil del maestro',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar perfil'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(compact ? 18 : 48),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1050),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileHeader(compact: compact, data: data),
                const SizedBox(height: 20),
                if (compact) ...[
                  _ProfileDetails(data: data),
                  const SizedBox(height: 20),
                  _ProfileActivity(data: data),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _ProfileDetails(data: data)),
                      SizedBox(width: 20),
                      Expanded(flex: 2, child: _ProfileActivity(data: data)),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.compact, required this.data});
  final bool compact;
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(compact ? 22 : 30),
    decoration: BoxDecoration(
      color: _navy,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        const CircleAvatar(
          radius: 42,
          backgroundColor: Color(0xFFD9E2F1),
          child: Icon(Icons.person, color: _navy, size: 46),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _value(data, 'nombreApellido'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'Entrenador institucional  •  ${_value(data, 'disciplinaExperiencia')}',
                style: const TextStyle(color: Color(0xFFDDE7F3), fontSize: 13),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.verified_outlined,
                    color: Color(0xFF7DE0BB),
                    size: 16,
                  ),
                  SizedBox(width: 5),
                  Text(
                    data['estadoValidacion'] == 'Pendiente'
                        ? 'Perfil pendiente de validación'
                        : 'Perfil verificado por UNIMET',
                    style: const TextStyle(
                      color: Color(0xFF7DE0BB),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ProfileDetails extends StatelessWidget {
  const _ProfileDetails({required this.data});
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) => _Panel(
    padding: const EdgeInsets.all(22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información personal',
          style: TextStyle(
            color: _navy,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 18),
        _InfoRow(
          icon: Icons.email_outlined,
          label: 'Correo institucional',
          value: _value(data, 'correo'),
        ),
        _InfoRow(
          icon: Icons.sports_soccer_outlined,
          label: 'Disciplina y experiencia',
          value: _value(data, 'disciplinaExperiencia'),
        ),
        _InfoRow(
          icon: Icons.verified_outlined,
          label: 'Certificación',
          value: _value(data, 'certificacion'),
        ),
        _InfoRow(
          icon: Icons.fact_check_outlined,
          label: 'Estado de validación',
          value: _value(data, 'estadoValidacion'),
        ),
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 12),
        const Text(
          'Certificaciones y especialidades',
          style: TextStyle(
            color: _navy,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Chip(
          label: Text(_value(data, 'certificacion')),
          labelStyle: const TextStyle(color: _navy, fontSize: 11),
          backgroundColor: const Color(0xFFEAF0F8),
          side: BorderSide.none,
        ),
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        Icon(icon, color: _orange, size: 19),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: _muted, fontSize: 11),
          ),
        ),
        Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: _navy,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _ProfileActivity extends StatelessWidget {
  const _ProfileActivity({required this.data});
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) => _Panel(
    padding: const EdgeInsets.all(22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen del maestro',
          style: TextStyle(
            color: _navy,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 18),
        const _SummaryMetric(
          label: 'Atletas a cargo',
          value: '142',
          icon: Icons.groups_outlined,
        ),
        const _SummaryMetric(
          label: 'Sesiones completadas',
          value: '128',
          icon: Icons.check_circle_outline,
        ),
        const _SummaryMetric(
          label: 'Asistencia promedio',
          value: '88%',
          icon: Icons.trending_up,
        ),
        const Divider(height: 28),
        const Text(
          'Estado de cuenta',
          style: TextStyle(
            color: _navy,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: data['estadoValidacion'] == 'Pendiente'
                ? const Color(0xFFFFF4DD)
                : const Color(0xFFE8F8F1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                data['estadoValidacion'] == 'Pendiente'
                    ? Icons.schedule
                    : Icons.check_circle,
                color: data['estadoValidacion'] == 'Pendiente'
                    ? Colors.orange
                    : const Color(0xFF0FA77A),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data['estadoValidacion'] == 'Pendiente'
                      ? 'Documentación pendiente de validación'
                      : 'Documentación vigente y completa',
                  style: TextStyle(
                    color: data['estadoValidacion'] == 'Pendiente'
                        ? Colors.orange.shade800
                        : const Color(0xFF087D5C),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Row(
      children: [
        Icon(icon, color: _orange, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: _muted, fontSize: 11),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: _navy,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

String _value(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value == null || value.toString().trim().isEmpty) {
    return 'No registrado';
  }
  return value.toString();
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: const Color(0xFFE0E7F0)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x080F2C59),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );
}

class _Session {
  const _Session({
    required this.title,
    required this.time,
    required this.place,
    required this.students,
    this.active = false,
  });
  final String title;
  final String time;
  final String place;
  final String students;
  final bool active;
}
