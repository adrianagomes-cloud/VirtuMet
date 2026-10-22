import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AttendancePage extends StatefulWidget {
  final String deporteId;
  final String deporteNombre;

  const AttendancePage({
    super.key,
    required this.deporteId,
    required this.deporteNombre,
  });

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

enum AttendanceStatus { presente, ausente, retraso, pendiente }

class StudentAttendanceItem {
  final String uid;
  final String nombre;
  final String carnet;
  final String facultad;
  final int rendimiento;
  AttendanceStatus estado;

  StudentAttendanceItem({
    required this.uid,
    required this.nombre,
    required this.carnet,
    required this.facultad,
    required this.rendimiento,
    this.estado = AttendanceStatus.pendiente,
  });
}

class _AttendancePageState extends State<AttendancePage> {
  // Colores corporativos VirtuMet
  static const Color orangePrimary = Color(0xFFFF5500);
  static const Color blueDark = Color(0xFF0F2C59);
  static const Color navyHeader = Color(0xFF0A192F);
  static const Color bgLight = Color(0xFFF4F6F9);

  String _searchQuery = '';
  bool _isSaving = false;

  final List<Map<String, String>> _recentActivities = [
    {
      'nombre': 'Daniel Herrera',
      'accion': 'Marcado como Presente',
      'tiempo': 'HACE 1 MIN'
    },
    {
      'nombre': 'Valentina Pérez',
      'accion': 'Marcado como Presente',
      'tiempo': 'HACE 5 MIN'
    },
    {
      'nombre': 'Mateo González',
      'accion': 'Marcado con Retraso',
      'tiempo': 'HACE 12 MIN'
    },
  ];

  late List<StudentAttendanceItem> _students;

  @override
  void initState() {
    super.initState();
    _students = [
      StudentAttendanceItem(
        uid: 'st_1',
        nombre: 'Alejandro Rodriguez',
        carnet: '202110452',
        facultad: 'Ingeniería',
        rendimiento: 95,
      ),
      StudentAttendanceItem(
        uid: 'st_2',
        nombre: 'Sofia Valenzuela',
        carnet: '202218891',
        facultad: 'Derecho',
        rendimiento: 88,
      ),
      StudentAttendanceItem(
        uid: 'st_3',
        nombre: 'Mateo González',
        carnet: '202018123',
        facultad: 'Ciencias Económicas',
        rendimiento: 72,
      ),
      StudentAttendanceItem(
        uid: 'st_4',
        nombre: 'Valentina Pérez',
        carnet: '202310555',
        facultad: 'Estudios Liberales',
        rendimiento: 100,
      ),
      StudentAttendanceItem(
        uid: 'st_5',
        nombre: 'Daniel Herrera',
        carnet: '202118678',
        facultad: 'Psicología',
        rendimiento: 82,
      ),
    ];
  }

  // Métricas calculadas dinámicamente
  int get countPresentes =>
      _students.where((s) => s.estado == AttendanceStatus.presente).length;
  int get countAusentes =>
      _students.where((s) => s.estado == AttendanceStatus.ausente).length;
  int get countRetrasos =>
      _students.where((s) => s.estado == AttendanceStatus.retraso).length;
  int get countPendientes =>
      _students.where((s) => s.estado == AttendanceStatus.pendiente).length;

  void _updateStudentStatus(
      StudentAttendanceItem student, AttendanceStatus newStatus) {
    setState(() {
      student.estado = newStatus;

      String actionText = '';
      if (newStatus == AttendanceStatus.presente) {
        actionText = 'Marcado como Presente';
      } else if (newStatus == AttendanceStatus.ausente) {
        actionText = 'Marcado como Ausente';
      } else if (newStatus == AttendanceStatus.retraso) {
        actionText = 'Marcado con Retraso';
      }

      if (actionText.isNotEmpty) {
        _recentActivities.insert(0, {
          'nombre': student.nombre,
          'accion': actionText,
          'tiempo': 'AHORA',
        });
      }
    });
  }

  Future<void> _saveAttendance() async {
    setState(() => _isSaving = true);

    try {
      final DateTime now = DateTime.now();
      final String fechaHoy =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final String? entrenadorUid = FirebaseAuth.instance.currentUser?.uid;

      final batch = FirebaseFirestore.instance.batch();

      for (var student in _students) {
        final ref = FirebaseFirestore.instance
            .collection('asistencias')
            .doc('${widget.deporteId}_${student.uid}_$fechaHoy');

        batch.set(
          ref,
          {
            'deporteId': widget.deporteId,
            'deporteNombre': widget.deporteNombre,
            'entrenadorUid': entrenadorUid,
            'estudianteUid': student.uid,
            'estudianteNombre': student.nombre,
            'estudianteCarnet': student.carnet,
            'fecha': fechaHoy,
            'estado': student.estado.name,
            'timestamp': Timestamp.now(),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      if (!mounted) return;

      setState(() {
        _recentActivities.insert(0, {
          'nombre': 'Sesión Finalizada',
          'accion': 'Asistencia guardada en Firestore',
          'tiempo': 'AHORA',
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '¡Asistencia guardada exitosamente! Puedes regresar al dashboard cuando gustes.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar asistencia: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredStudents = _students.where((student) {
      final query = _searchQuery.toLowerCase();
      return student.nombre.toLowerCase().contains(query) ||
          student.carnet.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: bgLight,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTopNavbar(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 16, color: blueDark),
                    label: const Text(
                      'VOLVER AL DASHBOARD',
                      style: TextStyle(
                        color: blueDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'GESTIÓN DE ASISTENCIA',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: blueDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Registra la participación de hoy en ${widget.deporteNombre} - Sección A',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: _kpiMetricCard(
                            'PRESENTES', countPresentes.toString(), Colors.green),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _kpiMetricCard(
                            'AUSENTES', countAusentes.toString(), Colors.red),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _kpiMetricCard(
                            'RETRASOS', countRetrasos.toString(), Colors.amber.shade800),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _kpiMetricCard(
                            'PENDIENTES', countPendientes.toString(), blueDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final bool isDesktop = constraints.maxWidth > 900;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: isDesktop ? 3 : 1,
                            child: _buildStudentTableCard(filteredStudents),
                          ),
                          if (isDesktop) const SizedBox(width: 24),
                          if (isDesktop)
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  _buildSessionDetailsCard(),
                                  const SizedBox(height: 20),
                                  _buildRecentActivityCard(),
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

            // PIE DE PÁGINA CENTRADO
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavbar() {
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
                  child: const Icon(Icons.fitness_center,
                      color: Colors.white, size: 18),
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
            color: blueDark, fontWeight: FontWeight.w500, fontSize: 13),
      ),
    );
  }

  Widget _kpiMetricCard(String label, String count, Color color) {
    return Container(
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
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentTableCard(List<StudentAttendanceItem> students) {
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
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o carnet...',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      filled: true,
                      fillColor: const Color(0xFFF3F5F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {},
                icon: const Icon(Icons.filter_list, size: 16, color: blueDark),
                label: const Text('Filtros',
                    style: TextStyle(color: blueDark, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {},
                child: const Text('Exportar Reporte',
                    style: TextStyle(color: blueDark, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangePrimary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isSaving ? null : _saveAttendance,
                child: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Guardar Sesión',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1.8),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                children: [
                  _tableHeader('ESTUDIANTE'),
                  _tableHeader('FACULTAD'),
                  _tableHeader('RENDIMIENTO'),
                  _tableHeader('ASISTENCIA', alignRight: true),
                ],
              ),
              ...students.map((student) {
                return TableRow(
                  decoration: const BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: blueDark.withValues(alpha: 0.1),
                            child: Text(
                              _getInitials(student.nombre),
                              style: const TextStyle(
                                  color: blueDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.nombre,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: blueDark),
                              ),
                              Text(
                                student.carnet,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      student.facultad,
                      style: const TextStyle(fontSize: 12, color: blueDark),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: student.rendimiento / 100,
                              backgroundColor: Colors.grey.shade200,
                              color: Colors.green,
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${student.rendimiento}%',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _statusIconButton(
                          icon: Icons.check,
                          color: Colors.green,
                          isSelected:
                              student.estado == AttendanceStatus.presente,
                          onTap: () => _updateStudentStatus(
                              student, AttendanceStatus.presente),
                        ),
                        const SizedBox(width: 6),
                        _statusIconButton(
                          icon: Icons.close,
                          color: Colors.red,
                          isSelected: student.estado == AttendanceStatus.ausente,
                          onTap: () => _updateStudentStatus(
                              student, AttendanceStatus.ausente),
                        ),
                        const SizedBox(width: 6),
                        _statusIconButton(
                          icon: Icons.access_time_filled,
                          color: Colors.amber.shade700,
                          isSelected: student.estado == AttendanceStatus.retraso,
                          onTap: () => _updateStudentStatus(
                              student, AttendanceStatus.retraso),
                        ),
                      ],
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(String text, {bool alignRight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _statusIconButton({
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected ? Colors.white : color,
        ),
      ),
    );
  }

  Widget _buildSessionDetailsCard() {
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
          const Text(
            'Detalles de Sesión',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: blueDark),
          ),
          const Divider(height: 20),
          _detailRow('Fecha', '25 de octubre de 2026'),
          _detailRow('Horario', '14:00 - 16:00'),
          _detailRow('Lugar', 'Cancha Techada 2'),
          _detailRow('Estado', 'En Curso', isTag: true),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: blueDark.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Recuerda que el cierre de sesión es automático a las 16:15. Asegúrate de guardar los cambios antes de salir.',
              style: TextStyle(fontSize: 11, color: blueDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isTag = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          if (!isTag)
            Text(value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold, color: blueDark))
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                value,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard() {
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
          const Text(
            'Actividad Reciente',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: blueDark),
          ),
          const SizedBox(height: 14),
          ..._recentActivities.map(
            (item) => _recentActivityItem(
              item['nombre']!,
              item['accion']!,
              item['tiempo']!,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Ver Historial Completo >',
            style: TextStyle(
                color: orangePrimary,
                fontSize: 11,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _recentActivityItem(String name, String action, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 12, color: blueDark)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(action,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(time,
                  style: const TextStyle(
                      fontSize: 9,
                      color: orangePrimary,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 12),
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
              // 1. LADO IZQUIERDO: Logo y Descripción
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

              // 2. CENTRO: Columna de Asistencia
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

              // ESPACIADOR DERECHO (Garantiza el centrado exacto)
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

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'A';
  }
}