import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_common.dart';

/// Reportes del administrador: indicadores y gráficos de barras (widgets
/// nativos, sin dependencias nuevas). "Más buscados" = disciplinas con más
/// inscripciones no canceladas. Usa el modelo de datos del catálogo:
///   deportes: nombre, estado, cupoMaximo/cuposMaximos
///   inscripciones: deporteId, estado
///   users: rol
class AdminStatsView extends StatelessWidget {
  const AdminStatsView({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    return StreamBuilder<QuerySnapshot>(
      stream: db.collection('deportes').snapshots(),
      builder: (context, sportsSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: db.collection('inscripciones').snapshots(),
          builder: (context, inscSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: db.collection('users').snapshots(),
              builder: (context, usersSnap) {
                final err = sportsSnap.error ?? inscSnap.error ?? usersSnap.error;
                if (err != null) {
                  return AdminPage(children: [Text('Error al cargar reportes: $err')]);
                }
                if (!sportsSnap.hasData || !inscSnap.hasData || !usersSnap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(60),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final sports = sportsSnap.data!.docs;
                final users = usersSnap.data!.docs
                    .map((d) => d.data() as Map<String, dynamic>)
                    .toList();

                final Map<String, int> porDeporte = {};
                int inscActivas = 0;
                for (final d in inscSnap.data!.docs) {
                  final m = d.data() as Map<String, dynamic>;
                  if (m['estado'] == 'Cancelada') continue;
                  inscActivas++;
                  final id = m['deporteId']?.toString();
                  if (id != null) porDeporte[id] = (porDeporte[id] ?? 0) + 1;
                }

                final estudiantes = users.where((u) => u['rol'] == 'Estudiante').length;
                final entrenadores = users.where((u) => u['rol'] == 'Entrenador').length;
                final activas = sports
                    .where((d) => ((d.data() as Map)['estado'] ?? 'Activo') == 'Activo')
                    .length;

                final ranking = sports.map((d) {
                  final m = d.data() as Map<String, dynamic>;
                  final cupo =
                      ((m['cuposMaximos'] ?? m['cupoMaximo'] ?? 0) as num).toInt();
                  return _Bar(
                    (m['nombre'] ?? 'Sin nombre').toString(),
                    porDeporte[d.id] ?? 0,
                    cupo,
                  );
                }).toList()
                  ..sort((a, b) => b.valor.compareTo(a.valor));

                final ocupacion = ranking.where((b) => b.cupo > 0).toList()
                  ..sort((a, b) => (b.valor / b.cupo).compareTo(a.valor / a.cupo));

                return AdminPage(
                  children: [
                    const SectionTitle(
                      title: 'Reportes y Estadísticas',
                      subtitle: 'Uso de la plataforma en tiempo real.',
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _Kpi('Disciplinas activas', '$activas', Icons.sports_soccer, kOrange),
                        _Kpi('Estudiantes', '$estudiantes', Icons.school_outlined, kNavy),
                        _Kpi('Entrenadores', '$entrenadores', Icons.sports, kNavy),
                        _Kpi('Inscripciones activas', '$inscActivas',
                            Icons.how_to_reg_outlined, kOrange),
                      ],
                    ),
                    const SizedBox(height: 24),
                    LayoutBuilder(builder: (context, c) {
                      final wide = c.maxWidth > 900;
                      final top = _ChartCard(
                        title: 'Deportes más buscados',
                        subtitle: 'Inscripciones por disciplina',
                        bars: ranking.take(6).toList(),
                        maxValue: ranking.isEmpty ? 1 : ranking.first.valor,
                        color: kOrange,
                      );
                      final ocup = _ChartCard(
                        title: 'Ocupación de cupos',
                        subtitle: 'Inscritos / cupo máximo',
                        bars: ocupacion.take(6).toList(),
                        maxValue: 1,
                        color: kNavy,
                        asRatio: true,
                      );
                      return wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: top),
                                const SizedBox(width: 16),
                                Expanded(child: ocup),
                              ],
                            )
                          : Column(children: [top, const SizedBox(height: 16), ocup]);
                    }),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _Bar {
  final String etiqueta;
  final int valor;
  final int cupo;
  _Bar(this.etiqueta, this.valor, this.cupo);
}

class _Kpi extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _Kpi(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: AdminCard(
        child: Row(
          children: [
            Icon(icon, size: 34, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color),
                  ),
                  Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_Bar> bars;
  final int maxValue;
  final Color color;
  final bool asRatio;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.bars,
    required this.maxValue,
    required this.color,
    this.asRatio = false,
  });

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: kNavy),
          ),
          Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          const SizedBox(height: 16),
          if (bars.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Aún no hay datos.')),
            ),
          for (final b in bars)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _barRow(b),
            ),
        ],
      ),
    );
  }

  Widget _barRow(_Bar b) {
    final double frac = asRatio
        ? (b.cupo == 0 ? 0.0 : (b.valor / b.cupo).clamp(0.0, 1.0).toDouble())
        : (maxValue == 0 ? 0.0 : (b.valor / maxValue).clamp(0.0, 1.0).toDouble());
    final String label =
        asRatio ? '${(frac * 100).round()}%  (${b.valor}/${b.cupo})' : '${b.valor}';
    return Row(
      children: [
        SizedBox(width: 120, child: Text(b.etiqueta, overflow: TextOverflow.ellipsis)),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: frac,
              minHeight: 16,
              color: color,
              backgroundColor: const Color(0xFFE9ECEF),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(width: 90, child: Text(label, textAlign: TextAlign.right)),
      ],
    );
  }
}
