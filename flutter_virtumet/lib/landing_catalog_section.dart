import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'registration_page.dart';

/// Catálogo público de la landing: muestra en tiempo real las disciplinas que
/// publica el administrador (colección `deportes`), con el mismo diseño de
/// tarjetas del catálogo del estudiante. Es solo vista: el botón "Inscribirme"
/// lleva a crear cuenta. No lee `inscripciones` (los cupos salen de
/// `cuposInscritos` en el propio documento del deporte).
class LandingCatalogSection extends StatefulWidget {
  const LandingCatalogSection({super.key});

  @override
  State<LandingCatalogSection> createState() => _LandingCatalogSectionState();
}

class _LandingCatalogSectionState extends State<LandingCatalogSection> {
  static const Color orangePrimary = Color(0xFFFF5500);
  static const Color blueDark = Color(0xFF0F2C59);
  static const Color border = Color(0xFFCBD5E1);

  static const List<String> _categories = [
    'Todas las disciplinas',
    'De equipo',
    'Individuales',
  ];

  String _query = '';
  String _category = _categories.first;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF8F9FA),
      padding: const EdgeInsets.symmetric(vertical: 70, horizontal: 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CATÁLOGO DEPORTIVO',
                style: TextStyle(
                  color: orangePrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Disciplinas disponibles',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: blueDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Explora las disciplinas y sus cupos en tiempo real. Para inscribirte necesitas una cuenta.',
                style: TextStyle(color: Colors.black54, fontSize: 15),
              ),
              const SizedBox(height: 24),
              _filters(),
              const SizedBox(height: 24),
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('deportes').snapshots(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return _emptyBox(
                      Icons.error_outline,
                      'No se pudo cargar el catálogo en este momento.',
                    );
                  }
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(50),
                        child: CircularProgressIndicator(color: orangePrimary),
                      ),
                    );
                  }

                  final docs = (snap.data?.docs ?? []).where((d) {
                    final m = d.data() as Map<String, dynamic>;
                    // Las disciplinas inactivas no se muestran al público
                    final estado = (m['estado'] ?? 'Activo').toString();
                    if (estado == 'Inactivo') return false;
                    final hay = '${m['nombre'] ?? ''} ${m['codigo'] ?? ''} '
                            '${m['entrenador'] ?? ''} ${m['lugar'] ?? ''}'
                        .toLowerCase();
                    final cat = (m['categoria'] ?? 'De equipo').toString();
                    final okCat = _category == _categories.first || cat == _category;
                    return hay.contains(_query) && okCat;
                  }).toList();

                  if (docs.isEmpty) {
                    return _emptyBox(
                      Icons.sports_soccer_outlined,
                      'No hay disciplinas disponibles por ahora.',
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 400,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, i) => _card(context, docs[i]),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filters() {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 420,
          height: 46,
          child: TextField(
            onChanged: (v) => setState(() => _query = v.toLowerCase().trim()),
            decoration: InputDecoration(
              hintText: 'Buscar por disciplina, código, entrenador o lugar...',
              hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
              prefixIcon: const Icon(Icons.search, size: 20, color: blueDark),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: border, width: 1.2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: border, width: 1.2),
              ),
            ),
          ),
        ),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border, width: 1.2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _category,
              items: [
                for (final c in _categories)
                  DropdownMenuItem(
                    value: c,
                    child: Text(c,
                        style: const TextStyle(fontSize: 13, color: blueDark)),
                  ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyBox(IconData icon, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(
              color: blueDark,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    final String codigo = (m['codigo'] ?? 'DE-001').toString();
    final String nombre = (m['nombre'] ?? 'Sin Nombre').toString();
    final String horario = (m['horario'] ?? 'Por definir').toString();
    final String lugar = (m['lugar'] ?? 'Instalaciones UNIMET').toString();
    final String entrenador = (m['entrenador'] ?? 'Por asignar').toString();
    final String imageUrl = (m['imageUrl'] ?? '').toString();
    final String categoria = (m['categoria'] ?? 'De equipo').toString();
    final String estado = (m['estado'] ?? 'Activo').toString();
    final int cuposMax = ((m['cuposMaximos'] ?? m['cupoMaximo'] ?? 20) as num).toInt();
    final int inscritos = ((m['cuposInscritos'] ?? 0) as num).toInt();
    final int disponibles = (cuposMax - inscritos).clamp(0, cuposMax);
    final bool enMantenimiento = estado == 'Mantenimiento';
    final bool puedeInscribirse = disponibles > 0 && !enMantenimiento;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        height: 130,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _fallbackHeader(),
                      )
                    : _fallbackHeader(),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: blueDark.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    codigo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoria.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nombre,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: blueDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  _detailRow(Icons.access_time_rounded, horario),
                  const SizedBox(height: 4),
                  _detailRow(Icons.location_on_outlined, lugar),
                  const SizedBox(height: 4),
                  _detailRow(Icons.person_outline_rounded, 'Entrenador: $entrenador'),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: puedeInscribirse
                              ? Colors.green.withValues(alpha: 0.12)
                              : Colors.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          enMantenimiento
                              ? 'En mantenimiento'
                              : '$disponibles / $cuposMax cupos',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: puedeInscribirse ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: puedeInscribirse ? orangePrimary : Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        // Sin sesión no se puede inscribir: lleva a crear cuenta
                        onPressed: puedeInscribirse
                            ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegistrationPage(),
                                  ),
                                )
                            : null,
                        child: Text(
                          puedeInscribirse
                              ? 'Inscribirme'
                              : (enMantenimiento ? 'No disponible' : 'Agotado'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackHeader() {
    return Container(
      height: 130,
      width: double.infinity,
      color: blueDark,
      child: const Center(
        child: Icon(Icons.sports_soccer, color: Colors.white, size: 40),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.black54),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Color(0xFF1F2937)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
