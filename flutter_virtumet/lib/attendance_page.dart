import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

class _AttendancePageState extends State<AttendancePage> {
  static const Color orangePrimary = Color(0xFFFF5500);
  static const Color blueDark = Color(0xFF0F2C59);
  static const Color bgLight = Color(0xFFF4F6F9);

  String _searchQuery = '';
  final Map<String, String> _attendanceMap = {};
  final List<Map<String, String>> _recentActivity = [];
  bool _isSaving = false;

  String _formatFechaHoy() {
    final now = DateTime.now();
    final meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${now.day} de ${meses[now.month - 1]} de ${now.year}';
  }

  void _markAttendance(String studentId, String studentName, String status) {
    setState(() {
      _attendanceMap[studentId] = status;
      String actionText = '';
      if (status == 'presente') actionText = 'Marcado como Presente';
      if (status == 'ausente') actionText = 'Marcado como Ausente';
      if (status == 'retraso') actionText = 'Marcado con Retraso';

      _recentActivity.insert(0, {
        'nombre': studentName,
        'accion': actionText,
        'tiempo': 'HACE UN MOMENTO',
      });
    });
  }

  Future<void> _saveSession(String fechaHoy) async {
    if (_attendanceMap.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No has registrado asistencia aún.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final docRef = FirebaseFirestore.instance
          .collection('asistencias')
          .doc('${widget.deporteId}_$fechaHoy');

      await docRef.set({
        'deporteId': widget.deporteId,
        'deporteNombre': widget.deporteNombre,
        'fecha': fechaHoy,
        'actualizadoEn': FieldValue.serverTimestamp(),
        'asistencias': _attendanceMap,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Asistencia guardada exitosamente en Firestore!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar asistencia: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final String fechaHoyKey =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: blueDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'GESTIÓN DE ASISTENCIA - ${widget.deporteNombre.toUpperCase()}',
          style: const TextStyle(
            color: blueDark,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // 1. STREAM DEL DEPORTE ESPECÍFICO PARA DETALLES DE SESIÓN
        stream: FirebaseFirestore.instance
            .collection('deportes')
            .doc(widget.deporteId)
            .snapshots(),
        builder: (context, sportSnapshot) {
          final sportData =
              sportSnapshot.data?.data() as Map<String, dynamic>?;

          final String horarioReal = sportData?['horario'] ?? 'Por definir';
          final String lugarReal = sportData?['lugar'] ?? 'Instalaciones UNIMET';

          return StreamBuilder<QuerySnapshot>(
            // 2. STREAM DE INSCRIPCIONES FILTRADO POR ESTE DEPORTE
            stream: FirebaseFirestore.instance
                .collection('inscripciones')
                .where('deporteId', isEqualTo: widget.deporteId)
                .snapshots(),
            builder: (context, inscripcionesSnapshot) {
              final inscripcionesDocs =
                  inscripcionesSnapshot.data?.docs ?? [];

              return StreamBuilder<QuerySnapshot>(
                // Fallback a colección users por si los alumnos están vinculados directamente
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .snapshots(),
                builder: (context, usersSnapshot) {
                  List<Map<String, dynamic>> alumnosInscritos = [];

                  if (inscripcionesDocs.isNotEmpty) {
                    for (var doc in inscripcionesDocs) {
                      final data = doc.data() as Map<String, dynamic>;
                      alumnosInscritos.add({
                        'id': doc.id,
                        'nombre': data['nombreEstudiante'] ??
                            data['nombre'] ??
                            'Estudiante',
                        'carnet': data['carnet'] ?? data['cedula'] ?? '20260000',
                        'facultad': data['facultad'] ?? 'Ingeniería',
                        'rendimiento': data['rendimiento'] ?? '90%',
                      });
                    }
                  } else if (usersSnapshot.hasData) {
                    for (var doc in usersSnapshot.data!.docs) {
                      final uData = doc.data() as Map<String, dynamic>;
                      final String rol = (uData['rol'] ?? uData['role'] ?? '')
                          .toString()
                          .toLowerCase();
                      final String depId = (uData['deporteId'] ?? '').toString();

                      if ((rol.contains('estudiante') || rol.contains('atleta')) &&
                          depId == widget.deporteId) {
                        alumnosInscritos.add({
                          'id': doc.id,
                          'nombre': uData['nombreApellido'] ??
                              uData['nombre'] ??
                              'Estudiante',
                          'carnet': uData['carnet'] ?? '20260000',
                          'facultad': uData['facultad'] ?? 'UNIMET',
                          'rendimiento': '88%',
                        });
                      }
                    }
                  }

                  // Cálculo de métricas
                  int presentes = 0;
                  int ausentes = 0;
                  int retrasos = 0;
                  int pendientes = 0;

                  for (var alumno in alumnosInscritos) {
                    final status = _attendanceMap[alumno['id']] ?? 'pendiente';
                    if (status == 'presente') presentes++;
                    if (status == 'ausente') ausentes++;
                    if (status == 'retraso') retrasos++;
                    if (status == 'pendiente') pendientes++;
                  }

                  // Filtro por caja de búsqueda
                  final alumnosFiltrados = alumnosInscritos.where((a) {
                    final name = a['nombre'].toString().toLowerCase();
                    final carnet = a['carnet'].toString().toLowerCase();
                    return name.contains(_searchQuery) ||
                        carnet.contains(_searchQuery);
                  }).toList();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Registra la participación de hoy en ${widget.deporteNombre}',
                          style: const TextStyle(
                              fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),

                        // TARJETAS KPIS
                        Row(
                          children: [
                            _kpiStat('PRESENTES', presentes.toString(),
                                Colors.green),
                            const SizedBox(width: 16),
                            _kpiStat(
                                'AUSENTES', ausentes.toString(), Colors.red),
                            const SizedBox(width: 16),
                            _kpiStat('RETRASOS', retrasos.toString(),
                                Colors.orange),
                            const SizedBox(width: 16),
                            _kpiStat('PENDIENTES', pendientes.toString(),
                                blueDark),
                          ],
                        ),
                        const SizedBox(height: 28),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            final bool isDesktop = constraints.maxWidth > 900;
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // SECCIÓN IZQUIERDA: LISTA DE ESTUDIANTES
                                Expanded(
                                  flex: isDesktop ? 2 : 1,
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: const Color(0xFFCBD5E1)),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: SizedBox(
                                                height: 40,
                                                child: TextField(
                                                  onChanged: (v) {
                                                    setState(() {
                                                      _searchQuery =
                                                          v.toLowerCase().trim();
                                                    });
                                                  },
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        'Buscar por nombre o carnet...',
                                                    hintStyle: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey),
                                                    prefixIcon: const Icon(
                                                        Icons.search,
                                                        size: 18,
                                                        color: Colors.grey),
                                                    filled: true,
                                                    fillColor:
                                                        const Color(0xFFF3F5F8),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(10),
                                                      borderSide: BorderSide.none,
                                                    ),
                                                    contentPadding: EdgeInsets.zero,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: orangePrimary,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 18,
                                                    vertical: 14),
                                              ),
                                              onPressed: _isSaving
                                                  ? null
                                                  : () => _saveSession(
                                                      fechaHoyKey),
                                              icon: _isSaving
                                                  ? const SizedBox(
                                                      width: 14,
                                                      height: 14,
                                                      child:
                                                          CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2,
                                                      ),
                                                    )
                                                  : const Icon(Icons.save,
                                                      size: 16),
                                              label: Text(
                                                _isSaving
                                                    ? 'Guardando...'
                                                    : 'Guardar Sesión',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),

                                        if (alumnosFiltrados.isEmpty)
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(30),
                                            child: const Column(
                                              children: [
                                                Icon(
                                                  Icons.people_outline,
                                                  size: 40,
                                                  color: Colors.grey,
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  'No hay estudiantes inscritos en esta disciplina.',
                                                  style: TextStyle(
                                                      color: blueDark,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13),
                                                ),
                                              ],
                                            ),
                                          )
                                        else
                                          ...alumnosFiltrados.map((alumno) {
                                            final String id = alumno['id'];
                                            final String status =
                                                _attendanceMap[id] ?? 'pendiente';

                                            return _studentRow(
                                              id: id,
                                              nombre: alumno['nombre'],
                                              carnet: alumno['carnet'],
                                              facultad: alumno['facultad'],
                                              rendimiento: alumno['rendimiento'],
                                              currentStatus: status,
                                            );
                                          }),
                                      ],
                                    ),
                                  ),
                                ),

                                if (isDesktop) const SizedBox(width: 24),

                                // SECCIÓN DERECHA: DETALLES DE LA SESIÓN REAL
                                if (isDesktop)
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      children: [
                                        _buildSessionDetailsCard(
                                          horario: horarioReal,
                                          lugar: lugarReal,
                                        ),
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
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _kpiStat(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _studentRow({
    required String id,
    required String nombre,
    required String carnet,
    required String facultad,
    required String rendimiento,
    required String currentStatus,
  }) {
    final initials = nombre.isNotEmpty ? nombre.substring(0, 2).toUpperCase() : 'AT';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: blueDark.withValues(alpha: 0.1),
            child: Text(initials,
                style: const TextStyle(
                    color: blueDark,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: blueDark)),
                Text(carnet,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(facultad,
                style: const TextStyle(fontSize: 12, color: Colors.black87)),
          ),
          Row(
            children: [
              _statusButton(id, nombre, 'presente', Icons.check_circle_rounded,
                  Colors.green, currentStatus == 'presente'),
              const SizedBox(width: 6),
              _statusButton(id, nombre, 'ausente', Icons.cancel_rounded,
                  Colors.red, currentStatus == 'ausente'),
              const SizedBox(width: 6),
              _statusButton(id, nombre, 'retraso', Icons.watch_later_rounded,
                  Colors.orange, currentStatus == 'retraso'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusButton(String id, String name, String status, IconData icon,
      Color color, bool isActive) {
    return InkWell(
      onTap: () => _markAttendance(id, name, status),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 18, color: isActive ? Colors.white : color),
      ),
    );
  }

  Widget _buildSessionDetailsCard({
    required String horario,
    required String lugar,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Detalles de Sesión',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15, color: blueDark)),
          const Divider(height: 20),
          _detailItem('Fecha', _formatFechaHoy()),
          _detailItem('Horario', horario),
          _detailItem('Lugar', lugar),
          _detailItem('Estado', 'En Curso', isBadge: true),
        ],
      ),
    );
  }

  Widget _detailItem(String label, String value, {bool isBadge = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          if (isBadge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
              ),
            )
          else
            Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: blueDark)),
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
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Actividad Reciente',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15, color: blueDark)),
          const SizedBox(height: 12),
          if (_recentActivity.isEmpty)
            const Text(
              'No se han registrado marcas en esta sesión.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            )
          else
            ..._recentActivity.take(4).map((act) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(act['nombre']!,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: blueDark)),
                          Text(act['accion']!,
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                      Text(act['tiempo']!,
                          style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: orangePrimary)),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}